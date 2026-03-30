# JavaScript Standards for Drupal

This document contains JavaScript coding standards for Drupal frontend development.

## Table of Contents
1. [Drupal.behaviors Pattern](#drupalbehaviors-pattern)
2. [Event Handling with once()](#event-handling-with-once)
3. [ES6+ Syntax](#es6-syntax)
4. [Translation and Formatting](#translation-and-formatting)
5. [File Structure](#file-structure)

---

## Drupal.behaviors Pattern

### DS_JS_002: Use Drupal.behaviors for all JavaScript
**Severity:** High

All JavaScript that interacts with the DOM must use the `Drupal.behaviors` pattern.

**Good:**
```javascript
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.myComponent = {
    attach: function (context, settings) {
      once('my-component', '.js-my-component', context).forEach(function (element) {
        // Initialize component
        element.addEventListener('click', handleClick);
      });
    },
    detach: function (context, settings, trigger) {
      // Cleanup when element is removed from DOM
      if (trigger === 'unload') {
        // Full page unload cleanup
      }
    }
  };

  function handleClick(event) {
    // Handle click
  }
})(Drupal, once);
```

**Bad:**
```javascript
// Direct DOM manipulation without behaviors
document.addEventListener('DOMContentLoaded', function() {
  document.querySelector('.my-component').addEventListener('click', function() {
    // This won't work with AJAX-loaded content
  });
});

// jQuery ready without Drupal integration
$(document).ready(function() {
  // This breaks on AJAX updates
});
```

**Why Drupal.behaviors?**
- **AJAX compatibility**: Behaviors re-run when new content is loaded via AJAX
- **BigPipe support**: Works with Drupal's progressive page rendering
- **Consistent lifecycle**: attach/detach provides proper initialization and cleanup
- **Context awareness**: Only processes new elements, not the entire DOM

**Behavior Lifecycle:**
1. `attach` runs on page load for the entire document
2. `attach` runs again when AJAX loads new content (context = new content)
3. `detach` runs before content is removed from DOM
4. `detach` with trigger='unload' runs on page unload

---

## Event Handling with once()

### DS_JS_003: Use once() to prevent duplicate handlers
**Severity:** High

Use the `once()` function from Drupal core to prevent duplicate event handlers.

**Good:**
```javascript
Drupal.behaviors.toggleMenu = {
  attach: function (context, settings) {
    once('toggle-menu', '.js-menu-toggle', context).forEach(function (element) {
      element.addEventListener('click', function (e) {
        e.preventDefault();
        document.body.classList.toggle('menu-open');
      });
    });
  }
};
```

**Bad:**
```javascript
Drupal.behaviors.toggleMenu = {
  attach: function (context, settings) {
    // Without once(), this adds a new handler every time attach runs
    document.querySelectorAll('.js-menu-toggle').forEach(function (element) {
      element.addEventListener('click', function (e) {
        // This handler will fire multiple times after AJAX!
      });
    });
  }
};
```

**once() Syntax:**
```javascript
// Returns array of elements that haven't been processed yet
once('unique-id', '.selector', context).forEach(callback);

// The unique-id should be descriptive of the behavior
once('accordion-toggle', '.js-accordion', context);
once('form-validation', '.js-validate', context);
```

**Declaring once as a Dependency:**
In your `.libraries.yml`:
```yaml
my-component:
  js:
    js/components/my-component.js: {}
  dependencies:
    - core/drupal
    - core/once
```

---

## ES6+ Syntax

### DS_JS_001: Use ES6+ syntax
**Severity:** Medium

Use modern JavaScript syntax for cleaner, more maintainable code.

**Good:**
```javascript
(function (Drupal, once) {
  'use strict';

  // Arrow functions for callbacks
  once('example', '.js-item', context).forEach((element) => {
    element.addEventListener('click', handleClick);
  });

  // Template literals
  const message = `Welcome, ${userName}!`;

  // Destructuring
  const { modulePath, basePath } = drupalSettings;

  // Const/let instead of var
  const MAX_ITEMS = 10;
  let currentIndex = 0;

  // Spread operator
  const allItems = [...existingItems, ...newItems];

  // Default parameters
  function createComponent(options = {}) {
    const { animate = true, duration = 300 } = options;
  }
})(Drupal, once);
```

**Bad:**
```javascript
(function (Drupal, once) {
  // Using var instead of const/let
  var MAX_ITEMS = 10;
  var currentIndex = 0;

  // String concatenation instead of template literals
  var message = 'Welcome, ' + userName + '!';

  // Anonymous functions instead of arrow functions
  items.forEach(function(item) {
    // ...
  });
})(Drupal, once);
```

### DS_JS_005: Use strict mode
**Severity:** Medium

Always enable strict mode within IIFEs.

**Good:**
```javascript
(function (Drupal) {
  'use strict';

  // Your code here
})(Drupal);
```

---

## Translation and Formatting

### DS_JS_004: Use Drupal.t() for translatable strings
**Severity:** Medium

All user-facing strings must use `Drupal.t()` for translation.

**Good:**
```javascript
// Simple translation
const message = Drupal.t('Save changes');

// With placeholders
const greeting = Drupal.t('Hello, @name!', { '@name': userName });

// Placeholders types:
// @ - Plain text (HTML escaped)
// % - Emphasized text (wrapped in <em>)
// ! - Raw HTML (use with caution)
const warning = Drupal.t('Are you sure you want to delete %title?', {
  '%title': itemTitle
});

// Plural strings
const itemCount = Drupal.formatPlural(
  count,
  '1 item',
  '@count items'
);
```

**Bad:**
```javascript
// Hardcoded strings
const message = 'Save changes';
alert('Error occurred');

// Concatenation for messages
const greeting = 'Hello, ' + userName + '!';
```

**Drupal.formatPlural() Usage:**
```javascript
const message = Drupal.formatPlural(
  count,                           // Number
  'You have 1 new message',        // Singular
  'You have @count new messages',  // Plural
  { '@count': count }              // Placeholders (optional)
);
```

---

## File Structure

### File Organization

```
mytheme/
├── js/
│   ├── components/
│   │   ├── accordion.js
│   │   ├── modal.js
│   │   └── tabs.js
│   ├── forms/
│   │   ├── validation.js
│   │   └── autocomplete.js
│   └── theme.js
```

### File Template

```javascript
/**
 * @file
 * Brief description of what this file does.
 */

(function (Drupal, once) {
  'use strict';

  /**
   * Behavior description.
   *
   * @type {Drupal~behavior}
   */
  Drupal.behaviors.behaviorName = {
    attach: function (context, settings) {
      once('behavior-id', '.js-selector', context).forEach(function (element) {
        // Initialization code
      });
    },
    detach: function (context, settings, trigger) {
      // Cleanup code (optional)
    }
  };

})(Drupal, once);
```

### Library Declaration

```yaml
# mytheme.libraries.yml
accordion:
  js:
    js/components/accordion.js: {}
  dependencies:
    - core/drupal
    - core/once

modal:
  js:
    js/components/modal.js: {}
  dependencies:
    - core/drupal
    - core/once
    - core/drupal.dialog
```

---

## Common Patterns

### AJAX Form Handling

```javascript
Drupal.behaviors.ajaxForm = {
  attach: function (context, settings) {
    once('ajax-form', '.js-ajax-form', context).forEach(function (form) {
      form.addEventListener('submit', function (e) {
        e.preventDefault();

        const formData = new FormData(form);

        fetch(form.action, {
          method: 'POST',
          body: formData,
          headers: {
            'X-Requested-With': 'XMLHttpRequest'
          }
        })
        .then(response => response.json())
        .then(data => {
          // Handle response
        })
        .catch(error => {
          console.error('Error:', error);
        });
      });
    });
  }
};
```

### Drupal Settings Access

```javascript
Drupal.behaviors.useSettings = {
  attach: function (context, settings) {
    // Access settings passed from PHP
    const mySettings = settings.myModule || {};
    const apiEndpoint = mySettings.apiEndpoint;
    const maxItems = mySettings.maxItems || 10;

    // Use settings
    if (apiEndpoint) {
      fetchData(apiEndpoint);
    }
  }
};
```

### State Management with data Attributes

```javascript
Drupal.behaviors.toggleState = {
  attach: function (context, settings) {
    once('toggle-state', '.js-toggle', context).forEach(function (element) {
      element.addEventListener('click', function () {
        const target = document.getElementById(this.dataset.target);
        const isExpanded = this.getAttribute('aria-expanded') === 'true';

        this.setAttribute('aria-expanded', !isExpanded);
        target.classList.toggle('is-hidden');
      });
    });
  }
};
```

---

## Accessibility in JavaScript

### Focus Management

```javascript
// Opening a modal
function openModal(modal) {
  modal.classList.add('is-open');
  modal.setAttribute('aria-hidden', 'false');

  // Store the element that opened the modal
  modal.triggerElement = document.activeElement;

  // Focus the first focusable element
  const firstFocusable = modal.querySelector(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  );
  if (firstFocusable) {
    firstFocusable.focus();
  }
}

// Closing a modal
function closeModal(modal) {
  modal.classList.remove('is-open');
  modal.setAttribute('aria-hidden', 'true');

  // Return focus to trigger element
  if (modal.triggerElement) {
    modal.triggerElement.focus();
  }
}
```

### Keyboard Navigation

```javascript
Drupal.behaviors.keyboardNav = {
  attach: function (context, settings) {
    once('keyboard-nav', '.js-tabs', context).forEach(function (tablist) {
      const tabs = tablist.querySelectorAll('[role="tab"]');

      tablist.addEventListener('keydown', function (e) {
        const currentIndex = Array.from(tabs).indexOf(document.activeElement);

        switch (e.key) {
          case 'ArrowLeft':
            e.preventDefault();
            const prevIndex = currentIndex > 0 ? currentIndex - 1 : tabs.length - 1;
            tabs[prevIndex].focus();
            break;
          case 'ArrowRight':
            e.preventDefault();
            const nextIndex = currentIndex < tabs.length - 1 ? currentIndex + 1 : 0;
            tabs[nextIndex].focus();
            break;
        }
      });
    });
  }
};
```

---

## References

- [Drupal JavaScript Coding Standards](https://www.drupal.org/docs/develop/standards/javascript)
- [Drupal.behaviors API](https://www.drupal.org/docs/drupal-apis/javascript-api/javascript-api-overview)
- [Using JavaScript in Drupal](https://www.drupal.org/docs/theming-drupal/adding-stylesheets-css-and-javascript-js-to-a-drupal-theme)
