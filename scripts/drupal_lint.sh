#!/bin/bash
#
# Drupal Linting Helper Script
# Run various linting tools on Drupal code
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
STANDARD="Drupal,DrupalPractice"
FILE_EXTENSIONS="php,module,inc,install,test,profile,theme,yml,txt,md"
PHPCS_SEVERITY=1
PHPMD_RULESET="cleancode,codesize,controversial,design,naming,unusedcode"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] <path>"
    echo ""
    echo "Options:"
    echo "  -s, --standard STANDARD    Coding standard (default: Drupal,DrupalPractice)"
    echo "  -e, --extensions EXT       File extensions to check (default: php,module,inc,install,test,profile,theme)"
    echo "  -p, --phpcs                Run PHP CodeSniffer only"
    echo "  -m, --phpmd                Run PHP Mess Detector only"
    echo "  -r, --rector               Run Drupal Rector only"
    echo "  -a, --all                  Run all tools (default)"
    echo "  -f, --fix                  Automatically fix issues where possible"
    echo "  -v, --verbose              Verbose output"
    echo "  -h, --help                 Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/module           # Run all checks on a module"
    echo "  $0 -p -f /path/to/file.php   # Run PHPCS with auto-fix"
    echo "  $0 -s PSR12 /path/to/code    # Use PSR12 standard"
}

# Parse command line arguments
RUN_PHPCS=0
RUN_PHPMD=0
RUN_RECTOR=0
AUTO_FIX=0
VERBOSE=0
TARGET_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--standard)
            STANDARD="$2"
            shift 2
            ;;
        -e|--extensions)
            FILE_EXTENSIONS="$2"
            shift 2
            ;;
        -p|--phpcs)
            RUN_PHPCS=1
            shift
            ;;
        -m|--phpmd)
            RUN_PHPMD=1
            shift
            ;;
        -r|--rector)
            RUN_RECTOR=1
            shift
            ;;
        -a|--all)
            RUN_PHPCS=1
            RUN_PHPMD=1
            RUN_RECTOR=1
            shift
            ;;
        -f|--fix)
            AUTO_FIX=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            TARGET_PATH="$1"
            shift
            ;;
    esac
done

# Check if path is provided
if [ -z "$TARGET_PATH" ]; then
    echo -e "${RED}Error: No path provided${NC}"
    usage
    exit 1
fi

# Check if path exists
if [ ! -e "$TARGET_PATH" ]; then
    echo -e "${RED}Error: Path '$TARGET_PATH' does not exist${NC}"
    exit 1
fi

# If no specific tool selected, run all
if [ $RUN_PHPCS -eq 0 ] && [ $RUN_PHPMD -eq 0 ] && [ $RUN_RECTOR -eq 0 ]; then
    RUN_PHPCS=1
    RUN_PHPMD=1
    RUN_RECTOR=1
fi

echo -e "${GREEN}=== Drupal Code Quality Check ===${NC}"
echo "Target: $TARGET_PATH"
echo "Standards: $STANDARD"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Run PHP CodeSniffer
if [ $RUN_PHPCS -eq 1 ]; then
    echo -e "${YELLOW}Running PHP CodeSniffer...${NC}"
    
    if command_exists phpcs; then
        if [ $AUTO_FIX -eq 1 ]; then
            if [ $VERBOSE -eq 1 ]; then
                phpcbf --standard="$STANDARD" --extensions="$FILE_EXTENSIONS" -v "$TARGET_PATH"
            else
                phpcbf --standard="$STANDARD" --extensions="$FILE_EXTENSIONS" "$TARGET_PATH"
            fi
            echo "Auto-fix applied where possible"
        fi
        
        if [ $VERBOSE -eq 1 ]; then
            phpcs --standard="$STANDARD" --extensions="$FILE_EXTENSIONS" --severity="$PHPCS_SEVERITY" -v "$TARGET_PATH"
        else
            phpcs --standard="$STANDARD" --extensions="$FILE_EXTENSIONS" --severity="$PHPCS_SEVERITY" "$TARGET_PATH"
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ PHP CodeSniffer: No issues found${NC}"
        else
            echo -e "${RED}✗ PHP CodeSniffer: Issues found${NC}"
        fi
    else
        echo -e "${YELLOW}PHP CodeSniffer not installed. Install with:${NC}"
        echo "composer global require drupal/coder"
        echo "phpcs --config-set installed_paths ~/.composer/vendor/drupal/coder/coder_sniffer"
    fi
    echo ""
fi

# Run PHP Mess Detector
if [ $RUN_PHPMD -eq 1 ]; then
    echo -e "${YELLOW}Running PHP Mess Detector...${NC}"
    
    if command_exists phpmd; then
        if [ $VERBOSE -eq 1 ]; then
            phpmd "$TARGET_PATH" text "$PHPMD_RULESET" --suffixes php,module,inc,install,test,profile,theme
        else
            phpmd "$TARGET_PATH" text "$PHPMD_RULESET" --suffixes php,module,inc,install,test,profile,theme 2>/dev/null
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ PHP Mess Detector: No issues found${NC}"
        else
            echo -e "${RED}✗ PHP Mess Detector: Issues found${NC}"
        fi
    else
        echo -e "${YELLOW}PHP Mess Detector not installed. Install with:${NC}"
        echo "composer global require phpmd/phpmd"
    fi
    echo ""
fi

# Run Drupal Rector
if [ $RUN_RECTOR -eq 1 ]; then
    echo -e "${YELLOW}Running Drupal Rector...${NC}"
    
    if command_exists rector; then
        # Create a temporary rector config if not present
        if [ ! -f "rector.php" ]; then
            cat > /tmp/rector_drupal.php << 'EOF'
<?php

declare(strict_types=1);

use DrupalRector\Set\Drupal10SetList;
use DrupalRector\Set\Drupal9SetList;
use Rector\Config\RectorConfig;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->sets([
        Drupal9SetList::DRUPAL_9,
        Drupal10SetList::DRUPAL_10,
    ]);
    
    $rectorConfig->fileExtensions([
        'php',
        'module',
        'theme',
        'install',
        'profile',
        'inc',
        'engine',
    ]);
    
    $rectorConfig->parallel();
};
EOF
            RECTOR_CONFIG="/tmp/rector_drupal.php"
        else
            RECTOR_CONFIG="rector.php"
        fi
        
        if [ $AUTO_FIX -eq 1 ]; then
            rector process "$TARGET_PATH" --config="$RECTOR_CONFIG"
            echo "Rector fixes applied"
        else
            rector process "$TARGET_PATH" --config="$RECTOR_CONFIG" --dry-run
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Drupal Rector: No issues found${NC}"
        else
            echo -e "${RED}✗ Drupal Rector: Deprecations found${NC}"
        fi
        
        # Clean up temp file
        if [ "$RECTOR_CONFIG" == "/tmp/rector_drupal.php" ]; then
            rm -f /tmp/rector_drupal.php
        fi
    else
        echo -e "${YELLOW}Drupal Rector not installed. Install with:${NC}"
        echo "composer require --dev palantirnet/drupal-rector"
    fi
    echo ""
fi

echo -e "${GREEN}=== Linting Complete ===${NC}"

# Generate summary report
if [ $VERBOSE -eq 1 ]; then
    echo ""
    echo "Summary Report:"
    echo "==============="
    echo "Path checked: $TARGET_PATH"
    echo "Standards used: $STANDARD"
    echo "File extensions: $FILE_EXTENSIONS"
    
    if [ $AUTO_FIX -eq 1 ]; then
        echo "Auto-fix: Enabled"
    else
        echo "Auto-fix: Disabled"
    fi
fi

exit 0
