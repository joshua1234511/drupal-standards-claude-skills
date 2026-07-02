# Documentation Standards

Standards for writing and maintaining documentation in Drupal projects: DocBlocks, API documentation, hook documentation, module help, READMEs, and handbook/Markdown pages. These follow the Drupal API documentation and comment standards and the Drupal Documentation Working Group's guidance.

> **Note:** Foundational DocBlock rules already appear in [php-standards.md](php-standards.md) — see **PHP013** (File DocBlocks), **PHP014** (Class and Method DocBlocks), and **PHP015** (Inline Comments). This file expands on those with the finer-grained tag, hook, API, README, and prose conventions. Where overlap exists, it is cross-referenced rather than repeated.

## Table of Contents

1. [DocBlock Tags](#docblock-tags)
2. [Hook Documentation](#hook-documentation)
3. [API Documentation Conventions](#api-documentation-conventions)
4. [Module Help](#module-help)
5. [README Structure](#readme-structure)
6. [Handbook & Markdown Documentation](#handbook--markdown-documentation)

---

## DocBlock Tags

### DOC001: @param Tags

**Severity:** `medium`

Document every parameter with an `@param` tag. The type and variable name go on the tag line; the description goes on the following line, indented three spaces relative to the asterisk. Mark optional parameters with `(optional)` and describe defaults. Do not use `@param` as a substitute for a real type hint — see [PHP010](php-standards.md#php010-parameter-type-declarations).

**Good Example:**
```php
<?php

/**
 * Builds a render array for a list of nodes.
 *
 * @param \Drupal\node\NodeInterface[] $nodes
 *   The nodes to render, keyed by node ID.
 * @param string $view_mode
 *   The view mode to render each node in.
 * @param array $options
 *   (optional) An associative array of options:
 *   - cache: Whether to cache the result. Defaults to TRUE.
 *   - langcode: Language code to render in. Defaults to the current language.
 *
 * @return array
 *   A render array representing the node list.
 */
public function buildList(array $nodes, string $view_mode, array $options = []): array {
  // Implementation.
}
```

**Bad Example:**
```php
<?php

/**
 * @param $nodes description of nodes    // ❌ No type, description on same line.
 * @param array $options options         // ❌ Vague, no optional marker, no defaults.
 */
public function buildList($nodes, array $options = []): array {}
```

---

### DOC002: @return Tags

**Severity:** `medium`

Document the return value with `@return`, giving the type on the tag line and a description on the next line. Omit `@return` only for constructors and methods declared `: void` where a description would add nothing. Never write `@return void` — the type hint already says it.

**Good Example:**
```php
<?php

/**
 * Loads the active configuration override.
 *
 * @return \Drupal\Core\Config\Config|null
 *   The configuration override, or NULL if none is active.
 */
public function getOverride(): ?Config {
  // Implementation.
}
```

**Bad Example:**
```php
<?php

/**
 * @return mixed   // ❌ No description; "mixed" hides the real shape.
 */
public function getOverride() {}

/**
 * @return void    // ❌ Redundant with the : void hint; drop the tag entirely.
 */
public function reset(): void {}
```

---

### DOC003: @throws Tags

**Severity:** `medium`

Document every exception a method can throw with `@throws`, one tag per exception class, in the order they may be thrown. Give the fully-qualified class name and a description of the condition that triggers it.

**Good Example:**
```php
<?php

/**
 * Imports configuration from a YAML file.
 *
 * @param string $path
 *   The absolute path to the YAML file.
 *
 * @throws \Drupal\Core\Config\StorageException
 *   Thrown when the file cannot be read.
 * @throws \Drupal\mymodule\Exception\InvalidConfigException
 *   Thrown when the file contains invalid configuration.
 */
public function importFromFile(string $path): void {
  // Implementation.
}
```

**Bad Example:**
```php
<?php

/**
 * Imports configuration from a YAML file.
 */                                  // ❌ Method throws two exceptions; none documented.
public function importFromFile(string $path): void {
  throw new StorageException('...');
}
```

---

### DOC004: {@inheritdoc} for Overrides

**Severity:** `medium`

When a method implements an interface or overrides a parent, use a `{@inheritdoc}` DocBlock instead of copying the parent's description. Only add extra text below `{@inheritdoc}` when the override does something the parent contract does not describe.

**Good Example:**
```php
<?php

/**
 * {@inheritdoc}
 */
public function getCacheTags(): array {
  return Cache::mergeTags(parent::getCacheTags(), ['mymodule:list']);
}

/**
 * {@inheritdoc}
 *
 * Additionally logs each access check for auditing.
 */
public function access(AccountInterface $account): AccessResultInterface {
  // Implementation.
}
```

**Bad Example:**
```php
<?php

/**
 * Gets the cache tags.        // ❌ Duplicates the interface docblock; drifts over time.
 *
 * @return string[]
 *   The cache tags.
 */
public function getCacheTags(): array {}
```

---

### DOC005: Property and Constant DocBlocks

**Severity:** `low`

Document class properties with a one-line summary and a `@var` tag. Document constants with a summary describing their meaning, not their literal value. Constructor-promoted properties are documented via the constructor's `@param` tags instead (see [PHP024](php-standards.md#php024-use-constructor-property-promotion-php-80)).

**Good Example:**
```php
<?php

/**
 * The maximum number of items processed per batch run.
 */
public const BATCH_SIZE = 50;

/**
 * The entity type manager.
 *
 * @var \Drupal\Core\Entity\EntityTypeManagerInterface
 */
protected EntityTypeManagerInterface $entityTypeManager;
```

**Bad Example:**
```php
<?php

// ❌ No docblock, no @var.
protected $entityTypeManager;

/**
 * Set to 50.        // ❌ Describes the value, not the meaning.
 */
public const BATCH_SIZE = 50;
```

---

## Hook Documentation

### DOC006: Hook Implementations

**Severity:** `medium`

Every hook implementation must be documented with exactly `Implements hook_NAME().` and nothing else — no `@param`/`@return`, since the API module links to the hook's canonical definition. For hooks that vary by type (e.g. `hook_form_FORM_ID_alter`), name the concrete hook.

**Good Example:**
```php
<?php

/**
 * Implements hook_form_FORM_ID_alter() for the user_register_form.
 */
function mymodule_form_user_register_form_alter(array &$form, FormStateInterface $form_state): void {
  // Implementation.
}

/**
 * Implements hook_entity_presave().
 */
function mymodule_entity_presave(EntityInterface $entity): void {
  // Implementation.
}
```

**Bad Example:**
```php
<?php

/**
 * Alter the registration form.    // ❌ Not the standard phrasing; breaks API linking.
 *
 * @param array $form              // ❌ Redundant params for a hook implementation.
 */
function mymodule_form_user_register_form_alter(array &$form, FormStateInterface $form_state): void {}
```

---

### DOC007: Defining New Hooks

**Severity:** `medium`

When a module defines its own hook, document it in a `.api.php` file using a sample function whose name uses the `hook_` prefix. Describe when the hook fires, what altering it achieves, and document parameters and return value fully — this is the canonical source api.drupal.org generates from.

**Good Example:**
```php
<?php

/**
 * @file
 * Hooks provided by the My Module module.
 */

/**
 * Alter the list of processable items before processing begins.
 *
 * This hook fires once per batch run, after items are loaded but before any
 * are transformed. Use it to remove items or adjust their priority.
 *
 * @param array $items
 *   The items to be processed, keyed by item ID. Modify by reference.
 * @param \Drupal\mymodule\ProcessContext $context
 *   The current processing context.
 *
 * @see \Drupal\mymodule\Processor::run()
 */
function hook_mymodule_items_alter(array &$items, ProcessContext $context): void {
  if (isset($items['legacy'])) {
    unset($items['legacy']);
  }
}
```

**Bad Example:**
```php
<?php

// ❌ New hook defined but never documented in mymodule.api.php,
// so it never appears on api.drupal.org and integrators can't discover it.
$items = \Drupal::moduleHandler()->invokeAll('mymodule_items', [$context]);
```

---

## API Documentation Conventions

### DOC008: Summary Line

**Severity:** `medium`

Begin every DocBlock with a single-sentence summary written in the imperative-descriptive third person ("Builds…", "Returns…", "Determines whether…"), ending with a period and fitting on one line (≤ 80 characters). Add a blank line, then longer explanation if needed.

**Good Example:**
```php
<?php

/**
 * Determines whether the current user may edit the given node.
 *
 * Access is granted when the user owns the node or holds the
 * 'administer nodes' permission. Anonymous users are always denied.
 */
public function mayEdit(NodeInterface $node): bool {}
```

**Bad Example:**
```php
<?php

/**
 * This function is used to check if a user can edit a node and it also handles
 * the case where the user is anonymous and returns the appropriate boolean.  // ❌ Multi-line run-on summary.
 */
public function mayEdit(NodeInterface $node): bool {}
```

---

### DOC009: Document When and Why, Not Just What

**Severity:** `medium`

Good API documentation explains the situations where a developer should reach for a function and where they should not, and how it fits into the surrounding subsystem. Describing only the mechanics ("what it does") is the most common documentation gap. Link related APIs with `@see` so readers understand the bigger picture.

**Good Example:**
```php
<?php

/**
 * Queues an entity for asynchronous re-indexing.
 *
 * Use this instead of reindexing inline whenever the change happens during a
 * request the user is waiting on — it defers the work to cron. For CLI or batch
 * contexts where blocking is acceptable, call reindexNow() directly, which is
 * faster because it skips the queue round-trip.
 *
 * @see \Drupal\mymodule\Indexer::reindexNow()
 * @see \Drupal\Core\Queue\QueueInterface
 */
public function queueReindex(EntityInterface $entity): void {}
```

**Bad Example:**
```php
<?php

/**
 * Adds the entity to the queue.   // ❌ Restates the code; no guidance on when to use it.
 */
public function queueReindex(EntityInterface $entity): void {}
```

---

### DOC010: Cross-References with @see, @deprecated, @todo

**Severity:** `low`

Use `@see` to link related functions, classes, URLs, or issues. Use `@deprecated in ... is removed from ...` with a matching `@see` to the replacement and a change-record URL. Use `@todo` (not `TODO:` in comments) for tracked follow-ups, ideally with an issue link. See also inline `@todo` usage in [PHP015](php-standards.md#php015-inline-comments).

**Good Example:**
```php
<?php

/**
 * Returns the legacy processor.
 *
 * @deprecated in mymodule:2.0.0 and is removed from mymodule:3.0.0. Use
 *   \Drupal\mymodule\Processor instead.
 *
 * @see https://www.drupal.org/node/1234567
 * @see \Drupal\mymodule\Processor
 *
 * @todo Remove the compatibility shim once all consumers migrate.
 *   https://www.drupal.org/project/mymodule/issues/7654321
 */
public function getLegacyProcessor(): LegacyProcessor {}
```

**Bad Example:**
```php
<?php

/**
 * @deprecated Don't use this anymore.   // ❌ No version info, no replacement, no @see.
 */
public function getLegacyProcessor(): LegacyProcessor {}
```

---

## Module Help

### DOC011: hook_help() Implementation

**Severity:** `medium`

Provide `hook_help()` for the module's help route so administrators see purpose and usage on the module page and at `admin/help`. Match on the `help.page.MODULE` route, return translatable, sanitized markup, and keep it concise — link out for detail rather than embedding a full manual.

**Good Example:**
```php
<?php

use Drupal\Core\Routing\RouteMatchInterface;

/**
 * Implements hook_help().
 */
function mymodule_help(string $route_name, RouteMatchInterface $route_match): string {
  switch ($route_name) {
    case 'help.page.mymodule':
      $output = '';
      $output .= '<h3>' . t('About') . '</h3>';
      $output .= '<p>' . t('My Module queues content for asynchronous re-indexing to keep search results fresh without slowing down editors.') . '</p>';
      $output .= '<h3>' . t('Uses') . '</h3>';
      $output .= '<dl>';
      $output .= '<dt>' . t('Configuring the queue') . '</dt>';
      $output .= '<dd>' . t('Set the batch size on the <a href=":settings">settings page</a>.', [':settings' => Url::fromRoute('mymodule.settings')->toString()]) . '</dd>';
      $output .= '</dl>';
      return $output;
  }
  return '';
}
```

**Bad Example:**
```php
<?php

function mymodule_help($route_name, $route_match) {
  // ❌ Untranslated, unsanitized, and returns help for every route.
  return "This module does indexing. Edit config at admin/config/mymodule.";
}
```

---

## README Structure

### DOC012: README File Structure

**Severity:** `medium`

Every contrib and custom module should ship a `README.md` following the drupal.org README template: Introduction, Requirements, Installation, Configuration, Maintainers. Document Drupal-specific setup only; link to upstream docs for anything not Drupal-specific.

**Good Example:**
```markdown
# My Module

## Introduction

My Module queues content for asynchronous re-indexing so editors are not blocked
while search indexes rebuild.

## Requirements

This module requires the following:

- Drupal core Search API (`search_api`)

## Installation

Install as you would normally install a contributed Drupal module. See
[Installing modules](https://www.drupal.org/docs/extending-drupal/installing-modules)
for further information.

## Configuration

1. Enable the module at **Administration > Extend**.
2. Configure the batch size at **Administration > Configuration > My Module**.
3. Grant the *administer my module* permission to the relevant roles.

## Maintainers

- Jane Doe - [janedoe](https://www.drupal.org/u/janedoe)
```

**Bad Example:**
```markdown
# my_module

Some helpful module.

## How to install Composer

First download Composer from getcomposer.org, then run...
<!-- ❌ No standard sections; documents Composer (not Drupal-specific) instead of the module. -->
```

---

## Handbook & Markdown Documentation

### DOC013: Document Drupal; Link to Everything Else

**Severity:** `medium`

Drupal documentation should document Drupal and link out for third-party tools. Do not embed lengthy instructions for Docker, Apache, PHP installation, etc. — they go stale and are better maintained upstream. Keep the Drupal-specific steps; link the rest.

**Good Example:**
```markdown
## Local development

We recommend [DDEV](https://ddev.readthedocs.io/) for local environments.
Follow DDEV's installation guide, then from the project root:

    ddev start
    ddev composer install
    ddev drush site:install

See the [DDEV docs](https://ddev.readthedocs.io/) for platform-specific setup.
```

**Bad Example:**
```markdown
## Local development

### Installing Docker on macOS

1. Download Docker Desktop from docker.com...
2. Open the .dmg and drag Docker to Applications...
<!-- ❌ Re-documents Docker; will be wrong within a release or two. -->
```

---

### DOC014: Be Opinionated and Lead with the Quick Path

**Severity:** `low`

Give readers one recommended path they can follow with confidence. If multiple valid approaches exist, name the preferred one first, then list alternatives with links rather than full parallel documentation. Put the short path to success (a TL;DR / quick-start block) first; deeper explanation follows for those who want it.

**Good Example:**
```markdown
## Quick start

    ddev start && ddev drush site:install --yes

That gets most people to a working site. Prefer another tool? Lando and
DigitalOcean also work — see [Alternative environments](#alternatives).

## What those commands do

`ddev start` provisions the containers; `drush site:install` ...
```

**Bad Example:**
```markdown
## Setup

You can use DDEV, or Lando, or Docksal, or a native LAMP stack, or MAMP, or
XAMPP, or Vagrant. Here is how to configure all seven in full detail...
<!-- ❌ Exhaustive and unopinionated; no clear path for a beginner. -->
```

---

### DOC015: Keep Pages Short, Scannable, and Correctly Termed

**Severity:** `low`

Most readers arrive with a specific question and scan. Use the minimum words needed, clear headings, and prefer several short pages over one long page. Use Drupal terminology precisely (*entity*, *node*, *bundle*, *field*, *region*, *block*), always capitalise *Drupal*, and write *JavaScript* as one word with a capital J and S, per the Drupal Content Style Guide.

**Good Example:**
```markdown
## Adding a field to a content type

1. Go to **Structure > Content types** and edit the bundle.
2. On the **Manage fields** tab, add the field.
3. Configure the field and save.

Fields added here apply to every node of that content type.
```

**Bad Example:**
```markdown
## Fields

In drupal you can add things called fields to your content. Javascript is
sometimes used. This page will exhaustively explain the entire history of the
Field API across many paragraphs before telling you how to add one...
<!-- ❌ Lowercase "drupal", wrong "Javascript", buried instructions, wall of text. -->
```

---

## See Also

- [PHP Coding Standards — Documentation section](php-standards.md#documentation) (PHP013–PHP015)
- [Drupal API documentation and comment standards](https://www.drupal.org/docs/develop/standards/php/api-documentation-and-comment-standards)
- [Drupal Content Style Guide](https://www.drupal.org/drupalorg/style-guide)
- [README.md template for contrib modules](https://www.drupal.org/docs/develop/managing-a-drupalorg-theme-module-or-distribution/documenting-your-project/readme-template)
- [Documentation Working Group overview](https://www.drupal.org/docs/working-group/documentation-working-group-overview)
