# Altering and Decorating Services

Modify existing services by altering, decorating, or replacing them through service providers.

## Service Provider Overview

Create a service provider to modify services during container compilation. The class must:
- Be named `{ModuleName}ServiceProvider` (PascalCase)
- Be in the module's top-level namespace
- Extend `ServiceProviderBase` or implement `ServiceModifierInterface`

## Basic Service Provider

```php
<?php
// src/MyModuleServiceProvider.php

namespace Drupal\my_module;

use Drupal\Core\DependencyInjection\ContainerBuilder;
use Drupal\Core\DependencyInjection\ServiceProviderBase;

class MyModuleServiceProvider extends ServiceProviderBase {

  /**
   * {@inheritdoc}
   */
  public function alter(ContainerBuilder $container): void {
    // Modify services here
  }

}
```

## Altering a Service

Replace a service's class or add arguments:

```php
<?php

namespace Drupal\my_module;

use Drupal\Core\DependencyInjection\ContainerBuilder;
use Drupal\Core\DependencyInjection\ServiceProviderBase;
use Symfony\Component\DependencyInjection\Reference;

class MyModuleServiceProvider extends ServiceProviderBase {

  public function alter(ContainerBuilder $container): void {
    // Check service exists before altering
    if ($container->hasDefinition('language_manager')) {
      $definition = $container->getDefinition('language_manager');
      
      // Replace the class
      $definition->setClass('Drupal\my_module\MyLanguageManager');
      
      // Add an argument
      $definition->addArgument(new Reference('entity_type.manager'));
    }
  }

}
```

### Warning About Service Replacement

**Service replacement is powerful but brittle.** If multiple modules replace the same service, only one wins (based on container build order). Prefer service decoration when possible.

## Service Decoration (Recommended)

Decoration wraps the original service, preserving its functionality while adding behavior.

### Decorator Service Definition

```yaml
# my_module.services.yml
services:
  my_module.decorated_language_manager:
    class: Drupal\my_module\DecoratedLanguageManager
    decorates: language_manager
    arguments: ['@.inner', '@logger.factory']
```

The `@.inner` reference provides the original service.

### Decorator Class

```php
<?php

namespace Drupal\my_module;

use Drupal\Core\Language\LanguageInterface;
use Drupal\Core\Language\LanguageManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;

class DecoratedLanguageManager implements LanguageManagerInterface {

  public function __construct(
    protected readonly LanguageManagerInterface $inner,
    protected readonly LoggerChannelFactoryInterface $loggerFactory,
  ) {}

  public function getCurrentLanguage($type = LanguageInterface::TYPE_INTERFACE): LanguageInterface {
    // Add custom behavior
    $this->loggerFactory->get('my_module')
      ->debug('Getting current language of type @type', ['@type' => $type]);
    
    // Delegate to original service
    return $this->inner->getCurrentLanguage($type);
  }

  // Implement all other interface methods by delegating to $this->inner
  public function getLanguages($flags = LanguageInterface::STATE_CONFIGURABLE): array {
    return $this->inner->getLanguages($flags);
  }

  public function getLanguage($langcode): ?LanguageInterface {
    return $this->inner->getLanguage($langcode);
  }

  public function getDefaultLanguage(): LanguageInterface {
    return $this->inner->getDefaultLanguage();
  }

  // ... implement remaining interface methods

}
```

### Decoration Priority

Control decoration order with `decoration_priority`:

```yaml
services:
  my_module.decorated_service:
    class: Drupal\my_module\MyDecorator
    decorates: some_service
    decoration_priority: 10  # Higher = wraps outer layers
    arguments: ['@.inner']
```

## Adding Compiler Passes

For advanced service manipulation, use compiler passes:

