# JavaScript Standards

JavaScript coding standards for Drupal front-end development including Drupal behaviors, ES6+, and AJAX.

## Table of Contents

1. [Drupal Behaviors](#drupal-behaviors)
2. [ES6+ Best Practices](#es6-best-practices)
3. [AJAX and Fetch](#ajax-and-fetch)
4. [Performance](#performance)
5. [jQuery Usage](#jquery-usage)
6. [Error Handling](#error-handling)
7. [Documentation](#documentation)

---

## Drupal Behaviors

### JS001: Use Drupal Behaviors

**Severity:** `high`

Always use `Drupal.behaviors` instead of jQuery document ready or IIFEs. Behaviors are re-run when content is dynamically added (AJAX, BigPipe).

**Good Example:**
```javascript
/**
 * @file
 * JavaScript behaviors for the mymodule module.
 */

(function (Drupal, drupalSettings, once) {
  'use strict';

  /**
   * Attaches the mymodule interactive functionality.
   *
   * @type {Drupal~behavior}
   */
  Drupal.behaviors.mymoduleInteractive = {
    attach: function (context, settings) {
      // Use once() to ensure elements are only processed once
      once('mymodule-interactive', '.mymodule-widget', context).forEach(function (element) {
        // Initialize the widget
        new MyModuleWidget(element, settings.mymodule || {});
      });
    },
    detach: function (context, settings, trigger) {
      // Clean up when content is removed
      // trigger can be: 'unload', 'move', 'serialize'
      if (trigger === 'unload') {
        once.remove('mymodule-interactive', '.mymodule-widget', context).forEach(function (element) {
          // Destroy widget instances, remove event listeners
          if (element.mymoduleWidget) {
            element.mymoduleWidget.destroy();
          }
        });
      }
    }
  };

  /**
   * Widget class for mymodule functionality.
   *
   * @param {HTMLElement} element
   *   The widget container element.
   * @param {Object} options
   *   Configuration options.
   */
  function MyModuleWidget(element, options) {
    this.element = element;
    this.options = Object.assign({
      apiUrl: '/api/mymodule',
      debounceMs: 300
    }, options);

    this.init();
    
    // Store reference for cleanup
    element.mymoduleWidget = this;
  }

  MyModuleWidget.prototype.init = function () {
    this.bindEvents();
    this.loadInitialData();
  };

  MyModuleWidget.prototype.bindEvents = function () {
    const self = this;
    
    this.element.addEventListener('click', function (event) {
      if (event.target.matches('.mymodule-action')) {
        self.handleAction(event);
      }
    });
  };

  MyModuleWidget.prototype.destroy = function () {
    // Clean up event listeners and resources
    this.element.innerHTML = '';
  };

})(Drupal, drupalSettings, once);
```

**Bad Example:**
```javascript
// ❌ Using jQuery document ready - won't work with AJAX/BigPipe
$(document).ready(function () {
  $('.mymodule-widget').each(function () {
    // This only runs once on page load
  });
});

// ❌ Using IIFE without Drupal.behaviors
(function ($) {
  $('.mymodule-widget').doSomething();
})(jQuery);

// ❌ Not using once() - elements processed multiple times
Drupal.behaviors.myBehavior = {
  attach: function (context) {
    // BUG: This runs on every AJAX response!
    $('.widget').addClass('processed');
  }
};
```

---

### JS002: Use the once() Function

**Severity:** `high`

Always use `once()` to prevent behaviors from running multiple times on the same elements.

**Good Example:**
```javascript
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleAccordion = {
    attach: function (context) {
      // once() returns array of newly matched elements
      const accordions = once('mymodule-accordion', '.accordion', context);
      
      accordions.forEach(function (accordion) {
        initAccordion(accordion);
      });
    },
    detach: function (context, settings, trigger) {
      if (trigger === 'unload') {
        // Remove the once marker when detaching
        once.remove('mymodule-accordion', '.accordion', context);
      }
    }
  };

  // Multiple behaviors on same element type - use unique IDs
  Drupal.behaviors.mymoduleAccordionA11y = {
    attach: function (context) {
      once('mymodule-accordion-a11y', '.accordion', context).forEach(function (accordion) {
        // Add ARIA attributes
        accordion.setAttribute('role', 'region');
      });
    }
  };

})(Drupal, once);
```

**Bad Example:**
```javascript
// ❌ Not using once - runs every time
Drupal.behaviors.myBehavior = {
  attach: function (context) {
    // This adds duplicate event listeners on AJAX!
    $('.button', context).on('click', function () {
      // Handler runs multiple times
    });
  }
};

// ❌ Using deprecated jQuery.once
$('.widget').once('mymodule').each(function () {
  // Deprecated - use once() from drupal core
});
```

---

### JS003: Behavior Namespacing

**Severity:** `medium`

Use unique, descriptive names for behaviors to avoid conflicts.

**Good Example:**
```javascript
(function (Drupal, once) {
  'use strict';

  // Clear namespace: module_feature
  Drupal.behaviors.mymoduleDropdownMenu = {
    attach: function (context) {
      once('mymodule-dropdown-menu', '[data-dropdown]', context).forEach(initDropdown);
    }
  };

  Drupal.behaviors.mymoduleFormValidation = {
    attach: function (context) {
      once('mymodule-form-validation', 'form.mymodule-form', context).forEach(initValidation);
    }
  };

  // Helper functions are private to the closure
  function initDropdown(element) {
    // Implementation
  }

  function initValidation(form) {
    // Implementation
  }

})(Drupal, once);
```

**Bad Example:**
```javascript
// ❌ Generic names that may conflict
Drupal.behaviors.dropdown = {};
Drupal.behaviors.validation = {};
Drupal.behaviors.init = {};
```

---

## ES6+ Best Practices

### JS004: Use const and let

**Severity:** `medium`

Use `const` for values that won't be reassigned, `let` for variables that will. Never use `var`.

**Good Example:**
```javascript
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleExample = {
    attach: function (context, settings) {
      // const for values that won't change
      const API_URL = settings.mymodule.apiUrl;
      const container = document.querySelector('.container');
      const items = container.querySelectorAll('.item');

      // let for values that will change
      let currentIndex = 0;
      let isLoading = false;
      let results = [];

      items.forEach(function (item) {
        // const within block scope
        const id = item.dataset.id;
        const name = item.dataset.name;
        
        item.addEventListener('click', function () {
          currentIndex++;
          processItem(id, name);
        });
      });
    }
  };

})(Drupal, once);
```

**Bad Example:**
```javascript
// ❌ Using var
var API_URL = '/api';
var container = document.querySelector('.container');

// ❌ Using let when const is appropriate
let items = document.querySelectorAll('.item'); // Never reassigned

// ❌ Reassigning const (will throw error)
const count = 0;
count = 1; // TypeError
```

---

### JS005: Use Arrow Functions Appropriately

**Severity:** `low`

Use arrow functions for callbacks. Use traditional functions when you need `this` binding.

**Good Example:**
```javascript
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleArrows = {
    attach: function (context) {
      // Arrow functions for callbacks - lexical `this`
      const buttons = once('mymodule-btn', '.btn', context);
      
      buttons.forEach((button) => {
        button.addEventListener('click', (event) => {
          event.preventDefault();
          this.handleClick(event.target);  // `this` is the behavior
        });
      });

      // Array methods with arrows
      const values = items
        .filter((item) => item.active)
        .map((item) => item.value)
        .reduce((acc, val) => acc + val, 0);
    },

    handleClick: function (element) {
      // Traditional function preserves `this` context
      console.log(this);  // The behavior object
    }
  };

  // Traditional functions for constructors
  function MyWidget(element) {
    this.element = element;
    this.init();
  }

  MyWidget.prototype.init = function () {
    // Use self or bind for callbacks that need access
    const self = this;
    
    this.element.addEventListener('click', function (event) {
      self.handleClick(event);
    });

    // Or use bind
    this.element.addEventListener('keydown', this.handleKeydown.bind(this));

    // Or arrow function
    this.element.addEventListener('focus', (event) => {
      this.handleFocus(event);
    });
  };

})(Drupal, once);
```

**Bad Example:**
```javascript
// ❌ Arrow function losing `this` context
const widget = {
  name: 'Widget',
  init: () => {
    console.log(this.name);  // undefined - arrow inherits outer `this`
  }
};

// ❌ Arrow function as constructor
const Widget = (element) => {
  this.element = element;  // Error: arrow functions can't be constructors
};
```

---

### JS006: Use Template Literals

**Severity:** `low`

Use template literals for string interpolation and multi-line strings.

**Good Example:**
```javascript
(function (Drupal) {
  'use strict';

  Drupal.behaviors.mymoduleTemplates = {
    attach: function (context, settings) {
      const userName = settings.mymodule.userName;
      const itemCount = settings.mymodule.itemCount;

      // String interpolation
      const greeting = `Hello, ${userName}! You have ${itemCount} items.`;

      // Expressions in templates
      const status = `Status: ${itemCount > 0 ? 'Active' : 'Empty'}`;

      // Multi-line HTML
      const template = `
        <div class="card">
          <h3 class="card__title">${Drupal.checkPlain(userName)}</h3>
          <p class="card__count">${itemCount} items</p>
          <button class="card__action" data-user="${Drupal.checkPlain(userName)}">
            View Details
          </button>
        </div>
      `;

      // Tagged template for escaping
      const safeHtml = Drupal.theme('mymoduleCard', {
        title: userName,
        count: itemCount
      });
    }
  };

  // Theme function for generating HTML safely
  Drupal.theme.mymoduleCard = function (options) {
    return `
      <div class="card">
        <h3>${Drupal.checkPlain(options.title)}</h3>
        <span>${Number(options.count)}</span>
      </div>
    `;
  };

})(Drupal);
```

**Bad Example:**
```javascript
// ❌ String concatenation
const greeting = 'Hello, ' + userName + '! You have ' + itemCount + ' items.';

// ❌ Unescaped user input in template
const html = `<div>${userInput}</div>`;  // XSS vulnerability!
```

---

### JS007: Use Async/Await for Asynchronous Operations

**Severity:** `medium`

Use async/await for cleaner asynchronous code.

**Good Example:**
```javascript
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleAsync = {
    attach: function (context, settings) {
      once('mymodule-async', '.async-loader', context).forEach((element) => {
        this.initAsyncLoader(element, settings.mymodule);
      });
    },

    initAsyncLoader: async function (element, config) {
      const loadButton = element.querySelector('.load-more');
      const container = element.querySelector('.results');

      loadButton.addEventListener('click', async (event) => {
        event.preventDefault();
        
        // Show loading state
        loadButton.disabled = true;
        loadButton.textContent = Drupal.t('Loading...');

        try {
          const data = await this.fetchData(config.apiUrl);
          this.renderResults(container, data);
        }
        catch (error) {
          Drupal.message.add(Drupal.t('Failed to load data.'), 'error');
          console.error('Fetch error:', error);
        }
        finally {
          loadButton.disabled = false;
          loadButton.textContent = Drupal.t('Load More');
        }
      });
    },

    fetchData: async function (url) {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      return response.json();
    },

    renderResults: function (container, data) {
      const html = data.items.map((item) => 
        `<div class="result-item">${Drupal.checkPlain(item.title)}</div>`
      ).join('');
      
      container.insertAdjacentHTML('beforeend', html);
    }
  };

})(Drupal, once);
```

**Bad Example:**
```javascript
// ❌ Callback hell
function loadData(callback) {
  fetch('/api/data')
    .then(function (response) {
      response.json().then(function (data) {
        processData(data, function (processed) {
          saveData(processed, function (result) {
            callback(result);
          });
        });
      });
    });
}

// ❌ Unhandled promise rejection
async function fetchData() {
  const response = await fetch('/api/data');  // No try-catch!
  return response.json();
}
```

---

## AJAX and Fetch

### JS008: Use Fetch API with Proper Error Handling

**Severity:** `high`

Use the Fetch API for HTTP requests with proper error handling and CSRF tokens.

**Good Example:**
```javascript
(function (Drupal, drupalSettings) {
  'use strict';

  /**
   * API client for mymodule.
   */
  Drupal.mymodule = Drupal.mymodule || {};

  Drupal.mymodule.api = {
    /**
     * Base fetch wrapper with error handling.
     */
    fetch: async function (url, options = {}) {
      const defaults = {
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        credentials: 'same-origin'  // Include cookies
      };

      const config = { ...defaults, ...options };
      config.headers = { ...defaults.headers, ...options.headers };

      // Add CSRF token for non-GET requests
      if (config.method && config.method !== 'GET') {
        const token = await this.getCsrfToken();
        config.headers['X-CSRF-Token'] = token;
      }

      try {
        const response = await fetch(url, config);
        
        if (!response.ok) {
          const error = await this.parseError(response);
          throw error;
        }

        // Handle empty responses
        const text = await response.text();
        return text ? JSON.parse(text) : null;
      }
      catch (error) {
        if (error.name === 'TypeError') {
          // Network error
          throw new Error(Drupal.t('Network error. Please check your connection.'));
        }
        throw error;
      }
    },

    /**
     * Get CSRF token from Drupal.
     */
    getCsrfToken: async function () {
      if (this.csrfToken) {
        return this.csrfToken;
      }

      const response = await fetch('/session/token');
      this.csrfToken = await response.text();
      return this.csrfToken;
    },

    /**
     * Parse error response.
     */
    parseError: async function (response) {
      let message = Drupal.t('An error occurred.');
      
      try {
        const data = await response.json();
        message = data.message || data.error || message;
      }
      catch (e) {
        // Response wasn't JSON
      }

      const error = new Error(message);
      error.status = response.status;
      return error;
    },

    /**
     * GET request.
     */
    get: function (url) {
      return this.fetch(url, { method: 'GET' });
    },

    /**
     * POST request.
     */
    post: function (url, data) {
      return this.fetch(url, {
        method: 'POST',
        body: JSON.stringify(data)
      });
    },

    /**
     * DELETE request.
     */
    delete: function (url) {
      return this.fetch(url, { method: 'DELETE' });
    }
  };

  // Usage in behavior
  Drupal.behaviors.mymoduleApiExample = {
    attach: function (context) {
      once('mymodule-api', '.api-form', context).forEach(async (form) => {
        form.addEventListener('submit', async (event) => {
          event.preventDefault();
          
          const formData = new FormData(form);
          const data = Object.fromEntries(formData);

          try {
            const result = await Drupal.mymodule.api.post('/api/mymodule/items', data);
            Drupal.announce(Drupal.t('Item saved successfully.'));
          }
          catch (error) {
            Drupal.message.add(error.message, 'error');
          }
        });
      });
    }
  };

})(Drupal, drupalSettings);
```

**Bad Example:**
```javascript
// ❌ No error handling
fetch('/api/data')
  .then(response => response.json())
  .then(data => console.log(data));

// ❌ Missing CSRF token for POST
fetch('/api/data', {
  method: 'POST',
  body: JSON.stringify(data)
});

// ❌ Using jQuery.ajax when Fetch is available
$.ajax({
  url: '/api/data',
  success: function (data) {}
});
```

---

### JS009: Drupal AJAX Framework

**Severity:** `medium`

Use Drupal's AJAX framework for form interactions and progressive enhancement.

**Good Example:**
```javascript
(function (Drupal) {
  'use strict';

  /**
   * Custom AJAX command.
   */
  Drupal.AjaxCommands.prototype.mymoduleUpdateWidget = function (ajax, response, status) {
    const element = document.querySelector(response.selector);
    
    if (element) {
      element.innerHTML = response.html;
      
      // Attach behaviors to new content
      Drupal.attachBehaviors(element);
      
      // Announce to screen readers
      if (response.message) {
        Drupal.announce(response.message);
      }
    }
  };

  /**
   * Custom AJAX error handler.
   */
  Drupal.behaviors.mymoduleAjaxErrors = {
    attach: function (context) {
      // Global AJAX error handling
      once('mymodule-ajax-error', 'body', context).forEach(() => {
        document.addEventListener('drupalAjaxError', (event) => {
          const { response } = event.detail;
          
          // Log error for debugging
          console.error('AJAX Error:', response);
          
          // Show user-friendly message
          Drupal.message.add(
            Drupal.t('An error occurred. Please try again.'),
            'error'
          );
        });
      });
    }
  };

})(Drupal);

// PHP side - returning AJAX commands
public function ajaxCallback(Request $request): AjaxResponse {
  $response = new AjaxResponse();
  
  // Built-in commands
  $response->addCommand(new ReplaceCommand('#widget', $rendered_html));
  $response->addCommand(new MessageCommand($this->t('Updated!')));
  
  // Custom command
  $response->addCommand(new Command('mymoduleUpdateWidget', [
    'selector' => '#my-widget',
    'html' => $rendered_widget,
    'message' => $this->t('Widget updated successfully.'),
  ]));
  
  return $response;
}
```

---

## Performance

### JS010: Debounce and Throttle Event Handlers

**Severity:** `medium`

Debounce or throttle expensive operations triggered by frequent events.

**Good Example:**
```javascript
(function (Drupal, once, debounce) {
  'use strict';

  Drupal.behaviors.mymoduleSearch = {
    attach: function (context, settings) {
      once('mymodule-search', '.search-input', context).forEach((input) => {
        // Debounce search - wait 300ms after user stops typing
        const debouncedSearch = debounce(this.performSearch.bind(this), 300);
        
        input.addEventListener('input', (event) => {
          debouncedSearch(event.target.value);
        });
      });

      once('mymodule-scroll', '.infinite-scroll', context).forEach((container) => {
        // Throttle scroll - max once per 100ms
        const throttledScroll = this.throttle(this.handleScroll.bind(this), 100);
        
        container.addEventListener('scroll', throttledScroll);
      });
    },

    performSearch: async function (query) {
      if (query.length < 3) {
        return;
      }
      
      const results = await Drupal.mymodule.api.get(`/api/search?q=${encodeURIComponent(query)}`);
      this.renderResults(results);
    },

    handleScroll: function (event) {
      const container = event.target;
      const scrollBottom = container.scrollHeight - container.scrollTop - container.clientHeight;
      
      if (scrollBottom < 100) {
        this.loadMore();
      }
    },

    /**
     * Simple throttle implementation.
     */
    throttle: function (func, limit) {
      let inThrottle;
      return function (...args) {
        if (!inThrottle) {
          func.apply(this, args);
          inThrottle = true;
          setTimeout(() => inThrottle = false, limit);
        }
      };
    }
  };

})(Drupal, once, Drupal.debounce);
```

**Bad Example:**
```javascript
// ❌ Unthrottled scroll handler - fires hundreds of times
window.addEventListener('scroll', function () {
  // Expensive operation on every scroll event
  calculatePositions();
  updateUI();
});

// ❌ Unthrottled resize
window.addEventListener('resize', function () {
  rebuildLayout();  // Very expensive
});
```

---

### JS011: Efficient DOM Operations

**Severity:** `medium`

Minimize DOM manipulation and reflows.

**Good Example:**
```javascript
(function (Drupal) {
  'use strict';

  Drupal.behaviors.mymoduleEfficient = {
    attach: function (context) {
      // Cache DOM references
      const container = context.querySelector('.item-container');
      if (!container) return;

      // Batch DOM updates using DocumentFragment
      const fragment = document.createDocumentFragment();
      
      items.forEach((item) => {
        const element = document.createElement('div');
        element.className = 'item';
        element.textContent = item.name;
        fragment.appendChild(element);
      });
      
      // Single DOM insertion
      container.appendChild(fragment);

      // Or use insertAdjacentHTML for better performance
      const html = items.map(item => 
        `<div class="item">${Drupal.checkPlain(item.name)}</div>`
      ).join('');
      container.insertAdjacentHTML('beforeend', html);

      // Batch style changes
      requestAnimationFrame(() => {
        elements.forEach((el) => {
          el.style.transform = 'translateX(100px)';
          el.style.opacity = '1';
        });
      });
    }
  };

})(Drupal);
```

**Bad Example:**
```javascript
// ❌ Multiple DOM insertions in loop
items.forEach(function (item) {
  container.innerHTML += '<div>' + item.name + '</div>';  // Reflow each time!
});

// ❌ Reading and writing layout in loop (layout thrashing)
elements.forEach(function (el) {
  const height = el.offsetHeight;  // Read
  el.style.height = height + 10 + 'px';  // Write - triggers reflow
});
```

---

## Error Handling

### JS012: Proper Error Handling

**Severity:** `high`

Handle errors gracefully and provide user feedback.

**Good Example:**
```javascript
(function (Drupal) {
  'use strict';

  Drupal.behaviors.mymoduleErrorHandling = {
    attach: function (context, settings) {
      once('mymodule-errors', '.action-form', context).forEach((form) => {
        form.addEventListener('submit', async (event) => {
          event.preventDefault();
          
          const submitButton = form.querySelector('[type="submit"]');
          const originalText = submitButton.textContent;
          
          try {
            // Disable during submission
            submitButton.disabled = true;
            submitButton.textContent = Drupal.t('Saving...');
            
            const result = await this.submitForm(form);
            
            // Success feedback
            Drupal.message.add(Drupal.t('Saved successfully!'), 'status');
            Drupal.announce(Drupal.t('Your changes have been saved.'));
            
          }
          catch (error) {
            // User-friendly error message
            const message = this.getErrorMessage(error);
            Drupal.message.add(message, 'error');
            
            // Log for debugging
            console.error('Form submission failed:', error);
            
            // Focus first invalid field if validation error
            if (error.validationErrors) {
              const firstError = form.querySelector('.error');
              if (firstError) {
                firstError.focus();
              }
            }
          }
          finally {
            // Always restore button state
            submitButton.disabled = false;
            submitButton.textContent = originalText;
          }
        });
      });
    },

    getErrorMessage: function (error) {
      // Map technical errors to user-friendly messages
      if (error.status === 403) {
        return Drupal.t('You do not have permission to perform this action.');
      }
      if (error.status === 404) {
        return Drupal.t('The requested resource was not found.');
      }
      if (error.status >= 500) {
        return Drupal.t('A server error occurred. Please try again later.');
      }
      if (error.message) {
        return error.message;
      }
      return Drupal.t('An unexpected error occurred.');
    }
  };

  // Global error handler for uncaught errors
  window.addEventListener('error', function (event) {
    console.error('Uncaught error:', event.error);
    // Optionally report to error tracking service
  });

  // Unhandled promise rejections
  window.addEventListener('unhandledrejection', function (event) {
    console.error('Unhandled promise rejection:', event.reason);
    event.preventDefault();  // Prevent console error
  });

})(Drupal);
```

---

## Documentation

### JS013: JSDoc Documentation

**Severity:** `medium`

Document JavaScript functions with JSDoc comments.

**Good Example:**
```javascript
/**
 * @file
 * Provides interactive widget functionality for mymodule.
 */

(function (Drupal, once) {
  'use strict';

  /**
   * Widget constructor.
   *
   * @constructor
   * @param {HTMLElement} element
   *   The widget container element.
   * @param {Object} options
   *   Configuration options.
   * @param {string} options.apiUrl
   *   The API endpoint URL.
   * @param {number} [options.timeout=5000]
   *   Request timeout in milliseconds.
   * @param {Function} [options.onSuccess]
   *   Callback function on successful operation.
   */
  function MyWidget(element, options) {
    /**
     * The widget container element.
     *
     * @type {HTMLElement}
     */
    this.element = element;

    /**
     * Widget configuration.
     *
     * @type {Object}
     */
    this.options = Object.assign({
      apiUrl: '/api',
      timeout: 5000,
      onSuccess: null
    }, options);

    this.init();
  }

  /**
   * Initialize the widget.
   *
   * @return {MyWidget}
   *   Returns this for chaining.
   */
  MyWidget.prototype.init = function () {
    this.bindEvents();
    return this;
  };

  /**
   * Fetch data from the API.
   *
   * @async
   * @param {string} endpoint
   *   The API endpoint path.
   * @param {Object} [params={}]
   *   Query parameters.
   *
   * @return {Promise<Object>}
   *   Promise resolving to the response data.
   *
   * @throws {Error}
   *   Throws if the request fails.
   *
   * @example
   * const data = await widget.fetchData('/items', { page: 1 });
   */
  MyWidget.prototype.fetchData = async function (endpoint, params = {}) {
    const url = new URL(this.options.apiUrl + endpoint, window.location.origin);
    Object.entries(params).forEach(([key, value]) => {
      url.searchParams.append(key, value);
    });

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    return response.json();
  };

  /**
   * Drupal behavior for widget initialization.
   *
   * @type {Drupal~behavior}
   *
   * @prop {Drupal~behaviorAttach} attach
   *   Attaches widget functionality to elements.
   * @prop {Drupal~behaviorDetach} detach
   *   Cleans up widget instances when elements are removed.
   */
  Drupal.behaviors.mymoduleWidget = {
    attach: function (context, settings) {
      once('mymodule-widget', '.mymodule-widget', context).forEach(function (element) {
        new MyWidget(element, settings.mymodule);
      });
    },
    detach: function (context, settings, trigger) {
      if (trigger === 'unload') {
        once.remove('mymodule-widget', '.mymodule-widget', context);
      }
    }
  };

})(Drupal, once);
```
