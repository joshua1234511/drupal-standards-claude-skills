#!/usr/bin/env python3
"""
Drupal Code Validator
Validates PHP files against Drupal coding standards.
"""

import sys
import os
import re
import subprocess
import json
from pathlib import Path
from typing import List, Dict, Any, Optional

class DrupalValidator:
    """Validator for Drupal coding standards."""
    
    def __init__(self, file_path: str):
        """Initialize validator with file path."""
        self.file_path = Path(file_path)
        self.content = self.file_path.read_text(encoding='utf-8')
        self.lines = self.content.splitlines()
        self.errors = []
        self.warnings = []
        
    def validate(self) -> Dict[str, Any]:
        """Run all validations and return results."""
        # Check file extension
        valid_extensions = ['.module', '.inc', '.php', '.theme', '.install', '.test']
        if self.file_path.suffix not in valid_extensions:
            self.warnings.append(f"File extension '{self.file_path.suffix}' is not a standard Drupal extension")
        
        # Run validation checks
        self._check_file_comment()
        self._check_namespace()
        self._check_use_statements()
        self._check_class_structure()
        self._check_function_comments()
        self._check_indentation()
        self._check_line_length()
        self._check_security_issues()
        self._check_t_function_usage()
        self._check_dependency_injection()
        self._check_form_api()
        self._check_database_api()
        self._check_cache_tags()
        
        return {
            'file': str(self.file_path),
            'errors': self.errors,
            'warnings': self.warnings,
            'passed': len(self.errors) == 0
        }
    
    def _check_file_comment(self):
        """Check for proper file docblock."""
        if not self.content.startswith('<?php'):
            self.errors.append("File must start with <?php")
            
        # Check for @file tag
        if '@file' not in self.content[:500]:
            self.errors.append("Missing @file documentation in file docblock")
    
    def _check_namespace(self):
        """Check namespace declaration."""
        if '.module' not in str(self.file_path) and 'class ' in self.content:
            if not re.search(r'^namespace\s+Drupal\\\\', self.content, re.MULTILINE):
                self.errors.append("Classes must have proper Drupal namespace")
    
    def _check_use_statements(self):
        """Check use statement ordering."""
        use_statements = []
        for i, line in enumerate(self.lines):
            if line.startswith('use '):
                use_statements.append((i, line))
        
        if use_statements:
            sorted_uses = sorted(use_statements, key=lambda x: x[1])
            if use_statements != sorted_uses:
                self.warnings.append("Use statements should be sorted alphabetically")
    
    def _check_class_structure(self):
        """Check class structure and naming."""
        class_matches = re.findall(r'^class\s+(\w+)', self.content, re.MULTILINE)
        for class_name in class_matches:
            if not class_name[0].isupper():
                self.errors.append(f"Class '{class_name}' must start with uppercase letter")
            if '_' in class_name:
                self.warnings.append(f"Class '{class_name}' should use CamelCase, not underscores")
    
    def _check_function_comments(self):
        """Check for proper function documentation."""
        function_pattern = r'^(public|protected|private|)\s*(static\s+)?function\s+(\w+)\s*\('
        functions = re.findall(function_pattern, self.content, re.MULTILINE)
        
        for visibility, static, func_name in functions:
            # Look for docblock before function
            func_pos = self.content.find(f'function {func_name}')
            if func_pos > 0:
                before_func = self.content[max(0, func_pos-500):func_pos]
                if '/**' not in before_func:
                    self.warnings.append(f"Function '{func_name}' missing documentation")
    
    def _check_indentation(self):
        """Check for proper 2-space indentation."""
        for i, line in enumerate(self.lines, 1):
            if line and not line.lstrip():
                continue
            indent = len(line) - len(line.lstrip())
            if indent % 2 != 0:
                self.warnings.append(f"Line {i}: Indentation should be multiples of 2 spaces")
    
    def _check_line_length(self):
        """Check line length (80 chars recommended)."""
        for i, line in enumerate(self.lines, 1):
            if len(line) > 80:
                self.warnings.append(f"Line {i}: Line exceeds 80 characters ({len(line)} chars)")
    
    def _check_security_issues(self):
        """Check for common security issues."""
        # Check for SQL injection vulnerabilities
        if re.search(r'db_query\([\'"].*\$', self.content):
            self.errors.append("Potential SQL injection: Use placeholders in db_query()")
        
        # Check for XSS vulnerabilities
        if re.search(r'print\s+\$_GET|\$_POST|\$_REQUEST', self.content):
            self.errors.append("Potential XSS: Sanitize user input before output")
        
        # Check for eval usage
        if 'eval(' in self.content:
            self.errors.append("Security risk: Avoid using eval()")
    
    def _check_t_function_usage(self):
        """Check proper use of t() function."""
        # Check for concatenation in t()
        if re.search(r't\([\'"].*[\'"\s]*\.\s*\$', self.content):
            self.warnings.append("Use placeholders in t() instead of concatenation")
        
        # Check for variables as first parameter
        if re.search(r't\(\$\w+[,\)]', self.content):
            self.errors.append("First parameter of t() must be a literal string")
    
    def _check_dependency_injection(self):
        """Check for proper dependency injection."""
        # Check for \Drupal:: usage in classes
        if 'class ' in self.content:
            drupal_service_calls = re.findall(r'\\Drupal::\w+\(', self.content)
            for call in drupal_service_calls:
                if call not in ['\\Drupal::service(', '\\Drupal::translation(']:
                    self.warnings.append(f"Consider using dependency injection instead of {call}")
    
    def _check_form_api(self):
        """Check Form API usage."""
        if 'FormBase' in self.content or 'FormInterface' in self.content:
            # Check for proper form ID
            if 'public function getFormId()' in self.content:
                if not re.search(r'return\s+[\'"][\w_]+[\'"]', self.content):
                    self.warnings.append("Form ID should be a machine name string")
            
            # Check for validation and submit handlers
            if 'public function buildForm(' in self.content:
                if 'validateForm' not in self.content:
                    self.warnings.append("Consider implementing validateForm() for form validation")
    
    def _check_database_api(self):
        """Check Database API usage."""
        # Check for deprecated db_* functions
        deprecated_db_functions = ['db_query', 'db_insert', 'db_update', 'db_delete', 'db_select']
        for func in deprecated_db_functions:
            if func + '(' in self.content:
                self.warnings.append(f"Function {func}() is deprecated in Drupal 9+, use Database service")
    
    def _check_cache_tags(self):
        """Check for proper cache tags."""
        if 'render' in self.content and '#cache' not in self.content:
            self.warnings.append("Consider adding cache tags to render arrays")


