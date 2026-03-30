#!/bin/bash
#
# Drupal Development Environment Setup Script
# Installs necessary tools for Drupal development and linting
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}Drupal Development Environment Setup${NC}"
echo -e "${BLUE}==================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# Safety guardrails
# ------------------------------------------------------------------------------
#
# This repository is a containerised DrevOps project. Prefer using the existing
# tooling (e.g. Ahoy commands) rather than installing global tools or generating
# new config files from this script.
#
# If you *really* want to run the generic installer behaviour, pass --generic.
#
GENERIC_MODE=0
for arg in "$@"; do
  case "$arg" in
    --generic)
      GENERIC_MODE=1
      ;;
    -h|--help)
      echo "Usage: $0 [--generic]"
      echo ""
      echo "Without --generic, this script will print safe guidance and exit."
      echo "With --generic, it will attempt to install tools and write config files."
      exit 0
      ;;
  esac
done

if [ -f ".ahoy.yml" ]; then
  echo -e "${GREEN}Detected Ahoy/DrevOps project (.ahoy.yml found).${NC}"
  echo ""
  echo "Use the project's existing tooling instead of this generic installer:"
  echo "  - ahoy lint-be"
  echo "  - ahoy lint-fe"
  echo "  - ahoy lint"
  echo "  - ahoy cli"
  echo ""
  echo -e "${YELLOW}No changes were made.${NC}"
  exit 0
fi

if [ "$GENERIC_MODE" -ne 1 ]; then
  echo -e "${YELLOW}NOTE:${NC} This is a generic environment setup script."
  echo "It can install global tools and create config files in the current directory."
  echo ""
  echo "Run with --generic if you want to proceed."
  exit 0
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Composer
echo -e "${YELLOW}Checking for Composer...${NC}"
if command_exists composer; then
    echo -e "${GREEN}✓ Composer is installed${NC}"
    composer --version
else
    echo -e "${RED}✗ Composer is not installed${NC}"
    echo ""
    echo "Install Composer first (do not run arbitrary installers with sudo):"
    echo "  - https://getcomposer.org/download/"
    echo ""
    exit 1
fi
echo ""

# Add Composer global bin to PATH if not already there
COMPOSER_BIN="$HOME/.composer/vendor/bin"
if [[ ":$PATH:" != *":$COMPOSER_BIN:"* ]]; then
    echo -e "${YELLOW}Adding Composer global bin to PATH...${NC}"
    export PATH="$COMPOSER_BIN:$PATH"
    echo -e "${GREEN}✓ PATH updated${NC}"
fi
echo ""

# Install Drupal Coder (includes PHP_CodeSniffer with Drupal standards)
echo -e "${YELLOW}Installing Drupal Coder...${NC}"
composer global require drupal/coder --no-interaction
echo -e "${GREEN}✓ Drupal Coder installed${NC}"
echo ""

# Configure PHP_CodeSniffer with Drupal standards
echo -e "${YELLOW}Configuring PHP_CodeSniffer...${NC}"
if command_exists phpcs; then
    phpcs --config-set installed_paths "$HOME/.composer/vendor/drupal/coder/coder_sniffer"
    echo -e "${GREEN}✓ PHP_CodeSniffer configured with Drupal standards${NC}"
    
    # Show available standards
    echo "Available coding standards:"
    phpcs -i
else
    echo -e "${RED}✗ PHP_CodeSniffer not found${NC}"
fi
echo ""

# Install PHP Mess Detector
echo -e "${YELLOW}Installing PHP Mess Detector...${NC}"
composer global require phpmd/phpmd --no-interaction
if command_exists phpmd; then
    echo -e "${GREEN}✓ PHP Mess Detector installed${NC}"
    phpmd --version
else
    echo -e "${RED}✗ PHP Mess Detector installation failed${NC}"
fi
echo ""

# Install PHP Copy/Paste Detector
echo -e "${YELLOW}Installing PHP Copy/Paste Detector...${NC}"
composer global require sebastian/phpcpd --no-interaction
if command_exists phpcpd; then
    echo -e "${GREEN}✓ PHP Copy/Paste Detector installed${NC}"
else
    echo -e "${RED}✗ PHP Copy/Paste Detector installation failed${NC}"
fi
echo ""

