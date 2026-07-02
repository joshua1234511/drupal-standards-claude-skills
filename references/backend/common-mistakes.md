# Common Mistakes & Corrections

Common AI/developer mistakes in Drupal 10/11 and their correct patterns. Each item captures a frequently-repeated incorrect pattern (often from habit, legacy Drupal 7 knowledge, or plausible-but-invented APIs) alongside the current, idiomatic fix. **Severity levels: critical, high, medium, low**

These corrections are drawn from a failure taxonomy: `CONFABULATION` (invented plausible APIs), `SKILL_STALE` (superseded patterns), `ASSUMPTION_ERROR` (right facts, wrong inference), and `SKILL_GAP` (missing mental model).

## Table of Contents

1. [Deprecated & Invented Entity APIs](#deprecated--invented-entity-apis)
2. [Service Location vs Dependency Injection](#service-location-vs-dependency-injection)
3. [Cache Tag Invalidation Model](#cache-tag-invalidation-model)
4. [Legacy Drupal 7 Procedural Patterns](#legacy-drupal-7-procedural-patterns)
5. [Static Entity Loading in Services](#static-entity-loading-in-services)
6. [Render Arrays vs Direct Rendering](#render-arrays-vs-direct-rendering)
7. [Configuration vs State vs Settings](#configuration-vs-state-vs-settings)
8. [Deprecated Utility & Global Functions](#deprecated-utility--global-functions)

---

## Deprecated & Invented Entity APIs

### FIX001: Use entityTypeManager(), not entityManager()

**Severity:** `critical`

`\Drupal::entityManager()` was removed in Drupal 9. It is one of the most common confabulated APIs because it *sounds* plausible and mirrors legacy documentation. The service was split into several managers; entity storage now comes from the entity type manager.

**Correct:**
```php
// Static access (only where DI is unavailable, e.g. .module hooks)
$storage = \Drupal::entityTypeManager()->getStorage('node');
$node = $storage->load(1);

// Related split services
$field_manager = \Drupal::service('entity_field.manager');
$bundle_info = \Drupal::service('entity_type.bundle.info');
$repository = \Drupal::service('entity.repository');
```

**Incorrect:**
```php
// ❌ CRITICAL: Removed in Drupal 9 - does not exist
$storage = \Drupal::entityManager()->getStorage('node');

// ❌ CRITICAL: Invented method on the wrong manager
$node = \Drupal::entityManager()->load('node', 1);
```

**Rationale:** `entityManager()` was deprecated in 8.0 and removed in 9.0. Invoking it fatals. Always verify the current service entry point rather than reaching for a legacy-style name.

**References:**
- https://www.drupal.org/node/2549139
- https://api.drupal.org/api/drupal/core%21lib%21Drupal.php/function/Drupal%3A%3AentityTypeManager

---

### FIX002: Load entities via storage, not removed static ::load() habits

**Severity:** `high`

Static entity load helpers like `Node::load()` still exist, but in services and controllers you should load through injected storage. A frequent mistake is inventing storage method names or assuming `entityManager()` returns storage.

**Correct:**
```php
$node_storage = $this->entityTypeManager->getStorage('node');

// Single load
$node = $node_storage->load($nid);

// Multiple load
$nodes = $node_storage->loadMultiple($nids);

// Property-based load
$nodes = $node_storage->loadByProperties(['type' => 'article', 'status' => 1]);
```

**Incorrect:**
```php
// ❌ Invented convenience method
$node = $this->entityTypeManager->load('node', $nid);

// ❌ Wrong: getStorage does not take an ID
$node = $this->entityTypeManager->getStorage('node', $nid);
```

**Rationale:** `getStorage($entity_type_id)` returns a storage handler; loading is a second call. Conflating the two is a confabulation that fails at runtime.

---

## Service Location vs Dependency Injection

### FIX003: Inject services via the constructor in controllers and services

**Severity:** `high`

A classic `ASSUMPTION_ERROR`: the agent knows the correct service name but reaches for `\Drupal::service()` inside a class where dependency injection is available. Static service location in injectable classes hurts testability and is a code-standards violation.

**Correct:**
```php
namespace Drupal\mymodule\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class MyController extends ControllerBase {

  public function __construct(
    protected EntityTypeManagerInterface $entityTypeManager,
  ) {}

  public static function create(ContainerInterface $container): static {
    return new static(
      $container->get('entity_type.manager'),
    );
  }

  public function page(): array {
    $nodes = $this->entityTypeManager->getStorage('node')->loadMultiple();
    // ...
  }
}
```

**Incorrect:**
```php
class MyController extends ControllerBase {

  public function page(): array {
    // ❌ Service location inside an injectable class
    $storage = \Drupal::service('entity_type.manager')->getStorage('node');
    // ...
  }
}
```

**Rationale:** Controllers, forms, blocks, and tagged services all support DI via `create()` / `services.yml`. Static calls only belong in procedural code (`.module`, `.install`, `.theme`) where no container injection point exists.

**References:**
- https://www.drupal.org/docs/drupal-apis/services-and-dependency-injection

---

### FIX004: Use static \Drupal:: only in procedural code

**Severity:** `medium`

The inverse mistake: over-engineering procedural hook code with service wiring that cannot be injected. Inside `.module`/`.install` hooks there is no constructor, so static access is correct there.

**Correct:**
```php
// mymodule.module - procedural, no DI available
function mymodule_node_insert(NodeInterface $node): void {
  \Drupal::logger('mymodule')->info('Node @id created', ['@id' => $node->id()]);
}
```

**Incorrect:**
```php
// ❌ There is no container injection point in a procedural hook;
//    attempting create()/constructor patterns here is wrong.
function mymodule_node_insert(NodeInterface $node): void {
  $service = new SomeService($container->get(...)); // no $container here
}
```

**Rationale:** Match the tool to the context. DI in classes; static `\Drupal::` in hooks and other procedural entry points.

---

## Cache Tag Invalidation Model

### FIX005: Understand two-phase cache tag invalidation

**Severity:** `high`

A common `SKILL_GAP`: assuming cache tag invalidation synchronously deletes cache items because most cache systems work that way. Drupal invalidation is two-phase.

**Correct (mental model):**
```php
// Invalidation updates a checksum immediately; it does NOT delete items.
\Drupal::service('cache_tags.invalidator')->invalidateTags(['node:1']);

// On the NEXT read, the cached item's stored tag checksum is compared to the
// current checksum. If they differ, the item is treated as a miss and
// regenerated. Eviction is lazy, on next read - not eager deletion.
$cache = \Drupal::cache()->get('my_cid');
// $cache === FALSE if any of its tags were invalidated since it was written.
```

**Incorrect (wrong assumption):**
```php
// ❌ Wrong mental model: invalidation does NOT eagerly/synchronously delete.
// Do not rely on the item being physically gone right after invalidateTags().
\Drupal::service('cache_tags.invalidator')->invalidateTags(['node:1']);
// assert(\Drupal::cache()->get('my_cid') removed from backend) // false assumption
```

**Rationale:** Invalidation is a checksum bump; stale items are removed lazily on next read. Attach the right cache tags to render arrays and let the system handle correctness, rather than trying to manually delete entries.

**References:**
- https://www.drupal.org/docs/drupal-apis/cache-api/cache-tags

---

## Legacy Drupal 7 Procedural Patterns

### FIX006: Do not use db_query() or removed database functions

**Severity:** `critical`

`db_query()`, `db_select()`, and friends were removed. Reaching for them is a `SKILL_STALE` failure carried over from Drupal 7 muscle memory.

**Correct:**
```php
// Injected connection (preferred)
$result = $this->database->select('users_field_data', 'u')
  ->fields('u', ['uid', 'name'])
  ->condition('status', 1)
  ->execute()
  ->fetchAll();

// Static access only in procedural code
$connection = \Drupal::database();
```

**Incorrect:**
```php
// ❌ CRITICAL: Removed procedural DB API from Drupal 7
$result = db_query("SELECT uid, name FROM {users} WHERE status = 1");
$result = db_select('users', 'u')->fields('u')->execute();
```

**Rationale:** The procedural `db_*` layer is gone. Use the `database` service (injected) or `\Drupal::database()` in procedural contexts.

---

### FIX007: Replace drupal_set_message() with the messenger service

**Severity:** `high`

`drupal_set_message()` was removed. Use the messenger service, injected where possible.

**Correct:**
```php
// In an injectable class
$this->messenger()->addStatus($this->t('Saved.'));
$this->messenger()->addWarning($this->t('Check your input.'));
$this->messenger()->addError($this->t('Something failed.'));

// Procedural
\Drupal::messenger()->addStatus(t('Saved.'));
```

**Incorrect:**
```php
// ❌ Removed function
drupal_set_message(t('Saved.'));
drupal_set_message(t('Failed.'), 'error');
```

**Rationale:** Messaging moved to the `messenger` service with typed methods (`addStatus`, `addWarning`, `addError`) replacing the string `$type` argument.

---

## Static Entity Loading in Services

### FIX008: Do not call \Drupal::currentUser() inside injectable services

**Severity:** `medium`

Another `ASSUMPTION_ERROR`: the correct account exists at `\Drupal::currentUser()`, but inside a service the current user should be injected as `current_user` for testability and cache correctness.

**Correct:**
```php
use Drupal\Core\Session\AccountProxyInterface;

class MyService {
  public function __construct(
    protected AccountProxyInterface $currentUser,
  ) {}

  public function canDoThing(): bool {
    return $this->currentUser->hasPermission('do thing');
  }
}
```
```yaml
# mymodule.services.yml
services:
  mymodule.my_service:
    class: Drupal\mymodule\MyService
    arguments: ['@current_user']
```

**Incorrect:**
```php
class MyService {
  public function canDoThing(): bool {
    // ❌ Static access inside an injectable service
    return \Drupal::currentUser()->hasPermission('do thing');
  }
}
```

**Rationale:** Injecting `current_user` makes the service unit-testable and keeps dependencies explicit. Static access hides them.

---

## Render Arrays vs Direct Rendering

### FIX009: Return render arrays, do not render to string prematurely

**Severity:** `high`

A frequent mistake is calling the renderer manually and returning a string from a controller, which loses cacheability metadata and bubbling.

**Correct:**
```php
public function page(): array {
  return [
    '#theme' => 'item_list',
    '#items' => $items,
    '#cache' => [
      'tags' => ['node_list'],
      'contexts' => ['user.permissions'],
    ],
  ];
}
```

**Incorrect:**
```php
public function page(): string {
  // ❌ Premature rendering loses cache metadata and bubbled attachments
  $build = ['#theme' => 'item_list', '#items' => $items];
  return \Drupal::service('renderer')->render($build);
}
```

**Rationale:** Returning the render array lets the render pipeline handle caching, attachments, and placeholders. Manual early rendering discards cache tags/contexts and can trigger "leaked metadata" errors.

---

## Configuration vs State vs Settings

### FIX010: Choose the right storage: config, state, or settings

**Severity:** `medium`

Mixing up configuration, state, and settings is a common `SKILL_GAP`. Each has a distinct purpose and misuse causes deployment and cache problems.

**Correct:**
```php
// Config: exportable, deployable, per-environment overridable via settings.php
$api_mode = $this->configFactory->get('mymodule.settings')->get('api_mode');

// State: runtime values NOT meant to be deployed (last cron run, counters)
$last_run = \Drupal::state()->get('mymodule.last_run', 0);
\Drupal::state()->set('mymodule.last_run', time());

// Settings: read-only, defined in settings.php (secrets, environment config)
$path = Settings::get('file_private_path');
```

**Incorrect:**
```php
// ❌ Storing environment-specific runtime data in exportable config
$this->configFactory->getEditable('mymodule.settings')
  ->set('last_cron_run', time())  // churns config on every run
  ->save();

// ❌ Storing deployable structure in state (never exported, lost across envs)
\Drupal::state()->set('mymodule.enabled_features', $feature_list);
```

**Rationale:** Config is for deployable settings, state for transient runtime values, and settings.php for secrets/environment. Putting runtime counters in config pollutes config sync; putting deployable structure in state breaks environment parity.

---

## Deprecated Utility & Global Functions

### FIX011: Use format_date/DateFormatter service, not removed helpers

**Severity:** `medium`

Legacy global helpers such as `format_date()`, `check_plain()`, and `drupal_render()` were removed or relocated. These are common `SKILL_STALE` confabulations.

**Correct:**
```php
use Drupal\Component\Utility\Html;

// Date formatting via service
$formatted = \Drupal::service('date.formatter')->format($timestamp, 'medium');

// Escaping plain text
$safe = Html::escape($user_input);

// Rendering (prefer returning render arrays; if you must render)
$output = \Drupal::service('renderer')->renderInIsolation($build);
```

**Incorrect:**
```php
// ❌ Removed global functions
$formatted = format_date($timestamp, 'medium');
$safe = check_plain($user_input);
$output = drupal_render($build);
```

**Rationale:** These procedural helpers were replaced by the `date.formatter` service, `Html::escape()`, and the `renderer` service respectively. Reaching for the old names fatals or triggers deprecation errors.

---

### FIX012: Use \Drupal::request() / RequestStack, not $_GET/$_POST directly

**Severity:** `high`

Reading raw superglobals bypasses Drupal's request handling and is both a security and correctness mistake (no sanitization context, breaks under sub-requests and CLI).

**Correct:**
```php
use Symfony\Component\HttpFoundation\RequestStack;

class MyService {
  public function __construct(
    protected RequestStack $requestStack,
  ) {}

  public function getSearchTerm(): ?string {
    return $this->requestStack->getCurrentRequest()->query->get('search');
  }
}

// Procedural fallback
$search = \Drupal::request()->query->get('search');
```

**Incorrect:**
```php
// ❌ Raw superglobals: no request abstraction, unsafe by habit
$search = $_GET['search'];
$data = $_POST['data'];
```

**Rationale:** The Symfony `Request` object provides the current request across sub-requests and CLI, and integrates with Drupal's parameter bags. Direct superglobal access is fragile and encourages unescaped input handling.

**References:**
- https://api.drupal.org/api/drupal/core%21lib%21Drupal.php/function/Drupal%3A%3Arequest
