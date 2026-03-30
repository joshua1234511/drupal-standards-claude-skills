# CSS Comments and Documentation Standards

This document contains standards for CSS comments and documentation in Drupal frontend development.

## Table of Contents
1. [Comment Standards](#comment-standards)
2. [File Documentation](#file-documentation)
3. [Inline Comments](#inline-comments)
4. [Section Comments](#section-comments)

---

## Comment Standards

### DS_CSS_020: Use Doxygen-style multi-line comments
**Severity:** Medium

Use Doxygen-style comments for multi-line descriptions and file headers.

**Good:**
```css
/**
 * @file
 * Component styles for navigation.
 *
 * This file contains styles for the main
 * navigation component including responsive
 * behavior and accessibility features.
 */
```

**Bad:**
```css
/* Navigation styles */
/* Contains menu and responsive code */
```

**Rationale:** Standardized comment format improves documentation consistency and tool compatibility.

**Fix Guidance:** Use `/** */` blocks with `@file` annotation for comprehensive file documentation.

**References:**
- https://www.drupal.org/node/1887862

---

## File Documentation

### File Header Format

Every CSS file should begin with a Doxygen-style comment block:

```css
/**
 * @file
 * Brief one-line description of the file's purpose.
 *
 * Extended description providing more context about what this
 * file contains, its relationship to other files, and any
 * important implementation notes.
 *
 * Key features:
 * - Feature 1
 * - Feature 2
 * - Feature 3
 */
```

### Complete File Header Example

```css
/**
 * @file
 * Card component styles.
 *
 * Defines the visual appearance and layout for card components
 * used throughout the site. Cards are flexible containers that
 * can display content in various layouts including:
 *
 * - Standard cards with image, title, and description
 * - Featured cards with enhanced styling
 * - Compact cards for sidebar display
 * - Product cards with pricing information
 *
 * Dependencies:
 * - base/typography.css
 * - components/buttons.css
 *
 * @see components/buttons.css for button styles used within cards
 * @see https://www.drupal.org/project/myproject for project documentation
 */
```

### File Documentation Fields

**@file (required)**
Brief description of the file's purpose.

**Extended description**
Detailed explanation of file contents and purpose.

**@see (optional)**
References to related files or documentation.
```css
/**
 * @file
 * Navigation component styles.
 *
 * @see components/menu.css for menu-specific styles
 * @see https://example.com/docs for full documentation
 */
```

**@todo (optional)**
Note items that need to be addressed.
```css
/**
 * @file
 * Gallery component styles.
 *
 * @todo Add support for video gallery items
 * @todo Optimize loading for large image sets
 */
```

**@deprecated (optional)**
Mark deprecated code with migration instructions.
```css
/**
 * @file
 * Legacy table styles.
 *
 * @deprecated in project:2.0 and is removed from project:3.0.
 *   Use components/data-table.css instead.
 * @see components/data-table.css
 */
```

---

## Inline Comments

### Single-Line Comments

Use single-line comments for brief explanations:

```css
/* Primary button styles */
.button--primary {
  background: blue;
  color: white;
}

/* Hover state */
.button--primary:hover {
  background: darkblue;
}
```

### Multi-Line Comments

Use multi-line comments for longer explanations:

```css
/**
 * Complex grid layout that adapts to various content types.
 * 
 * The grid uses CSS Grid with auto-fit to create a responsive
 * layout without media queries. Items will automatically wrap
 * to new rows as the container width decreases.
 */
.grid-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
}
```

### Commenting Complex Calculations

```css
/**
 * Calculate fluid typography using viewport units.
 * 
 * Formula: minimum + (maximum - minimum) * (viewport - min breakpoint) / (max breakpoint - min breakpoint)
 * This ensures smooth scaling between 16px (mobile) and 20px (desktop).
 */
.fluid-text {
  font-size: calc(1rem + 0.25 * ((100vw - 20rem) / 60));
}
```

### Commenting Browser Hacks

```css
/**
 * Fix for IE11 flexbox bug with min-height.
 * 
 * IE11 doesn't properly calculate flex item heights when using
 * min-height on the flex container. This wrapper div with display: flex
 * provides the needed structural fix.
 */
.flex-wrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}
```

### Commenting Temporary Solutions

```css
/**
 * TEMPORARY: Quick fix for menu overlap issue.
 * 
 * This increased z-index resolves the immediate problem but
 * should be refactored as part of the broader z-index management
 * system being implemented in ticket #1234.
 * 
 * @todo Remove this hack when z-index system is implemented (ticket #1234)
 */
.nav-menu {
  z-index: 9999; /* Temporary fix */
}
```

---

## Section Comments

### Major Section Dividers

Use prominent comment blocks to separate major sections:

```css
/* ========================================================================
   Base Styles
   ======================================================================== */

/* Typography */
/* Layout */
/* Colors */


/* ========================================================================
   Components
   ======================================================================== */

/* Buttons */
/* Cards */
/* Forms */


/* ========================================================================
   Utilities
   ======================================================================== */

/* Spacing */
/* Visibility */
/* Text utilities */
```

### Component Sections

Organize component files with clear sections:

```css
/**
 * @file
 * Card component styles.
 */


/* Base Component
   ========================================================================== */

.card {
  display: block;
  padding: 1.5rem;
  background: white;
  border: 1px solid gray;
}


/* Component Variants
   ========================================================================== */

.card--featured {
  border-width: 2px;
  border-color: blue;
}

.card--compact {
  padding: 1rem;
}


/* Sub-elements
   ========================================================================== */

.card__header {
  margin-bottom: 1rem;
}

.card__title {
  font-size: 1.25rem;
  font-weight: bold;
}

.card__body {
  line-height: 1.5;
}


/* States
   ========================================================================== */

.card.is-loading {
  opacity: 0.5;
  pointer-events: none;
}

.card.is-expanded {
  max-height: none;
}


/* Responsive Adjustments
   ========================================================================== */

@media (min-width: 48rem) {
  .card {
    padding: 2rem;
  }
}
```

### Table of Contents for Large Files

For files longer than 200 lines, include a table of contents:

```css
/**
 * @file
 * Navigation component styles.
 *
 * Table of Contents:
 *
 * 1. Base Navigation Styles
 * 2. Primary Navigation
 * 3. Secondary Navigation
 * 4. Mobile Navigation
 *    4.1 Hamburger Menu
 *    4.2 Slide-out Panel
 * 5. Dropdown Menus
 * 6. Breadcrumbs
 * 7. Responsive Adjustments
 */


/* ==========================================================================
   1. Base Navigation Styles
   ========================================================================== */


/* ==========================================================================
   2. Primary Navigation
   ========================================================================== */
```

---

## Special Comment Patterns

### LTR/RTL Comments

Mark directional properties for internationalization:

```css
.element {
  margin-left: 1rem; /* LTR */
  float: right; /* LTR */
}

.element:dir(rtl) {
  margin-left: 0;
  margin-right: 1rem;
  float: left;
}
```

### Browser-Specific Comments

```css
/* Webkit-specific styles for scrollbar customization */
::-webkit-scrollbar {
  width: 8px;
}

/* Firefox-specific property */
.element {
  scrollbar-width: thin; /* Firefox only */
}
```

### Accessibility Comments

```css
/**
 * Hide content visually but keep it accessible to screen readers.
 * 
 * This technique:
 * - Maintains element in document flow
 * - Keeps content focusable
 * - Prevents visual display
 * - Preserves accessibility tree
 */
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}
```

### Performance Comments

```css
/**
 * Using transform and opacity for animations to leverage
 * GPU acceleration and avoid layout thrashing.
 * 
 * These properties trigger composition-only changes which
 * are more performant than properties that trigger layout
 * or paint operations.
 */
.animated-card {
  transition: transform 0.3s ease, opacity 0.3s ease;
}
```

---

## Comment Best Practices

### DO:
- Write comments that explain "why", not "what"
- Update comments when updating code
- Use consistent formatting and style
- Document complex calculations and logic
- Note browser-specific workarounds
- Mark temporary solutions with @todo
- Reference related files and documentation
- Use proper grammar and punctuation

### DON'T:
- State the obvious
- Leave commented-out code (use version control)
- Write misleading or outdated comments
- Use comments as a substitute for clear code
- Overcomment simple, self-explanatory code
- Use vague language like "fix this later"
- Mix commenting styles within a file

### Good vs. Bad Examples

**Bad (states the obvious):**
```css
/* Make text blue */
.text-blue {
  color: blue;
}
```

**Good (explains why):**
```css
/**
 * Brand primary color for all interactive elements.
 * Meets WCAG AA contrast requirements on white background.
 */
.text-primary {
  color: #0066cc;
}
```

**Bad (outdated/misleading):**
```css
/* Display as grid (Actually using flexbox now) */
.container {
  display: flex;
}
```

**Good (accurate and current):**
```css
/**
 * Flexbox layout for header components.
 * Provides better browser support than Grid for this use case.
 */
.container {
  display: flex;
}
```

---

## Documentation Tools

### Automated Documentation

Consider using CSS documentation generators:

**KSS (Knyle Style Sheets):**
```css
/**
 * Buttons
 *
 * Button styles for various actions throughout the site.
 *
 * Markup:
 * <button class="button {{modifier_class}}">{{title}}</button>
 *
 * .button--primary - Primary action button
 * .button--secondary - Secondary action button
 * .button--danger - Destructive action button
 *
 * Styleguide Components.Buttons
 */
.button {
  /* styles */
}
```

**Stylelint Comments:**
```css
/* stylelint-disable selector-max-id */
#legacy-id {
  /* Override for legacy selector */
}
/* stylelint-enable selector-max-id */
```

### IDE/Editor Integration

Most modern editors support CSS comment parsing for:
- Outline views
- Quick navigation
- Documentation tooltips
- Intelligent autocomplete

Use structured comments to leverage these features.