# Install PHP Static Analysis Tool
echo -e "${YELLOW}Installing PHPStan...${NC}"
composer global require phpstan/phpstan --no-interaction
composer global require mglaman/phpstan-drupal --no-interaction
composer global require phpstan/extension-installer --no-interaction
if command_exists phpstan; then
    echo -e "${GREEN}✓ PHPStan installed${NC}"
    phpstan --version
else
    echo -e "${RED}✗ PHPStan installation failed${NC}"
fi
echo ""

# Install Drupal Check (wrapper around PHPStan for Drupal)
echo -e "${YELLOW}Installing Drupal Check...${NC}"
composer global require mglaman/drupal-check --no-interaction
if command_exists drupal-check; then
    echo -e "${GREEN}✓ Drupal Check installed${NC}"
else
    echo -e "${RED}✗ Drupal Check installation failed${NC}"
fi
echo ""

# Create phpstan.neon configuration file
echo -e "${YELLOW}Creating PHPStan configuration...${NC}"
cat > phpstan.neon << 'EOF'
includes:
    - phar://phpstan.phar/conf/bleedingEdge.neon

parameters:
    level: 5
    paths:
        - web/modules/custom
        - web/themes/custom
    excludes_analyse:
        - */tests/*
        - */Tests/*
    drupal:
        drupal_root: web
    fileExtensions:
        - php
        - module
        - theme
        - inc
        - install
        - test
        - profile
    reportUnmatchedIgnoredErrors: false
    ignoreErrors:
        - '#Unsafe usage of new static\(\)#'
EOF
echo -e "${GREEN}✓ PHPStan configuration created${NC}"
echo ""

# Create .phpcs.xml configuration file
echo -e "${YELLOW}Creating PHPCS configuration...${NC}"
cat > .phpcs.xml << 'EOF'
<?xml version="1.0"?>
<ruleset name="Drupal Custom">
  <description>Drupal coding standards for custom modules and themes</description>

  <!-- Include Drupal standards -->
  <rule ref="Drupal"/>
  <rule ref="DrupalPractice"/>

  <!-- Files to check -->
  <file>web/modules/custom</file>
  <file>web/themes/custom</file>

  <!-- Exclude patterns -->
  <exclude-pattern>*/vendor/*</exclude-pattern>
  <exclude-pattern>*/node_modules/*</exclude-pattern>
  <exclude-pattern>*/tests/*</exclude-pattern>
  <exclude-pattern>*.css</exclude-pattern>
  <exclude-pattern>*.md</exclude-pattern>
  <exclude-pattern>*.txt</exclude-pattern>

  <!-- File extensions -->
  <arg name="extensions" value="php,module,inc,install,test,profile,theme,js"/>

  <!-- Show progress -->
  <arg value="p"/>

  <!-- Show sniff codes -->
  <arg value="s"/>

  <!-- Use colors -->
  <arg name="colors"/>
</ruleset>
EOF
echo -e "${GREEN}✓ PHPCS configuration created${NC}"
echo ""

# Create .phpmd.xml configuration file
echo -e "${YELLOW}Creating PHPMD configuration...${NC}"
cat > .phpmd.xml << 'EOF'
<?xml version="1.0"?>
<ruleset name="Drupal PHPMD Ruleset"
         xmlns="http://pmd.sf.net/ruleset/1.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://pmd.sf.net/ruleset/1.0.0
                     http://pmd.sf.net/ruleset_xml_schema.xsd"
         xsi:noNamespaceSchemaLocation="
                     http://pmd.sf.net/ruleset_xml_schema.xsd">
    <description>
        Drupal optimized PHPMD ruleset
    </description>

    <!-- Import rulesets -->
    <rule ref="rulesets/cleancode.xml">
        <exclude name="StaticAccess"/>
        <exclude name="ElseExpression"/>
    </rule>
    
    <rule ref="rulesets/codesize.xml">
        <exclude name="ExcessiveMethodLength"/>
        <exclude name="ExcessiveClassLength"/>
        <exclude name="ExcessivePublicCount"/>
    </rule>
    
    <rule ref="rulesets/codesize.xml/ExcessiveMethodLength">
        <properties>
            <property name="minimum" value="100"/>
        </properties>
    </rule>
    
    <rule ref="rulesets/controversial.xml">
        <exclude name="CamelCaseClassName"/>
        <exclude name="CamelCaseMethodName"/>
        <exclude name="CamelCaseParameterName"/>
        <exclude name="CamelCaseVariableName"/>
    </rule>
    
    <rule ref="rulesets/design.xml">
        <exclude name="CouplingBetweenObjects"/>
    </rule>
    
    <rule ref="rulesets/design.xml/CouplingBetweenObjects">
        <properties>
            <property name="maximum" value="20"/>
        </properties>
    </rule>
    
    <rule ref="rulesets/naming.xml">
        <exclude name="ShortVariable"/>
        <exclude name="LongVariable"/>
    </rule>
    
    <rule ref="rulesets/naming.xml/ShortVariable">
        <properties>
            <property name="minimum" value="2"/>
        </properties>
    </rule>
    
    <rule ref="rulesets/unusedcode.xml"/>
</ruleset>
EOF
echo -e "${GREEN}✓ PHPMD configuration created${NC}"
echo ""

# Create Makefile for common tasks
echo -e "${YELLOW}Creating Makefile for common tasks...${NC}"
cat > Makefile << 'EOF'
# Drupal Development Makefile

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lint
lint: ## Run all linting tools
	@echo "Running PHP CodeSniffer..."
	@phpcs
	@echo "Running PHP Mess Detector..."
	@phpmd web/modules/custom,web/themes/custom text .phpmd.xml
	@echo "Running PHPStan..."
	@phpstan analyse

.PHONY: fix
fix: ## Auto-fix coding standards issues
	@echo "Running PHP Code Beautifier..."
	@phpcbf

.PHONY: check
check: ## Run Drupal Check for deprecations
	@drupal-check web/modules/custom web/themes/custom

.PHONY: test
test: ## Run PHPUnit tests
	@./vendor/bin/phpunit

.PHONY: install-tools
install-tools: ## Install/update development tools
	@composer global require drupal/coder
	@composer global require phpmd/phpmd
	@composer global require phpstan/phpstan
	@composer global require mglaman/phpstan-drupal
	@composer global require mglaman/drupal-check

.PHONY: pre-commit
pre-commit: lint test ## Run pre-commit checks

.PHONY: clean
clean: ## Clean generated files
	@rm -rf vendor/ node_modules/
EOF
echo -e "${GREEN}✓ Makefile created${NC}"
echo ""

# Create pre-commit hook
echo -e "${YELLOW}Creating Git pre-commit hook...${NC}"
if [ -d .git ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
#
# Pre-commit hook for Drupal development
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Running pre-commit checks...${NC}"

# Get list of staged PHP files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(php|module|inc|install|test|profile|theme)$')

if [ -z "$STAGED_FILES" ]; then
    echo "No PHP files to check"
    exit 0
fi

# Run PHPCS on staged files
echo "Checking coding standards..."
for FILE in $STAGED_FILES; do
    phpcs "$FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Coding standards check failed for $FILE${NC}"
        echo "Run 'phpcbf $FILE' to fix automatically"
        exit 1
    fi
done

echo -e "${GREEN}✓ All pre-commit checks passed${NC}"
exit 0
EOF
    chmod +x .git/hooks/pre-commit
    echo -e "${GREEN}✓ Git pre-commit hook created${NC}"
else
    echo -e "${YELLOW}Not in a Git repository, skipping pre-commit hook${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo "Installed tools:"
echo "  • PHP_CodeSniffer with Drupal standards"
echo "  • PHP Mess Detector"
echo "  • PHPStan with Drupal extension"
echo "  • Drupal Check"
echo "  • PHP Copy/Paste Detector"
echo ""
echo "Configuration files created:"
echo "  • phpstan.neon - PHPStan configuration"
echo "  • .phpcs.xml - PHPCS configuration"
echo "  • .phpmd.xml - PHPMD configuration"
echo "  • Makefile - Common development tasks"
echo ""
echo "Usage examples:"
echo "  make lint          # Run all linters"
echo "  make fix           # Auto-fix coding standards"
echo "  make check         # Check for deprecations"
echo "  phpcs file.php     # Check single file"
echo "  phpcbf file.php    # Fix single file"
echo ""
echo -e "${YELLOW}Note: You may need to restart your terminal for PATH changes to take effect${NC}"
