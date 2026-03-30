# Dependency Injection Best Practices

Guidelines for effective dependency injection in Drupal 10 and 11 modules.

## Why Use Dependency Injection?

### Benefits

1. **Testability**: Mock dependencies in unit tests
2. **Decoupling**: Code doesn't depend on specific implementations
3. **Flexibility**: Swap implementations without code changes
4. **Clarity**: Dependencies are explicit in constructors
5. **Maintainability**: Changes isolated to single locations

### Bad Example (Without DI)

```php
class MyService {
  public function getNodes(): array {
    // Tightly coupled to global Drupal container
    $storage = \Drupal::entityTypeManager()->getStorage('node');
    $user = \Drupal::currentUser();
    $config = \Drupal::config('mymodule.settings');
    
    // Hard to test, hard to swap implementations
    return $storage->loadMultiple();
  }
}
```

### Good Example (With DI)

```php
class MyService {
  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
    protected readonly AccountProxyInterface $currentUser,
    protected readonly ConfigFactoryInterface $configFactory,
  ) {}

  public function getNodes(): array {
    $storage = $this->entityTypeManager->getStorage('node');
    // Easy to test with mocked dependencies
    return $storage->loadMultiple();
  }
}
```

## When to Use Each Pattern

### Constructor Injection (Services)

**Use for**: Custom service classes defined in `services.yml`

```yaml
services:
  mymodule.helper:
    class: Drupal\mymodule\Helper
    arguments: ['@entity_type.manager']
```

### ContainerInjectionInterface (Forms/Controllers)

**Use for**: Forms, controllers, and other classes instantiated by Drupal

```php
class MyForm extends FormBase {
  public function __construct(protected readonly AccountProxyInterface $user) {}
  
  public static function create(ContainerInterface $container): static {
    return new static($container->get('current_user'));
  }
}
```

### ContainerFactoryPluginInterface (Plugins)

**Use for**: Blocks, field formatters, queue workers, conditions, etc.

```php
class MyBlock extends BlockBase implements ContainerFactoryPluginInterface {
  public static function create(ContainerInterface $container, array $configuration, $plugin_id, $plugin_definition): static {
    return new static($configuration, $plugin_id, $plugin_definition, $container->get('current_user'));
  }
}
```

### \Drupal::service() (Last Resort)

**Use for**: Procedural code only (`.module`, `.install` files)

```php
// mymodule.module
function mymodule_cron() {
  $service = \Drupal::service('mymodule.processor');
  $service->processBatch();
}
```

## Service Design Guidelines

### Keep Services Stateless

Services should not store request-specific state:

```php
// ❌ BAD: Stores state
class BadService {
  protected array $processedItems = [];
  
  public function process($item): void {
    $this->processedItems[] = $item;  // State accumulates across requests!
  }
}

// ✅ GOOD: Stateless
class GoodService {
  public function process($item): ProcessedItem {
    return new ProcessedItem($item);  // Returns result, no stored state
  }
}
```

### Single Responsibility

Each service should do one thing well:

```php
// ❌ BAD: Does too much
class EverythingService {
  public function loadNodes() {}
  public function sendEmail() {}
  public function generatePdf() {}
  public function validateInput() {}
}

// ✅ GOOD: Focused services
class NodeLoader {}
class EmailSender {}
class PdfGenerator {}
class InputValidator {}
```

### Depend on Interfaces, Not Implementations

```php
// ❌ BAD: Depends on concrete class
public function __construct(
  protected readonly TranslationManager $translator,
) {}

// ✅ GOOD: Depends on interface
public function __construct(
  protected readonly TranslationInterface $translator,
) {}
```

## Property Visibility

### Never Use Private for Injected Services

Private properties don't serialize (breaks AJAX forms, caching):

```php
// ❌ WRONG
class MyForm extends FormBase {
  private AccountProxyInterface $user;  // Lost after serialization!
}

// ✅ RIGHT
class MyForm extends FormBase {
  protected AccountProxyInterface $user;  // Survives serialization
}

// ✅ ALSO RIGHT (constructor property promotion)
class MyForm extends FormBase {
  public function __construct(
    protected readonly AccountProxyInterface $user,
  ) {}
}
```

## Service Naming Conventions

### Module-Prefixed Names (Recommended)

```yaml
services:
  mymodule.node_processor:
    class: Drupal\mymodule\Service\NodeProcessor
  
  mymodule.api_client:
    class: Drupal\mymodule\Service\ApiClient
```

### FQCN Names (Alternative)

```yaml
services:
  Drupal\mymodule\Service\NodeProcessor:
    class: Drupal\mymodule\Service\NodeProcessor
```

