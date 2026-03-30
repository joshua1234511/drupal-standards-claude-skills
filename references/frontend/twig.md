# Twig Template Standards

Twig templating standards for Drupal theming, covering syntax, security, performance, and best practices.

## Table of Contents

1. [Template Structure](#template-structure)
2. [Security](#security)
3. [Variables and Filters](#variables-and-filters)
4. [Template Suggestions](#template-suggestions)
5. [Performance](#performance)
6. [Accessibility in Templates](#accessibility-in-templates)
7. [Debugging](#debugging)

---

## Template Structure

### TWIG001: Use Proper Template Documentation

**Severity:** `medium`

Every template should have a documentation block describing available variables.

**Good Example:**
```twig
{#
/**
 * @file
 * Theme override for displaying a node.
 *
 * Available variables:
 * - node: The node entity with limited access to object methods.
 * - label: (optional) The title of the node.
 * - content: All node items. Use {{ content }} to print them all,
 *   or print a subset such as {{ content.field_example }}. Use
 *   {{ content|without('field_example') }} to exclude fields.
 * - author_picture: The node author's user picture.
 * - metadata: Metadata for this node.
 * - date: (optional) Themed creation date field.
 * - author_name: (optional) Themed author name field.
 * - url: Direct URL of the current node.
 * - display_submitted: Whether submission information should be displayed.
 * - attributes: HTML attributes for the containing element.
 * - title_attributes: HTML attributes for the title.
 * - content_attributes: HTML attributes for the content.
 * - title_prefix: Additional content for the title area.
 * - title_suffix: Additional content for the title area.
 * - view_mode: View mode (e.g., 'full', 'teaser').
 * - teaser: Flag for the teaser view mode.
 * - page: Flag for the full page view mode.
 * - logged_in: Flag for authenticated status.
 * - is_admin: Flag for admin user status.
 *
 * @see template_preprocess_node()
 * @see mymodule_preprocess_node()
 */
#}

{% set classes = [
  'node',
  'node--type-' ~ node.bundle|clean_class,
  node.isPromoted() ? 'node--promoted',
  node.isSticky() ? 'node--sticky',
  not node.isPublished() ? 'node--unpublished',
  view_mode ? 'node--view-mode-' ~ view_mode|clean_class,
] %}

<article{{ attributes.addClass(classes) }}>
  {{ title_prefix }}
  {% if label and not page %}
    <h2{{ title_attributes }}>
      <a href="{{ url }}" rel="bookmark">{{ label }}</a>
    </h2>
  {% endif %}
  {{ title_suffix }}

  {% if display_submitted %}
    <footer class="node__meta">
      {{ author_picture }}
      <div{{ author_attributes.addClass('node__submitted') }}>
        {% trans %}
          Submitted by {{ author_name }} on {{ date }}
        {% endtrans %}
        {{ metadata }}
      </div>
    </footer>
  {% endif %}

  <div{{ content_attributes.addClass('node__content') }}>
    {{ content }}
  </div>
</article>
```

---

### TWIG002: Use Attributes Object Properly

**Severity:** `high`

Use Drupal's Attribute object for HTML attributes to ensure proper escaping and flexibility.

**Good Example:**
```twig
{# Adding classes with addClass() #}
<div{{ attributes.addClass('my-class', 'another-class') }}>

{# Conditional classes #}
{% set classes = [
  'card',
  is_featured ? 'card--featured',
  has_image ? 'card--with-image' : 'card--no-image',
] %}
<article{{ attributes.addClass(classes) }}>

{# Adding other attributes #}
<div{{ attributes.setAttribute('data-id', node.id) }}>

{# Multiple attribute modifications #}
{% set link_attributes = create_attribute() %}
{% set link_attributes = link_attributes
  .addClass('link')
  .setAttribute('target', '_blank')
  .setAttribute('rel', 'noopener noreferrer')
%}
<a{{ link_attributes }} href="{{ url }}">{{ text }}</a>

{# Removing attributes #}
<div{{ attributes.removeAttribute('id').removeClass('unwanted-class') }}>

{# Checking for attribute existence #}
{% if attributes.hasClass('special') %}
  <span class="icon"></span>
{% endif %}

{# Preserving existing attributes while adding more #}
<input{{ attributes.addClass('form-control') }}>
```

**Bad Example:**
```twig
{# ❌ String concatenation for classes #}
<div class="card {{ is_featured ? 'card--featured' : '' }}">

{# ❌ Losing original attributes #}
<div class="my-class">  {# Overwrites attributes variable! #}

{# ❌ Building attributes manually #}
<div class="{{ classes|join(' ') }}" id="{{ id }}">
```

---

### TWIG003: Template Naming Conventions

**Severity:** `medium`

Follow Drupal's template naming conventions for proper template suggestions.

**Good Example:**
```
templates/
├── node/
│   ├── node.html.twig                    # Base node template
│   ├── node--article.html.twig           # Article content type
│   ├── node--article--teaser.html.twig   # Article teaser view mode
│   ├── node--article--full.html.twig     # Article full view mode
│   └── node--123.html.twig               # Specific node ID
├── field/
│   ├── field.html.twig                   # Base field template
│   ├── field--body.html.twig             # Body field
│   ├── field--node--field-image.html.twig # Image field on nodes
│   └── field--node--field-image--article.html.twig # Image on articles
├── block/
│   ├── block.html.twig
│   └── block--system-branding-block.html.twig
├── views/
│   ├── views-view.html.twig
│   ├── views-view--news.html.twig        # Specific view
│   └── views-view-unformatted--news--block_1.html.twig
├── form/
│   ├── form-element.html.twig
│   └── input--textfield.html.twig
└── layout/
    ├── page.html.twig
    ├── page--front.html.twig
    └── page--node--article.html.twig
```

---

## Security

### TWIG004: Never Use raw Filter with User Input

**Severity:** `critical`

Twig auto-escapes output. Never bypass this with `|raw` unless content is pre-sanitized.

**Good Example:**
```twig
{# Auto-escaped - safe #}
{{ user_input }}
{{ title }}
{{ node.label }}

{# Rendering Drupal render arrays - already sanitized #}
{{ content.field_body }}
{{ content|without('field_tags') }}

{# Using Drupal's built-in safe markup #}
{{ message|raw }}  {# Only if message is a \Drupal\Core\Render\Markup object #}

{# Safe because value is from trusted source #}
{{ icon_svg|raw }}  {# SVG loaded from theme files, not user input #}

{# Escaping for specific contexts #}
<div class="{{ class_name|e('html_attr') }}">
<a href="{{ url|e('url') }}">
<script>var data = {{ json_data|json_encode|raw }};</script>
```

**Bad Example:**
```twig
{# ❌ CRITICAL: User input with raw #}
{{ user_comment|raw }}
{{ form_value|raw }}

{# ❌ CRITICAL: Concatenated HTML with user input #}
{% set html = '<div>' ~ user_input ~ '</div>' %}
{{ html|raw }}

{# ❌ Assuming database content is safe #}
{{ node.body.value|raw }}  {# Could contain XSS if not filtered #}
```

---

### TWIG005: Escape URLs Properly

**Severity:** `high`

Use proper URL escaping and validation.

**Good Example:**
```twig
{# Using Drupal's URL objects (already safe) #}
<a href="{{ url }}">Link</a>
<a href="{{ path('entity.node.canonical', {'node': node.id}) }}">View</a>

{# External URLs - escape for URL context #}
<a href="{{ external_url|e('url') }}">External Link</a>

{# Building URLs safely #}
{% set query = {'search': search_term, 'page': current_page} %}
<a href="{{ path('view.search.page', query) }}">Search Results</a>

{# Image sources #}
<img src="{{ file_url(image_uri) }}" alt="{{ image_alt }}">

{# Background images in style attribute #}
<div style="background-image: url('{{ image_url|e('css') }}');">
```

**Bad Example:**
```twig
{# ❌ Unescaped user-provided URL #}
<a href="{{ user_url }}">Link</a>

{# ❌ Building URLs with string concatenation #}
<a href="/search?q={{ search_term }}">Search</a>  {# Missing escaping #}

{# ❌ JavaScript URLs #}
<a href="javascript:{{ user_code }}">Click</a>  {# XSS vulnerability #}
```

---

### TWIG006: Safe Translation with Placeholders

**Severity:** `high`

Use proper placeholders in translations to ensure escaping.

**Good Example:**
```twig
{# Using @ placeholder (escaped) for user content #}
{{ 'Hello @name'|t({'@name': user.displayname}) }}

{# Using % placeholder (escaped + emphasized) #}
{{ 'The file %filename has been uploaded.'|t({'%filename': filename}) }}

{# Using :placeholder for URLs (escaped for href) #}
{{ 'Visit our <a href=":url">website</a>.'|t({':url': website_url}) }}

{# Plural translations #}
{% trans %}
  1 item
{% plural count %}
  {{ count }} items
{% endtrans %}

{# Complex translations with context #}
{% trans with {'context': 'Navigation'} %}
  Home
{% endtrans %}

{# Translations in attributes #}
<button aria-label="{{ 'Close dialog'|t }}">×</button>
```

**Bad Example:**
```twig
{# ❌ String concatenation in translations #}
{{ ('Hello ' ~ user_name)|t }}

{# ❌ Using ! placeholder (unescaped - deprecated) #}
{{ 'Welcome !name'|t({'!name': user_input}) }}

{# ❌ Missing translation wrapper #}
<button>Submit</button>  {# Should be {{ 'Submit'|t }} #}
```

---

## Variables and Filters

### TWIG007: Use Appropriate Filters

**Severity:** `medium`

Use the correct Twig filter for each situation.

**Good Example:**
```twig
{# String manipulation #}
{{ title|upper }}
{{ description|lower }}
{{ text|capitalize }}
{{ long_text|truncate(100, true, '...') }}
{{ name|title }}

{# Clean class names #}
<div class="node--type-{{ node.bundle|clean_class }}">
<div id="section-{{ section_id|clean_id }}">

{# Date formatting #}
{{ node.created.value|date('F j, Y') }}
{{ node.created.value|format_date('medium') }}
<time datetime="{{ node.created.value|date('c') }}">
  {{ node.created.value|format_date('long') }}
</time>

{# Number formatting #}
{{ price|number_format(2, '.', ',') }}
{{ percentage|round(1) }}%

{# Array operations #}
{{ items|join(', ') }}
{{ items|first }}
{{ items|last }}
{{ items|length }}

{# Rendering #}
{{ content.field_body|render }}
{% if content.field_image|render|trim %}
  {{ content.field_image }}
{% endif %}

{# Safe string operations #}
{{ text|striptags }}
{{ html|striptags('<p><a>') }}  {# Allow specific tags #}

{# Default values #}
{{ variable|default('fallback') }}
{{ user.name|default('Anonymous') }}

{# Without filter for excluding fields #}
{{ content|without('field_tags', 'links', 'field_image') }}
```

---

### TWIG008: Check Variables Before Use

**Severity:** `medium`

Always verify variables exist before accessing their properties.

**Good Example:**
```twig
{# Check if variable exists and is not empty #}
{% if title %}
  <h1>{{ title }}</h1>
{% endif %}

{# Check for rendered content #}
{% if content.field_image|render|trim %}
  <div class="image-wrapper">
    {{ content.field_image }}
  </div>
{% endif %}

{# Check array/object properties #}
{% if node.field_category is not empty %}
  <span>{{ node.field_category.entity.label }}</span>
{% endif %}

{# Use default filter for fallbacks #}
<img src="{{ image_url|default('/themes/custom/mytheme/images/placeholder.png') }}" 
     alt="{{ image_alt|default('') }}">

{# Check for specific values #}
{% if view_mode == 'full' %}
  {{ content }}
{% elseif view_mode == 'teaser' %}
  {{ content.field_summary }}
{% endif %}

{# Null-safe access with default #}
{{ node.field_author.entity.name.value|default('Unknown Author') }}

{# Check boolean/truthy values #}
{% if is_front %}
  <div class="front-page-banner">...</div>
{% endif %}

{# Multiple conditions #}
{% if logged_in and user.hasPermission('access content') %}
  <a href="{{ edit_url }}">Edit</a>
{% endif %}
```

**Bad Example:**
```twig
{# ❌ Accessing potentially null properties #}
{{ node.field_author.entity.name.value }}

{# ❌ Not checking if field is empty #}
<div class="tags">{{ content.field_tags }}</div>  {# May render empty div #}

{# ❌ Assuming array key exists #}
{{ items[0].title }}  {# Error if items is empty #}
```

---

## Template Suggestions

### TWIG009: Implement Template Suggestions

**Severity:** `medium`

Add custom template suggestions in your theme for more granular control.

**Good Example:**
```php
// mytheme.theme

/**
 * Implements hook_theme_suggestions_HOOK_alter() for node templates.
 */
function mytheme_theme_suggestions_node_alter(array &$suggestions, array $variables) {
  $node = $variables['elements']['#node'];
  $view_mode = $variables['elements']['#view_mode'];
  
  // Add suggestion based on field value
  if ($node->hasField('field_layout') && !$node->get('field_layout')->isEmpty()) {
    $layout = $node->get('field_layout')->value;
    $suggestions[] = 'node__' . $node->bundle() . '__' . $layout;
    $suggestions[] = 'node__' . $node->bundle() . '__' . $view_mode . '__' . $layout;
  }
  
  // Add suggestion for nodes with specific taxonomy term
  if ($node->hasField('field_category') && !$node->get('field_category')->isEmpty()) {
    $term = $node->get('field_category')->entity;
    if ($term) {
      $suggestions[] = 'node__' . $node->bundle() . '__category_' . $term->id();
    }
  }
}

/**
 * Implements hook_theme_suggestions_HOOK_alter() for page templates.
 */
function mytheme_theme_suggestions_page_alter(array &$suggestions, array $variables) {
  // Add suggestion based on route
  $route_name = \Drupal::routeMatch()->getRouteName();
  
  if ($route_name === 'entity.node.canonical') {
    $node = \Drupal::routeMatch()->getParameter('node');
    if ($node) {
      // page--node--{bundle}.html.twig
      $suggestions[] = 'page__node__' . $node->bundle();
    }
  }
  
  // Add suggestion based on path alias
  $current_path = \Drupal::service('path.current')->getPath();
  $alias = \Drupal::service('path_alias.manager')->getAliasByPath($current_path);
  
  if ($alias !== $current_path) {
    $alias_parts = explode('/', trim($alias, '/'));
    $suggestion = 'page';
    foreach ($alias_parts as $part) {
      $suggestion .= '__' . str_replace('-', '_', $part);
      $suggestions[] = $suggestion;
    }
  }
}

/**
 * Implements hook_theme_suggestions_HOOK_alter() for blocks.
 */
function mytheme_theme_suggestions_block_alter(array &$suggestions, array $variables) {
  // Add suggestion based on region
  if (isset($variables['elements']['#configuration']['region'])) {
    $region = $variables['elements']['#configuration']['region'];
    $suggestions[] = 'block__' . $region;
    
    if (isset($variables['elements']['#plugin_id'])) {
      $suggestions[] = 'block__' . $region . '__' . $variables['elements']['#plugin_id'];
    }
  }
}
```

---

## Performance

### TWIG010: Use Lazy Builders for Dynamic Content

**Severity:** `medium`

Use lazy builders for personalized or uncacheable content.

**Good Example:**
```php
// In preprocess function
function mytheme_preprocess_node(&$variables) {
  // Use lazy builder for user-specific content
  $variables['user_actions'] = [
    '#lazy_builder' => [
      'mymodule.lazy_builder:renderUserActions',
      [$variables['node']->id()],
    ],
    '#create_placeholder' => TRUE,
  ];
}

// Lazy builder service
namespace Drupal\mymodule;

class LazyBuilder {
  
  public function renderUserActions(int $nid): array {
    $node = $this->entityTypeManager->getStorage('node')->load($nid);
    
    $build = [];
    
    if ($node->access('update')) {
      $build['edit'] = [
        '#type' => 'link',
        '#title' => $this->t('Edit'),
        '#url' => $node->toUrl('edit-form'),
      ];
    }
    
    // This will be cached per-user
    $build['#cache'] = [
      'contexts' => ['user'],
      'tags' => ['node:' . $nid],
    ];
    
    return $build;
  }
}
```

```twig
{# In template - renders as placeholder initially #}
<div class="node-actions">
  {{ user_actions }}
</div>
```

---

### TWIG011: Add Cache Metadata

**Severity:** `high`

Ensure templates have proper cache metadata for optimal performance.

**Good Example:**
```php
// In preprocess function
function mytheme_preprocess_node(&$variables) {
  $node = $variables['node'];
  
  // Add cache tags
  $variables['#cache']['tags'][] = 'node:' . $node->id();
  $variables['#cache']['tags'][] = 'user:' . $node->getOwnerId();
  
  // Add cache contexts
  $variables['#cache']['contexts'][] = 'user.permissions';
  $variables['#cache']['contexts'][] = 'url.query_args';
  
  // Set max-age
  $variables['#cache']['max-age'] = 3600; // 1 hour
  
  // Conditional content based on permissions
  if ($this->currentUser->hasPermission('edit any article content')) {
    $variables['can_edit'] = TRUE;
    $variables['#cache']['contexts'][] = 'user';
  }
}
```

```twig
{# Cache context affects what's rendered #}
{% if can_edit %}
  <a href="{{ edit_url }}">{{ 'Edit'|t }}</a>
{% endif %}
```

---

### TWIG012: Minimize Logic in Templates

**Severity:** `medium`

Keep templates focused on presentation. Move complex logic to preprocess functions.

**Good Example:**
```php
// mytheme.theme - Preprocess function
function mytheme_preprocess_node__article(&$variables) {
  $node = $variables['node'];
  
  // Calculate reading time in PHP, not Twig
  $body = $node->get('body')->value ?? '';
  $word_count = str_word_count(strip_tags($body));
  $variables['reading_time'] = ceil($word_count / 200);
  
  // Format author info
  $author = $node->getOwner();
  $variables['author_info'] = [
    'name' => $author->getDisplayName(),
    'url' => $author->toUrl(),
    'picture' => $this->getUserPicture($author),
  ];
  
  // Determine layout class
  $has_sidebar = !$node->get('field_sidebar')->isEmpty();
  $variables['layout_class'] = $has_sidebar ? 'layout--with-sidebar' : 'layout--full-width';
  
  // Process related articles
  $variables['related_articles'] = $this->getRelatedArticles($node, 3);
}
```

```twig
{# Template is clean and focused on markup #}
<article class="{{ layout_class }}">
  <header>
    <h1>{{ label }}</h1>
    <div class="meta">
      <span class="reading-time">{{ reading_time }} {{ 'min read'|t }}</span>
      <a href="{{ author_info.url }}">{{ author_info.name }}</a>
    </div>
  </header>
  
  <div class="content">
    {{ content|without('field_sidebar') }}
  </div>
  
  {% if related_articles %}
    <aside class="related">
      <h2>{{ 'Related Articles'|t }}</h2>
      {{ related_articles }}
    </aside>
  {% endif %}
</article>
```

**Bad Example:**
```twig
{# ❌ Too much logic in template #}
{% set word_count = node.body.value|striptags|split(' ')|length %}
{% set reading_time = (word_count / 200)|round(0, 'ceil') %}

{% if node.field_category.entity.field_featured.value == true 
   and node.created.value > 'now'|date_modify('-7 days')|date('U') %}
  <span class="badge">New & Featured</span>
{% endif %}

{% for i in 1..5 %}
  {% if i <= rating %}
    ★
  {% else %}
    ☆
  {% endif %}
{% endfor %}
```

---

## Accessibility in Templates

### TWIG013: Include Accessibility Attributes

**Severity:** `high`

Include proper ARIA attributes and semantic HTML in templates.

**Good Example:**
```twig
{# Navigation with ARIA #}
<nav{{ attributes.addClass('main-nav') }} aria-label="{{ 'Main navigation'|t }}">
  <ul role="menubar">
    {% for item in items %}
      <li role="none">
        <a href="{{ item.url }}" 
           role="menuitem"
           {{ item.is_current ? 'aria-current="page"' }}>
          {{ item.title }}
        </a>
      </li>
    {% endfor %}
  </ul>
</nav>

{# Card with proper heading structure #}
{% set heading_level = heading_level|default(2) %}
<article class="card" aria-labelledby="card-title-{{ node.id }}">
  {% if content.field_image|render|trim %}
    <div class="card__image">
      {{ content.field_image }}
    </div>
  {% endif %}
  
  <div class="card__content">
    <h{{ heading_level }} id="card-title-{{ node.id }}" class="card__title">
      <a href="{{ url }}">{{ label }}</a>
    </h{{ heading_level }}>
    
    {{ content.field_summary }}
    
    <a href="{{ url }}" class="card__link" aria-describedby="card-title-{{ node.id }}">
      {{ 'Read more'|t }}
      <span class="visually-hidden">{{ 'about @title'|t({'@title': label}) }}</span>
    </a>
  </div>
</article>

{# Accessible icon with text #}
<button type="button" class="btn">
  <svg aria-hidden="true" class="icon">
    <use xlink:href="#icon-save"></use>
  </svg>
  <span>{{ 'Save'|t }}</span>
</button>

{# Icon-only button #}
<button type="button" class="btn btn--icon" aria-label="{{ 'Close dialog'|t }}">
  <svg aria-hidden="true" class="icon">
    <use xlink:href="#icon-close"></use>
  </svg>
</button>

{# Skip link #}
<a href="#main-content" class="skip-link">
  {{ 'Skip to main content'|t }}
</a>

<main id="main-content" tabindex="-1">
  {{ page.content }}
</main>
```

---

## Debugging

### TWIG014: Enable Twig Debugging in Development

**Severity:** `low`

Enable Twig debugging to see template suggestions and variable information.

**Setup:**
```yaml
# sites/development.services.yml
parameters:
  twig.config:
    debug: true
    auto_reload: true
    cache: false

# settings.local.php
$settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
$settings['cache']['bins']['render'] = 'cache.backend.null';
$settings['cache']['bins']['page'] = 'cache.backend.null';
$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';
```

**Using Debug Output:**
```twig
{# Print variable contents #}
{{ dump(content) }}
{{ dump(node.field_image) }}

{# Print all available variables #}
{{ dump() }}

{# Kint module provides better output #}
{{ kint(node) }}

{# Print specific variable info #}
<pre>{{ _context|keys|join('\n') }}</pre>

{# Debug in HTML comments (visible in source) #}
<!-- Variable type: {{ node|class }} -->
<!-- Field count: {{ node.field_items|length }} -->
```

**Template Comments in HTML:**
```html
<!-- When debug is enabled, you'll see: -->
<!-- THEME DEBUG -->
<!-- THEME HOOK: 'node' -->
<!-- FILE NAME SUGGESTIONS:
   * node--article--full.html.twig
   * node--article.html.twig
   * node--full.html.twig
   x node.html.twig
-->
<!-- BEGIN OUTPUT from 'themes/custom/mytheme/templates/node--article.html.twig' -->
```
