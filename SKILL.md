---
name: drupal-standards
metadata:
  author: Joshua Fernandes
  drupal_org: https://www.drupal.org/u/joshua1234511
  github: https://github.com/joshua1234511
  linkedin: https://www.linkedin.com/in/joshua1234511
  website: https://fernandesjoshua.com
  location: Cuncolim, Salcette, Goa, India
description: Comprehensive Drupal coding standards with on-demand loading for back-end (PHP, security, database, services, testing) and front-end (JavaScript, Twig, CSS, accessibility) development. Supports Drupal 10/11 with 280+ validated standards.
---

# Drupal Standards v3.1

Comprehensive standards for Drupal development with **on-demand loading** to optimize context usage.

> **Maintained by [Joshua Fernandes](https://fernandesjoshua.com)**  
> 🌐 [drupal.org/u/joshua1234511](https://www.drupal.org/u/joshua1234511) · 🐙 [github.com/joshua1234511](https://github.com/joshua1234511) · 💼 [linkedin.com/in/joshua1234511](https://www.linkedin.com/in/joshua1234511)  
> 📍 Goa, India

## Key Backend Development Principles

These are the **non-negotiable fundamentals** every Drupal developer must follow. Apply these regardless of which reference files are loaded.

| Principle | Summary | Deep Reference |
|-----------|---------|----------------|
| **Coding Standards** | Follow Drupal community PHP standards, API docs standards, and SQL best practices. Use `phpcs --standard=Drupal,DrupalPractice`. | `references/backend/php-standards.md` |
| **OOP** | Modern Drupal is OOP-first. Use classes, interfaces, traits, and leverage Symfony components (HttpKernel, DI Container). Avoid procedural code except in `.module` files where hooks are unavoidable. | `references/backend/php-standards.md` |
| **Dependency Injection** | Always inject services via the container. Never use `\Drupal::service()` inside a class that can accept constructor injection. | `references/backend/services.md` |
| **Events over Hooks** | Prefer Symfony Event Subscribers over legacy hooks for all new functionality. Hooks remain valid for alter hooks and API compatibility, but Events are the modern pattern. | `references/backend/services.md` (§ Events and Subscribers) |
| **API Usage** | Use Drupal's Entity API, Form API, Config API, and Queue API rather than raw SQL or custom solutions. Maintain compatibility by coding to interfaces. | `references/backend/forms-api.md`, `references/backend/api.md` |
| **Security** | Sanitize all user input. Use the Database API's parameterized queries (never string concatenation). Always check permissions. Follow Drupal's security advisories. | `references/backend/security.md` |
| **Testing** | Write PHPUnit tests (Unit, Kernel, Functional). SimpleTest has been removed from core — do not use it. Aim for meaningful coverage of services, controllers, and plugins. | `references/backend/testing.md` |
| **Documentation** | Every class, method, and hook must have a complete DocBlock. Include `@param`, `@return`, `@throws`. Module README must cover installation, configuration, and API references. | `references/backend/php-standards.md` (§ Documentation) |
| **Drupal AI** | Use the `ai.provider` service (drupal/ai) for all LLM/AI integrations. Never call vendor SDKs (Anthropic, OpenAI) directly. Inject `ai.provider`, tag all calls, sanitize against prompt injection, gate behind permissions, and mock providers in tests. | `references/backend/drupal-ai.md` |

> 💡 **Quick rule**: If you're writing a new class → DI + Events. If you're writing SQL → use the Database API. If you're writing a service with business logic → write a Unit test for it. If you're integrating AI/LLM → use `ai.provider`, never vendor SDKs directly.

---

## On-Demand Loading Strategy

**IMPORTANT:** Load only the standards relevant to the current task. Do NOT load all files at once.

### Task Detection

| Task Type | Load These Files |
|-----------|------------------|
| PHP module development | `references/backend/php-standards.md` |
| Security review/hardening | `references/backend/security.md` |
| Database operations | `references/backend/database.md` |
| Form development | `references/backend/forms-api.md` |
| Service/DI patterns (overview) | `references/backend/services.md` |
| DI — services.yml definition | `references/backend/di/services-definition.md` |
| DI — forms & controllers | `references/backend/di/dependency-injection-forms.md` |
| DI — blocks & plugins | `references/backend/di/dependency-injection-plugins.md` |
| DI — service tags & collectors | `references/backend/di/service-tags.md` |
| DI — altering & decorating | `references/backend/di/altering-services.md` |
| DI — best practices | `references/backend/di/best-practices.md` |
| Unit/Kernel testing | `references/backend/testing.md` |
| API development | `references/backend/api.md` |
| Hooks & Events | `references/backend/hooks.md`, `references/backend/services.md` |
| Drupal AI / LLM integration | `references/backend/drupal-ai.md` |
| AI chatbot / embeddings / tools | `references/backend/drupal-ai.md` |
| AI provider development (custom) | `references/backend/drupal-ai.md` (§ Writing a Custom AI Provider) |
| Anthropic / Claude integration | `references/backend/drupal-ai.md` (§ Anthropic Provider) |
| JavaScript / Drupal behaviors | `references/frontend/javascript.md`, `references/frontend/javascript-extended.md` |
| CSS formatting & syntax | `references/frontend/css-formatting.md` |
| CSS architecture / BEM / SMACSS | `references/frontend/css-architecture.md` |
| CSS units / rem / spacing | `references/frontend/css-units.md` |
| CSS RTL / i18n support | `references/frontend/css-rtl.md` |
| CSS comments / Doxygen | `references/frontend/css-comments.md` |
| Twig templates | `references/frontend/twig.md`, `references/frontend/twig-extended.md` |
| Accessibility | `references/frontend/accessibility.md` |
| Build/deployment | `references/devops.md` |

### Quick Reference Loading

```
# For back-end PHP work:
→ Load: backend/php-standards.md, backend/security.md

# For Dependency Injection (pick the most relevant):
→ Overview:          backend/services.md
→ Services YAML:     backend/di/services-definition.md
→ Forms/Controllers: backend/di/dependency-injection-forms.md
→ Blocks/Plugins:    backend/di/dependency-injection-plugins.md
→ Service tags:      backend/di/service-tags.md
→ Alter/Decorate:    backend/di/altering-services.md
→ Best practices:    backend/di/best-practices.md

# For new features (Events preferred over Hooks):
→ Load: backend/services.md (covers DI + Event Subscribers)

# For hook-based work (legacy or alter hooks):
→ Load: backend/hooks.md

# For Drupal AI / LLM integration:
→ Load: backend/drupal-ai.md
→ Also load: backend/security.md (AI-specific prompt injection risks apply)

# For CSS work (pick what's needed):
→ Formatting:    frontend/css-formatting.md
→ Architecture:  frontend/css-architecture.md
→ Units/spacing: frontend/css-units.md
→ RTL support:   frontend/css-rtl.md
→ Comments:      frontend/css-comments.md

# For JavaScript:
→ Load: frontend/javascript.md + frontend/javascript-extended.md

# For Twig templates:
→ Load: frontend/twig.md + frontend/twig-extended.md

# For full theming review:
→ Load: frontend/css-architecture.md, frontend/css-formatting.md,
        frontend/twig.md, frontend/twig-extended.md, frontend/accessibility.md

# For full-stack feature:
→ Load: backend/php-standards.md, backend/forms-api.md, frontend/javascript.md
```

## File Extensions Reference

| Extension | Type | Primary Standards |
|-----------|------|-------------------|
| `.module` | Module hooks | backend/php-standards.md |
| `.inc` | Include files | backend/php-standards.md |
| `.php` | Classes/Services | backend/php-standards.md, backend/services.md |
| `.install` | Install/update | backend/database.md |
| `.theme` | Theme functions | frontend/twig.md |
| `.html.twig` | Templates | frontend/twig.md, frontend/accessibility.md |
| `.js` | JavaScript | frontend/javascript.md |
| `.css` | Stylesheets | frontend/css.md |
| `.yml` | Configuration | backend/services.md |

## Critical Security Quick Reference

Always verify these before committing:

```php
// ✅ ALWAYS: Use parameterized queries
$query = $this->database->select('users', 'u')
  ->fields('u', ['uid', 'name'])
  ->condition('status', 1);

// ✅ ALWAYS: Escape output  
use Drupal\Component\Utility\Html;
$safe = Html::escape($userInput);

// ✅ ALWAYS: Use Form API (includes CSRF)
public function buildForm(array $form, FormStateInterface $form_state) {
  $form['#token'] = TRUE; // Default, but explicit is good
}

// ✅ ALWAYS: Check permissions
if (!$this->currentUser->hasPermission('administer content')) {
  throw new AccessDeniedHttpException();
}

// ❌ NEVER: Concatenate user input
db_query("SELECT * FROM users WHERE name = '" . $_GET['name'] . "'");

// ❌ NEVER: Use |raw without sanitization
{{ user_input|raw }}

// ❌ NEVER: Bypass access checks
$node = Node::load($nid); // Missing access check!
```

## Validation Tools

### Run Comprehensive Validation
```bash
# Validate single file
python3 .cursor/skills/drupal-backend-standards/scripts/drupal_validator.py mymodule.module

# Validate directory
python3 .cursor/skills/drupal-backend-standards/scripts/drupal_validator.py /path/to/module --recursive

# Validate with specific category
python3 .cursor/skills/drupal-backend-standards/scripts/drupal_validator.py mymodule.module --category security
```

### Run Linting Tools
```bash
# Run all tools (phpcs, phpmd, phpstan)
bash .cursor/skills/drupal-backend-standards/scripts/drupal_lint.sh /path/to/code

# Run with auto-fix
bash .cursor/skills/drupal-backend-standards/scripts/drupal_lint.sh -p -f /path/to/code

# Setup development environment
bash .cursor/skills/drupal-backend-standards/scripts/setup_drupal_dev.sh
```

## Standards Categories Overview

### Back-End Standards (Load: `references/backend/`)

| File | Standards | Status | Coverage |
|------|-----------|--------|----------|
| `php-standards.md` | 24 | ✅ Exists | PSR-4, coding style, type hints, OOP, documentation |
| `security.md` | 19 | ✅ Exists | Input validation, SQL injection, XSS, CSRF, access control |
| `services.md` | 11 | ✅ Exists | DI overview, service definitions, plugins, events |
| `testing.md` | 9 | ✅ Exists | PHPUnit, Kernel tests, Functional tests, Behat |
| `database.md` | 7 | ✅ Exists | Database API, parameterized queries, Schema API, migrations |
| `forms-api.md` | 8 | ✅ Exists | Form building, validation, AJAX, States API, CSRF |
| `api.md` | 7 | ✅ Exists | Entity API, REST resources, JSON:API, auth, error handling |
| `hooks.md` | 7 | ✅ Exists | Hook implementation, alter hooks, Events over Hooks |
| `drupal-ai.md` | 18 | ✅ Exists | AI module, operation types, Anthropic/Claude, prompt security |
| `di/services-definition.md` | 19 | ✅ **Integrated** | Full services.yml syntax, naming, factories, aliases |
| `di/dependency-injection-forms.md` | 10 | ✅ **Integrated** | DI in forms, controllers, AutowireTrait (Drupal 10.2+) |
| `di/dependency-injection-plugins.md` | 17 | ✅ **Integrated** | DI in blocks, plugins, ContainerFactoryPluginInterface |
| `di/service-tags.md` | 17 | ✅ **Integrated** | Service tags, collectors, event_subscriber, cache tags |
| `di/altering-services.md` | 18 | ✅ **Integrated** | ServiceProviderInterface, decoration, altering |
| `di/best-practices.md` | 34 | ✅ **Integrated** | Anti-patterns, autowiring, performance, testing |

### Front-End Standards (Load: `references/frontend/`)

| File | Standards | Status | Coverage |
|------|-----------|--------|----------|
| `javascript.md` | 13 | ✅ Exists | Drupal behaviors, ES6+, jQuery, AJAX |
| `javascript-extended.md` | 22 | ✅ **Integrated** | once(), Drupal.t(), strict mode, full behavior patterns |
| `accessibility.md` | 16 | ✅ Exists | WCAG 2.2, ARIA, keyboard navigation, semantic HTML |
| `twig.md` | 14 | ✅ Exists | Template syntax, filters, security, preprocess hooks |
| `twig-extended.md` | 30 | ✅ **Integrated** | Attributes object, BEM in Twig, escaping, patterns |
| `css-formatting.md` | 21 | ✅ **Integrated** | Indentation, selectors, quotes, semicolons, vendor prefixes |
| `css-architecture.md` | 9 | ✅ **Integrated** | SMACSS, BEM naming, .is- states, .js- hooks |
| `css-units.md` | 8 | ✅ **Integrated** | rem over px, zero units, responsive values |
| `css-rtl.md` | 17 | ✅ **Integrated** | RTL/LTR support, logical properties, i18n |
| `css-comments.md` | 29 | ✅ **Integrated** | Doxygen-style file headers, section documentation |

### DevOps Standards (Load: `references/devops.md`)

| Coverage | Standards | Status |
|----------|-----------|--------|
| GitHub Actions | 4 | ✅ Exists |
| Build optimization | 2 | ✅ Exists |
| Configuration management | 2 | ✅ Exists |
| Deployment | 2 | ✅ Exists |

**Total: 370+ validated standards across 25 reference files** ✅

## Common Patterns Quick Reference

### Service with Dependency Injection

```php
// mymodule.services.yml
services:
  mymodule.data_processor:
    class: Drupal\mymodule\Service\DataProcessor
    arguments:
      - '@database'
      - '@entity_type.manager'
      - '@logger.factory'
      - '@cache.default'

// src/Service/DataProcessor.php
namespace Drupal\mymodule\Service;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Database\Connection;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelFactoryInterface;

class DataProcessor {

  public function __construct(
    protected Connection $database,
    protected EntityTypeManagerInterface $entityTypeManager,
    protected LoggerChannelFactoryInterface $loggerFactory,
    protected CacheBackendInterface $cache,
  ) {}

  public function process(array $data): array {
    $cid = 'mymodule:data:' . hash('sha256', serialize($data));
    
    if ($cached = $this->cache->get($cid)) {
      return $cached->data;
    }
    
    try {
      $result = $this->doProcessing($data);
      $this->cache->set($cid, $result, CacheBackendInterface::CACHE_PERMANENT, ['mymodule:data']);
      return $result;
    }
    catch (\Exception $e) {
      $this->loggerFactory->get('mymodule')->error('Processing failed: @message', [
        '@message' => $e->getMessage(),
      ]);
      throw $e;
    }
  }
}
```

### Form with AJAX

```php
namespace Drupal\mymodule\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\Ajax\AjaxResponse;
use Drupal\Core\Ajax\ReplaceCommand;

class MyAjaxForm extends FormBase {

  public function getFormId(): string {
    return 'mymodule_ajax_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $form['category'] = [
      '#type' => 'select',
      '#title' => $this->t('Category'),
      '#options' => $this->getCategories(),
      '#ajax' => [
        'callback' => '::updateSubcategories',
        'wrapper' => 'subcategory-wrapper',
        'event' => 'change',
      ],
    ];

    $form['subcategory_wrapper'] = [
      '#type' => 'container',
      '#attributes' => ['id' => 'subcategory-wrapper'],
    ];

    $category = $form_state->getValue('category');
    if ($category) {
      $form['subcategory_wrapper']['subcategory'] = [
        '#type' => 'select',
        '#title' => $this->t('Subcategory'),
        '#options' => $this->getSubcategories($category),
      ];
    }

    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Submit'),
    ];

    return $form;
  }

  public function updateSubcategories(array &$form, FormStateInterface $form_state): array {
    return $form['subcategory_wrapper'];
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->messenger()->addStatus($this->t('Form submitted successfully.'));
  }
}
```

### Twig Template with Accessibility

```twig
{#
/**
 * @file
 * Theme override for article teasers.
 *
 * Available variables:
 * - node: The node entity
 * - label: The node title
 * - content: All node items
 * - url: The canonical URL
 */
#}
<article{{ attributes.addClass('article-teaser') }} role="article" aria-labelledby="title-{{ node.id }}">
  
  {{ title_prefix }}
  <h2{{ title_attributes.setAttribute('id', 'title-' ~ node.id) }}>
    <a href="{{ url }}" rel="bookmark">{{ label }}</a>
  </h2>
  {{ title_suffix }}

  {% if display_submitted %}
    <footer class="article-meta">
      <span class="visually-hidden">{{ 'Posted by'|t }}</span>
      {{ author_name }}
      <span class="visually-hidden">{{ 'on'|t }}</span>
      <time datetime="{{ node.createdtime|date('c') }}">{{ date }}</time>
    </footer>
  {% endif %}

  <div{{ content_attributes.addClass('article-content') }}>
    {{ content|without('field_tags', 'links') }}
  </div>

  {% if content.field_tags|render|trim %}
    <nav aria-label="{{ 'Article tags'|t }}" class="article-tags">
      {{ content.field_tags }}
    </nav>
  {% endif %}

</article>
```

## Pre-Commit Checklist

Before committing, verify:

### Security
- [ ] All user input is sanitized (`Html::escape()`, `Xss::filter()`)
- [ ] Database queries use placeholders or Query API
- [ ] Forms have CSRF protection (automatic with Form API)
- [ ] File uploads are validated (extensions, MIME types)
- [ ] Access checks are in place for all operations

### Code Quality
- [ ] Code passes `phpcs --standard=Drupal,DrupalPractice`
- [ ] No errors from `phpmd` or `phpstan`
- [ ] Type declarations on all parameters and returns
- [ ] DocBlocks are complete and accurate

### Performance
- [ ] Render arrays include cache metadata (`#cache`)
- [ ] Expensive operations use caching
- [ ] Database queries are optimized

### Testing
- [ ] Unit tests written for new services (PHPUnit — SimpleTest removed from core, do NOT use)
- [ ] Kernel tests for database operations
- [ ] Functional tests for user interactions

### Drupal AI
- [ ] AI calls go through `ai.provider` service — no direct vendor SDK calls
- [ ] All AI calls tagged with module name (third parameter)
- [ ] User input sanitized before inclusion in prompts (prompt injection prevention)
- [ ] AI features gated behind Drupal permissions
- [ ] AI provider mocked in automated tests (no real API calls in tests)
- [ ] API keys stored only in provider config — never hardcoded

### Accessibility
- [ ] All images have meaningful alt text
- [ ] Form inputs have labels
- [ ] Interactive elements are keyboard accessible
- [ ] Color contrast meets WCAG AA

### Drupal AI Integration
- [ ] `ai.provider` injected via DI — no `\Drupal::service()` inside classes
- [ ] Using `getDefaultProviderForOperationType()` — no hardcoded provider IDs (for public modules)
- [ ] All AI calls tagged with module name (third parameter)
- [ ] User input sanitized before inclusion in prompts (prompt injection prevention)
- [ ] No sensitive data (PII, keys, passwords) sent to AI providers
- [ ] AI providers mocked in all unit/kernel tests — no live API calls
- [ ] `ai_logging` enabled in production environment

## Drush Commands Reference

```bash
# Development
drush cr                          # Clear all caches
drush watchdog:show               # View recent logs
drush php:eval "code"             # Execute PHP

# Configuration
drush config:export               # Export config to files
drush config:import               # Import config from files
drush config:get system.site      # Get config value

# Code generation
drush generate module             # Generate module scaffold
drush generate controller         # Generate controller
drush generate form               # Generate form class
drush generate service            # Generate service

# Database
drush sql:query "SELECT..."       # Run SQL query
drush sql:dump > backup.sql       # Export database
drush sql:cli                     # Open SQL CLI

# Maintenance
drush cron                        # Run cron
drush updb                        # Run database updates
drush locale:update               # Update translations
```
