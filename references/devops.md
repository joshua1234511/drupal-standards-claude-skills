# DevOps and Deployment Standards

Standards for CI/CD, GitHub Actions, build optimization, and deployment workflows for Drupal projects.

## Table of Contents

1. [GitHub Actions](#github-actions)
2. [Build Optimization](#build-optimization)
3. [Configuration Management](#configuration-management)
4. [Deployment Workflows](#deployment-workflows)
5. [Environment Configuration](#environment-configuration)

---

## GitHub Actions

### GHA001: Use Latest Action Versions

**Severity:** `medium`

Use the latest stable versions of GitHub Actions.

**Good Example:**
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      # ✅ Use v4 for latest features
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, xml, ctype, iconv, intl, pdo_mysql, dom, filter, gd, json, mbstring, pdo
          coverage: xdebug
          tools: composer:v2
      
      # Cache Composer dependencies
      - name: Get Composer cache directory
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT
      
      - uses: actions/cache@v4
        with:
          path: ${{ steps.composer-cache.outputs.dir }}
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: ${{ runner.os }}-composer-
      
      - name: Install dependencies
        run: composer install --no-progress --prefer-dist --optimize-autoloader
      
      - name: Run tests
        run: ./vendor/bin/phpunit
      
      # ✅ Upload artifacts with v4
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-results
          path: |
            tests/results/
            var/log/
          retention-days: 7
```

**Bad Example:**
```yaml
# ❌ Using outdated versions
- uses: actions/checkout@v2
- uses: actions/upload-artifact@v2
- uses: actions/cache@v2
```

---

### GHA002: Implement Dependency Caching

**Severity:** `high`

Cache dependencies to speed up workflow runs.

**Good Example:**
```yaml
name: CI with Caching

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      
      # Composer cache
      - name: Get Composer cache directory
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT
      
      - name: Cache Composer dependencies
        uses: actions/cache@v4
        with:
          path: |
            ${{ steps.composer-cache.outputs.dir }}
            vendor/
          key: php-${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: |
            php-${{ runner.os }}-composer-
      
      # NPM cache
      - name: Cache NPM dependencies
        uses: actions/cache@v4
        with:
          path: |
            ~/.npm
            node_modules/
          key: node-${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            node-${{ runner.os }}-npm-
      
      # Drupal cache
      - name: Cache Drupal
        uses: actions/cache@v4
        with:
          path: |
            web/core/
            web/modules/contrib/
            web/themes/contrib/
          key: drupal-${{ runner.os }}-${{ hashFiles('**/composer.lock') }}
      
      - name: Install PHP dependencies
        run: composer install --no-progress --prefer-dist --optimize-autoloader
      
      - name: Install NPM dependencies
        run: npm ci
```

---

### GHA003: Security Best Practices

**Severity:** `high`

Follow security best practices for GitHub Actions.

**Good Example:**
```yaml
name: Secure CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  pull-requests: write

jobs:
  security-scan:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      # Use minimum required permissions
      - name: Check Composer audit
        run: composer audit
      
      # Don't expose secrets in logs
      - name: Deploy
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
        run: |
          # ✅ Use environment variable, don't echo secrets
          ./scripts/deploy.sh
      
      # Pin action versions with SHA for security
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
      
      # Use OIDC for cloud deployments instead of long-lived credentials
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-actions
          aws-region: us-east-1
  
  code-scanning:
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript, php
      
      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
```

---

### GHA004: Set Appropriate Timeouts

**Severity:** `medium`

Set job and step timeouts to prevent hung workflows.

**Good Example:**
```yaml
name: CI with Timeouts

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Job timeout
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        timeout-minutes: 10
        run: composer install
      
      - name: Run unit tests
        timeout-minutes: 15
        run: ./vendor/bin/phpunit --testsuite unit
      
      - name: Run integration tests
        timeout-minutes: 20
        run: ./vendor/bin/phpunit --testsuite integration
        continue-on-error: false
  
  deploy:
    needs: test
    runs-on: ubuntu-latest
    timeout-minutes: 15
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Deploy to production
        timeout-minutes: 10
        run: ./scripts/deploy.sh
```

---

### GHA005: Complete CI/CD Workflow

**Severity:** `high`

Implement a complete CI/CD workflow for Drupal.

**Good Example:**
```yaml
# .github/workflows/drupal-ci.yml
name: Drupal CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  PHP_VERSION: '8.2'
  NODE_VERSION: '20'
  COMPOSER_MEMORY_LIMIT: -1

jobs:
  # Static analysis and linting
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
          tools: phpcs, phpstan, php-cs-fixer
      
      - name: Install dependencies
        run: composer install --no-progress
      
      - name: PHP CodeSniffer
        run: vendor/bin/phpcs --standard=Drupal,DrupalPractice web/modules/custom
      
      - name: PHPStan
        run: vendor/bin/phpstan analyse web/modules/custom --level=5
      
      - name: Check Drupal coding standards
        run: vendor/bin/drupal-check web/modules/custom
  
  # Unit and kernel tests
  test-unit:
    runs-on: ubuntu-latest
    needs: lint
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: drupal_test
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
          extensions: mbstring, xml, pdo_mysql, gd
          coverage: xdebug
      
      - name: Get Composer cache
        id: composer-cache
        run: echo "dir=$(composer config cache-files-dir)" >> $GITHUB_OUTPUT
      
      - uses: actions/cache@v4
        with:
          path: ${{ steps.composer-cache.outputs.dir }}
          key: composer-${{ hashFiles('**/composer.lock') }}
      
      - name: Install dependencies
        run: composer install --no-progress
      
      - name: Run unit tests
        run: vendor/bin/phpunit --testsuite unit --coverage-clover coverage.xml
      
      - name: Run kernel tests
        env:
          SIMPLETEST_DB: mysql://root:root@127.0.0.1:3306/drupal_test
        run: vendor/bin/phpunit --testsuite kernel
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: coverage.xml
  
  # Functional tests
  test-functional:
    runs-on: ubuntu-latest
    needs: lint
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: drupal_test
        ports:
          - 3306:3306
      
      chrome:
        image: selenium/standalone-chrome:latest
        ports:
          - 4444:4444
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ env.PHP_VERSION }}
      
      - name: Install dependencies
        run: composer install --no-progress
      
      - name: Install Drupal
        run: |
          cd web
          php core/scripts/drupal install minimal --db-url=mysql://root:root@127.0.0.1:3306/drupal_test
      
      - name: Start PHP server
        run: |
          cd web
          php -S localhost:8888 &
          sleep 5
      
      - name: Run functional tests
        env:
          SIMPLETEST_DB: mysql://root:root@127.0.0.1:3306/drupal_test
          SIMPLETEST_BASE_URL: http://localhost:8888
          MINK_DRIVER_ARGS_WEBDRIVER: '["chrome", {"browserName":"chrome"}, "http://localhost:4444/wd/hub"]'
        run: vendor/bin/phpunit --testsuite functional
  
  # Build frontend assets
  build-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build assets
        run: npm run build
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: frontend-build
          path: web/themes/custom/*/dist/
  
  # Deploy to staging
  deploy-staging:
    runs-on: ubuntu-latest
    needs: [test-unit, test-functional, build-frontend]
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download frontend build
        uses: actions/download-artifact@v4
        with:
          name: frontend-build
          path: web/themes/custom/
      
      - name: Deploy to staging
        env:
          SSH_PRIVATE_KEY: ${{ secrets.STAGING_SSH_KEY }}
          DEPLOY_HOST: ${{ secrets.STAGING_HOST }}
        run: ./scripts/deploy.sh staging
  
  # Deploy to production
  deploy-production:
    runs-on: ubuntu-latest
    needs: [test-unit, test-functional, build-frontend]
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Download frontend build
        uses: actions/download-artifact@v4
        with:
          name: frontend-build
      
      - name: Deploy to production
        env:
          SSH_PRIVATE_KEY: ${{ secrets.PRODUCTION_SSH_KEY }}
          DEPLOY_HOST: ${{ secrets.PRODUCTION_HOST }}
        run: ./scripts/deploy.sh production
```

---

## Build Optimization

### BUILD001: Optimize Frontend Builds

**Severity:** `medium`

Configure build tools for optimal production output.

**Good Example:**
```javascript
// webpack.config.js
const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = (env, argv) => {
  const isProduction = argv.mode === 'production';

  return {
    mode: isProduction ? 'production' : 'development',
    
    entry: {
      main: './src/js/main.js',
      admin: './src/js/admin.js',
    },
    
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: isProduction ? '[name].[contenthash].js' : '[name].js',
      clean: true,
    },
    
    // Source maps for debugging
    devtool: isProduction ? 'source-map' : 'eval-source-map',
    
    optimization: {
      minimize: isProduction,
      minimizer: [
        new TerserPlugin({
          terserOptions: {
            compress: {
              drop_console: isProduction,
            },
          },
        }),
        new CssMinimizerPlugin(),
      ],
      // Code splitting
      splitChunks: {
        chunks: 'all',
        cacheGroups: {
          vendor: {
            test: /[\\/]node_modules[\\/]/,
            name: 'vendors',
            chunks: 'all',
          },
        },
      },
      // Use deterministic IDs for better caching
      moduleIds: 'deterministic',
    },
    
    plugins: [
      new MiniCssExtractPlugin({
        filename: isProduction ? '[name].[contenthash].css' : '[name].css',
      }),
    ],
    
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader',
            options: {
              presets: ['@babel/preset-env'],
              cacheDirectory: true,
            },
          },
        },
        {
          test: /\.scss$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            'postcss-loader',
            'sass-loader',
          ],
        },
      ],
    },
  };
};
```

---

## Configuration Management

### CONFIG001: Export and Import Configuration

**Severity:** `high`

Use proper configuration management workflows.

**Good Example:**
```bash
#!/bin/bash
# scripts/sync-config.sh

set -e

ENVIRONMENT="${1:-local}"

echo "Syncing configuration for $ENVIRONMENT environment..."

# Export current configuration
drush config:export -y

# Check for configuration changes
if [[ $(git status --porcelain config/sync/) ]]; then
  echo "Configuration changes detected:"
  git diff config/sync/
  
  # In CI, fail if there are unexpected changes
  if [[ "$CI" == "true" ]]; then
    echo "ERROR: Unexpected configuration changes in CI"
    exit 1
  fi
fi

# Import configuration
drush config:import -y

# Clear caches
drush cache:rebuild

echo "Configuration sync complete."
```

```yaml
# config/sync/system.site.yml
uuid: 12345678-1234-1234-1234-123456789abc
name: 'My Drupal Site'
mail: admin@example.com
page:
  403: ''
  404: ''
  front: /node
admin_compact_mode: false
weight_select_max: 100
langcode: en
default_langcode: en

# config/sync/mymodule.settings.yml
api_endpoint: ''
cache_lifetime: 3600
features:
  feature_a: true
  feature_b: false
```

---

### CONFIG002: Environment-Specific Configuration

**Severity:** `high`

Handle environment-specific configuration properly.

**Good Example:**
```php
// settings.php

// Load environment-specific settings
$env = getenv('DRUPAL_ENV') ?: 'local';
$settings_file = __DIR__ . "/settings.{$env}.php";

if (file_exists($settings_file)) {
  include $settings_file;
}

// Configuration split based on environment
$config['config_split.config_split.local']['status'] = ($env === 'local');
$config['config_split.config_split.dev']['status'] = ($env === 'development');
$config['config_split.config_split.staging']['status'] = ($env === 'staging');
$config['config_split.config_split.prod']['status'] = ($env === 'production');
```

```yaml
# config/split/local/devel.settings.yml
# Local-only development settings
toolbar:
  enabled: true
devel_dumper:
  default_dumper: kint

# config/split/prod/system.performance.yml
# Production performance settings
cache:
  page:
    max_age: 900
preprocess:
  css: true
  js: true
```

---

## Deployment Workflows

### DEPLOY001: Deployment Script

**Severity:** `high`

Use automated deployment scripts with proper checks.

**Good Example:**
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT="${1:-staging}"
DEPLOY_PATH="/var/www/${ENVIRONMENT}"
BACKUP_PATH="/var/backups/${ENVIRONMENT}"
RELEASE_PATH="${DEPLOY_PATH}/releases/$(date +%Y%m%d%H%M%S)"
CURRENT_PATH="${DEPLOY_PATH}/current"

echo "========================================"
echo "Deploying to ${ENVIRONMENT}"
echo "========================================"

# Pre-deployment checks
echo "Running pre-deployment checks..."

# Check if required environment variables are set
if [[ -z "$SSH_PRIVATE_KEY" ]] || [[ -z "$DEPLOY_HOST" ]]; then
  echo "ERROR: Missing required environment variables"
  exit 1
fi

# Set up SSH
mkdir -p ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/deploy_key
chmod 600 ~/.ssh/deploy_key
ssh-keyscan -H "$DEPLOY_HOST" >> ~/.ssh/known_hosts

# Create release directory
ssh -i ~/.ssh/deploy_key "deploy@${DEPLOY_HOST}" "mkdir -p ${RELEASE_PATH}"

# Deploy code
echo "Deploying code..."
rsync -avz --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='web/sites/*/files' \
  -e "ssh -i ~/.ssh/deploy_key" \
  ./ "deploy@${DEPLOY_HOST}:${RELEASE_PATH}/"

# Run deployment tasks on server
ssh -i ~/.ssh/deploy_key "deploy@${DEPLOY_HOST}" << EOF
  set -e
  cd ${RELEASE_PATH}
  
  # Link shared files
  ln -nfs ${DEPLOY_PATH}/shared/files ${RELEASE_PATH}/web/sites/default/files
  ln -nfs ${DEPLOY_PATH}/shared/settings.local.php ${RELEASE_PATH}/web/sites/default/settings.local.php
  
  # Install dependencies
  composer install --no-dev --optimize-autoloader
  
  # Run database updates
  cd web
  drush updatedb -y
  
  # Import configuration
  drush config:import -y
  
  # Clear caches
  drush cache:rebuild
  
  # Switch symlink to new release
  ln -nfs ${RELEASE_PATH} ${CURRENT_PATH}
  
  # Cleanup old releases (keep last 5)
  cd ${DEPLOY_PATH}/releases
  ls -1t | tail -n +6 | xargs -r rm -rf
  
  echo "Deployment complete!"
EOF

# Post-deployment verification
echo "Verifying deployment..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://${ENVIRONMENT}.example.com/")

if [[ "$RESPONSE" != "200" ]]; then
  echo "ERROR: Site returned HTTP ${RESPONSE}"
  
  # Rollback
  echo "Rolling back..."
  ssh -i ~/.ssh/deploy_key "deploy@${DEPLOY_HOST}" << EOF
    PREVIOUS=\$(ls -1t ${DEPLOY_PATH}/releases | sed -n '2p')
    ln -nfs ${DEPLOY_PATH}/releases/\${PREVIOUS} ${CURRENT_PATH}
EOF
  
  exit 1
fi

echo "========================================"
echo "Deployment successful!"
echo "========================================"
```

---

## Environment Configuration

### ENV001: Environment Variables

**Severity:** `high`

Use environment variables for configuration that varies between environments.

**Good Example:**
```bash
# .env.example (committed to repo)
DRUPAL_ENV=local
DB_HOST=localhost
DB_NAME=drupal
DB_USER=drupal
DB_PASS=
DB_PORT=3306

HASH_SALT=

# External services
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=

# API keys (never commit actual values)
GOOGLE_MAPS_API_KEY=
RECAPTCHA_SITE_KEY=
RECAPTCHA_SECRET_KEY=

# Feature flags
FEATURE_NEW_CHECKOUT=false
FEATURE_DARK_MODE=false
```

```php
// settings.php

// Database configuration from environment
$databases['default']['default'] = [
  'driver' => 'mysql',
  'host' => getenv('DB_HOST') ?: 'localhost',
  'port' => getenv('DB_PORT') ?: '3306',
  'database' => getenv('DB_NAME') ?: 'drupal',
  'username' => getenv('DB_USER') ?: 'drupal',
  'password' => getenv('DB_PASS') ?: '',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
];

// Hash salt
$settings['hash_salt'] = getenv('HASH_SALT') ?: 'default-hash-salt-change-in-production';

// Trusted host patterns
$settings['trusted_host_patterns'] = [
  '^' . preg_quote(getenv('SITE_DOMAIN') ?: 'localhost') . '$',
  '^www\.' . preg_quote(getenv('SITE_DOMAIN') ?: 'localhost') . '$',
];

// Feature flags
$config['mymodule.settings']['features']['new_checkout'] = 
  filter_var(getenv('FEATURE_NEW_CHECKOUT'), FILTER_VALIDATE_BOOLEAN);
$config['mymodule.settings']['features']['dark_mode'] = 
  filter_var(getenv('FEATURE_DARK_MODE'), FILTER_VALIDATE_BOOLEAN);
```
