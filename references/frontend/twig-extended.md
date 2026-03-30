# Twig Template Standards for Drupal

This document contains Twig template coding standards for Drupal frontend development.

## Table of Contents
1. [Attributes Object](#attributes-object)
2. [BEM Class Naming](#bem-class-naming)
3. [Escaping and Security](#escaping-and-security)
4. [Template Structure](#template-structure)
5. [Common Patterns](#common-patterns)

---

## Attributes Object

### DS_TWIG_001: Use Drupal attributes object properly
**Severity:** High

Always use the `attributes` object for element attributes instead of hardcoding.

**Good:**
```twig
{# Properly using attributes object #}
<div{{ attributes }}>
  {{ content }}
</div>

{# Adding classes while preserving existing attributes #}
<div{{ attributes.addClass('my-class') }}>
  {{ content }}
</div>

{# Adding multiple classes #}
{% set classes = [
  'block',
  'block--' ~ plugin_id|clean_class,
  label ? 'block--with-label',
] %}
<div{{ attributes.addClass(classes) }}>
  {{ content }}
</div>
```

**Bad:**
```twig
{# Hardcoding attributes breaks Drupal's attribute system #}
<div class="my-class" id="my-id">
  {{ content }}
</div>

{# Overwriting attributes completely #}
<div class="{{ attributes.class }}">
  {{ content }}
</div>
```

**Attributes Object Methods:**

```twig
{# Add a class #}
{{ attributes.addClass('new-class') }}

{# Add multiple classes #}
{{ attributes.addClass(['class-one', 'class-two']) }}

{# Remove a class #}
{{ attributes.removeClass('old-class') }}

{# Add an attribute #}
{{ attributes.setAttribute('data-id', '123') }}

{# Remove an attribute #}
{{ attributes.removeAttribute('data-old') }}

{# Check if attribute exists #}
{% if attributes.hasClass('active') %}
  {# ... #}
{% endif %}

{# Create new attributes object #}
{% set new_attributes = create_attribute() %}
{% set new_attributes = new_attributes.addClass('custom-class') %}
<span{{ new_attributes }}>Text</span>
```

**Why Use Attributes?**
- Preserves attributes added by Drupal core and contrib modules
- Maintains accessibility attributes (ARIA, roles)
- Keeps data attributes from Views, paragraphs, etc.
- Enables proper quickedit and contextual links functionality

---

## BEM Class Naming

### DS_TWIG_002: Use BEM naming conventions in templates
**Severity:** Medium

Apply BEM naming consistently in Twig templates.

**Good:**
```twig
{# Block (component) #}
{% set classes = [
  'card',
  card_type ? 'card--' ~ card_type|clean_class,
  is_featured ? 'card--featured',
] %}

<article{{ attributes.addClass(classes) }}>
  {# Element (sub-component) #}
  {% if image %}
    <div class="card__image">
      {{ image }}
    </div>
  {% endif %}

  <div class="card__content">
    {# Element #}
    {% if title %}
      <h3 class="card__title">{{ title }}</h3>
    {% endif %}

    {# Element #}
    <div class="card__body">
      {{ body }}
    </div>
  </div>

  {# Element with modifier #}
  {% if footer %}
    <footer class="card__footer card__footer--{{ footer_style|default('default') }}">
      {{ footer }}
    </footer>
  {% endif %}
</article>
```

**Bad:**
```twig
{# Inconsistent naming #}
<article class="card {{ type }}">
  <div class="cardImage">{{ image }}</div>
  <div class="content">
    <h3 class="title">{{ title }}</h3>
  </div>
</article>
```

**Dynamic Class Building:**

```twig
{# Build classes array dynamically #}
{% set classes = ['component'] %}

{% if variant %}
  {% set classes = classes|merge(['component--' ~ variant|clean_class]) %}
{% endif %}

{% if is_active %}
  {% set classes = classes|merge(['is-active']) %}
{% endif %}

<div{{ attributes.addClass(classes) }}>
```

**Using clean_class Filter:**

```twig
{# Always use clean_class for dynamic class names #}
<div class="block--{{ block_type|clean_class }}">

{# clean_class converts:
   "My Block Type" → "my-block-type"
   "some_value" → "some-value"
   "123numbers" → "123numbers" #}
```

---

## Escaping and Security

### DS_TWIG_003: Proper escaping in templates
**Severity:** High

Understand and correctly apply Twig's auto-escaping.

**Drupal Auto-Escaping:**
Drupal 8+ auto-escapes all variables. Use `|raw` only when absolutely necessary.

**Good:**
```twig
{# Text content - auto-escaped, safe #}
<p>{{ body }}</p>

{# Render arrays - already safe #}
{{ content.field_image }}

{# Attributes - already safe #}
<div{{ attributes }}>

{# Trans - already safe #}
{% trans %}Welcome, {{ username }}{% endtrans %}
```

**When |raw is Acceptable:**

```twig
{# Render arrays are safe #}
{{ content|raw }}

{# Markup from safe Drupal APIs #}
{{ description|raw }}

{# Trusted HTML from admin-only fields #}
{% if user_is_admin %}
  {{ admin_html|raw }}
{% endif %}
```

**Bad - NEVER Do This:**

```twig
{# Never use raw on user input! #}
{{ user_comment|raw }}

{# Never use raw on URL parameters #}
{{ query_param|raw }}

{# Never use raw on form values #}
{{ form_input|raw }}
```

**Safe Patterns:**

```twig
{# URL encoding #}
<a href="{{ path('entity.node.canonical', {'node': node.id}) }}">

{# Attribute escaping #}
<div data-value="{{ value|e('html_attr') }}">

{# JavaScript string #}
<script>
  var title = {{ title|json_encode|raw }};
</script>
```

---

## Template Structure

### File Header

Every template should start with a documentation block:

```twig
{#
/**
 * @file
 * Theme override for a field.
 *
 * Available variables:
 * - attributes: HTML attributes for the containing element.
 * - label_hidden: Whether to show or hide the field label.
 * - title_attributes: HTML attributes for the title.
 * - label: The label for the field.
 * - items: List of all the field items.
 * - entity_type: The entity type of the field's entity.
 * - field_name: The name of the field.
 *
 * @see template_preprocess_field()
 */
#}
```

### Template Organization

```twig
{#
/**
 * @file
 * Card component template.
 */
#}

{# 1. Variable preparation #}
{% set classes = [
  'card',
  type ? 'card--' ~ type|clean_class,
] %}

{% set title_classes = [
  'card__title',
  title_size ? 'card__title--' ~ title_size,
] %}

{# 2. Main template structure #}
<article{{ attributes.addClass(classes) }}>
  {% block card_media %}
    {% if image %}
      <div class="card__media">
        {{ image }}
      </div>
    {% endif %}
  {% endblock %}

  {% block card_content %}
    <div class="card__content">
      {% if title %}
        <h3{{ title_attributes.addClass(title_classes) }}>
          {{ title }}
        </h3>
      {% endif %}

      {% if body %}
        <div class="card__body">
          {{ body }}
        </div>
      {% endif %}
    </div>
  {% endblock %}

  {% block card_footer %}
    {% if footer %}
      <footer class="card__footer">
        {{ footer }}
      </footer>
    {% endif %}
  {% endblock %}
</article>
```

### Template Naming Conventions

```
templates/
├── block/
│   ├── block.html.twig                    # Base block template
│   ├── block--system-branding-block.html.twig
│   └── block--views-block.html.twig
├── field/
│   ├── field.html.twig                    # Base field template
│   ├── field--node--title.html.twig
│   └── field--field-image.html.twig
├── node/
│   ├── node.html.twig                     # Base node template
│   ├── node--article.html.twig
│   └── node--article--teaser.html.twig
├── paragraph/
│   ├── paragraph.html.twig
│   └── paragraph--hero.html.twig
└── components/
    ├── card.html.twig                     # Custom components
    └── button.html.twig
```

---

## Common Patterns

### Conditional Wrapper

```twig
{# Only render wrapper if content exists #}
{% if content.field_items|render|trim %}
  <div class="items-wrapper">
    {{ content.field_items }}
  </div>
{% endif %}
```

### Link Handling

```twig
{# Internal link #}
<a href="{{ path('entity.node.canonical', {'node': nid}) }}">
  {{ title }}
</a>

{# Link with attributes #}
{% set link_attributes = create_attribute() %}
{% set link_attributes = link_attributes
  .addClass('button')
  .setAttribute('target', '_blank')
  .setAttribute('rel', 'noopener')
%}
<a href="{{ url }}"{{ link_attributes }}>{{ text }}</a>

{# Link field #}
{% if content.field_link.0['#url'] %}
  <a href="{{ content.field_link.0['#url'] }}"{{ content.field_link.0['#attributes'] }}>
    {{ content.field_link.0['#title'] }}
  </a>
{% endif %}
```

### Image Handling

```twig
{# Responsive image #}
{% if content.field_image|render|trim %}
  <figure class="image-wrapper">
    {{ content.field_image }}
    {% if content.field_caption|render|trim %}
      <figcaption class="image-caption">
        {{ content.field_caption }}
      </figcaption>
    {% endif %}
  </figure>
{% endif %}
```

### Loop with Index

```twig
{% for item in items %}
  {% set item_classes = [
    'item',
    loop.first ? 'item--first',
    loop.last ? 'item--last',
    loop.index is odd ? 'item--odd' : 'item--even',
  ] %}
  <div class="{{ item_classes|join(' ') }}">
    {{ item.content }}
  </div>
{% endfor %}
```

### Include Component

```twig
{# Include with variables #}
{% include '@mytheme/components/card.html.twig' with {
  title: node.label,
  body: content.body,
  image: content.field_image,
  type: 'featured'
} only %}

{# Include with default values #}
{% include '@mytheme/components/button.html.twig' with {
  text: button_text|default('Learn More'),
  style: button_style|default('primary'),
  url: button_url
} %}
```

### Embed for Blocks

```twig
{# Base layout template #}
{% embed '@mytheme/layouts/section.html.twig' %}
  {% block header %}
    <h2>{{ title }}</h2>
  {% endblock %}

  {% block content %}
    {{ content }}
  {% endblock %}
{% endembed %}
```

---

## Accessibility in Twig

### ARIA Attributes

```twig
{# Expandable content #}
<button 
  class="toggle js-toggle"
  aria-expanded="{{ is_expanded ? 'true' : 'false' }}"
  aria-controls="content-{{ id }}"
>
  {{ button_text }}
</button>
<div 
  id="content-{{ id }}" 
  class="content {{ is_expanded ? '' : 'is-hidden' }}"
  aria-hidden="{{ is_expanded ? 'false' : 'true' }}"
>
  {{ content }}
</div>
```

### Screen Reader Only Text

```twig
{# Visually hidden but accessible #}
<a href="{{ url }}">
  {{ title }}
  <span class="visually-hidden">
    {% trans %}(opens in new tab){% endtrans %}
  </span>
</a>
```

### Skip Links

```twig
{# In page.html.twig #}
<a href="#main-content" class="visually-hidden focusable skip-link">
  {% trans %}Skip to main content{% endtrans %}
</a>
```

---

## Translation

### Trans Tag

```twig
{# Simple translation #}
{% trans %}Welcome to our site{% endtrans %}

{# With variables #}
{% trans %}
  Hello {{ username }}, you have {{ count }} messages.
{% endtrans %}

{# Plural #}
{% trans %}
  You have 1 item in your cart.
{% plural count %}
  You have {{ count }} items in your cart.
{% endtrans %}

{# With context #}
{% trans with {'context': 'Email subject'} %}
  New message received
{% endtrans %}
```

### Trans Filter

```twig
{# Simple filter #}
{{ 'Submit'|t }}

{# With placeholders #}
{{ 'Welcome, @name'|t({'@name': username}) }}
```

---

## Performance Tips

### Avoid Expensive Operations in Loops

```twig
{# Good - Calculate once outside loop #}
{% set total = items|length %}
{% for item in items %}
  <p>Item {{ loop.index }} of {{ total }}</p>
{% endfor %}

{# Bad - Recalculates every iteration #}
{% for item in items %}
  <p>Item {{ loop.index }} of {{ items|length }}</p>
{% endfor %}
```

### Lazy Rendering

```twig
{# Check if field has content before rendering #}
{% if content.field_sidebar|render|trim %}
  <aside class="sidebar">
    {{ content.field_sidebar }}
  </aside>
{% endif %}
```

### Cache Contexts

```twig
{# Add cache context in preprocess, not template #}
{# In theme.theme: #}
{# $variables['#cache']['contexts'][] = 'user.roles'; #}
```

---

## References

- [Twig Coding Standards](https://www.drupal.org/docs/develop/standards/twig)
- [Twig in Drupal](https://www.drupal.org/docs/theming-drupal/twig-in-drupal)
- [Attributes Object](https://www.drupal.org/docs/8/theming-drupal-8/using-attributes-in-templates)
