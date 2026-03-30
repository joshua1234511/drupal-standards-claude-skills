# Dependency Injection in Forms

Forms that require services should access them via dependency injection, not static `\Drupal::service()` calls.

## Basic Form with DI

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ExampleForm extends FormBase {

  public function __construct(
    protected readonly AccountInterface $account,
  ) {}

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('current_user'),
    );
  }

  public function getFormId(): string {
    return 'example_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $uid = $this->account->id();
    
    $form['message'] = [
      '#markup' => $this->t('Hello, user @uid!', ['@uid' => $uid]),
    ];
    
    return $form;
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    // Handle submission
  }

}
```

## Key Points

1. The `create()` method is a factory that receives the container
2. Services are loaded in `create()` and passed to `__construct()`
3. Order in `create()` must match order in `__construct()`
4. `FormBase` implements `ContainerInjectionInterface`

## ConfigFormBase Example

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ExampleConfigForm extends ConfigFormBase {

  public function __construct(
    ConfigFactoryInterface $config_factory,
    protected readonly AccountProxyInterface $currentUser,
  ) {
    parent::__construct($config_factory);
  }

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('config.factory'),
      $container->get('current_user'),
    );
  }

  protected function getEditableConfigNames(): array {
    return ['example.settings'];
  }

  public function getFormId(): string {
    return 'example_config_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $config = $this->config('example.settings');
    
    $form['option'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Option'),
      '#default_value' => $config->get('option'),
    ];

    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->config('example.settings')
      ->set('option', $form_state->getValue('option'))
      ->save();
    
    parent::submitForm($form, $form_state);
  }

}
```

## AutowireTrait (Drupal 10.2+)

Simplify injection by removing the `create()` method:

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\DependencyInjection\AutowireTrait;
use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountProxyInterface;

class AutowiredForm extends FormBase {

  use AutowireTrait;

  public function __construct(
    protected readonly AccountProxyInterface $currentUser,
  ) {}

  public function getFormId(): string {
    return 'autowired_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    return ['#markup' => 'User: ' . $this->currentUser->getDisplayName()];
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {}

}
```

### Autowire with Ambiguous Interfaces

When multiple services implement the same interface, use the `#[Autowire]` attribute:

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\DependencyInjection\AutowireTrait;
use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class FormWithCaching extends FormBase {

  use AutowireTrait;

  public function __construct(
    protected readonly AccountProxyInterface $currentUser,
    #[Autowire(service: 'cache.render')]
    protected readonly CacheBackendInterface $cacheRender,
    #[Autowire(service: 'cache.data')]
    protected readonly CacheBackendInterface $cacheData,
  ) {}

  public function getFormId(): string {
    return 'form_with_caching';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    // Use $this->cacheRender or $this->cacheData
    return [];
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {}

}
```

## ConfigFormBase with AutowireTrait

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\DependencyInjection\AutowireTrait;
use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountProxyInterface;

class AutowiredConfigForm extends ConfigFormBase {

  use AutowireTrait;

  public function __construct(
    ConfigFactoryInterface $config_factory,
    protected readonly AccountProxyInterface $currentUser,
  ) {
    parent::__construct($config_factory);
  }

  protected function getEditableConfigNames(): array {
    return ['example.settings'];
  }

  public function getFormId(): string {
    return 'autowired_config_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    parent::submitForm($form, $form_state);
  }

}
```

## AJAX Forms: Serialization Warning

**Critical**: Forms rebuilt via AJAX are serialized. Private properties don't serialize correctly.

```php
// ❌ WRONG: Private visibility breaks AJAX
class AjaxForm extends FormBase {
  private AccountProxyInterface $user; // Lost after AJAX rebuild!
}

// ✅ RIGHT: Use protected or public
class AjaxForm extends FormBase {
  protected AccountProxyInterface $user; // Persists through AJAX
}

// ✅ ALSO RIGHT: Constructor property promotion with protected
class AjaxForm extends FormBase {
  public function __construct(
    protected readonly AccountProxyInterface $user, // Safe for AJAX
  ) {}
}
```

### AJAX Form Example

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\Ajax\AjaxResponse;
use Drupal\Core\Ajax\ReplaceCommand;
use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class AjaxExampleForm extends FormBase {

  // MUST be protected, not private!
  protected AccountProxyInterface $currentUser;

  public function __construct(AccountProxyInterface $current_user) {
    $this->currentUser = $current_user;
  }

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('current_user'),
    );
  }

  public function getFormId(): string {
    return 'ajax_example_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $form['trigger'] = [
      '#type' => 'select',
      '#title' => $this->t('Select option'),
      '#options' => ['a' => 'Option A', 'b' => 'Option B'],
      '#ajax' => [
        'callback' => '::ajaxCallback',
        'wrapper' => 'result-wrapper',
      ],
    ];

    $form['result'] = [
      '#type' => 'container',
      '#attributes' => ['id' => 'result-wrapper'],
      '#markup' => '',
    ];

    return $form;
  }

  public function ajaxCallback(array &$form, FormStateInterface $form_state): array {
    // $this->currentUser is still available because it's protected
    $form['result']['#markup'] = $this->t('Selected by @user', [
      '@user' => $this->currentUser->getDisplayName(),
    ]);
    return $form['result'];
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {}

}
```

## Entity Forms

Entity forms extend `EntityForm` and may need additional services:

```php
<?php

namespace Drupal\example\Form;

use Drupal\Core\Entity\EntityForm;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Routing\RouteBuilderInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class ExampleEntityForm extends EntityForm {

  public function __construct(
    protected readonly RouteBuilderInterface $routeBuilder,
  ) {}

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('router.builder'),
    );
  }

  public function save(array $form, FormStateInterface $form_state): int {
    $result = parent::save($form, $form_state);
    
    // Rebuild routes if needed
    $this->routeBuilder->rebuild();
    
    return $result;
  }

}
```

## Multiple Services Pattern

```php
public function __construct(
  protected readonly EntityTypeManagerInterface $entityTypeManager,
  protected readonly Connection $database,
  protected readonly ConfigFactoryInterface $configFactory,
  protected readonly MessengerInterface $messenger,
  protected readonly LoggerChannelFactoryInterface $loggerFactory,
) {}

public static function create(ContainerInterface $container): static {
  return new static(
    $container->get('entity_type.manager'),
    $container->get('database'),
    $container->get('config.factory'),
    $container->get('messenger'),
    $container->get('logger.factory'),
  );
}
```