Access via: `\Drupal::service(NodeProcessor::class)`

## Avoiding Common Pitfalls

### Don't Inject the Container

```php
// ❌ WRONG: Defeats the purpose of DI
public function __construct(
  protected readonly ContainerInterface $container,
) {}

public function doSomething(): void {
  $service = $this->container->get('some_service');  // Service locator anti-pattern
}

// ✅ RIGHT: Inject what you need
public function __construct(
  protected readonly SomeServiceInterface $someService,
) {}
```

### Don't Use DI in Entities

Entities cannot receive dependency injection. Use static service calls or pass dependencies to methods:

```php
// In entity class
public function getOwnerName(): string {
  // Static call is acceptable in entities
  return \Drupal::service('entity_type.manager')
    ->getStorage('user')
    ->load($this->getOwnerId())
    ->getDisplayName();
}

// OR pass dependency to method
public function getOwnerName(EntityTypeManagerInterface $entityTypeManager): string {
  return $entityTypeManager
    ->getStorage('user')
    ->load($this->getOwnerId())
    ->getDisplayName();
}
```

### Don't Over-Inject

Only inject what you actually use:

```php
// ❌ BAD: Injecting unused services
public function __construct(
  protected readonly EntityTypeManagerInterface $entityTypeManager,
  protected readonly ConfigFactoryInterface $configFactory,  // Never used
  protected readonly LoggerChannelFactoryInterface $logger,  // Never used
  protected readonly ModuleHandlerInterface $moduleHandler,  // Never used
) {}

// ✅ GOOD: Only inject what's needed
public function __construct(
  protected readonly EntityTypeManagerInterface $entityTypeManager,
) {}
```

## Testing with Dependency Injection

### Unit Test Example

```php
<?php

namespace Drupal\Tests\mymodule\Unit;

use Drupal\Core\Entity\EntityStorageInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\mymodule\Service\NodeProcessor;
use Drupal\Tests\UnitTestCase;

class NodeProcessorTest extends UnitTestCase {

  public function testProcessNodes(): void {
    // Create mocks
    $storage = $this->createMock(EntityStorageInterface::class);
    $storage->method('loadMultiple')->willReturn([]);
    
    $entityTypeManager = $this->createMock(EntityTypeManagerInterface::class);
    $entityTypeManager->method('getStorage')->willReturn($storage);
    
    // Create service with mocked dependencies
    $processor = new NodeProcessor($entityTypeManager);
    
    // Test the service
    $result = $processor->processAll();
    $this->assertEquals([], $result);
  }

}
```

## AutowireTrait Best Practices (Drupal 10.2+)

### When to Use AutowireTrait

- Simple forms with standard service interfaces
- When interfaces map uniquely to services
- To reduce boilerplate code

### When to Avoid AutowireTrait

- When you need specific service IDs (use `#[Autowire]` attribute)
- For plugins (use `ContainerFactoryPluginInterface`)
- When extending classes that don't support it

### Combining with #[Autowire] Attribute

```php
use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\DependencyInjection\AutowireTrait;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class MyForm extends FormBase {
  use AutowireTrait;

  public function __construct(
    protected readonly AccountProxyInterface $currentUser,  // Autowired
    #[Autowire(service: 'cache.render')]
    protected readonly CacheBackendInterface $cache,  // Specific service
  ) {}
}
```

## Service Configuration Checklist

Before committing a new service:

- [ ] Service name is prefixed with module name
- [ ] Class implements an interface (if applicable)
- [ ] All dependencies are injected (no `\Drupal::` calls in class)
- [ ] Properties are protected/public, not private
- [ ] Service is stateless (or documented why not)
- [ ] Unit tests mock dependencies properly
- [ ] `drush cr` works without errors

## Migration from Static Calls

### Step 1: Identify Static Calls

```bash
grep -r "\\\\Drupal::" src/
```

### Step 2: Create Service Definition

```yaml
services:
  mymodule.legacy_service:
    class: Drupal\mymodule\LegacyService
    arguments: ['@entity_type.manager', '@current_user']
```

### Step 3: Refactor Class

```php
// Before
class LegacyService {
  public function doThing(): void {
    $manager = \Drupal::entityTypeManager();
    $user = \Drupal::currentUser();
  }
}

// After
class LegacyService {
  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
    protected readonly AccountProxyInterface $currentUser,
  ) {}

  public function doThing(): void {
    $storage = $this->entityTypeManager->getStorage('node');
    $uid = $this->currentUser->id();
  }
}
```

### Step 4: Update Callers

```php
// Before
$service = new LegacyService();

// After
$service = \Drupal::service('mymodule.legacy_service');
// Or inject it into the calling class
```
