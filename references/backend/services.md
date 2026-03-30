# Services and Dependency Injection Standards

Standards for creating services, using dependency injection, and working with Drupal's plugin system.

## Table of Contents

1. [Service Definitions](#service-definitions)
2. [Dependency Injection](#dependency-injection)
3. [Controllers and Forms](#controllers-and-forms)
4. [Plugin System](#plugin-system)
5. [Events and Subscribers](#events-and-subscribers)
6. [Service Tags](#service-tags)

---

## Service Definitions

### SVC001: Define Services in services.yml

**Severity:** `high`

Define custom services in your module's `*.services.yml` file with proper structure.

**Good Example:**
```yaml
# mymodule.services.yml
services:
  # Service with dependencies
  mymodule.data_processor:
    class: Drupal\mymodule\Service\DataProcessor
    arguments:
      - '@database'
      - '@entity_type.manager'
      - '@logger.factory'
      - '@cache.default'
      - '@current_user'
    tags:
      - { name: 'mymodule_processor' }

  # Service with lazy loading
  mymodule.expensive_service:
    class: Drupal\mymodule\Service\ExpensiveService
    arguments:
      - '@database'
    lazy: true

  # Service with factory
  mymodule.api_client:
    class: Drupal\mymodule\Service\ApiClient
    factory: ['Drupal\mymodule\Service\ApiClientFactory', 'create']
    arguments:
      - '@http_client'
      - '@config.factory'

  # Service alias
  mymodule.processor:
    alias: mymodule.data_processor

  # Service with configuration
  mymodule.configurable_service:
    class: Drupal\mymodule\Service\ConfigurableService
    arguments:
      - '@config.factory'
      - '%mymodule.default_limit%'

  # Private service (not directly accessible)
  mymodule.internal_helper:
    class: Drupal\mymodule\Service\InternalHelper
    public: false

parameters:
  mymodule.default_limit: 100
```

**Bad Example:**
```yaml
# ❌ Missing dependencies
services:
  mymodule.service:
    class: Drupal\mymodule\Service\MyService
    # No arguments - will use \Drupal::service() internally

# ❌ Incorrect argument format
services:
  mymodule.service:
    arguments:
      - database  # Missing @ symbol
      - Drupal\Core\Entity\EntityTypeManager  # Should be service reference
```

---

### SVC002: Service Naming Conventions

**Severity:** `medium`

Follow consistent naming conventions for services.

**Good Example:**
```yaml
services:
  # Pattern: module_name.service_purpose
  mymodule.data_processor:
    class: Drupal\mymodule\Service\DataProcessor

  mymodule.node_manager:
    class: Drupal\mymodule\Service\NodeManager

  mymodule.api.client:
    class: Drupal\mymodule\Api\Client

  mymodule.api.authenticator:
    class: Drupal\mymodule\Api\Authenticator

  # Access checkers: module.access_checker.name
  mymodule.access_checker.custom_entity:
    class: Drupal\mymodule\Access\CustomEntityAccessCheck
    tags:
      - { name: access_check, applies_to: _custom_entity_access }

  # Event subscribers: module.event_subscriber.name
  mymodule.event_subscriber.node:
    class: Drupal\mymodule\EventSubscriber\NodeEventSubscriber
    tags:
      - { name: event_subscriber }

  # Route subscribers: module.route_subscriber
  mymodule.route_subscriber:
    class: Drupal\mymodule\Routing\RouteSubscriber
    tags:
      - { name: event_subscriber }

  # Breadcrumb builders: module.breadcrumb.name
  mymodule.breadcrumb.custom:
    class: Drupal\mymodule\Breadcrumb\CustomBreadcrumbBuilder
    tags:
      - { name: breadcrumb_builder, priority: 100 }
```

---

## Dependency Injection

### SVC003: Constructor Injection

**Severity:** `high`

Always use constructor injection for services. Avoid using `\Drupal::service()` in classes.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;
use Drupal\Core\Session\AccountProxyInterface;

/**
 * Processes data for the mymodule module.
 */
class DataProcessor {

  /**
   * The logger channel.
   *
   * @var \Psr\Log\LoggerInterface
   */
  protected $logger;

  /**
   * Constructs a DataProcessor object.
   *
   * @param \Drupal\Core\Database\Connection $database
   *   The database connection.
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entityTypeManager
   *   The entity type manager.
   * @param \Drupal\Core\Logger\LoggerChannelFactoryInterface $loggerFactory
   *   The logger factory.
   * @param \Drupal\Core\Cache\CacheBackendInterface $cache
   *   The cache backend.
   * @param \Drupal\Core\Session\AccountProxyInterface $currentUser
   *   The current user.
   */
  public function __construct(
    protected Connection $database,
    protected EntityTypeManagerInterface $entityTypeManager,
    LoggerChannelFactoryInterface $loggerFactory,
    protected CacheBackendInterface $cache,
    protected AccountProxyInterface $currentUser,
  ) {
    $this->logger = $loggerFactory->get('mymodule');
  }

  /**
   * Processes the given data.
   *
   * @param array $data
   *   The data to process.
   *
   * @return array
   *   The processed data.
   */
  public function process(array $data): array {
    // Use injected services
    $nodes = $this->entityTypeManager
      ->getStorage('node')
      ->loadMultiple($data['nids']);

    $this->logger->info('Processed @count nodes for user @user', [
      '@count' => count($nodes),
      '@user' => $this->currentUser->getAccountName(),
    ]);

    return $nodes;
  }

}
```

**Bad Example:**
```php
<?php

namespace Drupal\mymodule\Service;

class BadService {

  public function process(array $data): array {
    // ❌ Using static service calls
    $database = \Drupal::database();
    $entity_manager = \Drupal::entityTypeManager();
    $current_user = \Drupal::currentUser();
    
    // ❌ Using service container directly
    $cache = \Drupal::service('cache.default');
    
    return [];
  }

}
```

---

### SVC004: Interface Type Hints

**Severity:** `medium`

Type hint interfaces instead of concrete classes when possible.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Service;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Session\AccountInterface;
use Psr\Log\LoggerInterface;

class FlexibleService {

  public function __construct(
    // Interface type hints allow for swapping implementations
    protected EntityTypeManagerInterface $entityTypeManager,
    protected ConfigFactoryInterface $configFactory,
    protected CacheBackendInterface $cache,
    protected LoggerInterface $logger,
  ) {}

  /**
   * Method accepting interface parameter.
   */
  public function processForUser(AccountInterface $account): array {
    // Works with User entity or AccountProxy
    $uid = $account->id();
    return [];
  }

}
```

---

## Controllers and Forms

### SVC005: Controller Dependency Injection

**Severity:** `high`

Use `create()` pattern for dependency injection in controllers.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\mymodule\Service\DataProcessor;
use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Controller for mymodule pages.
 */
class MyController extends ControllerBase {

  /**
   * Constructs a MyController object.
   *
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entityTypeManager
   *   The entity type manager.
   * @param \Drupal\mymodule\Service\DataProcessor $dataProcessor
   *   The data processor service.
   */
  public function __construct(
    protected EntityTypeManagerInterface $entityTypeManager,
    protected DataProcessor $dataProcessor,
  ) {}

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('entity_type.manager'),
      $container->get('mymodule.data_processor'),
    );
  }

  /**
   * Displays the main page.
   *
   * @return array
   *   A render array.
   */
  public function content(): array {
    $nodes = $this->entityTypeManager
      ->getStorage('node')
      ->loadByProperties(['status' => 1]);

    return [
      '#theme' => 'mymodule_list',
      '#nodes' => $nodes,
      '#cache' => [
        'tags' => ['node_list'],
        'contexts' => ['user.permissions'],
      ],
    ];
  }

  /**
   * API endpoint for data.
   *
   * @param \Symfony\Component\HttpFoundation\Request $request
   *   The request object.
   *
   * @return \Symfony\Component\HttpFoundation\JsonResponse
   *   JSON response.
   */
  public function apiEndpoint(Request $request): JsonResponse {
    $data = $this->dataProcessor->process([
      'type' => $request->query->get('type', 'default'),
    ]);

    return new JsonResponse($data);
  }

}
```

---

### SVC006: Form Dependency Injection

**Severity:** `high`

Use `create()` pattern for forms to inject services.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Form;

use Drupal\Core\Config\ConfigFactoryInterface;
use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\mymodule\Service\DataProcessor;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Configuration form for mymodule.
 */
class SettingsForm extends ConfigFormBase {

  /**
   * Constructs a SettingsForm object.
   *
   * @param \Drupal\Core\Config\ConfigFactoryInterface $config_factory
   *   The config factory.
   * @param \Drupal\mymodule\Service\DataProcessor $dataProcessor
   *   The data processor service.
   */
  public function __construct(
    ConfigFactoryInterface $config_factory,
    protected DataProcessor $dataProcessor,
  ) {
    parent::__construct($config_factory);
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('config.factory'),
      $container->get('mymodule.data_processor'),
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId(): string {
    return 'mymodule_settings';
  }

  /**
   * {@inheritdoc}
   */
  protected function getEditableConfigNames(): array {
    return ['mymodule.settings'];
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state): array {
    $config = $this->config('mymodule.settings');

    $form['api_endpoint'] = [
      '#type' => 'url',
      '#title' => $this->t('API Endpoint'),
      '#default_value' => $config->get('api_endpoint'),
      '#required' => TRUE,
    ];

    $form['cache_lifetime'] = [
      '#type' => 'number',
      '#title' => $this->t('Cache lifetime (seconds)'),
      '#default_value' => $config->get('cache_lifetime') ?? 3600,
      '#min' => 0,
      '#max' => 86400,
    ];

    return parent::buildForm($form, $form_state);
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->config('mymodule.settings')
      ->set('api_endpoint', $form_state->getValue('api_endpoint'))
      ->set('cache_lifetime', $form_state->getValue('cache_lifetime'))
      ->save();

    parent::submitForm($form, $form_state);
  }

}
```

---

## Plugin System

### SVC007: Plugin Annotations

**Severity:** `high`

Use proper annotations for plugin definitions.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\Plugin\Block;

use Drupal\Core\Access\AccessResult;
use Drupal\Core\Block\BlockBase;
use Drupal\Core\Cache\Cache;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Plugin\ContainerFactoryPluginInterface;
use Drupal\Core\Session\AccountInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Provides a featured content block.
 *
 * @Block(
 *   id = "mymodule_featured_content",
 *   admin_label = @Translation("Featured Content"),
 *   category = @Translation("My Module"),
 * )
 */
class FeaturedContentBlock extends BlockBase implements ContainerFactoryPluginInterface {

  /**
   * Constructs a FeaturedContentBlock object.
   *
   * @param array $configuration
   *   Plugin configuration.
   * @param string $plugin_id
   *   The plugin ID.
   * @param mixed $plugin_definition
   *   The plugin definition.
   * @param \Drupal\Core\Entity\EntityTypeManagerInterface $entityTypeManager
   *   The entity type manager.
   */
  public function __construct(
    array $configuration,
    $plugin_id,
    $plugin_definition,
    protected EntityTypeManagerInterface $entityTypeManager,
  ) {
    parent::__construct($configuration, $plugin_id, $plugin_definition);
  }

  /**
   * {@inheritdoc}
   */
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

  /**
   * {@inheritdoc}
   */
  public function defaultConfiguration(): array {
    return [
      'count' => 5,
      'content_type' => 'article',
    ] + parent::defaultConfiguration();
  }

  /**
   * {@inheritdoc}
   */
  public function blockForm($form, FormStateInterface $form_state): array {
    $form['count'] = [
      '#type' => 'number',
      '#title' => $this->t('Number of items'),
      '#default_value' => $this->configuration['count'],
      '#min' => 1,
      '#max' => 20,
    ];

    $form['content_type'] = [
      '#type' => 'select',
      '#title' => $this->t('Content type'),
      '#options' => $this->getContentTypeOptions(),
      '#default_value' => $this->configuration['content_type'],
    ];

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function blockSubmit($form, FormStateInterface $form_state): void {
    $this->configuration['count'] = $form_state->getValue('count');
    $this->configuration['content_type'] = $form_state->getValue('content_type');
  }

  /**
   * {@inheritdoc}
   */
  public function build(): array {
    $nodes = $this->entityTypeManager
      ->getStorage('node')
      ->loadByProperties([
        'type' => $this->configuration['content_type'],
        'status' => 1,
      ]);

    $nodes = array_slice($nodes, 0, $this->configuration['count']);

    $build = [
      '#theme' => 'mymodule_featured_content',
      '#nodes' => $nodes,
      '#cache' => [
        'tags' => ['node_list'],
        'contexts' => ['user.permissions'],
        'max-age' => 3600,
      ],
    ];

    return $build;
  }

  /**
   * {@inheritdoc}
   */
  protected function blockAccess(AccountInterface $account): AccessResult {
    return AccessResult::allowedIfHasPermission($account, 'access content');
  }

  /**
   * {@inheritdoc}
   */
  public function getCacheTags(): array {
    return Cache::mergeTags(parent::getCacheTags(), ['node_list']);
  }

  /**
   * {@inheritdoc}
   */
  public function getCacheContexts(): array {
    return Cache::mergeContexts(parent::getCacheContexts(), ['user.permissions']);
  }

  /**
   * Gets content type options.
   *
   * @return array
   *   Array of content type labels keyed by machine name.
   */
  protected function getContentTypeOptions(): array {
    $types = $this->entityTypeManager
      ->getStorage('node_type')
      ->loadMultiple();

    $options = [];
    foreach ($types as $type) {
      $options[$type->id()] = $type->label();
    }

    return $options;
  }

}
```

---

### SVC008: Custom Plugin Types

**Severity:** `medium`

Create custom plugin types for extensible functionality.

**Good Example:**
```php
<?php

// Plugin Manager
namespace Drupal\mymodule\Plugin;

use Drupal\Core\Plugin\DefaultPluginManager;
use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Extension\ModuleHandlerInterface;

/**
 * Plugin manager for data processor plugins.
 */
class DataProcessorManager extends DefaultPluginManager {

  public function __construct(
    \Traversable $namespaces,
    CacheBackendInterface $cache_backend,
    ModuleHandlerInterface $module_handler
  ) {
    parent::__construct(
      'Plugin/DataProcessor',
      $namespaces,
      $module_handler,
      'Drupal\mymodule\Plugin\DataProcessorInterface',
      'Drupal\mymodule\Annotation\DataProcessor'
    );
    
    $this->alterInfo('mymodule_data_processor_info');
    $this->setCacheBackend($cache_backend, 'mymodule_data_processors');
  }

}

// Plugin Interface
namespace Drupal\mymodule\Plugin;

use Drupal\Component\Plugin\PluginInspectionInterface;

interface DataProcessorInterface extends PluginInspectionInterface {

  public function process(array $data): array;
  
  public function supports(string $type): bool;

}

// Plugin Annotation
namespace Drupal\mymodule\Annotation;

use Drupal\Component\Annotation\Plugin;

/**
 * Defines a Data Processor plugin annotation.
 *
 * @Annotation
 */
class DataProcessor extends Plugin {

  public string $id;
  public string $label;
  public string $description = '';
  public int $weight = 0;

}

// Plugin Implementation
namespace Drupal\mymodule\Plugin\DataProcessor;

use Drupal\Core\Plugin\PluginBase;
use Drupal\mymodule\Plugin\DataProcessorInterface;

/**
 * Processes JSON data.
 *
 * @DataProcessor(
 *   id = "json",
 *   label = @Translation("JSON Processor"),
 *   description = @Translation("Processes JSON formatted data."),
 *   weight = 0,
 * )
 */
class JsonProcessor extends PluginBase implements DataProcessorInterface {

  public function process(array $data): array {
    // Processing logic
    return $data;
  }

  public function supports(string $type): bool {
    return $type === 'application/json';
  }

}
```

```yaml
# mymodule.services.yml
services:
  plugin.manager.mymodule_data_processor:
    class: Drupal\mymodule\Plugin\DataProcessorManager
    parent: default_plugin_manager
```

---

## Events and Subscribers

### SVC009: Event Subscribers

**Severity:** `medium`

Use event subscribers for decoupled functionality.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\mymodule\EventSubscriber;

use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;
use Drupal\Core\Messenger\MessengerInterface;
use Drupal\Core\Session\AccountProxyInterface;
use Drupal\Core\StringTranslation\StringTranslationTrait;
use Drupal\node\NodeInterface;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

/**
 * Event subscriber for mymodule.
 */
class MyModuleEventSubscriber implements EventSubscriberInterface {

  use StringTranslationTrait;

  public function __construct(
    protected EntityTypeManagerInterface $entityTypeManager,
    protected AccountProxyInterface $currentUser,
    protected MessengerInterface $messenger,
    protected LoggerChannelFactoryInterface $loggerFactory,
  ) {}

  /**
   * {@inheritdoc}
   */
  public static function getSubscribedEvents(): array {
    return [
      KernelEvents::REQUEST => ['onRequest', 100],
      KernelEvents::RESPONSE => ['onResponse', 0],
      // Custom events
      'mymodule.data_processed' => ['onDataProcessed'],
    ];
  }

  /**
   * Handles the request event.
   *
   * @param \Symfony\Component\HttpKernel\Event\RequestEvent $event
   *   The event object.
   */
  public function onRequest(RequestEvent $event): void {
    if (!$event->isMainRequest()) {
      return;
    }

    $request = $event->getRequest();
    
    // Log API requests
    if (str_starts_with($request->getPathInfo(), '/api/')) {
      $this->loggerFactory->get('mymodule')->info('API request: @path', [
        '@path' => $request->getPathInfo(),
      ]);
    }
  }

  /**
   * Handles the response event.
   *
   * @param \Symfony\Component\HttpKernel\Event\ResponseEvent $event
   *   The event object.
   */
  public function onResponse(ResponseEvent $event): void {
    $response = $event->getResponse();
    
    // Add custom headers
    $response->headers->set('X-Powered-By', 'MyModule');
  }

  /**
   * Handles custom data processed event.
   *
   * @param \Drupal\mymodule\Event\DataProcessedEvent $event
   *   The event object.
   */
  public function onDataProcessed(DataProcessedEvent $event): void {
    $data = $event->getData();
    
    $this->messenger->addStatus($this->t('Processed @count items.', [
      '@count' => count($data),
    ]));
  }

}
```

```yaml
# mymodule.services.yml
services:
  mymodule.event_subscriber:
    class: Drupal\mymodule\EventSubscriber\MyModuleEventSubscriber
    arguments:
      - '@entity_type.manager'
      - '@current_user'
      - '@messenger'
      - '@logger.factory'
    tags:
      - { name: event_subscriber }
```

---

### SVC010: Custom Events

**Severity:** `medium`

Create custom events for module extensibility.

**Good Example:**
```php
<?php

// Event class
namespace Drupal\mymodule\Event;

use Drupal\Component\EventDispatcher\Event;
use Drupal\node\NodeInterface;

/**
 * Event dispatched when data is processed.
 */
class DataProcessedEvent extends Event {

  /**
   * Event name.
   */
  public const EVENT_NAME = 'mymodule.data_processed';

  /**
   * Constructs a DataProcessedEvent object.
   *
   * @param array $data
   *   The processed data.
   * @param \Drupal\node\NodeInterface|null $node
   *   The related node, if any.
   */
  public function __construct(
    protected array $data,
    protected ?NodeInterface $node = NULL,
  ) {}

  /**
   * Gets the processed data.
   */
  public function getData(): array {
    return $this->data;
  }

  /**
   * Sets the processed data.
   */
  public function setData(array $data): void {
    $this->data = $data;
  }

  /**
   * Gets the related node.
   */
  public function getNode(): ?NodeInterface {
    return $this->node;
  }

}

// Dispatching the event
namespace Drupal\mymodule\Service;

use Drupal\mymodule\Event\DataProcessedEvent;
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

class DataProcessor {

  public function __construct(
    protected EventDispatcherInterface $eventDispatcher,
  ) {}

  public function process(array $data): array {
    // Process data...
    $processed = $this->doProcessing($data);
    
    // Dispatch event
    $event = new DataProcessedEvent($processed);
    $this->eventDispatcher->dispatch($event, DataProcessedEvent::EVENT_NAME);
    
    // Return potentially modified data
    return $event->getData();
  }

}
```

---

## Service Tags

### SVC011: Common Service Tags

**Severity:** `low`

Use appropriate service tags for framework integration.

**Good Example:**
```yaml
services:
  # Event subscriber
  mymodule.event_subscriber:
    class: Drupal\mymodule\EventSubscriber\MySubscriber
    tags:
      - { name: event_subscriber }

  # Access check
  mymodule.access_checker:
    class: Drupal\mymodule\Access\CustomAccessCheck
    tags:
      - { name: access_check, applies_to: _custom_access }

  # Breadcrumb builder
  mymodule.breadcrumb:
    class: Drupal\mymodule\Breadcrumb\CustomBreadcrumb
    tags:
      - { name: breadcrumb_builder, priority: 100 }

  # Path processor
  mymodule.path_processor:
    class: Drupal\mymodule\PathProcessor\CustomProcessor
    tags:
      - { name: path_processor_inbound, priority: 100 }
      - { name: path_processor_outbound, priority: 100 }

  # Route enhancer
  mymodule.route_enhancer:
    class: Drupal\mymodule\Routing\RouteEnhancer
    tags:
      - { name: route_enhancer }

  # Normalizer (for serialization)
  mymodule.normalizer:
    class: Drupal\mymodule\Normalizer\CustomNormalizer
    tags:
      - { name: normalizer, priority: 10 }

  # Theme negotiator
  mymodule.theme_negotiator:
    class: Drupal\mymodule\Theme\CustomNegotiator
    tags:
      - { name: theme_negotiator, priority: 100 }

  # Twig extension
  mymodule.twig_extension:
    class: Drupal\mymodule\Twig\MyExtension
    tags:
      - { name: twig.extension }

  # Cache context
  mymodule.cache_context.custom:
    class: Drupal\mymodule\Cache\Context\CustomCacheContext
    arguments: ['@request_stack']
    tags:
      - { name: cache.context }

  # Parameter converter
  mymodule.param_converter:
    class: Drupal\mymodule\ParamConverter\CustomConverter
    tags:
      - { name: paramconverter, priority: 10 }
```
