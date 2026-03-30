# RTL and Internationalization Standards

This document contains standards for right-to-left (RTL) language support and internationalization in Drupal frontend development.

## Table of Contents
1. [RTL Support](#rtl-support)
2. [Logical Properties](#logical-properties)
3. [Implementation Patterns](#implementation-patterns)

---

## RTL Support

### DS_CSS_018: Add LTR comments for directional properties
**Severity:** Medium

For properties without logical property equivalents, add `/* LTR */` comment and create additional RTL ruleset.

**Good:**
```css
.element {
  margin-left: 1rem; /* LTR */
}

.element:dir(rtl) {
  margin-left: 0;
  margin-right: 1rem;
}
```

**Bad:**
```css
.element {
  margin-left: 1rem;
}
```

**Rationale:** Proper RTL support ensures accessibility for right-to-left language users.

**Fix Guidance:** Add `/* LTR */` comments and create corresponding RTL rulesets for directional properties.

**References:**
- https://www.drupal.org/node/1887862

---

## Logical Properties

### Understanding Logical Properties

Logical properties are CSS properties that adapt automatically to the writing direction (LTR or RTL). They replace physical directional properties.

**Physical vs. Logical:**

```css
/* Physical properties (direction-specific) */
.element {
  margin-left: 1rem;
  margin-right: 2rem;
  padding-left: 0.5rem;
  border-right: 1px solid gray;
}

/* Logical properties (direction-agnostic) */
.element {
  margin-inline-start: 1rem;
  margin-inline-end: 2rem;
  padding-inline-start: 0.5rem;
  border-inline-end: 1px solid gray;
}
```

**Property Mapping:**

| Physical Property | Logical Property |
|------------------|------------------|
| `left` | `inset-inline-start` |
| `right` | `inset-inline-end` |
| `top` | `inset-block-start` |
| `bottom` | `inset-block-end` |
| `margin-left` | `margin-inline-start` |
| `margin-right` | `margin-inline-end` |
| `padding-left` | `padding-inline-start` |
| `padding-right` | `padding-inline-end` |
| `border-left` | `border-inline-start` |
| `border-right` | `border-inline-end` |
| `text-align: left` | `text-align: start` |
| `text-align: right` | `text-align: end` |

### When to Use Logical Properties

**Prefer logical properties when:**
- Building new components
- Refactoring existing code
- Target browsers support them (modern browsers)

**Example:**
```css
/* Modern approach with logical properties */
.card {
  margin-inline: 1rem; /* Both start and end */
  padding-block: 2rem; /* Both start and end */
  border-inline-start: 3px solid blue;
}
```

**Use physical properties with RTL fallback when:**
- Dealing with legacy browser support
- Properties don't have logical equivalents yet

---

## Implementation Patterns

### Pattern 1: Using Logical Properties (Preferred)

```css
/* Automatically adapts to RTL */
.button {
  padding-inline-start: 1rem;
  padding-inline-end: 1.5rem;
  margin-inline-end: 0.5rem;
  border-inline-start: 3px solid blue;
  text-align: start;
}
```

**Result:**
- LTR: Left padding 1rem, right padding 1.5rem
- RTL: Right padding 1rem, left padding 1.5rem

### Pattern 2: Physical Properties with RTL Ruleset

```css
/* LTR default */
.element {
  margin-left: 1rem; /* LTR */
  padding-left: 2rem; /* LTR */
  border-right: 1px solid gray; /* LTR */
  float: left; /* LTR */
}

/* RTL override */
.element:dir(rtl) {
  margin-left: 0;
  margin-right: 1rem;
  padding-left: 0;
  padding-right: 2rem;
  border-right: none;
  border-left: 1px solid gray;
  float: right;
}
```

### Pattern 3: Mixed Approach (Transition Phase)

```css
/* New logical properties */
.card {
  padding-inline: 1.5rem;
  margin-block-end: 2rem;
}

/* Legacy physical properties that need RTL */
.card__icon {
  float: left; /* LTR */
}

.card__icon:dir(rtl) {
  float: right;
}
```

### Common RTL Scenarios

#### 1. Icons and Decorative Elements

```css
/* Icon on the start side */
.button {
  padding-inline-start: 2.5rem;
  background-image: url('icon.svg');
  background-position: inline-start center;
  background-repeat: no-repeat;
}

/* Or with physical properties */
.button {
  padding-left: 2.5rem; /* LTR */
  background-position: left center; /* LTR */
}

.button:dir(rtl) {
  padding-left: 1rem;
  padding-right: 2.5rem;
  background-position: right center;
}
```

#### 2. Text Alignment

```css
/* Use logical values */
.text-start {
  text-align: start;
}

.text-end {
  text-align: end;
}

/* Center and justify work the same */
.text-center {
  text-align: center;
}
```

#### 3. Flexbox and Grid

```css
/* Flexbox automatically adapts with flex-direction */
.container {
  display: flex;
  flex-direction: row; /* Adapts to reading direction */
}

/* Grid with logical properties */
.grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  /* Grid flows naturally in reading direction */
}
```

#### 4. Positioning

```css
/* With logical properties */
.tooltip {
  position: absolute;
  inset-inline-start: 0;
  inset-block-start: 100%;
}

/* With physical properties */
.tooltip {
  position: absolute;
  left: 0; /* LTR */
  top: 100%;
}

.tooltip:dir(rtl) {
  left: auto;
  right: 0;
}
```

#### 5. Transforms

```css
/* Translate needs RTL handling */
.slideout {
  transform: translateX(-100%); /* LTR */
}

.slideout:dir(rtl) {
  transform: translateX(100%);
}

/* Or use CSS variables */
:root {
  --slide-direction: -100%;
}

:root:dir(rtl) {
  --slide-direction: 100%;
}

.slideout {
  transform: translateX(var(--slide-direction));
}
```

### Testing RTL Implementation

#### 1. Quick Test in Browser

```html
<!-- Add dir attribute to test -->
<html dir="rtl">
```

#### 2. Toggle with JavaScript

```javascript
// Toggle RTL for testing
document.documentElement.dir = 
  document.documentElement.dir === 'rtl' ? 'ltr' : 'rtl';
```

#### 3. Browser DevTools

Use browser developer tools to:
- Add `dir="rtl"` attribute
- Test with languages like Arabic or Hebrew
- Verify visual layout flips correctly

### RTL Checklist

When implementing RTL support:

- [ ] Icons and decorative elements flip correctly
- [ ] Text alignment is appropriate
- [ ] Margins and padding are mirrored
- [ ] Borders appear on correct side
- [ ] Animations and transitions work in both directions
- [ ] Dropdown menus and tooltips position correctly
- [ ] Form elements align properly
- [ ] Navigation flows in correct direction
- [ ] Breadcrumbs display in correct order
- [ ] Tables and data grids maintain readability

### Browser Support

**Logical Properties:**
- Chrome 89+
- Firefox 66+
- Safari 15+
- Edge 89+

For older browsers, use physical properties with `:dir(rtl)` fallbacks.

### Drupal-Specific Considerations

Drupal has built-in RTL support:

```php
// In your theme, Drupal automatically adds dir attribute
// when an RTL language is active
```

CSS files can have RTL variants:
```
styles.css        // LTR default
styles-rtl.css    // RTL overrides (optional)
```

Or use single CSS file with:
```css
/* Default LTR styles */
.element {
  /* styles */
}

/* RTL overrides */
:dir(rtl) .element {
  /* RTL-specific styles */
}
```

### Common Mistakes to Avoid

1. **Forgetting to flip floats:**
   ```css
   /* Bad */
   .item {
     float: left;
   }
   
   /* Good */
   .item {
     float: left; /* LTR */
   }
   
   .item:dir(rtl) {
     float: right;
   }
   ```

2. **Not handling transforms:**
   ```css
   /* Bad */
   .drawer {
     transform: translateX(-100%);
   }
   
   /* Good */
   .drawer {
     transform: translateX(-100%); /* LTR */
   }
   
   .drawer:dir(rtl) {
     transform: translateX(100%);
   }
   ```

3. **Using left/right in animations:**
   ```css
   /* Bad */
   @keyframes slideIn {
     from { left: -100%; }
     to { left: 0; }
   }
   
   /* Good - use transforms or logical properties */
   @keyframes slideIn {
     from { transform: translateX(-100%); }
     to { transform: translateX(0); }
   }
   ```

### Resources and Tools

**Testing Tools:**
- RTL Tester browser extension
- Chrome DevTools (modify dir attribute)
- Drupal's language switcher

**Languages to Test With:**
- Arabic (ar)
- Hebrew (he)
- Persian (fa)
- Urdu (ur)

**References:**
- [MDN: CSS Logical Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Logical_Properties)
- [W3C: CSS Writing Modes](https://www.w3.org/TR/css-writing-modes-4/)
- [Drupal RTL Support](https://www.drupal.org/docs/multilingual-guide/right-to-left-rtl-support)
