# CSS Formatting Standards

This document contains all CSS formatting standards for Drupal frontend development.

## Table of Contents
1. [Indentation and Whitespace](#indentation-and-whitespace)
2. [Line Endings and File Structure](#line-endings-and-file-structure)
3. [Selectors](#selectors)
4. [Declarations](#declarations)
5. [Values and Quotes](#values-and-quotes)
6. [Vendor Prefixes](#vendor-prefixes)
7. [Property Organization](#property-organization)

---

## Indentation and Whitespace

### DS_CSS_001: Use 2 spaces for indentation
**Severity:** Medium

All CSS indentation must use exactly 2 spaces. Declarations should be indented one level from their selector.

**Good:**
```css
.selector {
  property: value;
}
```

**Bad:**
```css
.selector {
    property: value;
}
```

**Rationale:** Consistent indentation improves code readability and collaboration.

**Fix Guidance:** Configure your editor to use 2 spaces for CSS indentation. Use EditorConfig for team consistency.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

### DS_CSS_004: Remove trailing whitespace
**Severity:** Low

Lines should not have any whitespace characters at the end.

**Good:**
```css
.selector {
  property: value;
}
```

**Bad:**
```css
.selector { 
  property: value; 
}
```

**Rationale:** Trailing whitespace can cause version control noise and is generally untidy.

**Fix Guidance:** Configure your editor to show and automatically remove trailing whitespace.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

## Line Endings and File Structure

### DS_CSS_002: Use Unix line endings (LF)
**Severity:** Low

CSS files must use Unix line endings (LF) rather than Windows (CRLF) or Mac (CR) line endings.

**Rationale:** Ensures consistent file handling across different operating systems and version control.

**Fix Guidance:** Configure your editor and git to use LF line endings. Use .gitattributes to enforce this.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

### DS_CSS_003: End files with single blank line
**Severity:** Low

CSS files should end with exactly one blank line, no more, no less.

**Good:**
```css
.last-rule {
  property: value;
}

```

**Bad:**
```css
.last-rule {
  property: value;
}
```

**Rationale:** Prevents issues with file concatenation and follows POSIX standards.

**Fix Guidance:** Configure your editor to automatically add a final newline to files.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

## Selectors

### DS_CSS_005: Use one selector per line for multiple selectors
**Severity:** Medium

When using multiple selectors, place each selector on its own line for better readability.

**Good:**
```css
.selector-one,
.selector-two {
  property: value;
}
```

**Bad:**
```css
.selector-one, .selector-two {
  property: value;
}
```

**Rationale:** Improves readability and makes it easier to scan and modify selectors.

**Fix Guidance:** Split multi-selector rules across multiple lines, with commas at the end of each line.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

### DS_CSS_006: Quote attribute values in selectors
**Severity:** Medium

Always use quotes around attribute values in CSS selectors.

**Good:**
```css
input[type="checkbox"]
```

**Bad:**
```css
input[type=checkbox]
```

**Rationale:** Quotes ensure proper parsing and are required for attribute values containing spaces or special characters.

**Fix Guidance:** Always wrap attribute values in double quotes when writing attribute selectors.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

### DS_CSS_016: Use functional pseudo-classes for combining selectors
**Severity:** Medium

Use functional pseudo-classes like `:is()`, `:not()`, or `:where()` to combine selectors when possible.

**Good:**
```css
:is(.warning, .error) {
  color: red;
}
```

**Bad:**
```css
.warning,
.error {
  color: red;
}
```

**Rationale:** Functional pseudo-classes provide more efficient and maintainable selector grouping.

**Fix Guidance:** Use `:is()`, `:not()`, or `:where()` for complex selector combinations where supported.

**References:**
- https://www.drupal.org/node/1887862

---

## Declarations

### DS_CSS_007: End declarations with semicolons
**Severity:** High

Every CSS declaration must end with a semicolon, including the last declaration in a rule.

**Good:**
```css
.selector {
  color: red;
  margin: 0;
}
```

**Bad:**
```css
.selector {
  color: red;
  margin: 0
}
```

**Rationale:** Prevents parsing errors and ensures consistent code style.

**Fix Guidance:** Always include semicolons after every CSS declaration.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

## Values and Quotes

### DS_CSS_008: Use double quotes for quoted values
**Severity:** Low

When quotes are needed in CSS values, use double quotes rather than single quotes.

**Good:**
```css
font-family: "Helvetica Neue", sans-serif;
```

**Bad:**
```css
font-family: 'Helvetica Neue', sans-serif;
```

**Rationale:** Consistency with other Drupal coding standards and improved readability.

**Fix Guidance:** Replace single quotes with double quotes in CSS string values.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

### DS_CSS_010: Omit units for zero values
**Severity:** Low

Do not include units when the value is zero (0px should be 0).

**Good:**
```css
margin: 0;
```

**Bad:**
```css
margin: 0px;
```

**Rationale:** Shorter code and universally understood since zero is zero regardless of unit.

**Fix Guidance:** Remove units from zero values in CSS declarations.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines

---

### DS_CSS_017: Use space after commas in property values
**Severity:** Low

Include a space after commas in property values for better readability.

**Good:**
```css
font-family: Arial, sans-serif;
background: linear-gradient(to right, red, blue);
```

**Bad:**
```css
font-family: Arial,sans-serif;
background: linear-gradient(to right,red,blue);
```

**Rationale:** Consistent spacing improves code readability and follows common CSS conventions.

**Fix Guidance:** Add spaces after commas in multi-value CSS properties.

**References:**
- https://www.drupal.org/node/1887862

---

## Vendor Prefixes

### DS_CSS_019: Place vendor prefixes before non-prefixed version
**Severity:** Medium

Place vendor-prefixed properties directly before their non-prefixed version.

**Good:**
```css
.element {
  -webkit-transform: scale(1.2);
  transform: scale(1.2);
}
```

**Bad:**
```css
.element {
  transform: scale(1.2);
  -webkit-transform: scale(1.2);
}
```

**Rationale:** Proper prefix ordering ensures the standard property overrides vendor-specific versions.

**Fix Guidance:** Place vendor-prefixed properties immediately before the standard property.

**References:**
- https://www.drupal.org/node/1887862

---

## Property Organization

### DS_CSS_011: Order properties logically
**Severity:** Medium

Order CSS properties in a logical sequence: positioning, box model, then other declarations.

**Good:**
```css
.element {
  position: relative;
  display: block;
  width: 100%;
  margin: 1rem;
  color: red;
}
```

**Bad:**
```css
.element {
  color: red;
  position: relative;
  margin: 1rem;
  width: 100%;
}
```

**Rationale:** Logical property ordering improves code readability and maintainability.

**Fix Guidance:** Use CSScomb or similar tools to automatically sort CSS properties.

**Recommended Property Order:**
1. Positioning: `position`, `top`, `right`, `bottom`, `left`, `z-index`
2. Box Model: `display`, `flex`, `grid`, `width`, `height`, `margin`, `padding`, `border`
3. Typography: `font`, `line-height`, `text-align`, `color`
4. Visual: `background`, `opacity`, `transform`, `transition`
5. Misc: `cursor`, `overflow`, etc.

**References:**
- https://www.drupal.org/docs/develop/standards/css/css-formatting-guidelines
