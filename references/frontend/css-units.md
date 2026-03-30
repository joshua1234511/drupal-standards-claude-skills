# CSS Units and Values Standards

This document contains standards for CSS units and values in Drupal frontend development.

## Table of Contents
1. [Unit Standards](#unit-standards)
2. [Best Practices](#best-practices)

---

## Unit Standards

### DS_CSS_009: Prefer rem units over px
**Severity:** Medium

Use rem units for sizing to improve accessibility and responsive design.

**Good:**
```css
.element {
  font-size: 1.2rem;
  padding: 1rem;
  margin: 2rem 0;
  width: 20rem;
}
```

**Bad:**
```css
.element {
  font-size: 18px;
  padding: 16px;
  margin: 32px 0;
  width: 320px;
}
```

**Rationale:** rem units scale with user font size preferences and provide better accessibility.

**Fix Guidance:** Use rem units for font sizes, margins, and padding. Use PostCSS for automatic px to rem conversion.

**Understanding rem Units:**

- `rem` stands for "root em" 
- Based on the root element's (`<html>`) font size
- Default browser font size is typically 16px
- `1rem = 16px` (by default)
- Scales when users change their browser's font size setting

**Conversion Chart (assuming 16px base):**
```
12px = 0.75rem
14px = 0.875rem
16px = 1rem
18px = 1.125rem
20px = 1.25rem
24px = 1.5rem
32px = 2rem
48px = 3rem
```

**When to Use Different Units:**

1. **Use rem for:**
   - Font sizes
   - Padding and margins
   - Element dimensions that should scale with text
   - Media query breakpoints

   ```css
   .card {
     padding: 1.5rem;
     margin-bottom: 2rem;
     font-size: 1rem;
     max-width: 30rem;
   }
   ```

2. **Use em for:**
   - Relative sizing within a component
   - Values that should scale with the element's font size

   ```css
   .button {
     font-size: 1rem;
     padding: 0.5em 1em; /* Scales with button's font size */
   }
   ```

3. **Use px for:**
   - Border widths
   - Small, fixed decorative elements
   - Box shadows

   ```css
   .card {
     border: 1px solid gray;
     box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
   }
   ```

4. **Use % for:**
   - Fluid layouts
   - Responsive widths

   ```css
   .container {
     width: 100%;
     max-width: 75rem;
   }
   
   .column {
     width: 50%;
   }
   ```

5. **Use viewport units (vw, vh) for:**
   - Full-screen sections
   - Hero images
   - Modal overlays

   ```css
   .hero {
     height: 100vh;
     width: 100vw;
   }
   ```

**Setting Root Font Size:**

```css
:root {
  /* Set base font size - easier calculations */
  font-size: 16px;
}

/* Or use 62.5% for easier math (10px base) */
:root {
  font-size: 62.5%; /* 10px */
}

/* Then 1.6rem = 16px */
```

**Accessibility Benefits:**

1. **Respects User Preferences:**
   - Users with low vision can increase browser font size
   - Your entire layout scales proportionally

2. **Better Reading Experience:**
   - Maintains readability at different zoom levels
   - Consistent spacing relationships

3. **WCAG Compliance:**
   - Helps meet WCAG 2.1 Level AA requirements
   - Text can be resized up to 200% without loss of functionality

**PostCSS Automation:**

```javascript
// postcss.config.js
module.exports = {
  plugins: {
    'postcss-pxtorem': {
      rootValue: 16,
      propList: ['*'],
      selectorBlackList: [],
      replace: true,
      mediaQuery: false,
      minPixelValue: 2
    }
  }
}
```

**Migration Strategy:**

1. Start with new components using rem
2. Gradually refactor existing code
3. Use PostCSS for automated conversion
4. Test with different browser font sizes
5. Document any intentional px usage

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

## Best Practices

### Consistent Unit Usage

**Within Components:**
Use consistent units within a single component to maintain proportional relationships:

```css
.card {
  /* All spacing uses rem for consistent scaling */
  padding: 1.5rem;
  margin-bottom: 2rem;
  border-radius: 0.5rem;
  font-size: 1rem;
  line-height: 1.5rem;
}
```

**Between Components:**
Maintain consistency across similar components:

```css
.card,
.panel,
.widget {
  /* Consistent base padding */
  padding: 1.5rem;
}

.card__title,
.panel__title,
.widget__title {
  /* Consistent title sizing */
  font-size: 1.25rem;
  margin-bottom: 1rem;
}
```

### Responsive Considerations

Use rem in media queries for better scaling:

```css
/* Good - scales with user font size */
@media (min-width: 48rem) {
  .element {
    font-size: 1.25rem;
  }
}

/* Less ideal - fixed pixel breakpoint */
@media (min-width: 768px) {
  .element {
    font-size: 20px;
  }
}
```

### Common Patterns

**Typography Scale:**
```css
:root {
  --font-size-xs: 0.75rem;   /* 12px */
  --font-size-sm: 0.875rem;  /* 14px */
  --font-size-base: 1rem;    /* 16px */
  --font-size-lg: 1.125rem;  /* 18px */
  --font-size-xl: 1.25rem;   /* 20px */
  --font-size-2xl: 1.5rem;   /* 24px */
  --font-size-3xl: 2rem;     /* 32px */
}
```

**Spacing Scale:**
```css
:root {
  --spacing-xs: 0.25rem;  /* 4px */
  --spacing-sm: 0.5rem;   /* 8px */
  --spacing-md: 1rem;     /* 16px */
  --spacing-lg: 1.5rem;   /* 24px */
  --spacing-xl: 2rem;     /* 32px */
  --spacing-2xl: 3rem;    /* 48px */
  --spacing-3xl: 4rem;    /* 64px */
}
```

**Usage:**
```css
.card {
  padding: var(--spacing-lg);
  margin-bottom: var(--spacing-xl);
  font-size: var(--font-size-base);
}

.card__title {
  font-size: var(--font-size-xl);
  margin-bottom: var(--spacing-md);
}
```

### Testing

Always test your implementations:

1. **Browser Font Size Test:**
   - Increase browser font size to 200%
   - Verify layout remains functional
   - Check for text overflow or breaking

2. **Zoom Test:**
   - Zoom to 200% using Ctrl/Cmd +
   - Verify proportions are maintained
   - Check responsive breakpoints

3. **Cross-Browser Test:**
   - Test in multiple browsers
   - Verify consistent rendering
   - Check for calculation differences
