# DevOps and Deployment Standards

Standards for CI/CD, GitHub Actions, build optimization, and deployment workflows for Drupal projects.

## Table of Contents

1. [GitHub Actions](#github-actions)
2. [Build Optimization](#build-optimization)
3. [Configuration Management](#configuration-management)
4. [Deployment Workflows](#deployment-workflows)
5. [Environment Configuration](#environment-configuration)
6. [Drupal.org Contribution Workflow](#drupalorg-contribution-workflow)
7. [Commit Messages](#commit-messages)
8. [Merge Requests](#merge-requests)
9. [GitLab CI (Drupal.org)](#gitlab-ci-drupalorg)
10. [Drupal.org to GitLab Migration](#drupalorg-to-gitlab-migration)

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

---

## Drupal.org Contribution Workflow

Drupal hosts its source code on a self-managed GitLab instance at `git.drupalcode.org`. Contributing to Drupal core or contrib projects follows conventions that differ from a typical GitHub fork-and-PR flow: an **issue-fork workflow** for branches and MRs, a **work items API** for issue tracking, and **Drupal Conventional Commits** for commit messages. Use the GitLab CLI (`glab`) and the GitLab REST API for these tasks.

### CONTRIB001: Use the Issue-Fork Model

**Severity:** `high`

Drupal does not use personal forks. Each issue gets a **dedicated fork** at `git.drupalcode.org/issue/<project>-<issue-id>`. Push your branch to that fork, then open a merge request **from the fork to the upstream project**. A fork is never created by pushing or via the API — always provision it first with a `/do:fork` comment on the work item or via the Drupal.org management UI.

Default to the issue fork even if you are a maintainer with push access. Drupal's collaboration culture is that *anyone* can contribute to an issue through its fork; pushing directly to `project/<repo>` locks non-maintainers out of collaborating.

**Good Example:**
```bash
# 1. View the work item (always pass --repo; never rely on cwd)
glab issue view 3586461 --repo "git.drupalcode.org/project/token"

# 2. Provision the issue fork by commenting /do:fork on the work item,
#    or clicking "Create issue fork" on the Drupal.org management page.
#    (Never create it by pushing or via the API — that returns 404/301.)

# 3. Add the fork remote. Note: SSH uses the ORIGIN host git.drupal.org,
#    NOT the CDN host git.drupalcode.org (which has no SSH listener).
git remote add token-3586461 git@git.drupal.org:issue/token-3586461.git

# 4. Branch as {issue-id}-{short-description}
git switch -c 3586461-add-issue-templates

# 5. Push to the issue fork (not to origin)
git push token-3586461 3586461-add-issue-templates
```

**Bad Example:**
```bash
# ❌ Creating a personal fork (Drupal doesn't use these)
# ❌ Pushing your branch straight to the upstream project as a maintainer
git push origin 3586461-add-issue-templates

# ❌ SSH remote pointing at the CDN host — hangs and times out on port 22
git remote add fork git@git.drupalcode.org:issue/token-3586461.git

# ❌ Trying to create the fork by pushing to a non-existent fork URL (404)
```

---

### CONTRIB002: Follow the Contributor Happy Path

**Severity:** `medium`

For a migrated project, follow this end-to-end sequence when submitting a change:

1. **Find or create the work item** — `glab issue view <id>` / `glab issue create`.
2. **Get a usable issue fork** — the step most people miss; you cannot push without it.
3. **Set up remotes & branch** — add the fork remote, branch as `{issue-id}-{short-description}`.
4. **Commit** in Conventional Commits format with `By:` lines (see COMMIT001).
5. **Push to the fork & open the MR** via the REST API — `glab mr create` cannot do cross-project (fork→upstream) MRs.
6. **Wire the MR to the issue** — put `Closes #<id>` in the description so GitLab links both sides and auto-closes the issue on merge.

**Is the project on GitLab yet?** Drupal.org is mid-migration. Migrated projects have issues at `git.drupalcode.org/project/<repo>/-/work_items/<id>` — use `glab`. Non-migrated projects keep issues at `www.drupal.org/project/<repo>/issues` — `glab` cannot see the legacy queue; use the drupal.org web UI or `drupalorg-cli`. An empty `glab issue list` on an obviously active project usually means it is still on the legacy queue.

**Getting a usable issue fork (decision tree):**
```
Does an issue fork exist yet?
├─ No  → create it:   /do:fork    (issue comment)  ·or·  "Create fork"    (Drupal.org page)
└─ Yes → do you already have push access?
         ├─ Yes → use it
         └─ No  → request access: /do:access (issue comment) ·or· "Request access" (page)
```

**Check access before requesting it:** a `git push` that 403s means you need `/do:access`; a 404 on the fork URL means the fork does not exist yet (`/do:fork`).

---

### CONTRIB003: Manage Issues via Work Items

**Severity:** `medium`

Issue URLs use `/-/work_items/<id>` (not `/-/issues/<id>`). Use `glab issue` commands, always passing `--repo`. Do not require a work item to exist — some projects still use the legacy queue.

**Good Example:**
```bash
# Look up issue templates before creating
ls .gitlab/issue_templates/
cat ".gitlab/issue_templates/Bug.md"

# Create a work item (check labels first with `glab label list`)
glab issue create \
  --title "Short descriptive title of the issue" \
  --description "$(cat /tmp/issue_body.md)" \
  --label "bug,needs-review" \
  --assignee "@me" \
  --repo "git.drupalcode.org/project/token"

# Common operations
glab issue list --repo "git.drupalcode.org/project/token"
glab issue view 3586461 --repo "git.drupalcode.org/project/token"
# ✅ `glab issue comment` requires -m, NOT --body
glab issue comment 3586461 -m "Message" --repo "git.drupalcode.org/project/token"
```

**Bad Example:**
```bash
# ❌ --body is not supported by `glab issue comment`
glab issue comment 3586461 --body "Message"

# ❌ Bare command with no --repo resolves against your default host (often
#    gitlab.com) or 404s — it can't know which Drupal project you mean
glab issue view 3586461
```

---

### CONTRIB004: Track State via Scoped Labels and /do: Commands

**Severity:** `medium`

Issue workflow state (Needs Work, Needs Review, RTBC) is tracked via **scoped labels**, not the work item status widget. Drupal.org's GitLab integration also processes custom `/do:` comment commands — these are not standard GitLab quick actions and only work on git.drupalcode.org.

| Label | Meaning |
|---|---|
| `state::needsWork` | Reviewer requested changes; MR in Draft |
| `state::needsReview` | Ready for a reviewer; MR marked Ready |
| `state::rtbc` | Reviewed and Tested By the Community — approved + CI green, ready to merge |

| `/do:` Command | What it does |
|---|---|
| `/do:fork` | Provisions the issue fork + branch from the default branch |
| `/do:access` | Grants current user access to an existing fork |
| `/do:label ~label1 ~label2` | Adds labels (e.g. `~state::rtbc`) |
| `/do:unlabel ~label1` | Removes a label |
| `/do:relabel ~label1 ~label2` | Replaces all labels |
| `/do:assign @username` / `/do:unassign` / `/do:reassign` | Manage assignees |

Label names are project-configurable — check `glab label list --repo "…"` first. The MR Draft/Ready toggle maps to issue state: Draft → Needs Work; Ready → Needs Review.

---

### CONTRIB005: Do Not Pull People In Unprompted

**Severity:** `medium`

Do not `@`-mention, assign, or add as reviewer any contributor in issues, MRs, comments, or commit messages unless the human directed you to. Pinging someone carries social weight (a notification, an implied ask on their time); deciding *whom* to involve is the maintainer's judgment call. State the substance instead — flag the open question or request review in general terms — and leave the tagging to the human. (`@me` for self-assignment is fine.)

---

## Commit Messages

### COMMIT001: Use Drupal Conventional Commits Format

**Severity:** `high`

Drupal uses the **Conventional Commits** specification with a Drupal-specific issue reference and `By:` attribution lines.

**Format:**
```
{type}: #{issue-id} Short summary of the change

Optional body — explain the why, not the what.
Wrap at ~72 characters.

By: drupal-username
By: other-contributor
```

**Types:** `feat` · `fix` · `docs` · `refactor` · `test` · `ci` · `perf` · `task` · `revert`

**Rules:**
- The issue ID is the last segment of the issue URL (e.g. `3586461` from `/-/work_items/3586461`). The numeric ID is identical on drupal.org and GitLab — no conversion needed.
- `By:` lines use **Drupal.org usernames**, not GitLab names, email addresses, or `@username` syntax — ask the user if unsure.
- Use `By:` for all contributors (author, reviewer, reporter). Maintainers may also use `Co-authored-by:`, `Reviewed-by:`, or `Reported-by:` for specificity.

**Good Example:**
```
feat: #3586461 Add standardized commit message format

Introduces the issue-template stub so contributors get a consistent
prompt when opening a work item.

By: drupal-username
By: another-contributor
```

**Bad Example:**
```
# ❌ No type prefix, no issue reference, uses a GitHub-style @handle / email
Added issue templates

By: @some-user <user@example.com>
```

---

## Merge Requests

### MR001: Open Cross-Project MRs via the REST API

**Severity:** `high`

MRs go **from the issue fork to the upstream project**. `glab mr create` cannot create cross-project (fork→upstream) MRs — use the GitLab REST API directly via `glab api`.

**Path encoding gotcha:** the REST API identifies a project by its namespaced path *URL-encoded* — the `/` becomes `%2F`. So `project/<repo>` is written `project%2F<repo>`, and `issue/<project>-<issue-id>` becomes `issue%2F<project>-<issue-id>` in API paths.

**Good Example:**
```bash
# Check for an existing MR first
glab mr list --repo "git.drupalcode.org/project/token"

# 1. Read the MR template and fill it in
cat .gitlab/merge_request_templates/Default.md

# 2. Find the UPSTREAM project's numeric ID (for target_project_id)
glab api --hostname git.drupalcode.org "/projects/project%2Ftoken"   # read the `id` field

# 3. Create the MR from the fork (path in URL) to upstream, body inline
glab api --hostname git.drupalcode.org \
  -F target_project_id=<upstream-id> \
  -f source_branch="3586461-add-issue-templates" \
  -f target_branch="main" \
  -f title="feat: #3586461 Short summary" \
  -f description='## Summary

What this MR does, in a single-quoted multi-line string. Markdown `code`
is fine inside single quotes.

Closes #3586461

AI-Generated: Yes (Used Claude to draft the issue templates.)' \
  -F remove_source_branch=true \
  "/projects/issue%2Ftoken-3586461/merge_requests"
```

**Bad Example:**
```bash
# ❌ glab mr create cannot do cross-project fork→upstream MRs
glab mr create --source-branch 3586461-add-issue-templates --target-branch main
```

**MR conventions:**
- **Title:** `{type}: #{issue-id} Short summary` — Conventional Commits format. GitLab squash-merges use the MR *title* as the commit message, so the title itself must follow the standard.
- **Target branch:** confirm with the user if not `main`.
- **Link the issue:** put `Closes #<id>` in the description.
- Mark the MR **Draft** while working, **Ready** when it needs review.

---

### MR002: Add the Required AI Disclosure

**Severity:** `high`

Drupal's [AI contribution policy](https://www.drupal.org/docs/develop/issues/issue-procedures-and-etiquette/policy-on-the-use-of-ai-when-contributing-to-drupal) requires disclosing any significant AI-assisted contribution. Append an `AI-Generated:` line to the MR description.

**Good Example:**
```
AI-Generated: Yes (Used Claude Code to refactor the service and write tests.)
```

---

### MR003: Merge and Rebase Constraints

**Severity:** `high`

Drupal.org projects require **fast-forward merges**, and merges must go through the **GitLab web UI** — API/CLI merges are blocked at the infrastructure level.

**Key constraints:**
- **API merges are blocked** — even a maintainer with a full `api`-scoped PAT cannot merge via `PUT /projects/:id/merge_requests/:iid/merge` or `glab mr merge`; both return permission errors or a 301 redirect to `drupal.org/git-error`. Direct anyone asking "can you commit this?" to the web UI merge button.
- **`detailed_merge_status: mergeable` does not mean the merge button is available** — the API reports `mergeable` when there are no conflicts/blocking discussions/CI failures, but does not account for whether the branch needs a rebase to fast-forward. If the branch is behind the target (e.g. `1.0.x`), rebase first.
- **Merging one MR staleness the siblings** — because merges must fast-forward, landing one MR advances the target branch and greys out the merge button on every other open MR targeting it. Merge siblings back-to-back, rebasing each after the previous lands.

**Good Example — rerolling / rebasing a stale branch:**
```bash
git fetch origin
git rebase origin/1.0.x
# resolve any conflicts (keep BOTH changes when two siblings touched a file)
git push --force-with-lease <issue-fork-remote> 3586461-add-issue-templates
```

---

### MR004: Prefer glab api Over curl; Never WebFetch GitLab URLs

**Severity:** `medium`

Use `glab api` for all REST calls — it handles authentication automatically, supports `--form` for multipart uploads and `--input` for JSON bodies. There is no remaining use case for `curl` (which requires manual token extraction).

Never WebFetch a GitLab URL — pages are JavaScript-rendered and return no useful content. Extract the IID from the path and use `glab` instead.

| URL pattern | `glab` command |
|-------------|----------------|
| `/-/merge_requests/43` | `glab mr view 43 --repo "git.drupalcode.org/project/<repo>"` |
| `/-/work_items/3588930` | `glab issue view 3588930 --repo "git.drupalcode.org/project/<repo>"` |

**`glab api` flags:** use `-f` / `--raw-field` for strings; `-F` / `--field` for integers, booleans, and repo placeholders. Adding any `-f`/`-F` flag makes the request a POST automatically.

**Two hostnames, different roles:** `git.drupalcode.org` is a Fastly CDN front serving HTTP(S) — use it for the web UI, `glab` subcommands, and `glab api` reads **and writes**. `git.drupal.org` is the GitLab origin — use it for **SSH** `git push` (the CDN has no SSH listener). A `glab api` write sent to `git.drupal.org` is silently downgraded to a GET (`HTTP 200` with a list instead of `201 Created`) — confirm writes by checking for `201` with `-i`.

**Token tiers:** start with Tier 1 read-only scopes (`read_api`, `read_user`, `read_repository`); add Tier 2 write scopes (`api` or `write_repository`) only when pushing/creating MRs/commenting. A GitLab PAT is **not** scoped to a single project — write scopes reach every repo you can write to, including protected release branches. Never push to a protected branch without explicit human approval.

---

## GitLab CI (Drupal.org)

### GLCI001: Inspect and Debug Pipelines with glab ci

**Severity:** `medium`

Use `glab ci` to inspect pipelines and debug failures. `glab ci trace` is the primary debugging tool — it streams the full job log.

**Good Example:**
```bash
glab ci status              # Pipeline status for current branch
glab ci view                # Interactive pipeline view
glab ci trace <job-name>    # Stream full log of a job (best for debugging)

# Or fetch a trace via the API
glab api --hostname git.drupalcode.org "/projects/<id>/jobs/<job-id>/trace"
```

**Bad Example:**
```bash
# ❌ WebFetching the job URL returns no log — the page is JS-rendered
```

---

### GLCI002: Re-run Pipelines by Pushing, Not via the API

**Severity:** `medium`

**Pipeline triggers via the API are blocked** on git.drupalcode.org — `glab ci run` and `POST /projects/:id/pipeline` do not work (permission error or 301 redirect to `drupal.org/git-error`). **Pipelines fire on push events only.** To re-run CI, push a new commit.

**Good Example:**
```bash
# Re-run CI with an empty commit when there is nothing else to push
git commit --allow-empty -m "ci: #3586461 Re-run pipeline"
git push <issue-fork-remote> 3586461-add-issue-templates
```

**Bad Example:**
```bash
# ❌ Blocked at the infrastructure level on git.drupalcode.org
glab ci run
```

---

## Drupal.org to GitLab Migration

### MIGRATE001: Translate Legacy Issue-Queue Vocabulary

**Severity:** `low`

Drupal's contribution workflow moved from the proprietary issue queue to GitLab. Contributors fluent in the old system use vocabulary that maps directly to GitLab concepts — translate it rather than asking them to reframe.

| Drupal.org term | GitLab equivalent |
|---|---|
| Patch | Merge request (MR) — no patch files; all work lives in MR branches |
| Interdiff | MR "Changes" tab, or `git diff <old-sha>..<new-sha>` |
| Needs reroll | Branch needs rebase onto current target (`git rebase origin/1.0.x`) |
| RTBC | `state::rtbc` label + MR approved + CI green |
| Needs review / Needs work | MR Ready awaiting reviewer / MR has requested changes |
| Fixed | MR merged / issue closed |
| Postponed | Issue open, MR closed or not created |
| Follow-up issue | Child item / linked item |
| Issue credit / attribution | Contribution record URL (filled in by the contributor) |
| Commit (applying a patch) | Merge (web UI only) |
| Version tag (e.g. 11.x) | Target branch |
| `By:` line in commit | `By:` line in Conventional Commit (Drupal.org usernames) |

**Things that work differently:**
- **No patch files or interdiffs** — "I posted a patch" means a branch was pushed and an MR opened; interdiffs are generated on demand from MR history.
- **Rerolling = rebasing** onto the current target, then `git push --force-with-lease`.
- **Credit attribution is a separate step** — GitLab posts a contribution-record link in a comment on the work item; the contributor must fill it in themselves to receive credit.
- **Merging requires the web UI** — direct anyone asking "can you commit this?" to the GitLab merge button.

**Common phrases:** "I attached an interdiff" → they pushed new commits, review the updated Changes tab. "This is RTBC" → verify CI is green and check for unresolved threads. "The patch needs a reroll" → rebase onto target. "It's in the queue" → there is a work item but no MR yet.
