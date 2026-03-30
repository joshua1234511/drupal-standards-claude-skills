# Service Tags and Collectors

Tags identify services for special processing. Service collectors gather tagged services for extensibility patterns.

## About Service Tags

Tags indicate that a service should be registered or used in a special way, or that it belongs to a category. Tags are processed during container compilation, so changes take effect after `drush cr`.

## Basic Tagged Service

```yaml
# mymodule.services.yml
services:
  mymodule.my_handler:
    class: Drupal\mymodule\Handler\MyHandler
    tags:
      - { name: event_subscriber }
```

## Service Collector Pattern

A service collector gathers other services by tag. This pattern enables modules to contribute implementations to a central manager.

### Collector Service Definition

```yaml
# mymodule.services.yml
services:
  mymodule.processor_manager:
    class: Drupal\mymodule\ProcessorManager
    arguments: ['@logger.factory']
    tags:
      - { name: service_collector, tag: mymodule_processor, call: addProcessor }
```

### Collected Service Definition

```yaml
# another_module.services.yml
services:
  another_module.special_processor:
    class: Drupal\another_module\SpecialProcessor
    tags:
      - { name: mymodule_processor, priority: 10 }
```

### Collector Class

```php
<?php

namespace Drupal\mymodule;

use Drupal\Core\Logger\LoggerChannelFactoryInterface;

class ProcessorManager {

  protected array $processors = [];

  public function __construct(
    protected readonly LoggerChannelFactoryInterface $loggerFactory,
  ) {}

  /**
   * Add a processor (called by container for each tagged service).
   *
   * @param \Drupal\mymodule\ProcessorInterface $processor
   *   The processor to add.
   * @param int $priority
   *   The priority (higher = runs first).
   */
  public function addProcessor(ProcessorInterface $processor, int $priority = 0): void {
    $this->processors[$priority][] = $processor;
  }

  public function process(array $data): array {
    krsort($this->processors);
    
    foreach ($this->processors as $priority => $processors) {
      foreach ($processors as $processor) {
        $data = $processor->process($data);
      }
    }
    
    return $data;
  }

}
```

### Collected Service Class

```php
<?php

namespace Drupal\another_module;

use Drupal\mymodule\ProcessorInterface;

class SpecialProcessor implements ProcessorInterface {

  public function process(array $data): array {
    // Transform the data
    $data['processed_by_special'] = TRUE;
    return $data;
  }

}
```

## Collector Tag Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `name` | Must be `service_collector` | Required |
| `tag` | Tag name to collect | Service ID |
| `call` | Method to call for each service | `addHandler` |

## Collected Service Tag Attributes

| Attribute | Description | Default |
|-----------|-------------|---------|
| `name` | Tag name (matches collector's `tag`) | Required |
| `priority` | Execution order (higher = first) | `0` |
| `id` | Identifier passed to collector method | Service ID |

## Core String Translation Example

```yaml
# core.services.yml
services:
  string_translation:
    class: Drupal\Core\StringTranslation\TranslationManager
    arguments: ['@language.default']
    tags:
      - { name: service_collector, tag: string_translator, call: addTranslator }

  string_translator.custom_strings:
    class: Drupal\Core\StringTranslation\Translator\CustomStrings
    arguments: ['@settings']
    tags:
      - { name: string_translator, priority: 30 }
```

### Collector Method Signature

```php
public function addTranslator(TranslatorInterface $translator, $priority = 0) {
  $this->translators[$priority][] = $translator;
  $this->sortedTranslators = NULL;
  return $this;
}
```

The method receives:
1. The collected service instance (first parameter)
2. Optional `priority` from tag (if in method signature)
3. Optional `id` from tag (if in method signature)

## Common Core Service Tags

| Tag Name | Purpose |
|----------|---------|
| `event_subscriber` | Event subscribers |
| `access_check` | Route access checkers |
| `breadcrumb_builder` | Breadcrumb builders |
| `path_processor_inbound` | Inbound path processing |
| `path_processor_outbound` | Outbound path processing |
| `cache.context` | Cache contexts |
| `normalizer` | Serialization normalizers |
| `theme_negotiator` | Theme negotiation |
| `string_translator` | String translation |

## Event Subscriber Tag

```yaml
services:
  mymodule.event_subscriber:
    class: Drupal\mymodule\EventSubscriber\MySubscriber
    tags:
      - { name: event_subscriber }
```

```php
<?php

namespace Drupal\mymodule\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class MySubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents(): array {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
    ];
  }

  public function onRequest(RequestEvent $event): void {
    // Handle the request event
  }

}
```

## Access Check Tag

```yaml
services:
  mymodule.access_checker:
    class: Drupal\mymodule\Access\CustomAccessChecker
    tags:
      - { name: access_check, applies_to: _custom_access }
```

```php
<?php

namespace Drupal\mymodule\Access;

use Drupal\Core\Access\AccessResult;
use Drupal\Core\Routing\Access\AccessInterface;
use Drupal\Core\Session\AccountInterface;

class CustomAccessChecker implements AccessInterface {

  public function access(AccountInterface $account): AccessResult {
    return AccessResult::allowedIf($account->hasPermission('access content'));
  }

}
```

Route definition:

```yaml
# mymodule.routing.yml
mymodule.protected:
  path: '/protected-page'
  defaults:
    _controller: '\Drupal\mymodule\Controller\ProtectedController::page'
  requirements:
    _custom_access: 'TRUE'
```

## Cache Context Tag

```yaml
services:
  cache_context.my_context:
    class: Drupal\mymodule\Cache\Context\MyContext
    tags:
      - { name: cache.context }
```

## Guidance on Tags vs Other Patterns

**Prefer tags when:**
- Multiple modules should contribute implementations
- Order matters (use `priority`)
- You're creating an extension point

**Use other patterns when:**
- Single implementation needed → just define service
- Replacing behavior → use service decoration
- One-off customization → use hooks or events

## Debugging Tags

```bash
# List services with specific tag
drush ev "\$c = \Drupal::getContainer(); 
  \$ids = \$c->findTaggedServiceIds('event_subscriber');
  print_r(array_keys(\$ids));"

# Check if service has tag
drush ev "\$def = \Drupal::getContainer()->getDefinition('mymodule.service');
  print_r(\$def->getTags());"
```
