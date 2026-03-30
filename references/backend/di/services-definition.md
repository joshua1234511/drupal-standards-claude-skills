# Services Definition Reference

Define services in `mymodule.services.yml` in your module's root directory. Drupal automatically discovers and registers these services.

## Basic Service Structure

```yaml
services:
  mymodule.example:
    class: Drupal\mymodule\Service\ExampleService
    arguments: ['@database', '%mymodule.setting%']

parameters:
  mymodule.setting: 'default_value'
```

## Arguments Syntax

| Syntax | Type | Example |
|--------|------|---------|
| `@service_id` | Service reference | `@database`, `@entity_type.manager` |
| `@?service_id` | Optional service (null if missing) | `@?cache.backend.null` |
| `%param_name%` | Container parameter | `%mymodule.setting%` |
| `'string'` | Literal string | `'my_table'` |
| `true`/`false` | Boolean | `true` |
| `123` | Integer | `123` |

## Complete Service Example

```yaml
# icecream.services.yml
services:
  icecream.scoop:
    class: Drupal\icecream\Services\Scoopdb
    arguments: ['@database']
```

```php
<?php
// src/Services/Scoopdb.php

namespace Drupal\icecream\Services;

use Drupal\Core\Database\Connection;

class Scoopdb {

  protected Connection $database;

  public function __construct(Connection $connection) {
    $this->database = $connection;
  }

  public function getIcecreamRecords(): array {
    $query = $this->database->query('SELECT nid FROM {icecream}');
    return $query->fetchAssoc();
  }

}
```

## Service Properties Reference

### Common Properties

| Property | Description | Default |
|----------|-------------|---------|
| `class` | Fully qualified class name | Required |
| `arguments` | Constructor arguments | `[]` |
| `public` | Can be fetched directly from container | `false` |
| `shared` | Return same instance (singleton) | `true` |
| `tags` | Service tags for collectors | `[]` |

### Advanced Properties

| Property | Description |
|----------|-------------|
| `abstract` | Template service, not instantiated directly |
| `parent` | Inherit from abstract service |
| `decorates` | Decorate/wrap another service |
| `factory` | Use factory method to create instance |
| `calls` | Setter injection methods |
| `configurator` | Post-instantiation configuration |
| `alias` | Create service alias |
| `file` | Include file before instantiation |
| `synthetic` | Service injected externally |

### Example with Multiple Properties

```yaml
services:
  mymodule.processor:
    class: Drupal\mymodule\Service\DataProcessor
    arguments: ['@database', '@logger.factory']
    public: false
    shared: true
    calls:
      - [setConfig, ['@config.factory']]
    tags:
      - { name: service_collector, tag: mymodule_plugin, call: addPlugin }
```

## Naming Services

### Traditional Naming (Recommended)

Prefix with module name for clarity:

```yaml
services:
  mymodule.data_processor:
    class: Drupal\mymodule\Service\DataProcessor
```

Access: `\Drupal::service('mymodule.data_processor')`

### FQCN Naming (Alternative)

Use full class namespace as service ID:

```yaml
services:
  Drupal\mymodule\Service\DataProcessor:
    class: Drupal\mymodule\Service\DataProcessor
    arguments: ['@config.factory']
```

Access: `\Drupal::service(DataProcessor::class)` or `$container->get(DataProcessor::class)`

## Service with Parameters

```yaml
parameters:
  mymodule.api_endpoint: 'https://api.example.com'
  mymodule.cache_ttl: 3600
  mymodule.debug_mode: false

services:
  mymodule.api_client:
    class: Drupal\mymodule\Service\ApiClient
    arguments:
      - '%mymodule.api_endpoint%'
      - '%mymodule.cache_ttl%'
      - '%mymodule.debug_mode%'
```

## Service with Factory

```yaml
services:
  mymodule.special_object:
    class: Drupal\mymodule\SpecialObject
    factory: ['Drupal\mymodule\SpecialObjectFactory', 'create']
    arguments: ['@config.factory']
```

## Optional Dependencies

Use `@?` prefix for services that may not exist:

```yaml
services:
  mymodule.enhanced_service:
    class: Drupal\mymodule\Service\EnhancedService
    arguments:
      - '@entity_type.manager'
      - '@?search_api.index_storage'  # Optional, null if missing
```

## Abstract and Parent Services

```yaml
services:
  mymodule.base_handler:
    abstract: true
    class: Drupal\mymodule\Handler\BaseHandler
    arguments: ['@logger.factory', '@config.factory']

  mymodule.node_handler:
    parent: mymodule.base_handler
    class: Drupal\mymodule\Handler\NodeHandler
    arguments:
      index_0: '@entity_type.manager'  # Replace first argument
```

## Interface Aliases

Create aliases for interfaces to enable autowiring:

```yaml
services:
  Drupal\Core\Entity\EntityTypeManagerInterface:
    alias: entity_type.manager

  mymodule.my_service:
    class: Drupal\mymodule\Service\MyService
    autowire: true
```

## Accessing Services

### In `.module` or `.install` Files

```php
// Dedicated accessor (if available)
$database = \Drupal::database();
$user = \Drupal::currentUser();

// Generic service() method
$custom = \Drupal::service('mymodule.custom_service');
```

### In Service Classes

Inject via constructor (defined in services.yml).

### In Forms/Controllers/Plugins

Use `ContainerInjectionInterface` or `ContainerFactoryPluginInterface`.

See `dependency-injection-forms.md` and `dependency-injection-plugins.md`.
