# Configuration Standards

Standards for working with Drupal's configuration system — choosing the right storage mechanism, writing schema, and following the export/import workflow. **Severity levels: critical, high, medium, low**

## Table of Contents

1. [Storage Mechanisms](#storage-mechanisms)
2. [Simple Config vs. Config Entities](#simple-config-vs-config-entities)
3. [Config Schema](#config-schema)
4. [Config Dependencies](#config-dependencies)
5. [Third-Party Settings](#third-party-settings)
6. [Config Overrides & Environments](#config-overrides--environments)
7. [Export/Import Workflow](#exportimport-workflow)
8. [Updating Config in Update Hooks](#updating-config-in-update-hooks)
9. [Secrets in Configuration](#secrets-in-configuration)

---

## Storage Mechanisms

### CFG001: Choose the Correct Storage Mechanism

**Severity:** `high`

Drupal separates stored data into three distinct mechanisms: **Config**, **State**, and **Settings**. Picking the wrong one causes deployment bugs, security issues, or data loss.

- **Config** (`config.factory` service / `\Drupal::config()`) stores site-building decisions that should be the same across all environments: content types, view definitions, module settings like "items per page." Config is exported to YAML, committed to git, and imported on deploy. Use it for anything an admin configures once and expects to persist across deployments.
- **State** (`state` service / `\Drupal::state()`) stores runtime data that changes frequently and is environment-specific: last cron run, system timestamps, maintenance mode flag. State is never exported.
- **Settings** (`$settings` in `settings.php`, read via `Settings::get()`) stores environment-specific values that must not leave the server: database credentials, API keys, hash salts, environment flags. Settings is not exportable and not accessible through the admin UI.

Use this decision table:

| Question | Use |
| --- | --- |
| Same across all environments? | Config |
| Changes frequently at runtime? | State |
| Environment-specific or secret? | Settings |
| Admin manages multiple instances through UI? | Config entity |
| Simple key-value module settings? | Simple config |

In services, controllers, forms, and plugins, inject the `config.factory` or `state` service via dependency injection rather than using static `\Drupal::` calls.

**Good Example:**
```php
// Site-building setting that ships and deploys with the site → config.
$items_per_page = $this->configFactory->get('my_module.settings')->get('items_per_page');

// Frequently-changing runtime value → state.
$this->state->set('my_module.last_run', \Drupal::time()->getRequestTime());
$last_run = $this->state->get('my_module.last_run', 0);

// Environment-specific secret → settings.php.
$api_key = Settings::get('my_module_api_key');
```

**Bad Example:**
```php
// ❌ Storing a frequently-changing timestamp in config.
// Every cron run creates a config diff and risks overwriting prod on deploy.
$this->configFactory->getEditable('my_module.settings')
  ->set('last_run', time())
  ->save();

// ❌ Storing a secret in config — it gets exported to YAML and committed to git.
$this->configFactory->getEditable('my_module.settings')
  ->set('api_key', 'sk_live_xxxxx')
  ->save();
```

**References:**
- https://www.drupal.org/docs/drupal-apis/configuration-api
- https://www.drupal.org/docs/drupal-apis/state-api

---

### CFG002: Use Immutable Config for Reads, Editable for Writes

**Severity:** `medium`

`get()` on an immutable config object returns the overridden (active) value the site is currently using. `getEditable()` returns a mutable object intended only for writing. Do not use `getEditable()` merely to read — it bypasses the override system and returns a saveable object you did not intend to save.

**Good Example:**
```php
// Read the active (overridden) value.
$name = $this->configFactory->get('system.site')->get('name');

// Read the original stored value, ignoring overrides.
$raw = $this->configFactory->get('system.site')->getOriginal('name', FALSE);

// Get a mutable object only when you actually need to write.
$config = $this->configFactory->getEditable('system.site');
$config->set('name', 'New Name')->save();
```

**Bad Example:**
```php
// ❌ Using getEditable() just to read a value.
$name = $this->configFactory->getEditable('system.site')->get('name');

// ❌ Trying to save an overridden config object — overrides are read-only.
$config = $this->configFactory->get('system.site');
$config->set('name', 'X')->save(); // Immutable objects cannot be saved.
```

---

## Simple Config vs. Config Entities

### CFG003: Use Simple Config for Module Settings

**Severity:** `medium`

**Simple config** (`my_module.settings`) is a single YAML file of key-value pairs. Use it for module settings with a small number of options: API endpoint URL, items per page, feature toggle. Pair it with a `ConfigFormBase` settings form.

**Good Example:**
```php
namespace Drupal\my_module\Form;

use Drupal\Core\Form\ConfigFormBase;
use Drupal\Core\Form\FormStateInterface;

class SettingsForm extends ConfigFormBase {

  public function getFormId(): string {
    return 'my_module_settings';
  }

  protected function getEditableConfigNames(): array {
    return ['my_module.settings'];
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $config = $this->config('my_module.settings');
    $form['items_per_page'] = [
      '#type' => 'number',
      '#title' => $this->t('Items per page'),
      '#default_value' => $config->get('items_per_page'),
    ];
    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->config('my_module.settings')
      ->set('items_per_page', $form_state->getValue('items_per_page'))
      ->save();
    parent::submitForm($form, $form_state);
  }
}
```

---

### CFG004: Use Config Entities for Multiple Managed Instances

**Severity:** `medium`

**Config entities** implement `ConfigEntityInterface` and are managed through the admin UI with list, add, edit, and delete operations. Use them when admins need to create multiple structured instances (image styles, text formats, views), or when the config participates in dependency chains with other config entities and needs dependency tracking, access control, and lifecycle hooks. Do not create a config entity when simple config would suffice — evaluate the actual requirements first.

**Good Example:**
```php
namespace Drupal\my_module\Entity;

use Drupal\Core\Config\Entity\ConfigEntityBase;

/**
 * @ConfigEntityType(
 *   id = "my_widget",
 *   label = @Translation("Widget"),
 *   config_prefix = "widget",
 *   entity_keys = {
 *     "id" = "id",
 *     "label" = "label",
 *   },
 *   config_export = {
 *     "id",
 *     "label",
 *     "endpoint",
 *   },
 * )
 */
class Widget extends ConfigEntityBase {
  protected string $id;
  protected string $label;
  protected string $endpoint;
}
```

**Bad Example:**
```php
// ❌ Using a config entity for one global module setting with no
// dependency tracking, access control, or lifecycle needs — use simple config.
```

---

## Config Schema

### CFG005: Provide a Schema for Every Config File

**Severity:** `high`

Every config file in `config/install/` or `config/optional/` must have a matching schema definition in `config/schema/*.schema.yml`. Config without schema breaks config validation (strict validation rolled out through Drupal 10.3+ and 11.x), config translation, config inspector, and causes silent type coercion during export/import.

**Good Example:**
```yaml
# config/schema/my_module.schema.yml
my_module.settings:
  type: config_object
  label: 'My module settings'
  mapping:
    api_endpoint:
      type: uri
      label: 'API endpoint'
    items_per_page:
      type: integer
      label: 'Items per page'
    enabled:
      type: boolean
      label: 'Enabled'
    tags:
      type: sequence
      label: 'Tags'
      sequence:
        type: string
```

**Bad Example:**
```yaml
# ❌ config/install/my_module.settings.yml with NO matching schema file.
# Config validation rejects it and translation is broken.
api_endpoint: 'https://api.example.com'
items_per_page: 10
```

---

### CFG006: Use Correct Schema Types

**Severity:** `medium`

Schema types (`string`, `integer`, `boolean`, `sequence`, `mapping`) must match the actual values in the YAML file. The most common error is using `string` for a human-readable label — use `label` instead so the value is translatable. Additional types: `uri` for URIs, `path` for internal paths, `date_format` for date format strings.

**Good Example:**
```yaml
my_module.settings:
  type: config_object
  label: 'My module settings'
  mapping:
    # Human-readable, translatable string → label.
    heading:
      type: label
      label: 'Heading'
    # Machine value → string.
    machine_key:
      type: string
      label: 'Machine key'
    # Numeric value → integer, not string.
    max_results:
      type: integer
      label: 'Maximum results'
```

**Bad Example:**
```yaml
my_module.settings:
  type: config_object
  mapping:
    # ❌ Human-readable label typed as string — not translatable.
    heading:
      type: string
    # ❌ Integer value typed as string — coercion fails silently.
    max_results:
      type: string
```

---

## Config Dependencies

### CFG007: Declare Config Dependencies

**Severity:** `high`

Every config entity and every config file in `config/install/` or `config/optional/` must declare its dependencies. The `ConfigImporter` validates dependencies on import — missing dependencies cause import failures. For config entities defined in code, dependencies are calculated automatically by `calculateDependencies()`. For install config YAML files, declare them explicitly.

Dependency types:
- **module**: modules that must be installed for this config to function.
- **config**: other config entities this config depends on.
- **theme**: themes this config depends on.
- **enforced**: dependencies that, when removed, cause this config to be deleted.

**Good Example:**
```yaml
# config/install/my_module.widget.default.yml
langcode: en
status: true
dependencies:
  module:
    - node
    - views
  config:
    - node.type.article
  enforced:
    module:
      - my_module
id: default
label: 'Default widget'
```

**Bad Example:**
```yaml
# ❌ Install config that references node.type.article and views but declares
# no dependencies — config import fails on a site without them.
id: default
label: 'Default widget'
```

---

## Third-Party Settings

### CFG008: Use Third-Party Settings for Config You Don't Own

**Severity:** `high`

When your module needs to attach settings to a config entity it does not own (e.g., adding a setting to a content type or field defined by another module), use the `third_party_settings` mechanism. Do not modify other modules' config keys directly. Third-party settings are namespaced by module and are automatically cleaned up when your module is uninstalled. They also require a schema definition using the `*.third_party.my_module` pattern.

**Good Example:**
```php
// Store a namespaced setting on a config entity owned by another module.
$content_type->setThirdPartySetting('my_module', 'custom_flag', TRUE);
$content_type->save();

// Read it back with a default.
$flag = $content_type->getThirdPartySetting('my_module', 'custom_flag', FALSE);
```

```yaml
# config/schema/my_module.schema.yml
node.type.*.third_party.my_module:
  type: mapping
  label: 'My module settings'
  mapping:
    custom_flag:
      type: boolean
      label: 'Custom flag'
```

**Bad Example:**
```php
// ❌ Writing a foreign key directly into another module's config entity.
$config = $this->configFactory->getEditable('node.type.article');
$config->set('my_module_custom_flag', TRUE)->save();
// Not namespaced, no schema, not cleaned up on uninstall.
```

---

## Config Overrides & Environments

### CFG009: Override Per-Environment Values in settings.php

**Severity:** `medium`

Drupal has a layered override system (settings.php overrides, language overrides, module overrides). "Same across all environments" means the _stored_ value is the same — overrides layer on top at runtime without changing the exported YAML. When a value must differ per environment, store the default in config and override it in `settings.php`, or use a tool such as Config Split for environment-specific config sets. This keeps a single canonical exported YAML while allowing per-environment behaviour.

**Good Example:**
```php
// settings.local.php (dev) — override without touching exported YAML.
$config['system.performance']['css']['preprocess'] = FALSE;
$config['system.performance']['js']['preprocess'] = FALSE;

// settings.php (prod) — point to an environment-specific endpoint.
$config['my_module.settings']['api_endpoint'] = getenv('MY_MODULE_ENDPOINT');
```

```php
// Reading always returns the overridden value at runtime.
$endpoint = $this->configFactory->get('my_module.settings')->get('api_endpoint');
```

**Bad Example:**
```php
// ❌ Hard-coding a dev-only value into exported config, then repeatedly
// re-exporting the "prod" value — every deploy fights the override.
$this->configFactory->getEditable('system.performance')
  ->set('css.preprocess', FALSE)
  ->save();
```

---

## Export/Import Workflow

### CFG010: Follow the Export/Import Workflow

**Severity:** `high`

The correct workflow for config changes on a running site:

1. Make changes through the admin UI or programmatically via the API.
2. Export with `drush config:export` (`cex`) or via `/admin/config/development/configuration`.
3. Review the diff in the sync directory (`config/sync/`).
4. Commit the YAML files to git.
5. On deploy, import with `drush config:import` (`cim`).

Do not hand-edit YAML files in `config/sync/` as the primary way to make config changes — Drupal normalizes values during export, and hand-edited files may have wrong types or missing keys. For module development, writing YAML directly in `config/install/` and `config/optional/` is the expected workflow, with schema validation as the quality gate.

**Good Example:**
```bash
# After changing settings in the UI:
drush config:export
git add config/sync
git diff --cached config/sync   # Review before committing.
git commit -m "Update my_module settings"

# On deploy:
drush config:import
drush cache:rebuild
```

**Bad Example:**
```bash
# ❌ Editing active site config by hand-writing sync YAML, then importing.
vim config/sync/my_module.settings.yml   # Wrong types / missing keys likely.
drush config:import
```

---

## Updating Config in Update Hooks

### CFG011: Modify Existing Config in Update Hooks

**Severity:** `high`

Changes to a module's `config/install/` YAML only apply on a fresh install — existing sites already imported the old config. To change config on existing sites, use `hook_update_N()` (or `hook_post_update_NAME()`) to load and modify the active config. In Drupal 10.3+, **config actions** in recipes can declaratively modify config owned by other modules; a module's own default config still belongs in `config/install/`.

Always load config, set the changed keys, and save — do not overwrite the entire object and lose user customisations.

**Good Example:**
```php
/**
 * Add the new 'enabled' setting to existing sites.
 */
function my_module_update_10001(): void {
  $config = \Drupal::configFactory()->getEditable('my_module.settings');
  if ($config->get('enabled') === NULL) {
    $config->set('enabled', TRUE)->save();
  }
}

/**
 * Post-update runs after config is imported and entities are available.
 */
function my_module_post_update_set_default_widget(): void {
  $storage = \Drupal::entityTypeManager()->getStorage('my_widget');
  if (!$storage->load('default')) {
    $storage->create(['id' => 'default', 'label' => 'Default'])->save();
  }
}
```

**Bad Example:**
```php
// ❌ Editing config/install/ YAML and expecting existing sites to pick it up.
// Only fresh installs read config/install/.

// ❌ Overwriting the whole config object, wiping admin customisations.
function my_module_update_10001(): void {
  \Drupal::configFactory()->getEditable('my_module.settings')
    ->setData(['enabled' => TRUE]) // Loses every other key.
    ->save();
}
```

---

## Secrets in Configuration

### CFG012: Never Store Secrets in Config

**Severity:** `critical`

Do not store API keys, passwords, tokens, or other secrets in config. Config is exported to YAML and committed to git, so any secret placed there leaks into version control. Store secrets in `settings.php` via `$settings[...]` and read them with `Settings::get()`, use environment variables, or use the Key module. If a value needs to differ per environment and is sensitive, it belongs in settings, not config.

**Good Example:**
```php
// settings.php (not committed / environment-provided).
$settings['my_module_api_key'] = getenv('MY_MODULE_API_KEY');

// Read the secret at runtime.
use Drupal\Core\Site\Settings;
$api_key = Settings::get('my_module_api_key');

// Or use the Key module for managed secrets.
$api_key = \Drupal::service('key.repository')->getKey('my_api_key')->getKeyValue();
```

**Bad Example:**
```php
// ❌ CRITICAL: Secret stored in config → exported to YAML → committed to git.
$this->configFactory->getEditable('my_module.settings')
  ->set('api_key', 'sk_live_1234567890abcdef')
  ->save();
```

```yaml
# ❌ CRITICAL: Secret sitting in an exported config file.
# config/sync/my_module.settings.yml
api_key: 'sk_live_1234567890abcdef'
```

**References:**
- https://www.drupal.org/docs/drupal-apis/configuration-api/configuration-override-system
- https://www.drupal.org/docs/drupal-apis/configuration-api/configuration-schemametadata