def validate_file(file_path: str) -> Dict[str, Any]:
    """Validate a single Drupal file."""
    validator = DrupalValidator(file_path)
    return validator.validate()


def validate_directory(directory: str, recursive: bool = True) -> List[Dict[str, Any]]:
    """Validate all PHP files in a directory."""
    results = []
    path = Path(directory)
    
    if recursive:
        files = path.rglob('*.php')
        files = list(files) + list(path.rglob('*.module'))
        files = list(files) + list(path.rglob('*.inc'))
        files = list(files) + list(path.rglob('*.theme'))
        files = list(files) + list(path.rglob('*.install'))
    else:
        files = path.glob('*.php')
        files = list(files) + list(path.glob('*.module'))
        files = list(files) + list(path.glob('*.inc'))
        files = list(files) + list(path.glob('*.theme'))
        files = list(files) + list(path.glob('*.install'))
    
    for file_path in files:
        results.append(validate_file(str(file_path)))
    
    return results


def run_phpcs(file_path: str, standard: str = 'Drupal') -> Optional[Dict[str, Any]]:
    """Run PHP CodeSniffer if available."""
    try:
        result = subprocess.run(
            ['phpcs', '--standard=' + standard, '--report=json', file_path],
            capture_output=True,
            text=True
        )
        return json.loads(result.stdout)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: drupal_validator.py <file_or_directory> [--recursive]")
        sys.exit(1)
    
    target = sys.argv[1]
    recursive = '--recursive' in sys.argv or '-r' in sys.argv
    
    target_path = Path(target)
    
    if target_path.is_file():
        result = validate_file(target)
        
        print(f"\nValidation Results for {result['file']}:")
        print("=" * 50)
        
        if result['errors']:
            print(f"\nErrors ({len(result['errors'])}):")
            for error in result['errors']:
                print(f"  ✗ {error}")
        
        if result['warnings']:
            print(f"\nWarnings ({len(result['warnings'])}):")
            for warning in result['warnings']:
                print(f"  ⚠ {warning}")
        
        if result['passed']:
            print("\n✅ Validation passed with no errors!")
        else:
            print("\n❌ Validation failed with errors!")
            sys.exit(1)
    
    elif target_path.is_dir():
        results = validate_directory(target, recursive)
        
        total_files = len(results)
        passed_files = sum(1 for r in results if r['passed'])
        total_errors = sum(len(r['errors']) for r in results)
        total_warnings = sum(len(r['warnings']) for r in results)
        
        print(f"\nValidation Summary:")
        print("=" * 50)
        print(f"Files validated: {total_files}")
        print(f"Files passed: {passed_files}")
        print(f"Total errors: {total_errors}")
        print(f"Total warnings: {total_warnings}")
        
        if total_errors > 0:
            print("\nFiles with errors:")
            for result in results:
                if result['errors']:
                    print(f"  {result['file']}: {len(result['errors'])} errors")
        
        if total_errors == 0:
            print("\n✅ All files passed validation!")
        else:
            sys.exit(1)
    
    else:
        print(f"Error: {target} is not a valid file or directory")
        sys.exit(1)


if __name__ == '__main__':
    main()
