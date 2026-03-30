# Accessibility Standards

Web accessibility standards for Drupal following WCAG 2.2 guidelines. Ensure your site is usable by everyone, including people with disabilities.

## Table of Contents

1. [Images and Media](#images-and-media)
2. [Forms and Inputs](#forms-and-inputs)
3. [Navigation and Focus](#navigation-and-focus)
4. [Semantic HTML](#semantic-html)
5. [ARIA Usage](#aria-usage)
6. [Color and Contrast](#color-and-contrast)
7. [Dynamic Content](#dynamic-content)
8. [Testing](#testing)

---

## Images and Media

### ACC001: Images Must Have Alt Attributes

**Severity:** `high` | **WCAG:** 1.1.1 (Level A)

All `<img>` elements must have alt attributes with meaningful descriptions.

**Good Example:**
```html
<!-- Informative images - describe content -->
<img src="chart-q4-sales.png" alt="Q4 2024 sales chart showing 25% growth in November">

<!-- Functional images - describe function -->
<img src="search-icon.svg" alt="Search">
<img src="download.png" alt="Download PDF report">

<!-- Decorative images - empty alt -->
<img src="decorative-border.png" alt="">
<img src="background-pattern.svg" alt="" role="presentation">

<!-- Complex images - provide detailed description -->
<figure>
  <img src="org-chart.png" alt="Company organizational chart" aria-describedby="org-chart-desc">
  <figcaption id="org-chart-desc">
    The CEO reports to the Board. Three VPs report to the CEO: VP Engineering, 
    VP Marketing, and VP Operations. Each VP manages 3-5 department heads.
  </figcaption>
</figure>

<!-- Image as link - describe destination -->
<a href="/products">
  <img src="product-catalog.jpg" alt="View our product catalog">
</a>
```

```twig
{# Twig template #}
<img src="{{ image_url }}" alt="{{ image_alt|default('') }}">

{# Responsive images #}
<picture>
  <source srcset="{{ image.webp }}" type="image/webp">
  <img src="{{ image.fallback }}" alt="{{ image.alt }}">
</picture>
```

**Bad Example:**
```html
<!-- ❌ Missing alt -->
<img src="logo.png">

<!-- ❌ Non-descriptive alt -->
<img src="chart.png" alt="image">
<img src="photo.jpg" alt="photo">

<!-- ❌ Filename as alt -->
<img src="IMG_1234.jpg" alt="IMG_1234.jpg">

<!-- ❌ Redundant text -->
<img src="photo.jpg" alt="Photo of a sunset">  <!-- "Photo of" is redundant -->
```

---

### ACC002: Video and Audio Accessibility

**Severity:** `high` | **WCAG:** 1.2.1-1.2.5 (Level A/AA)

Provide captions, transcripts, and audio descriptions for media content.

**Good Example:**
```html
<!-- Video with captions and description -->
<figure>
  <video controls aria-describedby="video-desc">
    <source src="tutorial.mp4" type="video/mp4">
    <track kind="captions" src="captions-en.vtt" srclang="en" label="English" default>
    <track kind="captions" src="captions-es.vtt" srclang="es" label="Español">
    <track kind="descriptions" src="descriptions.vtt" srclang="en" label="Audio descriptions">
    <!-- Fallback for no video support -->
    <p>Your browser doesn't support video. <a href="tutorial.mp4">Download the video</a>.</p>
  </video>
  <figcaption id="video-desc">Tutorial: How to configure your account settings</figcaption>
</figure>

<!-- Provide transcript link -->
<div class="video-container">
  <video id="intro-video" controls>
    <source src="intro.mp4" type="video/mp4">
    <track kind="captions" src="intro-captions.vtt" srclang="en" default>
  </video>
  <a href="#video-transcript">Read the transcript</a>
</div>

<div id="video-transcript" class="transcript">
  <h3>Video Transcript</h3>
  <p>[Speaker] Welcome to our platform...</p>
</div>

<!-- Audio with transcript -->
<figure>
  <audio controls>
    <source src="podcast.mp3" type="audio/mpeg">
  </audio>
  <details>
    <summary>Show transcript</summary>
    <div class="transcript">
      <p><strong>Host:</strong> Welcome to episode 42...</p>
    </div>
  </details>
</figure>
```

**Bad Example:**
```html
<!-- ❌ Video without captions -->
<video src="important-announcement.mp4" controls></video>

<!-- ❌ Auto-playing video -->
<video src="promo.mp4" autoplay></video>
```

---

## Forms and Inputs

### ACC003: Form Inputs Must Have Labels

**Severity:** `high` | **WCAG:** 1.3.1, 3.3.2 (Level A)

Every form input must have an associated label using `<label>`, `aria-label`, or `aria-labelledby`.

**Good Example:**
```php
// Drupal Form API - labels are automatic
$form['email'] = [
  '#type' => 'email',
  '#title' => $this->t('Email address'),
  '#required' => TRUE,
  '#description' => $this->t('We will send confirmation to this address.'),
];

$form['search'] = [
  '#type' => 'search',
  '#title' => $this->t('Search'),
  '#title_display' => 'invisible',  // Visually hidden but accessible
];

$form['quantity'] = [
  '#type' => 'number',
  '#title' => $this->t('Quantity'),
  '#min' => 1,
  '#max' => 100,
  '#field_suffix' => $this->t('items'),
];
```

```html
<!-- Explicit label association -->
<div class="form-item">
  <label for="username">Username</label>
  <input type="text" id="username" name="username" required>
  <p id="username-hint" class="description">Use only letters and numbers</p>
</div>

<!-- Input with aria-describedby for hints -->
<div class="form-item">
  <label for="password">Password</label>
  <input type="password" id="password" name="password" 
         aria-describedby="password-requirements" required>
  <div id="password-requirements">
    <p>Password must contain:</p>
    <ul>
      <li>At least 8 characters</li>
      <li>One uppercase letter</li>
      <li>One number</li>
    </ul>
  </div>
</div>

<!-- Visually hidden label -->
<label for="search" class="visually-hidden">Search</label>
<input type="search" id="search" name="search" placeholder="Search...">

<!-- Group related inputs with fieldset -->
<fieldset>
  <legend>Shipping Address</legend>
  
  <div class="form-item">
    <label for="street">Street address</label>
    <input type="text" id="street" name="street" autocomplete="street-address">
  </div>
  
  <div class="form-item">
    <label for="city">City</label>
    <input type="text" id="city" name="city" autocomplete="address-level2">
  </div>
</fieldset>
```

**Bad Example:**
```html
<!-- ❌ No label -->
<input type="text" name="email">

<!-- ❌ Placeholder as label -->
<input type="text" name="name" placeholder="Enter your name">

<!-- ❌ Label not associated -->
<label>Email</label>
<input type="email" name="email">

<!-- ❌ Using title attribute instead of label -->
<input type="text" name="phone" title="Phone number">
```

---

### ACC004: Error Messages Must Be Clear and Associated

**Severity:** `high` | **WCAG:** 3.3.1, 3.3.3 (Level A/AA)

Form errors must be clearly identified and associated with their inputs.

**Good Example:**
```php
// Drupal Form API
public function validateForm(array &$form, FormStateInterface $form_state): void {
  $email = $form_state->getValue('email');
  
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    // Error is automatically associated with the field
    $form_state->setErrorByName('email', $this->t('Please enter a valid email address, for example: name@example.com'));
  }
  
  $password = $form_state->getValue('password');
  if (strlen($password) < 8) {
    $form_state->setErrorByName('password', $this->t('Password must be at least 8 characters long. You entered @count characters.', [
      '@count' => strlen($password),
    ]));
  }
}
```

```html
<!-- Client-side validation with ARIA -->
<div class="form-item form-item--error">
  <label for="email" id="email-label">Email address</label>
  <input type="email" id="email" name="email" 
         aria-invalid="true"
         aria-describedby="email-error"
         required>
  <p id="email-error" class="form-item__error" role="alert">
    Please enter a valid email address, for example: name@example.com
  </p>
</div>

<!-- Error summary at form top -->
<div class="messages messages--error" role="alert" aria-labelledby="error-summary">
  <h2 id="error-summary">There were 2 errors in your submission:</h2>
  <ul>
    <li><a href="#email">Email address is invalid</a></li>
    <li><a href="#password">Password is too short</a></li>
  </ul>
</div>
```

```javascript
// JavaScript validation
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleValidation = {
    attach: function (context) {
      once('mymodule-validation', 'form.validated', context).forEach((form) => {
        form.addEventListener('submit', (event) => {
          const errors = this.validate(form);
          
          if (errors.length > 0) {
            event.preventDefault();
            this.showErrors(form, errors);
            
            // Move focus to first error
            const firstError = form.querySelector('[aria-invalid="true"]');
            if (firstError) {
              firstError.focus();
            }
            
            // Announce errors to screen readers
            Drupal.announce(
              Drupal.t('Form has @count errors. Please correct them and try again.', {
                '@count': errors.length
              }),
              'assertive'
            );
          }
        });
      });
    }
  };
})(Drupal, once);
```

---

### ACC005: Provide Input Assistance

**Severity:** `medium` | **WCAG:** 3.3.2 (Level A)

Provide clear instructions, examples, and input formats.

**Good Example:**
```php
$form['phone'] = [
  '#type' => 'tel',
  '#title' => $this->t('Phone number'),
  '#description' => $this->t('Format: (555) 123-4567'),
  '#placeholder' => '(555) 123-4567',
  '#attributes' => [
    'autocomplete' => 'tel',
    'pattern' => '\(\d{3}\) \d{3}-\d{4}',
  ],
];

$form['date'] = [
  '#type' => 'date',
  '#title' => $this->t('Event date'),
  '#description' => $this->t('Select a date between today and one year from now.'),
  '#attributes' => [
    'min' => date('Y-m-d'),
    'max' => date('Y-m-d', strtotime('+1 year')),
  ],
];

$form['amount'] = [
  '#type' => 'number',
  '#title' => $this->t('Donation amount'),
  '#field_prefix' => '$',
  '#min' => 5,
  '#max' => 10000,
  '#step' => 1,
  '#description' => $this->t('Minimum donation: $5'),
];
```

---

## Navigation and Focus

### ACC006: Keyboard Navigation

**Severity:** `high` | **WCAG:** 2.1.1, 2.1.2 (Level A)

All functionality must be accessible via keyboard.

**Good Example:**
```javascript
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleKeyboard = {
    attach: function (context) {
      // Custom dropdown with keyboard support
      once('mymodule-dropdown', '.dropdown', context).forEach((dropdown) => {
        const trigger = dropdown.querySelector('.dropdown__trigger');
        const menu = dropdown.querySelector('.dropdown__menu');
        const items = menu.querySelectorAll('.dropdown__item');

        trigger.addEventListener('keydown', (event) => {
          switch (event.key) {
            case 'Enter':
            case ' ':
            case 'ArrowDown':
              event.preventDefault();
              this.openMenu(dropdown);
              items[0].focus();
              break;
            case 'Escape':
              this.closeMenu(dropdown);
              trigger.focus();
              break;
          }
        });

        items.forEach((item, index) => {
          item.addEventListener('keydown', (event) => {
            switch (event.key) {
              case 'ArrowDown':
                event.preventDefault();
                if (index < items.length - 1) {
                  items[index + 1].focus();
                }
                break;
              case 'ArrowUp':
                event.preventDefault();
                if (index > 0) {
                  items[index - 1].focus();
                } else {
                  trigger.focus();
                }
                break;
              case 'Escape':
                this.closeMenu(dropdown);
                trigger.focus();
                break;
              case 'Tab':
                this.closeMenu(dropdown);
                break;
            }
          });
        });
      });
    },

    openMenu: function (dropdown) {
      const trigger = dropdown.querySelector('.dropdown__trigger');
      const menu = dropdown.querySelector('.dropdown__menu');
      
      trigger.setAttribute('aria-expanded', 'true');
      menu.hidden = false;
    },

    closeMenu: function (dropdown) {
      const trigger = dropdown.querySelector('.dropdown__trigger');
      const menu = dropdown.querySelector('.dropdown__menu');
      
      trigger.setAttribute('aria-expanded', 'false');
      menu.hidden = true;
    }
  };

})(Drupal, once);
```

```html
<!-- Dropdown markup -->
<div class="dropdown">
  <button class="dropdown__trigger" 
          aria-haspopup="true" 
          aria-expanded="false"
          aria-controls="dropdown-menu-1">
    Options
    <span class="dropdown__icon" aria-hidden="true">▼</span>
  </button>
  <ul class="dropdown__menu" id="dropdown-menu-1" role="menu" hidden>
    <li role="none">
      <a class="dropdown__item" role="menuitem" href="/edit">Edit</a>
    </li>
    <li role="none">
      <a class="dropdown__item" role="menuitem" href="/delete">Delete</a>
    </li>
  </ul>
</div>
```

**Bad Example:**
```html
<!-- ❌ Click-only interaction -->
<div class="dropdown" onclick="toggleMenu()">
  <span>Options ▼</span>
  <div class="menu">...</div>
</div>

<!-- ❌ Keyboard trap -->
<div class="modal" tabindex="0" onkeydown="if(event.key==='Tab') event.preventDefault()">
```

---

### ACC007: Focus Management

**Severity:** `high` | **WCAG:** 2.4.3, 2.4.7 (Level A/AA)

Focus must be visible and logically ordered.

**Good Example:**
```css
/* Visible focus indicator */
:focus {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* Enhanced focus for better visibility */
:focus-visible {
  outline: 3px solid #005fcc;
  outline-offset: 2px;
  box-shadow: 0 0 0 4px rgba(0, 95, 204, 0.25);
}

/* Remove default outline only if custom style provided */
button:focus-visible,
a:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px #005fcc, 0 0 0 5px white;
}

/* Skip link */
.skip-link {
  position: absolute;
  top: -40px;
  left: 0;
  background: #000;
  color: #fff;
  padding: 8px 16px;
  z-index: 100;
}

.skip-link:focus {
  top: 0;
}
```

```html
<!-- Skip link at top of page -->
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  
  <header>...</header>
  <nav>...</nav>
  
  <main id="main-content" tabindex="-1">
    <!-- Main content -->
  </main>
</body>
```

```javascript
// Focus management for modals
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.mymoduleModal = {
    attach: function (context) {
      once('mymodule-modal', '.modal', context).forEach((modal) => {
        const focusableElements = modal.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
        );
        const firstFocusable = focusableElements[0];
        const lastFocusable = focusableElements[focusableElements.length - 1];

        // Trap focus within modal
        modal.addEventListener('keydown', (event) => {
          if (event.key === 'Tab') {
            if (event.shiftKey && document.activeElement === firstFocusable) {
              event.preventDefault();
              lastFocusable.focus();
            } else if (!event.shiftKey && document.activeElement === lastFocusable) {
              event.preventDefault();
              firstFocusable.focus();
            }
          }
        });

        // Store trigger element
        modal.addEventListener('open', (event) => {
          this.previouslyFocused = document.activeElement;
          firstFocusable.focus();
        });

        // Restore focus on close
        modal.addEventListener('close', (event) => {
          if (this.previouslyFocused) {
            this.previouslyFocused.focus();
          }
        });
      });
    }
  };

})(Drupal, once);
```

---

### ACC008: Provide Skip Links and Landmarks

**Severity:** `medium` | **WCAG:** 2.4.1 (Level A)

Provide mechanisms to skip repetitive content.

**Good Example:**
```html
<!DOCTYPE html>
<html lang="en">
<head>...</head>
<body>
  <!-- Skip links -->
  <div class="skip-links">
    <a href="#main-content" class="skip-link">Skip to main content</a>
    <a href="#main-navigation" class="skip-link">Skip to navigation</a>
    <a href="#search" class="skip-link">Skip to search</a>
  </div>

  <header role="banner">
    <div class="site-branding">...</div>
    
    <nav id="main-navigation" role="navigation" aria-label="Main navigation">
      <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
      </ul>
    </nav>
    
    <form id="search" role="search" aria-label="Site search">
      <label for="search-input" class="visually-hidden">Search</label>
      <input type="search" id="search-input" name="search">
      <button type="submit">Search</button>
    </form>
  </header>

  <main id="main-content" role="main">
    <article>
      <h1>Page Title</h1>
      <!-- Content -->
    </article>
  </main>

  <aside role="complementary" aria-label="Related content">
    <!-- Sidebar content -->
  </aside>

  <footer role="contentinfo">
    <!-- Footer content -->
  </footer>
</body>
</html>
```

---

## Semantic HTML

### ACC009: Use Proper Heading Hierarchy

**Severity:** `high` | **WCAG:** 1.3.1 (Level A)

Use headings in logical, hierarchical order without skipping levels.

**Good Example:**
```html
<main>
  <h1>Understanding Web Accessibility</h1>
  
  <section>
    <h2>What is Accessibility?</h2>
    <p>Content...</p>
    
    <h3>Types of Disabilities</h3>
    <p>Content...</p>
    
    <h3>Assistive Technologies</h3>
    <p>Content...</p>
    
    <h4>Screen Readers</h4>
    <p>Content...</p>
    
    <h4>Voice Control</h4>
    <p>Content...</p>
  </section>
  
  <section>
    <h2>WCAG Guidelines</h2>
    <p>Content...</p>
  </section>
</main>
```

```twig
{# Twig template with dynamic heading levels #}
{% set heading_level = heading_level|default(2) %}

<article>
  <h{{ heading_level }}>{{ title }}</h{{ heading_level }}>
  
  {{ content }}
  
  {% if subsections %}
    {% for subsection in subsections %}
      <section>
        <h{{ heading_level + 1 }}>{{ subsection.title }}</h{{ heading_level + 1 }}>
        {{ subsection.content }}
      </section>
    {% endfor %}
  {% endif %}
</article>
```

**Bad Example:**
```html
<!-- ❌ Skipping heading levels -->
<h1>Main Title</h1>
<h3>Subsection</h3>  <!-- Should be h2 -->
<h5>Detail</h5>  <!-- Skipped h4 -->

<!-- ❌ Using headings for styling -->
<h4>Small text that isn't a heading</h4>

<!-- ❌ Multiple h1s on page (usually) -->
<h1>Site Name</h1>
<h1>Page Title</h1>
```

---

### ACC010: Use Semantic HTML Elements

**Severity:** `medium` | **WCAG:** 1.3.1 (Level A)

Use appropriate HTML elements for their semantic meaning.

**Good Example:**
```html
<!-- Use semantic elements -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
  </ul>
</nav>

<article>
  <header>
    <h2><a href="/article/1">Article Title</a></h2>
    <p>By <address class="author"><a href="/author/jane">Jane Doe</a></address></p>
    <time datetime="2024-03-15">March 15, 2024</time>
  </header>
  
  <p>Article content...</p>
  
  <footer>
    <p>Tags: <a href="/tag/accessibility">Accessibility</a></p>
  </footer>
</article>

<aside aria-label="Related articles">
  <h3>Related Articles</h3>
  <ul>...</ul>
</aside>

<!-- Use buttons for actions, links for navigation -->
<button type="button" onclick="saveItem()">Save</button>
<a href="/items/123">View Item</a>

<!-- Use proper list markup -->
<ul>
  <li>First item</li>
  <li>Second item</li>
</ul>

<dl>
  <dt>Term</dt>
  <dd>Definition</dd>
</dl>

<!-- Use tables for tabular data -->
<table>
  <caption>Monthly Sales Report</caption>
  <thead>
    <tr>
      <th scope="col">Month</th>
      <th scope="col">Revenue</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">January</th>
      <td>$10,000</td>
    </tr>
  </tbody>
</table>
```

**Bad Example:**
```html
<!-- ❌ Using divs for everything -->
<div class="nav">
  <div class="nav-item">Home</div>
</div>

<!-- ❌ Link that acts as button -->
<a href="#" onclick="save()">Save</a>

<!-- ❌ Button that navigates -->
<button onclick="window.location='/page'">Go to page</button>

<!-- ❌ Table for layout -->
<table>
  <tr>
    <td>Sidebar</td>
    <td>Main content</td>
  </tr>
</table>
```

---

## ARIA Usage

### ACC011: Use ARIA Correctly

**Severity:** `high` | **WCAG:** 4.1.2 (Level A)

Use ARIA attributes correctly to enhance accessibility, not replace semantic HTML.

**Good Example:**
```html
<!-- Tabs pattern -->
<div class="tabs">
  <div role="tablist" aria-label="Account settings">
    <button role="tab" 
            aria-selected="true" 
            aria-controls="panel-1" 
            id="tab-1"
            tabindex="0">
      Profile
    </button>
    <button role="tab" 
            aria-selected="false" 
            aria-controls="panel-2" 
            id="tab-2"
            tabindex="-1">
      Security
    </button>
  </div>
  
  <div role="tabpanel" 
       id="panel-1" 
       aria-labelledby="tab-1"
       tabindex="0">
    Profile content...
  </div>
  
  <div role="tabpanel" 
       id="panel-2" 
       aria-labelledby="tab-2"
       tabindex="0"
       hidden>
    Security content...
  </div>
</div>

<!-- Loading state -->
<div aria-busy="true" aria-live="polite">
  <span class="spinner" aria-hidden="true"></span>
  Loading content...
</div>

<!-- Expandable section -->
<button aria-expanded="false" aria-controls="details">
  Show details
</button>
<div id="details" hidden>
  Detailed information...
</div>

<!-- Current page indicator -->
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/widgets" aria-current="page">Widgets</a></li>
  </ol>
</nav>
```

**Bad Example:**
```html
<!-- ❌ Empty ARIA attributes -->
<button aria-label="">Submit</button>

<!-- ❌ Redundant ARIA -->
<button role="button">Click me</button>  <!-- button already has implicit role -->

<!-- ❌ ARIA instead of semantic HTML -->
<div role="button" tabindex="0">Click me</div>  <!-- Use <button> instead -->

<!-- ❌ Invalid ARIA values -->
<button aria-pressed="yes">Toggle</button>  <!-- Should be "true" or "false" -->

<!-- ❌ Non-existent ID reference -->
<input aria-labelledby="nonexistent-id">
```

---

### ACC012: Live Regions for Dynamic Content

**Severity:** `medium` | **WCAG:** 4.1.3 (Level AA)

Use ARIA live regions to announce dynamic content changes.

**Good Example:**
```html
<!-- Status messages -->
<div role="status" aria-live="polite" class="visually-hidden" id="status-messages">
  <!-- Messages inserted here will be announced -->
</div>

<!-- Alert messages -->
<div role="alert" aria-live="assertive" id="alert-container">
  <!-- Urgent messages inserted here -->
</div>

<!-- Search results count -->
<div aria-live="polite" aria-atomic="true">
  <span id="results-count">25 results found</span>
</div>
```

```javascript
(function (Drupal) {
  'use strict';

  // Use Drupal.announce for screen reader announcements
  Drupal.behaviors.mymoduleAnnounce = {
    attach: function (context) {
      once('mymodule-save', '.save-button', context).forEach((button) => {
        button.addEventListener('click', async () => {
          try {
            await saveData();
            
            // Polite announcement (waits for current speech)
            Drupal.announce(Drupal.t('Your changes have been saved.'));
            
          } catch (error) {
            // Assertive announcement (interrupts)
            Drupal.announce(
              Drupal.t('Error: Failed to save changes.'),
              'assertive'
            );
          }
        });
      });
    }
  };

})(Drupal);
```

---

## Color and Contrast

### ACC013: Sufficient Color Contrast

**Severity:** `high` | **WCAG:** 1.4.3, 1.4.6 (Level AA/AAA)

Ensure text has sufficient contrast against its background.

**Good Example:**
```css
/* Minimum contrast ratios:
   - Normal text (< 18pt): 4.5:1 (AA), 7:1 (AAA)
   - Large text (≥ 18pt or 14pt bold): 3:1 (AA), 4.5:1 (AAA)
*/

:root {
  /* High contrast color pairs */
  --color-text: #1a1a1a;           /* On white: 16.1:1 */
  --color-text-muted: #595959;     /* On white: 7.0:1 */
  --color-background: #ffffff;
  
  --color-link: #0056b3;           /* On white: 7.2:1 */
  --color-link-hover: #003d80;     /* On white: 11.5:1 */
  
  --color-error: #c41e3a;          /* On white: 6.2:1 */
  --color-success: #1e7e34;        /* On white: 5.9:1 */
}

body {
  color: var(--color-text);
  background-color: var(--color-background);
}

a {
  color: var(--color-link);
}

a:hover,
a:focus {
  color: var(--color-link-hover);
}

/* Error messages with icon, not just color */
.message--error {
  color: var(--color-error);
  border-left: 4px solid var(--color-error);
}

.message--error::before {
  content: "⚠ ";  /* Visual indicator beyond color */
}
```

**Bad Example:**
```css
/* ❌ Insufficient contrast */
body {
  color: #999999;  /* On white: only 2.8:1 */
  background: #ffffff;
}

a {
  color: #6699cc;  /* On white: only 3.0:1 */
}

/* ❌ Relying on color alone */
.error {
  color: red;  /* No other indicator */
}
```

---

### ACC014: Don't Rely on Color Alone

**Severity:** `high` | **WCAG:** 1.4.1 (Level A)

Use additional visual cues beyond color to convey information.

**Good Example:**
```html
<!-- Form validation with icons -->
<div class="form-item form-item--error">
  <label for="email">
    Email
    <span class="icon icon--error" aria-hidden="true">✕</span>
  </label>
  <input type="email" id="email" aria-invalid="true" aria-describedby="email-error">
  <p id="email-error" class="error-message">
    <span class="visually-hidden">Error:</span>
    Please enter a valid email address
  </p>
</div>

<!-- Required fields with asterisk -->
<label for="name">
  Name
  <span class="required" aria-hidden="true">*</span>
  <span class="visually-hidden">(required)</span>
</label>

<!-- Link with underline -->
<style>
  a { text-decoration: underline; }
  a:hover { text-decoration: none; }
</style>

<!-- Charts with patterns -->
<img src="chart.png" alt="Sales chart: Q1 striped pattern $100k, Q2 dotted pattern $150k">
```

---

## Dynamic Content

### ACC015: Accessible Modal Dialogs

**Severity:** `high` | **WCAG:** 2.4.3 (Level A)

Implement modals that are fully accessible.

**Good Example:**
```html
<!-- Modal markup -->
<div class="modal" 
     role="dialog" 
     aria-modal="true"
     aria-labelledby="modal-title"
     aria-describedby="modal-desc"
     hidden>
  <div class="modal__content">
    <h2 id="modal-title">Confirm Action</h2>
    <p id="modal-desc">Are you sure you want to delete this item?</p>
    
    <div class="modal__actions">
      <button type="button" class="modal__confirm">Delete</button>
      <button type="button" class="modal__cancel">Cancel</button>
    </div>
    
    <button type="button" class="modal__close" aria-label="Close dialog">
      <span aria-hidden="true">×</span>
    </button>
  </div>
</div>
```

```javascript
class AccessibleModal {
  constructor(element) {
    this.modal = element;
    this.previouslyFocused = null;
    this.focusableElements = null;
    
    this.bindEvents();
  }

  bindEvents() {
    // Close on Escape
    this.modal.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.close();
      }
    });

    // Close on backdrop click
    this.modal.addEventListener('click', (e) => {
      if (e.target === this.modal) {
        this.close();
      }
    });

    // Close button
    this.modal.querySelector('.modal__close').addEventListener('click', () => {
      this.close();
    });
  }

  open() {
    // Store current focus
    this.previouslyFocused = document.activeElement;
    
    // Show modal
    this.modal.hidden = false;
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden';
    
    // Get focusable elements
    this.focusableElements = this.modal.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    
    // Focus first element
    this.focusableElements[0].focus();
    
    // Trap focus
    this.modal.addEventListener('keydown', this.trapFocus.bind(this));
    
    // Announce to screen readers
    Drupal.announce(Drupal.t('Dialog opened'));
  }

  close() {
    this.modal.hidden = true;
    document.body.style.overflow = '';
    
    // Restore focus
    if (this.previouslyFocused) {
      this.previouslyFocused.focus();
    }
    
    Drupal.announce(Drupal.t('Dialog closed'));
  }

  trapFocus(e) {
    if (e.key !== 'Tab') return;
    
    const first = this.focusableElements[0];
    const last = this.focusableElements[this.focusableElements.length - 1];
    
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  }
}
```

---

## Testing

### ACC016: Automated and Manual Testing

**Severity:** `high`

Test accessibility with both automated tools and manual checks.

**Automated Testing:**
```bash
# Install pa11y for automated testing
npm install -g pa11y

# Test a page
pa11y https://example.com/page

# Test with specific standard
pa11y --standard WCAG2AA https://example.com

# Integrate with CI/CD
pa11y-ci --config .pa11yci.json
```

```json
// .pa11yci.json
{
  "defaults": {
    "standard": "WCAG2AA",
    "timeout": 10000,
    "wait": 500,
    "ignore": [
      "WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail"
    ]
  },
  "urls": [
    "http://localhost:8080/",
    "http://localhost:8080/contact",
    "http://localhost:8080/products"
  ]
}
```

**Manual Testing Checklist:**
```markdown
## Keyboard Navigation
- [ ] All interactive elements focusable with Tab
- [ ] Focus order is logical
- [ ] Focus indicator is visible
- [ ] No keyboard traps
- [ ] Escape closes modals/menus
- [ ] Arrow keys work in menus/tabs

## Screen Reader Testing
- [ ] Page title is descriptive
- [ ] Headings convey structure
- [ ] Images have appropriate alt text
- [ ] Form fields have labels
- [ ] Errors are announced
- [ ] Dynamic content changes announced
- [ ] ARIA labels are clear

## Visual Testing
- [ ] Text contrast ≥ 4.5:1
- [ ] Information not conveyed by color alone
- [ ] Text resizes without breaking layout
- [ ] Focus indicators visible
- [ ] Content visible at 200% zoom

## Content Testing
- [ ] Link text is descriptive
- [ ] Language is set on page
- [ ] Error messages are helpful
- [ ] Instructions are clear
```