```php
<?php

namespace Drupal\my_module;

use Drupal\Core\DependencyInjection\ContainerBuilder;
use Drupal\Core\DependencyInjection\ServiceProviderBase;
use Drupal\my_module\Compiler\MyCompilerPass;

class MyModuleServiceProvider extends ServiceProviderBase {

  public function register(ContainerBuilder $container): void {
    $container->addCompilerPass(new MyCompilerPass());
  }

}
```

### Compiler Pass Class

```php
<?php

namespace Drupal\my_module\Compiler;

use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\ContainerBuilder;

class MyCompilerPass implements CompilerPassInterface {

  public function process(ContainerBuilder $container): void {
    // Find all services with a specific tag
    $taggedServices = $container->findTaggedServiceIds('my_custom_tag');
    
    foreach ($taggedServices as $id => $tags) {
      $definition = $container->getDefinition($id);
      // Modify the definition
    }
  }

}
```

## Creating Interface Aliases

Enable autowiring by aliasing interfaces to implementations:

```php
<?php

namespace Drupal\my_module;

use Drupal\Core\DependencyInjection\ContainerBuilder;
use Drupal\Core\DependencyInjection\ServiceProviderBase;

class MyModuleServiceProvider extends ServiceProviderBase {

  public function alter(ContainerBuilder $container): void {
    // Allow autowiring by interface
    $container->setAlias(
      'Drupal\Core\Entity\EntityTypeManagerInterface',
      'entity_type.manager'
    );
  }

}
```

Or in `services.yml`:

```yaml
services:
  Drupal\Core\Entity\EntityTypeManagerInterface:
    alias: entity_type.manager
```

## Removing a Service

```php
public function alter(ContainerBuilder $container): void {
  if ($container->hasDefinition('unwanted_service')) {
    $container->removeDefinition('unwanted_service');
  }
}
```

## Modifying Service Tags

```php
public function alter(ContainerBuilder $container): void {
  if ($container->hasDefinition('some_service')) {
    $definition = $container->getDefinition('some_service');
    
    // Add a tag
    $definition->addTag('new_tag', ['priority' => 100]);
    
    // Get existing tags
    $tags = $definition->getTags();
    
    // Clear tags
    $definition->clearTags();
  }
}
```

## Override via services.yml (Use with Caution)

You can override services in YAML, but this is brittle for core services:

```yaml
# my_module.services.yml
services:
  # Override - FRAGILE, may break on core updates
  language_manager:
    class: Drupal\my_module\MyLanguageManager
    arguments: ['@language.default']
```

**Prefer service decoration or provider-based alteration instead.**

## When to Use Each Approach

| Goal | Approach |
|------|----------|
| Add behavior without replacing | Service decoration |
| Completely replace implementation | Service provider `alter()` |
| Modify service tags | Service provider `alter()` or compiler pass |
| Conditional modification | Compiler pass |
| Create autowire aliases | Service provider or `services.yml` |

## Best Practices

1. **Check service exists** before altering: `$container->hasDefinition()`
2. **Prefer decoration** over replacement for compatibility
3. **Use interfaces** in your replacement classes
4. **Test container rebuild** after changes: `drush cr`
5. **Document why** you're altering services
6. **Avoid overriding core services via YAML** - signatures change across releases

## Debugging Service Alterations

```bash
# Check if service was altered
drush ev "\$def = \Drupal::getContainer()->getDefinition('language_manager');
  echo \$def->getClass();"

# List all service providers
drush ev "\$kernel = \Drupal::service('kernel');
  \$method = new \ReflectionMethod(\$kernel, 'getServiceProviders');
  \$method->setAccessible(TRUE);
  print_r(array_keys(\$method->invoke(\$kernel, 'app')));"
```

## Container Compilation Flow

1. `DrupalKernel::handle()` boots the application
2. `initializeContainer()` compiles the container
3. Service definitions loaded from YAML files
4. Service providers discovered and `register()` called
5. Service providers' `alter()` called
6. Compiler passes process definitions
7. Container compiled and cached

Changes to services require `drush cr` to rebuild the container.
