# Dependency Injection in Plugins

Plugins (blocks, field formatters, queue workers, etc.) use `ContainerFactoryPluginInterface` for dependency injection.

## Block Plugin Example

```php
<?php

namespace Drupal\example\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Drupal\example\Services\CustomService;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides an example block.
 *
 * @Block(
 *   id = "example_block",
 *   admin_label = @Translation("Example Block"),
 *   category = @Translation("Custom")
 * )
 */
class ExampleBlock extends BlockBase implements ContainerFactoryPluginInterface {

  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    protected readonly AccountProxyInterface $currentUser,
    protected readonly CustomService $customService,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
  }

  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition
  ): static {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_user'),
      $container->get('example.custom_service'),
    );
  }

  public function build(): array {
    $data = $this->customService->getData();
    
    return [
      '#theme' => 'example_block',
      '#data' => $data,
      '#user' => $this->currentUser->getDisplayName(),
      '#cache' => [
        'contexts' => ['user'],
      ],
    ];
  }

}
```

## Key Differences from Forms

| Aspect | Forms | Plugins |
|--------|-------|---------|
| Interface | `ContainerInjectionInterface` | `ContainerFactoryPluginInterface` |
| `create()` params | Only `$container` | `$container`, `$configuration`, `$plugin_id`, `$plugin_definition` |
| Constructor | Only injected services | Plugin params + injected services |
| Parent call | Optional | Usually required |

## Plugin create() Signature

```php
public static function create(
  ContainerInterface $container,
  array $configuration,
  $plugin_id,
  $plugin_definition
): static {
  return new static(
    $configuration,       // First three params always passed
    $plugin_id,
    $plugin_definition,
    // Then your injected services:
    $container->get('service_id'),
  );
}
```

## Field Formatter with DI

```php
<?php

namespace Drupal\example\Plugin\Field\FieldFormatter;

use Drupal\Core\Field\FieldDefinitionInterface;
use Drupal\Core\Field\FieldItemListInterface;
use Drupal\Core\Field\FormatterBase;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Render\RendererInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Plugin implementation of the 'example_formatter' formatter.
 *
 * @FieldFormatter(
 *   id = "example_formatter",
 *   label = @Translation("Example Formatter"),
 *   field_types = {"text"}
 * )
 */
class ExampleFormatter extends FormatterBase implements ContainerFactoryPluginInterface {

  public function __construct(
    $plugin_id,
    $plugin_definition,
    FieldDefinitionInterface $field_definition,
    array $settings,
    $label,
    $view_mode,
    array $third_party_settings,
    protected readonly RendererInterface $renderer,
  ) {
    parent::__construct(
      $plugin_id,
      $plugin_definition,
      $field_definition,
      $settings,
      $label,
      $view_mode,
      $third_party_settings
    );
  }

  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition
  ): static {
    return new static(
      $plugin_id,
      $plugin_definition,
      $configuration['field_definition'],
      $configuration['settings'],
      $configuration['label'],
      $configuration['view_mode'],
      $configuration['third_party_settings'],
      $container->get('renderer'),
    );
  }

  public function viewElements(FieldItemListInterface $items, $langcode): array {
    $elements = [];
    
    foreach ($items as $delta => $item) {
      $elements[$delta] = [
        '#markup' => $item->value,
      ];
    }
    
    return $elements;
  }

}
```

## Queue Worker with DI

```php
<?php

namespace Drupal\example\Plugin\QueueWorker;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Queue\QueueWorkerBase;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Processes queued items.
 *
 * @QueueWorker(
 *   id = "example_queue",
 *   title = @Translation("Example Queue Worker"),
 *   cron = {"time" = 60}
 * )
 */
class ExampleQueueWorker extends QueueWorkerBase implements ContainerFactoryPluginInterface {

  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    protected readonly EntityTypeManagerInterface $entityTypeManager,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
  }

  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition
  ): static {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('entity_type.manager'),
    );
  }

  public function processItem($data): void {
    $storage = $this->entityTypeManager->getStorage('node');
    // Process the queued item
  }

}
```

## Condition Plugin with DI

```php
<?php

namespace Drupal\example\Plugin\Condition;

use Drupal\Core\Condition\ConditionPluginBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides a 'Role Check' condition.
 *
 * @Condition(
 *   id = "example_role_check",
 *   label = @Translation("Role Check")
 * )
 */
class RoleCheck extends ConditionPluginBase implements ContainerFactoryPluginInterface {

  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    protected readonly AccountProxyInterface $currentUser,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
  }

  public static function create(
    ContainerInterface $container,
    array $configuration,
    $plugin_id,
    $plugin_definition
  ): static {
    return new static(
      $configuration,
      $plugin_id,
      $plugin_definition,
      $container->get('current_user'),
    );
  }

  public function buildConfigurationForm(array $form, FormStateInterface $form_state): array {
    $form['role'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Required role'),
      '#default_value' => $this->configuration['role'] ?? '',
    ];
    return parent::buildConfigurationForm($form, $form_state);
  }

  public function submitConfigurationForm(array &$form, FormStateInterface $form_state): void {
    $this->configuration['role'] = $form_state->getValue('role');
    parent::submitConfigurationForm($form, $form_state);
  }

  public function evaluate(): bool {
    $role = $this->configuration['role'] ?? '';
    return $this->currentUser->hasPermission('access content');
  }

  public function summary(): string {
    return $this->t('User has required role');
  }

}
```

## Deriver Plugin with DI

```php
<?php

namespace Drupal\example\Plugin\Derivative;

use Drupal\Component\Plugin\Derivative\DeriverBase;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Plugin\Discovery\ContainerDeriverInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ExampleDeriver extends DeriverBase implements ContainerDeriverInterface {

  public function __construct(
    protected readonly EntityTypeManagerInterface $entityTypeManager,
  ) {}

  public static function create(
    ContainerInterface $container,
    $base_plugin_id
  ): static {
    return new static(
      $container->get('entity_type.manager'),
    );
  }

  public function getDerivativeDefinitions($base_plugin_definition): array {
    // Generate derivative definitions
    return $this->derivatives;
  }

}
```

## Common Plugin Types and Constructor Signatures

### Block

```php
__construct(array $configuration, $plugin_id, $plugin_definition, ...services)
```

### Field Formatter

```php
__construct($plugin_id, $plugin_definition, FieldDefinitionInterface $field_definition, 
            array $settings, $label, $view_mode, array $third_party_settings, ...services)
```

### Field Widget

```php
__construct($plugin_id, $plugin_definition, FieldDefinitionInterface $field_definition,
            array $settings, array $third_party_settings, ...services)
```

### Queue Worker

```php
__construct(array $configuration, $plugin_id, $plugin_definition, ...services)
```

### Condition

```php
__construct(array $configuration, $plugin_id, $plugin_definition, ...services)
```

## Troubleshooting

### "Service not found" error

Check service ID matches exactly what's in `*.services.yml`.

### Plugin not appearing

1. Clear cache: `drush cr`
2. Check annotation/attribute syntax
3. Verify namespace matches directory structure

### Services null after instantiation

Ensure `create()` method is implemented and interface is declared:

```php
class MyBlock extends BlockBase implements ContainerFactoryPluginInterface {
```
