# PHP Coding Standards

PHP coding standards for Drupal development following Drupal Coding Standards and PSR-12.

## Table of Contents

1. [Formatting & Syntax](#formatting--syntax)
2. [Naming Conventions](#naming-conventions)
3. [Type Declarations](#type-declarations)
4. [Documentation](#documentation)
5. [Namespaces & Imports](#namespaces--imports)
6. [Error Handling](#error-handling)
7. [Modern PHP Features](#modern-php-features)

---

## Formatting & Syntax

### PHP001: Indentation and Spacing

**Severity:** `medium`

Use 2 spaces for indentation (not tabs). Lines should not exceed 80 characters (recommended).

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

/**
 * Processes data according to business rules.
 */
class DataProcessor {

  /**
   * Processes the given input data.
   *
   * @param array $data
   *   The input data to process.
   *
   * @return array
   *   The processed data.
   */
  public function process(array $data): array {
    // Two-space indentation.
    $result = [];
    
    foreach ($data as $key => $value) {
      // Nested indentation continues with 2 spaces.
      if ($this->isValid($value)) {
        $result[$key] = $this->transform($value);
      }
    }
    
    return $result;
  }

}
```

**Bad Example:**
```php
<?php
// ❌ Using tabs
class BadClass {
	public function method() {  // Tab indentation
		return TRUE;
	}
}

// ❌ Inconsistent indentation
class InconsistentClass {
  public function method() {
      return TRUE;  // 4 spaces instead of 2
  }
}
```

---

### PHP002: Brace Placement

**Severity:** `medium`

Opening braces go on the same line as the statement. Closing braces go on their own line.

**Good Example:**
```php
<?php

// Functions
function mymodule_example(): void {
  // Code here.
}

// Classes
class MyClass {

  public function method(): string {
    return 'value';
  }

}

// Control structures
if ($condition) {
  // Do something.
}
elseif ($other_condition) {
  // Do something else.
}
else {
  // Default action.
}

// Switch statements
switch ($value) {
  case 'one':
    $result = 1;
    break;

  case 'two':
    $result = 2;
    break;

  default:
    $result = 0;
}

// Try-catch
try {
  $this->riskyOperation();
}
catch (\Exception $e) {
  $this->handleError($e);
}
finally {
  $this->cleanup();
}
```

**Bad Example:**
```php
<?php
// ❌ Brace on new line
function bad_function()
{
  return TRUE;
}

// ❌ else on same line as closing brace
if ($condition) {
  // Code.
} else {  // Should be on new line
  // Code.
}
```

---

### PHP003: Array Syntax

**Severity:** `medium`

Use short array syntax `[]` instead of `array()`. Multi-line arrays should have trailing commas.

**Good Example:**
```php
<?php

// Short syntax
$simple = ['one', 'two', 'three'];

// Associative array
$config = [
  'name' => 'Example',
  'version' => '1.0',
];

// Multi-line with trailing comma
$form['settings'] = [
  '#type' => 'fieldset',
  '#title' => $this->t('Settings'),
  '#collapsible' => TRUE,
  '#collapsed' => FALSE,
];  // Trailing comma makes diffs cleaner

// Nested arrays
$data = [
  'users' => [
    ['name' => 'Alice', 'role' => 'admin'],
    ['name' => 'Bob', 'role' => 'editor'],
  ],
  'config' => [
    'debug' => FALSE,
    'cache' => TRUE,
  ],
];
```

**Bad Example:**
```php
<?php
// ❌ Long array syntax
$data = array('one', 'two', 'three');

// ❌ No trailing comma (makes future additions harder)
$config = [
  'name' => 'Example',
  'version' => '1.0'  // Missing trailing comma
];
```

---

### PHP004: String Handling

**Severity:** `low`

Use single quotes for strings without variables. Use double quotes or concatenation for variable interpolation.

**Good Example:**
```php
<?php

// No variables - single quotes
$message = 'This is a simple string.';

// With variables - double quotes
$greeting = "Hello, {$user->name}!";

// Complex expressions - concatenation
$status = 'User ' . $user->getDisplayName() . ' logged in at ' . date('Y-m-d');

// Drupal translation with placeholders
$message = $this->t('Welcome @name! You have @count messages.', [
  '@name' => $user->getDisplayName(),
  '@count' => $message_count,
]);

// SQL identifiers in braces
$query = "SELECT * FROM {node_field_data} WHERE status = :status";
```

**Bad Example:**
```php
<?php
// ❌ Double quotes with no variables
$text = "This has no variables";  // Use single quotes

// ❌ Concatenation when interpolation is cleaner
$text = 'Hello, ' . $name . '! Your ID is ' . $id . '.';
// Better: "Hello, {$name}! Your ID is {$id}."
```

---

### PHP005: Whitespace and Operators

**Severity:** `low`

Use single spaces around operators and after commas.

**Good Example:**
```php
<?php

// Binary operators
$sum = $a + $b;
$result = $value * 2;
$is_valid = $status === 'active';

// Assignment
$name = 'value';
$count += 1;

// Comparison
if ($a === $b && $c !== $d) {
  // Code.
}

// Array access - no spaces
$value = $array['key'];
$item = $data[$index];

// Function calls - no space before parenthesis
$result = function_name($arg1, $arg2);
$this->method($param);

// Type casting - space after
$int_value = (int) $string;
$array_value = (array) $object;

// Concatenation - spaces around dot
$full_name = $first . ' ' . $last;
```

**Bad Example:**
```php
<?php
// ❌ No spaces around operators
$sum=$a+$b;

// ❌ Inconsistent spacing
$result = $a +$b;

// ❌ Space before function parenthesis
$result = function_name ($arg);

// ❌ No space after cast
$int_value = (int)$string;
```

---

## Naming Conventions

### PHP006: Function and Variable Names

**Severity:** `medium`

Use lowercase with underscores (snake_case) for functions and variables.

**Good Example:**
```php
<?php

// Functions
function mymodule_process_data(array $input_data): array {
  $processed_items = [];
  $item_count = 0;
  
  foreach ($input_data as $raw_item) {
    $clean_item = clean_input($raw_item);
    $processed_items[] = $clean_item;
    $item_count++;
  }
  
  return $processed_items;
}

// Hook implementations
function mymodule_entity_presave(EntityInterface $entity): void {
  // Implementation.
}

// Private helper functions - prefix with underscore
function _mymodule_internal_helper(): void {
  // Implementation.
}
```

**Bad Example:**
```php
<?php
// ❌ CamelCase for functions
function mymoduleProcessData($inputData) {
  return $inputData;
}

// ❌ Mixed case variables
$processedItems = [];
$ItemCount = 0;
```

---

### PHP007: Class and Interface Names

**Severity:** `medium`

Use PascalCase (UpperCamelCase) for classes, interfaces, and traits.

**Good Example:**
```php
<?php

namespace Drupal\mymodule\Service;

// Classes - PascalCase
class DataProcessor {
}

class NodeViewBuilder {
}

// Interfaces - suffix with Interface
interface DataProcessorInterface {
}

interface CacheableInterface {
}

// Traits - suffix with Trait
trait LoggerTrait {
}

trait StringTranslationTrait {
}

// Abstract classes - prefix with Abstract or Base
abstract class AbstractProcessor {
}

class BaseController extends ControllerBase {
}

// Exceptions - suffix with Exception
class ProcessingException extends \Exception {
}

class InvalidDataException extends \InvalidArgumentException {
}
```

**Bad Example:**
```php
<?php
// ❌ Lowercase class name
class data_processor {
}

// ❌ Interface without suffix
interface Processable {
}

// ❌ Inconsistent naming
class dataProcessor {  // Mixed case
}
```

---

### PHP008: Constants

**Severity:** `medium`

Use UPPERCASE with underscores for constants.

**Good Example:**
```php
<?php

namespace Drupal\mymodule;

// Class constants
class MyModule {

  public const VERSION = '1.0.0';
  public const MAX_RETRIES = 3;
  public const DEFAULT_TIMEOUT = 30;
  public const STATUS_ACTIVE = 'active';
  public const STATUS_PENDING = 'pending';
  public const STATUS_DISABLED = 'disabled';

}

// Global constants (in .module file)
define('MYMODULE_CACHE_LIFETIME', 3600);

// Boolean constants - uppercase
$enabled = TRUE;
$disabled = FALSE;
$unknown = NULL;
```

**Bad Example:**
```php
<?php
// ❌ Lowercase constants
const maxRetries = 3;

// ❌ Lowercase boolean
$enabled = true;
$disabled = false;
$unknown = null;
```

---

### PHP009: Service and Method Names

**Severity:** `medium`

Service IDs use lowercase with dots/underscores. Methods use camelCase.

**Good Example:**
```yaml
# mymodule.services.yml
services:
  mymodule.data_processor:
    class: Drupal\mymodule\Service\DataProcessor
    arguments: ['@database', '@logger.factory']

  mymodule.node_manager:
    class: Drupal\mymodule\Service\NodeManager
```

```php
<?php

namespace Drupal\mymodule\Service;

class DataProcessor {

  // Methods - camelCase
  public function processData(array $data): array {
    return $this->doProcessing($data);
  }

  public function getData(): array {
    return $this->fetchFromCache() ?? $this->fetchFromDatabase();
  }

  // Private/protected methods - still camelCase
  protected function doProcessing(array $data): array {
    return array_map([$this, 'transformItem'], $data);
  }

  private function transformItem(mixed $item): mixed {
    return $item;
  }

  // Getters and setters
  public function getStatus(): string {
    return $this->status;
  }

  public function setStatus(string $status): self {
    $this->status = $status;
    return $this;
  }

  // Boolean getters - is/has/can prefix
  public function isEnabled(): bool {
    return $this->enabled;
  }

  public function hasAccess(): bool {
    return $this->checkAccess();
  }

  public function canProcess(): bool {
    return $this->status === 'ready';
  }

}
```

---

## Type Declarations

### PHP010: Parameter Type Declarations

**Severity:** `high`

Always use type declarations for parameters.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Session\AccountInterface;
use Drupal\node\NodeInterface;

class EntityProcessor {

  // Scalar types
  public function processString(string $input): string {
    return trim($input);
  }

  public function calculateTotal(int $quantity, float $price): float {
    return $quantity * $price;
  }

  public function setEnabled(bool $enabled): void {
    $this->enabled = $enabled;
  }

  // Array and iterable
  public function processItems(array $items): array {
    return array_filter($items);
  }

  public function processIterable(iterable $items): \Generator {
    foreach ($items as $item) {
      yield $this->transform($item);
    }
  }

  // Object types
  public function processEntity(EntityInterface $entity): void {
    // Process entity.
  }

  public function processNode(NodeInterface $node): void {
    // Node-specific processing.
  }

  // Nullable types
  public function findUser(?int $uid): ?AccountInterface {
    if ($uid === NULL) {
      return NULL;
    }
    return $this->entityTypeManager->getStorage('user')->load($uid);
  }

  // Union types (PHP 8.0+)
  public function processInput(string|array $input): array {
    return is_string($input) ? [$input] : $input;
  }

  // Mixed type (when truly any type is acceptable)
  public function setValue(string $key, mixed $value): void {
    $this->values[$key] = $value;
  }

}
```

**Bad Example:**
```php
<?php
// ❌ No type declarations
public function processData($input) {
  return $input;
}

// ❌ Using docblock instead of type hint
/**
 * @param string $name
 */
public function setName($name) {
  $this->name = $name;
}
```

---

### PHP011: Return Type Declarations

**Severity:** `high`

Always declare return types for methods.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

class DataService {

  // Specific return type
  public function getName(): string {
    return $this->name;
  }

  public function getCount(): int {
    return count($this->items);
  }

  public function isActive(): bool {
    return $this->status === 'active';
  }

  // Array return
  public function getItems(): array {
    return $this->items;
  }

  // Object return
  public function getUser(): AccountInterface {
    return $this->currentUser;
  }

  // Nullable return
  public function findItem(string $id): ?ItemInterface {
    return $this->items[$id] ?? NULL;
  }

  // Void for methods that don't return
  public function save(): void {
    $this->storage->save($this->data);
  }

  // Self for fluent interfaces
  public function setName(string $name): self {
    $this->name = $name;
    return $this;
  }

  // Static return type
  public static function create(): static {
    return new static();
  }

  // Never return type (always throws/exits)
  public function fail(string $message): never {
    throw new \RuntimeException($message);
  }

}
```

---

### PHP012: Property Type Declarations

**Severity:** `medium`

Use typed properties (PHP 7.4+).

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;

class DataProcessor {

  // Typed properties with visibility
  protected Connection $database;
  protected EntityTypeManagerInterface $entityTypeManager;
  protected string $name = '';
  protected int $count = 0;
  protected bool $enabled = FALSE;
  protected array $items = [];
  protected ?string $description = NULL;

  // Constructor property promotion (PHP 8.0+)
  public function __construct(
    protected Connection $database,
    protected EntityTypeManagerInterface $entityTypeManager,
    protected string $moduleName = 'mymodule',
  ) {}

  // Readonly properties (PHP 8.1+)
  public readonly string $id;
  public readonly \DateTimeInterface $createdAt;

}
```

**Bad Example:**
```php
<?php
// ❌ Untyped properties
class BadService {
  protected $database;
  protected $name;
  private $items;
}
```

---

## Documentation

### PHP013: File DocBlocks

**Severity:** `medium`

Every PHP file should have a file-level DocBlock.

**Good Example:**
```php
<?php

/**
 * @file
 * Contains \Drupal\mymodule\Service\DataProcessor.
 *
 * Provides data processing functionality for the mymodule module.
 */

declare(strict_types=1);

namespace Drupal\mymodule\Service;
```

```php
<?php

/**
 * @file
 * Hook implementations for the My Module module.
 */

use Drupal\Core\Entity\EntityInterface;

/**
 * Implements hook_entity_presave().
 */
function mymodule_entity_presave(EntityInterface $entity): void {
  // Implementation.
}
```

---

### PHP014: Class and Method DocBlocks

**Severity:** `medium`

Document classes and methods with complete DocBlocks.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\Core\Entity\EntityInterface;

/**
 * Processes entities according to business rules.
 *
 * This service handles validation, transformation, and storage
 * of entity data for the mymodule module.
 *
 * @package Drupal\mymodule\Service
 */
class EntityProcessor {

  /**
   * The entity type manager.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface
   */
  protected EntityTypeManagerInterface $entityTypeManager;

  /**
   * Constructs an EntityProcessor object.
   *
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entity_type_manager
   *   The entity type manager service.
   * @param \Drupal\Core\Logger\LoggerChannelFactoryInterface $logger_factory
   *   The logger factory service.
   */
  public function __construct(
    EntityTypeManagerInterface $entity_type_manager,
    LoggerChannelFactoryInterface $logger_factory,
  ) {
    $this->entityTypeManager = $entity_type_manager;
    $this->logger = $logger_factory->get('mymodule');
  }

  /**
   * Processes the given entity.
   *
   * Validates the entity data, applies transformations, and saves
   * the result to the database.
   *
   * @param \Drupal\Core\Entity\EntityInterface $entity
   *   The entity to process.
   * @param array $options
   *   (optional) Processing options:
   *   - validate: Whether to validate before processing. Defaults to TRUE.
   *   - notify: Whether to send notifications. Defaults to FALSE.
   *
   * @return bool
   *   TRUE if processing succeeded, FALSE otherwise.
   *
   * @throws \Drupal\mymodule\Exception\ProcessingException
   *   Thrown when the entity cannot be processed.
   *
   * @see \Drupal\mymodule\Service\Validator::validate()
   */
  public function process(EntityInterface $entity, array $options = []): bool {
    // Implementation.
  }

  /**
   * Checks if the entity can be processed.
   *
   * @param \Drupal\Core\Entity\EntityInterface $entity
   *   The entity to check.
   *
   * @return bool
   *   TRUE if the entity can be processed.
   */
  public function canProcess(EntityInterface $entity): bool {
    return $entity->access('update');
  }

}
```

---

### PHP015: Inline Comments

**Severity:** `low`

Use inline comments to explain non-obvious code. Comments should start with a capital letter.

**Good Example:**
```php
<?php

public function processData(array $data): array {
  // Filter out invalid entries before processing.
  $valid_data = array_filter($data, [$this, 'isValid']);
  
  // Sort by priority to ensure correct processing order.
  // Higher priority items should be processed first.
  usort($valid_data, function ($a, $b) {
    return $b['priority'] <=> $a['priority'];
  });
  
  $results = [];
  foreach ($valid_data as $item) {
    // Skip items that have already been processed.
    if ($this->isProcessed($item['id'])) {
      continue;
    }
    
    // Transform and store the result.
    $results[] = $this->transform($item);
  }
  
  return $results;
}

// TODO: Implement caching for this method in next release.
// @todo Add support for batch processing.
// @see https://www.drupal.org/project/issues/mymodule
```

**Bad Example:**
```php
<?php
// ❌ Lowercase start
// filter the data
$data = array_filter($data);

// ❌ Obvious comments that don't add value
// Loop through items.
foreach ($items as $item) {
  // Set the value.
  $item->setValue($value);
}
```

---

## Namespaces & Imports

### PHP016: Namespace Structure

**Severity:** `high`

Follow PSR-4 namespace conventions for Drupal modules.

**Good Example:**
```php
<?php

declare(strict_types=1);

// Module namespace root
namespace Drupal\mymodule;

// Controllers
namespace Drupal\mymodule\Controller;

// Forms
namespace Drupal\mymodule\Form;

// Services
namespace Drupal\mymodule\Service;

// Plugins
namespace Drupal\mymodule\Plugin\Block;
namespace Drupal\mymodule\Plugin\Field\FieldFormatter;
namespace Drupal\mymodule\Plugin\QueueWorker;

// Event subscribers
namespace Drupal\mymodule\EventSubscriber;

// Access handlers
namespace Drupal\mymodule\Access;

// Entities
namespace Drupal\mymodule\Entity;

// Tests
namespace Drupal\Tests\mymodule\Unit;
namespace Drupal\Tests\mymodule\Kernel;
namespace Drupal\Tests\mymodule\Functional;
```

Directory structure:
```
modules/custom/mymodule/
├── src/
│   ├── Controller/
│   │   └── MyController.php
│   ├── Form/
│   │   └── SettingsForm.php
│   ├── Service/
│   │   └── DataProcessor.php
│   ├── Plugin/
│   │   └── Block/
│   │       └── MyBlock.php
│   └── Entity/
│       └── MyEntity.php
├── tests/
│   └── src/
│       ├── Unit/
│       │   └── Service/
│       │       └── DataProcessorTest.php
│       └── Kernel/
│           └── Entity/
│               └── MyEntityTest.php
└── mymodule.module
```

---

### PHP017: Use Statements

**Severity:** `medium`

Import classes at the top of the file with `use` statements.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Controller;

// Group 1: Core PHP classes
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

// Group 2: Drupal Core classes (alphabetical)
use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;
use Drupal\Core\Session\AccountInterface;

// Group 3: Contributed module classes
use Drupal\token\TokenInterface;

// Group 4: Custom module classes
use Drupal\mymodule\Service\DataProcessor;

// One class per use statement - no grouping
class MyController extends ControllerBase {
  // Implementation.
}
```

**Bad Example:**
```php
<?php
// ❌ Multiple classes in one use statement
use Drupal\Core\{Controller\ControllerBase, Database\Connection};

// ❌ Leading backslash
use \Drupal\Core\Controller\ControllerBase;

// ❌ Unsorted imports
use Drupal\mymodule\Service;
use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Database\Connection;
```

---

## Error Handling

### PHP018: Exception Handling

**Severity:** `high`

Use try-catch blocks for operations that may fail. Never suppress errors with @.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\mymodule\Exception\ProcessingException;

class DataProcessor {

  public function process(array $data): array {
    try {
      $validated = $this->validate($data);
      $result = $this->transform($validated);
      $this->save($result);
      
      return $result;
    }
    catch (ValidationException $e) {
      // Handle validation errors specifically.
      $this->logger->warning('Validation failed: @message', [
        '@message' => $e->getMessage(),
      ]);
      throw new ProcessingException('Invalid data provided', 0, $e);
    }
    catch (StorageException $e) {
      // Handle storage errors.
      $this->logger->error('Storage failed: @message', [
        '@message' => $e->getMessage(),
      ]);
      throw $e;
    }
    catch (\Exception $e) {
      // Catch-all for unexpected errors.
      $this->logger->error('Unexpected error: @message', [
        '@message' => $e->getMessage(),
        '@trace' => $e->getTraceAsString(),
      ]);
      throw new ProcessingException('Processing failed', 0, $e);
    }
    finally {
      // Always runs - cleanup.
      $this->cleanup();
    }
  }

  public function loadEntity(int $id): EntityInterface {
    $entity = $this->entityTypeManager
      ->getStorage('node')
      ->load($id);
    
    if ($entity === NULL) {
      throw new EntityNotFoundException("Entity $id not found");
    }
    
    return $entity;
  }

}

// Custom exceptions
namespace Drupal\mymodule\Exception;

class ProcessingException extends \RuntimeException {
}

class EntityNotFoundException extends \RuntimeException {
}
```

**Bad Example:**
```php
<?php
// ❌ Suppressing errors
$data = @file_get_contents($url);

// ❌ Empty catch block
try {
  $this->process();
}
catch (\Exception $e) {
  // Silently ignore - BAD!
}

// ❌ Using die/exit
if (!$data) {
  die('No data found');
}
```

---

### PHP019: Avoid Deprecated Functions

**Severity:** `high`

Use modern Drupal APIs instead of deprecated functions.

**Good Example:**
```php
<?php

// ✅ Database queries - use injected Connection
$results = $this->database->select('node', 'n')
  ->fields('n', ['nid', 'title'])
  ->execute();

// ✅ Entity loading - use EntityTypeManager
$node = $this->entityTypeManager->getStorage('node')->load($nid);

// ✅ Current user - inject AccountProxyInterface
$uid = $this->currentUser->id();

// ✅ URL generation - use Url class
$url = Url::fromRoute('entity.node.canonical', ['node' => $nid]);

// ✅ Link generation - use Link class
$link = Link::fromTextAndUrl($text, $url);

// ✅ Language - use language manager
$langcode = $this->languageManager->getCurrentLanguage()->getId();

// ✅ Module path - use extension.list service
$path = $this->extensionListModule->getPath('mymodule');

// ✅ Request - use RequestStack
$request = $this->requestStack->getCurrentRequest();
```

**Bad Example:**
```php
<?php
// ❌ Deprecated db_* functions
$results = db_query("SELECT * FROM {node}");
$record = db_select('users', 'u')->execute();

// ❌ Deprecated node_load
$node = node_load($nid);

// ❌ Deprecated global user
global $user;

// ❌ Deprecated url() function
$url = url('node/' . $nid);

// ❌ Deprecated l() function
$link = l($text, 'node/' . $nid);

// ❌ Deprecated drupal_get_path
$path = drupal_get_path('module', 'mymodule');

// ❌ Deprecated \Drupal::request()
$request = \Drupal::request();  // Use injected RequestStack instead
```

---

## Modern PHP Features

### PHP020: Use Strict Types

**Severity:** `medium`

Enable strict type checking at the beginning of PHP files.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

class Calculator {

  public function add(int $a, int $b): int {
    return $a + $b;
  }

  public function divide(float $a, float $b): float {
    if ($b === 0.0) {
      throw new \DivisionByZeroError('Cannot divide by zero');
    }
    return $a / $b;
  }

}

// With strict_types, this would throw TypeError:
// $calc->add('5', '3'); // Error!
// $calc->add(5, 3);     // OK, returns 8
```

---

### PHP021: Use Match Expressions (PHP 8.0+)

**Severity:** `low`

Use match expressions for cleaner conditionals.

**Good Example:**
```php
<?php

declare(strict_types=1);

// Match expression - more concise than switch
public function getStatusLabel(string $status): string {
  return match ($status) {
    'draft' => $this->t('Draft'),
    'pending' => $this->t('Pending Review'),
    'published' => $this->t('Published'),
    'archived' => $this->t('Archived'),
    default => $this->t('Unknown'),
  };
}

// Match with complex conditions
public function getDiscount(int $quantity): float {
  return match (TRUE) {
    $quantity >= 100 => 0.25,
    $quantity >= 50 => 0.15,
    $quantity >= 10 => 0.10,
    default => 0.0,
  };
}

// Instead of switch with return
// switch ($status) {
//   case 'draft':
//     return $this->t('Draft');
//   case 'pending':
//     return $this->t('Pending Review');
//   default:
//     return $this->t('Unknown');
// }
```

---

### PHP022: Use Named Arguments (PHP 8.0+)

**Severity:** `low`

Use named arguments for better readability with many parameters.

**Good Example:**
```php
<?php

// Method with many parameters
public function createUser(
  string $name,
  string $email,
  string $password,
  bool $active = TRUE,
  array $roles = [],
  ?string $timezone = NULL,
): UserInterface {
  // Implementation.
}

// Called with named arguments for clarity
$user = $this->createUser(
  name: 'John Doe',
  email: 'john@example.com',
  password: 'secure123',
  roles: ['editor', 'contributor'],
  active: TRUE,
);

// Skip optional parameters
$user = $this->createUser(
  name: 'Jane',
  email: 'jane@example.com',
  password: 'secure456',
  timezone: 'America/New_York',
);
```

---

### PHP023: Use Null Coalescing and Nullsafe Operators

**Severity:** `low`

Use modern null handling operators for cleaner code.

**Good Example:**
```php
<?php

// Null coalescing operator
$name = $user->name ?? 'Anonymous';
$config = $settings['option'] ?? $defaults['option'] ?? 'default';

// Null coalescing assignment
$this->cache ??= $this->buildCache();

// Nullsafe operator (PHP 8.0+)
$authorName = $node->getOwner()?->getDisplayName() ?? 'Unknown';

// Chain nullsafe operators
$countryCode = $user->getProfile()?->getAddress()?->getCountry()?->getCode();

// Instead of:
// $authorName = $node->getOwner() ? $node->getOwner()->getDisplayName() : 'Unknown';
// or
// if ($node->getOwner() !== NULL) {
//   $authorName = $node->getOwner()->getDisplayName();
// }
```

---

### PHP024: Use Constructor Property Promotion (PHP 8.0+)

**Severity:** `low`

Use constructor property promotion for cleaner service classes.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;

class DataProcessor {

  // Constructor property promotion
  public function __construct(
    protected Connection $database,
    protected EntityTypeManagerInterface $entityTypeManager,
    protected LoggerChannelFactoryInterface $loggerFactory,
    protected string $moduleName = 'mymodule',
  ) {}

  // Properties are automatically declared and assigned
  // No need for separate property declarations or assignments

}

// Instead of:
// class DataProcessor {
//   protected Connection $database;
//   protected EntityTypeManagerInterface $entityTypeManager;
//
//   public function __construct(
//     Connection $database,
//     EntityTypeManagerInterface $entity_type_manager,
//   ) {
//     $this->database = $database;
//     $this->entityTypeManager = $entity_type_manager;
//   }
// }
```
