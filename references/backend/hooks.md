# Hooks and Events Standards

Standards for implementing hooks and for choosing between the legacy Hook system and the modern Symfony Event Subscriber pattern.

## Table of Contents

1. [Events over Hooks — The Modern Approach](#events-over-hooks)
2. [Implementing Hooks](#implementing-hooks)
3. [Alter Hooks](#alter-hooks)
4. [Hook Discovery and Documentation](#hook-discovery-and-documentation)
5. [Event Subscribers (Preferred)](#event-subscribers)

---

## Events over Hooks — The Modern Approach

### HOOK001: Prefer Events for New Functionality

**Severity:** `high`

**For all new functionality, use the Symfony Event Subscriber system instead of hooks.** Events provide:
- Type-safety via typed Event classes
- Easier unit testing (no global function mock required)
- Better IDE support and discoverability
- Compatibility with Drupal's future direction (hooks are being deprecated progressively)

**Use hooks when:**
- Implementing `hook_entity_alter()`, `hook_form_alter()`, or other core-provided alter hooks
- Integrating with modules that only expose hooks (no events)
- Legacy compatibility is required

**Use Events when:**
- Creating your own integration points in a module
- Reacting to Symfony kernel events (request, response, exception)
- Reacting to Drupal core events (e.g., `ConfigEvents`, `MigrateEvents`)

---

## Implementing Hooks

### HOOK002: Implement Hooks in the Correct File

**Severity:** `high`

| Hook Type | File |
|-----------|------|
| Standard hooks (`hook_node_presave`, etc.) | `mymodule.module` |
| Theme hooks (`hook_theme`, `hook_preprocess_*`) | `mymodule.module` or `mymodule.theme` |
| Install/uninstall (`hook_install`, `hook_schema`) | `mymodule.install` |
| Update hooks (`hook_update_N`) | `mymodule.install` |
| Views hooks | `mymodule.views.inc` (declared in `.info.yml`) |

**Good Example:**
```php
// mymodule.module

/**
 * Implements hook_node_presave().
 */
function mymodule_node_presave(NodeInterface $node): void {
  if ($node->getType() === 'article') {
    // Set a computed field before save.
    $node->set('field_word_count', str_word_count($node->body->value));
  }
}
```

---

### HOOK003: Keep Hooks Thin — Delegate to Services

**Severity:** `medium`

Hook implementations should be thin wrappers that delegate business logic to injected services. Never put complex logic directly in a hook function.

**Good Example:**
```php
// mymodule.module — thin hook.
function mymodule_node_presave(NodeInterface $node): void {
  \Drupal::service('mymodule.node_processor')->processBeforeSave($node);
}

// src/Service/NodeProcessor.php — testable service with the real logic.
class NodeProcessor {
  public function processBeforeSave(NodeInterface $node): void {
    // All logic here — easily unit tested.
  }
}
```

**Bad Example:**
```php
// ❌ Business logic buried in an untestable hook.
function mymodule_node_presave(NodeInterface $node): void {
  $database = \Drupal::database();
  $count = $database->select('mymodule_log')->countQuery()->execute()->fetchField();
  // 50 more lines of logic...
}
```

---

## Alter Hooks

### HOOK004: Use hook_*_alter() Correctly

**Severity:** `medium`

Alter hooks receive data by reference. Always modify the `$data` parameter directly rather than returning a value.

**Good Example:**
```php
/**
 * Implements hook_form_FORM_ID_alter().
 */
function mymodule_form_user_login_form_alter(array &$form, FormStateInterface $form_state, string $form_id): void {
  // Add a custom validator.
  $form['#validate'][] = 'mymodule_user_login_validate';

  // Modify an existing element.
  $form['name']['#description'] = t('Enter your username or email address.');
}

/**
 * Custom login form validator.
 */
function mymodule_user_login_validate(array &$form, FormStateInterface $form_state): void {
  \Drupal::service('mymodule.auth_validator')->validate($form_state);
}
```

---

### HOOK005: Use hook_module_implements_alter() Sparingly

**Severity:** `low`

You can reorder hook implementations with `hook_module_implements_alter()`, but use it only when ordering is genuinely critical.

**Good Example:**
```php
/**
 * Implements hook_module_implements_alter().
 *
 * Ensure mymodule runs last for hook_node_presave.
 */
function mymodule_module_implements_alter(array &$implementations, string $hook): void {
  if ($hook === 'node_presave') {
    $group = $implementations['mymodule'];
    unset($implementations['mymodule']);
    $implementations['mymodule'] = $group;
  }
}
```

---

## Hook Discovery and Documentation

### HOOK006: Document Hooks You Provide

**Severity:** `medium`

If your module provides its own hooks for other modules to implement, document them in a `mymodule.api.php` file.

**Good Example:**
```php
// mymodule.api.php — documentation only, never executed.

/**
 * @addtogroup hooks
 * @{
 */

/**
 * Alter mymodule records before they are saved.
 *
 * @param array $record
 *   The record data, passed by reference.
 * @param string $context
 *   The context in which the record is being saved.
 */
function hook_mymodule_record_presave(array &$record, string $context): void {
  // Example: flag records as needing review.
  if ($context === 'import') {
    $record['needs_review'] = TRUE;
  }
}

/**
 * @} End of "addtogroup hooks".
 */
```

---

## Event Subscribers

### HOOK007: Create Event Subscribers for Custom React Logic

**Severity:** `high`

For reacting to system events (Drupal or Symfony), register an Event Subscriber service. See `references/backend/services.md` → §Events and Subscribers for full patterns.

**Quick Reference:**
```php
// src/EventSubscriber/MyModuleSubscriber.php
namespace Drupal\mymodule\EventSubscriber;

use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\HttpKernel\Event\RequestEvent;

class MyModuleSubscriber implements EventSubscriberInterface {

  public static function getSubscribedEvents(): array {
    return [
      KernelEvents::REQUEST => ['onRequest', 30],
    ];
  }

  public function onRequest(RequestEvent $event): void {
    // React to the request.
  }

}
```

```yaml
# mymodule.services.yml
services:
  mymodule.subscriber:
    class: Drupal\mymodule\EventSubscriber\MyModuleSubscriber
    tags:
      - { name: event_subscriber }
```

> 📖 For dispatching your own events, see `references/backend/services.md` → SVC010: Custom Events.
