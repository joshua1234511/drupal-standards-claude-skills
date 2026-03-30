# CSS Architecture Standards

This document contains CSS architecture and organization standards for Drupal frontend development, focusing on SMACSS methodology, BEM naming, and component-based design.

## Table of Contents
1. [Component-Based Architecture](#component-based-architecture)
2. [Naming Conventions](#naming-conventions)
3. [State Classes](#state-classes)
4. [JavaScript Hooks](#javascript-hooks)

---

## Component-Based Architecture

### DS_CSS_012: Use component-based CSS architecture
**Severity:** High

Structure CSS using SMACSS methodology with Base, Layout, Component, State, and Theme categories.

**Good:**
```css
/* Component */
.card {
  display: block;
}

/* Component variant */
.card--featured {
  border: 2px solid blue;
}
```

**Bad:**
```css
/* Context-dependent styling */
.sidebar .card {
  display: block;
  border: 2px solid blue;
}
```

**Rationale:** Component-based architecture creates predictable, reusable, maintainable, and scalable CSS.

**Fix Guidance:** Refactor context-dependent styles into standalone components with modifier classes.

**SMACSS Categories:**

1. **Base** - Default element styles (no classes)
   ```css
   body {
     font-family: Arial, sans-serif;
   }
   
   a {
     color: blue;
   }
   ```

2. **Layout** - Major page structure (prefix with `l-` or `layout-`)
   ```css
   .l-header {
     width: 100%;
   }
   
   .l-sidebar {
     width: 25%;
   }
   ```

3. **Component** - Reusable UI components
   ```css
   .card {
     padding: 1rem;
     border: 1px solid gray;
   }
   
   .button {
     display: inline-block;
     padding: 0.5rem 1rem;
   }
   ```

4. **State** - Temporary appearance changes (prefix with `is-`)
   ```css
   .is-active {
     font-weight: bold;
   }
   
   .is-hidden {
     display: none;
   }
   ```

5. **Theme** - Visual variations (prefix with `theme-`)
   ```css
   .theme-dark {
     background: black;
     color: white;
   }
   ```

**Key Principles:**
- Components should work anywhere on the page
- Avoid location-dependent styles
- Use modifier classes for variations
- Keep specificity low
- Make components self-contained

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-architecture-for-drupal-9

---

## Naming Conventions

### DS_CSS_013: Use BEM-like naming for CSS classes
**Severity:** High

Use clear naming conventions:
- `.component-name` - Base component
- `.component-name--variant` - Component variant/modifier
- `.component-name__sub-object` - Component sub-element

**Good:**
```css
.card {
  /* Base component */
}

.card--featured {
  /* Variant: featured card */
}

.card__title {
  /* Sub-element: card title */
}

.card__body {
  /* Sub-element: card body */
}
```

**Bad:**
```css
.cardTitle {
  /* camelCase not used */
}

.card_featured {
  /* Single underscore instead of double dash */
}

.featuredCard {
  /* Unclear relationship */
}
```

**Naming Rules:**

1. **Component Names:**
   - Use lowercase with hyphens between words
   - Example: `.navigation`, `.user-profile`, `.search-form`

2. **Modifiers (Variants):**
   - Use double dash `--` to separate from component name
   - Example: `.button--primary`, `.card--large`, `.alert--warning`

3. **Sub-elements:**
   - Use double underscore `__` to separate from component name
   - Example: `.card__header`, `.menu__item`, `.form__input`

**Complete Example:**
```css
/* Base component */
.product-card {
  display: flex;
  padding: 1rem;
  border: 1px solid gray;
}

/* Modifier: featured variant */
.product-card--featured {
  border-width: 2px;
  border-color: blue;
}

/* Sub-element: product image */
.product-card__image {
  width: 100%;
  height: auto;
}

/* Sub-element: product title */
.product-card__title {
  font-size: 1.5rem;
  font-weight: bold;
}

/* Sub-element with modifier */
.product-card__button--primary {
  background: blue;
  color: white;
}
```

**Rationale:** Clear naming conventions communicate component relationships and make code self-documenting.

**Fix Guidance:** Use dashes between words, double dashes for variants, double underscores for sub-objects.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-architecture-for-drupal-9

---

## State Classes

### DS_CSS_014: Use .is- prefix for state classes
**Severity:** Medium

State classes that represent temporary appearance changes should use the `.is-` prefix.

**Good:**
```css
.is-active {
  background: blue;
}

.is-hidden {
  display: none;
}

.is-loading {
  opacity: 0.5;
  cursor: wait;
}

.is-expanded {
  max-height: none;
}

.is-disabled {
  pointer-events: none;
  opacity: 0.5;
}
```

**Bad:**
```css
.active {
  background: blue;
}

.hidden {
  display: none;
}

.loading {
  opacity: 0.5;
}
```

**Common State Classes:**
- `.is-active` - Active/current state
- `.is-hidden` - Hidden from view
- `.is-visible` - Explicitly visible
- `.is-disabled` - Disabled/non-interactive
- `.is-loading` - Loading state
- `.is-expanded` - Expanded state (accordions, menus)
- `.is-collapsed` - Collapsed state
- `.is-selected` - Selected item
- `.is-checked` - Checked state
- `.is-error` - Error state
- `.is-success` - Success state
- `.is-open` - Open state (modals, dropdowns)
- `.is-closed` - Closed state

**Usage Example:**
```html
<button class="button button--primary is-disabled">
  Save
</button>

<div class="accordion is-expanded">
  <div class="accordion__header">
    Title
  </div>
  <div class="accordion__content">
    Content
  </div>
</div>
```

**Rationale:** Clear distinction between permanent component styles and temporary state changes.

**Fix Guidance:** Prefix all state-related classes with `.is-` to clearly identify their purpose.

**JavaScript Integration:**
State classes are typically toggled via JavaScript:
```javascript
element.classList.add('is-active');
element.classList.remove('is-hidden');
element.classList.toggle('is-expanded');
```

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-architecture-for-drupal-9

---

## JavaScript Hooks

### DS_CSS_015: Use .js- prefix for JavaScript hooks
**Severity:** Medium

Classes used solely for JavaScript targeting should use the `.js-` prefix and have no CSS styling.

**Good:**
```html
<!-- HTML -->
<button class="button js-toggle-menu">Menu</button>
```

```css
/* CSS - no styling for .js- classes */
.button {
  padding: 1rem;
  background: blue;
  color: white;
}

/* Do NOT style .js-toggle-menu */
```

```javascript
// JavaScript targets the hook class
document.querySelector('.js-toggle-menu').addEventListener('click', () => {
  // Toggle menu
});
```

**Bad:**
```html
<!-- HTML - same class for both styling and JS -->
<button class="toggle-menu">Menu</button>
```

```css
/* CSS - styling applied to the same class JS uses */
.toggle-menu {
  padding: 1rem;
  background: blue;
}
```

```javascript
// JavaScript targets the styled class
document.querySelector('.toggle-menu').addEventListener('click', () => {
  // Toggle menu - breaks if CSS class name changes
});
```

**Rationale:** Separates presentation from behavior, preventing CSS changes from breaking JavaScript.

**Fix Guidance:** Add `.js-` prefixed classes for JavaScript targeting, separate from styling classes.

**Common JavaScript Hook Patterns:**

1. **Toggle Actions:**
   ```html
   <button class="menu-button js-toggle-menu">Menu</button>
   <div class="mobile-menu js-mobile-menu">...</div>
   ```

2. **Form Handlers:**
   ```html
   <form class="contact-form js-contact-form">
     <input class="form__input js-form-input" />
     <button class="button js-form-submit">Submit</button>
   </form>
   ```

3. **Dynamic Content:**
   ```html
   <div class="product-grid js-product-grid">...</div>
   <button class="load-more-button js-load-more">Load More</button>
   ```

4. **Interactive Components:**
   ```html
   <div class="tabs js-tabs">
     <button class="tabs__button js-tab-trigger" data-tab="1">Tab 1</button>
     <div class="tabs__panel js-tab-panel" data-tab="1">Content 1</div>
   </div>
   ```

**Best Practices:**
- Use `.js-` classes ONLY for JavaScript targeting
- Never apply CSS styles to `.js-` classes
- Combine `.js-` classes with styling classes in HTML
- Keep `.js-` class names descriptive of their behavior
- Document complex JavaScript hooks in comments

**Benefits:**
- CSS refactoring won't break JavaScript functionality
- Clear separation of concerns
- Easier to identify elements with JavaScript behavior
- Safer to change class names for styling purposes

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-architecture-for-drupal-9
