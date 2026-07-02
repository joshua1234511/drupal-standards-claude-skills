# Accessibility Standards

Web accessibility standards for Drupal following WCAG 2.2 guidelines. Ensure your site is usable by everyone, including people with disabilities.

Accessibility in Drupal has Drupal-specific idioms that differ from generic web advice: the Form API generates ARIA associations for you, the theme system ships opinionated hiding utilities, `Drupal.announce()` replaces hand-rolled `aria-live` regions, and the testing story is shifting from Nightwatch to Playwright plus Axe-core in PHPUnit. Prefer these idioms over hand-written ARIA — default web-accessibility advice frequently steers you away from the Drupal way.

**Conformance baseline: WCAG 2.2 AA.** Do not regress to WCAG 2.1 reasoning unless explicitly asked. SC 2.5.8 *Target Size (Minimum)* is new in 2.2 and frequently missed.

## Table of Contents

1. [Images and Media](#images-and-media)
2. [Forms and Inputs](#forms-and-inputs)
3. [Navigation and Focus](#navigation-and-focus)
4. [Semantic HTML](#semantic-html)
5. [ARIA Usage](#aria-usage)
6. [Color and Contrast](#color-and-contrast)
7. [Dynamic Content](#dynamic-content)
8. [Render API and Form API Accessibility](#render-api-and-form-api-accessibility)
9. [Theme Layer Accessibility (Twig and CSS)](#theme-layer-accessibility-twig-and-css)
10. [Testing](#testing)
11. [Accessibility QA and Issue Authoring](#accessibility-qa-and-issue-authoring)

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

> **Drupal note:** Prefer rendering images through a render array (`#theme => 'image'`, or a field render array) rather than hand-writing `<img>` tags in Twig. Render elements enforce `#alt` and apply the theme layer automatically. See [ACC017](#acc017-image-render-elements-require-alt) for the Render API rule and [ACC029](#acc029-image-alt-in-twig-mirrors-the-render-api-rule) for the Twig equivalent when a render array is unavailable.

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

> **Drupal note:** In Form API, always supply `#title`. When the visible label is redundant in context (a search field next to a "Search" button), use `#title_display => 'invisible'` — never replace `#title` with `#attributes['aria-label']`. See [ACC018](#acc018-form-elements-use-title-and-description-not-hand-rolled-aria).

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

> **Drupal note:** For AJAX form submissions that surface inline validation errors, move focus to the first error server-side with `FocusCommand` rather than a client-side `element.focus()`. See [ACC027](#acc027-return-focus-after-ajax-with-focuscommand).

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

> **Drupal note:** `#description_display` defaults to `'after'`. Use `'before'` when the description is instruction the user needs *before* answering (format requirements, password rules). Do not fold the description into `#title` to make it more prominent — that breaks the label/description distinction in the accessibility tree.

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

> **Drupal note:** For non-modal widgets that must constrain Tab focus to a sub-tree (mega-menu, off-canvas tray, date picker), use `Drupal.tabbingManager` rather than hand-rolled `keydown` trapping. See [ACC028](#acc028-constrain-focus-with-drupaltabbingmanager-not-hand-rolled-traps).

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

> **Drupal note:** The hand-rolled focus trap above is illustrative. In real Drupal code, prefer `Drupal.dialog` for modals — it traps focus, sets `aria-modal="true"`, focuses the first element on open, and restores focus on close for you. See [ACC026](#acc026-build-modals-with-drupaldialog). Use `:focus-visible` (not `:focus`) so the ring only appears for keyboard users, and never strip the outline without a high-contrast replacement (WCAG 2.2 SC 2.4.13).

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

> **Drupal note:** In Drupal themes, implement skip links with core's `.visually-hidden.focusable` utility (hidden until it receives keyboard focus) rather than hand-rolled positioning CSS. On a `<nav>`/`<main>`/`<aside>` element, `role` is redundant — use `aria-label` only to disambiguate when more than one of the same landmark appears on the page. See [ACC024](#acc024-hide-content-with-the-right-drupal-utility) and [ACC021](#acc021-semantic-html-comes-from-the-render-api-no-redundant-roles).

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

> **Drupal note:** Generate these semantic elements via the Render API rather than hand-writing them. `#type => 'item_list'` produces a real `<ul>`, `#type => 'table'` a `<table>` with `<caption>` and `<th scope>`, `#type => 'link'` an `<a>` with `#url` validation. Hand-rolling them as `#markup` strings loses the semantics, translation, sanitisation, and cache metadata. See [ACC022](#acc022-never-put-interactive-elements-in-markup).

---

## ARIA Usage

### ACC011: Use ARIA Correctly

**Severity:** `high` | **WCAG:** 4.1.2 (Level A)

Use ARIA attributes correctly to enhance accessibility, not replace semantic HTML. Reach for native HTML5 elements before any ARIA role, state, or property — ARIA exists to fill gaps in HTML, not to repeat it.

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

<!-- ❌ Redundant roles that just restate the element -->
<nav role="navigation">...</nav>
<main role="main">...</main>
<ul role="list">...</ul>
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

> **Drupal note:** In Drupal, **do not hand-roll your own `<div aria-live>` region.** Core ships a single shared, polite live region via the `Drupal.announce()` API. A hand-rolled region conflicts with it, races the polite queue, and frequently announces the wrong thing. See [ACC025](#acc025-announce-changes-with-drupalannounce-not-hand-rolled-aria-live).

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

> **Drupal note:** Contrast must hold in **every** colour mode the theme supports — light, dark, and forced colours. Define colours as CSS custom properties and switch the token values inside `prefers-color-scheme: dark`. See [ACC031](#acc031-support-light-dark-and-forced-colour-modes).

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

> **Drupal note:** The hand-built modal above shows the required contract, but in a Drupal context you should reach for `Drupal.dialog` / `Drupal.dialog.ajax` first — it provides the focus trap, `aria-modal="true"`, initial focus, focus return, and Escape behaviour out of the box. Only hand-build a modal when the issue queue has accepted that core dialog cannot be used, and document why. See [ACC026](#acc026-build-modals-with-drupaldialog).

---

## Render API and Form API Accessibility

These standards apply anywhere `#type`, `#title`, `#theme`, or `#markup` appears in PHP — `*Form.php` classes, hook implementations in `*.module`/`*.inc`, controllers returning render arrays, and preprocess hooks. Most Drupal accessibility regressions originate here because agents reach for hand-written HTML and ARIA before checking whether Form API would have produced the right markup automatically.

### ACC017: Image Render Elements Require `#alt`

**Severity:** `high` | **WCAG:** 1.1.1 (Level A)

Every image render element must declare `#alt` — there is no implicit default. Meaningful images get translated alt text; decorative images use an empty string.

**Good Example:**
```php
$build['hero'] = [
  '#theme' => 'image',
  '#uri' => 'public://campaign/banner.jpg',
  '#alt' => $this->t('Volunteers planting trees on the riverbank.'),
];

// Decorative image with a text equivalent nearby — empty alt is required, not optional.
$build['decoration'] = [
  '#theme' => 'image',
  '#uri' => 'public://decor/swirl.svg',
  '#alt' => '',
];
```

**Bad Example:**
```php
// ❌ Missing #alt key
$build['hero'] = [
  '#theme' => 'image',
  '#uri' => 'public://campaign/banner.jpg',
];

// ❌ #alt => NULL, or alt that repeats the filename
$build['hero']['#alt'] = NULL;
$build['hero']['#alt'] = 'banner.jpg';
```

Alt text generated by a model without a human-in-the-loop check on a public-facing image is also a violation — see [ACC039](#acc039-disclose-ai-assistance-on-accessibility-artefacts).

---

### ACC018: Form Elements Use `#title` and `#description`, Not Hand-Rolled ARIA

**Severity:** `high` | **WCAG:** 1.3.1, 3.3.2 (Level A)

Form API generates the `<label for>` association, `aria-describedby`, and required-field indicators automatically when you supply the right keys. Do not write those attributes by hand — they duplicate or conflict with Form API output.

**Good Example:**
```php
$form['email'] = [
  '#type' => 'email',
  '#title' => $this->t('Your email address'),
  '#description' => $this->t('We will only use this to send order receipts.'),
  '#required' => TRUE,
];

// Redundant visible label — keep it in the a11y tree, hide it visually.
$form['search'] = [
  '#type' => 'search',
  '#title' => $this->t('Search'),
  '#title_display' => 'invisible',
];

// Instruction the user needs *before* answering.
$form['password'] = [
  '#type' => 'password',
  '#title' => $this->t('Password'),
  '#description' => $this->t('At least 8 characters, one uppercase letter, one number.'),
  '#description_display' => 'before',
];
```

**Bad Example:**
```php
// ❌ aria-label replaces the visible label — hides it from sighted keyboard users
$form['search'] = [
  '#type' => 'search',
  '#attributes' => ['aria-label' => $this->t('Search')],
];

// ❌ Hand-rolled aria-describedby duplicates what #description does correctly
$form['email'] = [
  '#type' => 'email',
  '#title' => $this->t('Email'),
  '#attributes' => ['aria-describedby' => 'email-help'],
];

// ❌ Description folded into the title
$form['email']['#title'] = $this->t('Email — we only use this for receipts');
```

---

### ACC019: Group Related Controls with `fieldset` or `details`

**Severity:** `high` | **WCAG:** 1.3.1, 3.3.2 (Level A)

Related radios and checkboxes need a programmatic group with a legend. Use `#type => 'fieldset'` (or `'details'` when collapsible) — the `<legend>` is the only thing assistive tech reliably treats as the group label.

**Good Example:**
```php
$form['shipping'] = [
  '#type' => 'fieldset',
  '#title' => $this->t('Shipping speed'),
  'speed' => [
    '#type' => 'radios',
    '#title' => $this->t('Choose a shipping speed'),
    '#title_display' => 'invisible',
    '#options' => [
      'standard' => $this->t('Standard (5–7 days)'),
      'express' => $this->t('Express (2 days)'),
    ],
  ],
];

// Collapsible group — native <details><summary>, correct keyboard/SR behaviour built in.
$form['advanced'] = [
  '#type' => 'details',
  '#title' => $this->t('Advanced options'),
  '#open' => FALSE,
];
```

**Bad Example:**
```php
// ❌ Standalone radios with no enclosing fieldset — individual labels are not a group label
$form['speed'] = [
  '#type' => 'radios',
  '#title' => $this->t('Shipping speed'),
  '#options' => [...],
];
```

```twig
{# ❌ Grouping with a div and a heading instead of a fieldset/legend #}
<div class="group">
  <h3>Shipping speed</h3>
  {{ radios }}
</div>
```

---

### ACC020: Use `#type => 'table'` for Data Tables

**Severity:** `high` | **WCAG:** 1.3.1 (Level A)

Drupal's table render element generates `<th scope="col">`, wraps rows in `<thead>`/`<tbody>`, renders `#caption` as `<caption>`, and shows `#empty` when there are no rows. Reach for it before any other approach.

**Good Example:**
```php
$build['orders'] = [
  '#type' => 'table',
  '#caption' => $this->t('Open orders for @user', ['@user' => $account->getDisplayName()]),
  '#header' => [
    $this->t('Order'),
    $this->t('Placed'),
    $this->t('Status'),
  ],
  '#rows' => $rows,
  '#empty' => $this->t('You have no open orders.'),
];

// Row-header cell renders as <th scope="row">.
$rows[] = [
  ['data' => $order_label, 'header' => TRUE],
  $placed,
  $status,
];
```

**Bad Example:**
```php
// ❌ Table built as a #markup string — loses <caption>, scope, and the empty state
$build['orders'] = [
  '#markup' => '<table><tr><td>' . $order . '</td></tr></table>',
];
```

For drag-and-drop reorderable rows, use `#tabledrag`; do not hand-build sort handles.

---

### ACC021: Semantic HTML Comes from the Render API — No Redundant Roles

**Severity:** `medium` | **WCAG:** 4.1.2 (Level A)

When you need a list, heading, navigation block, table, or link, find the Drupal `#type` or `#theme` first. Do not add `role` attributes that just restate the element Drupal already generated.

**Good Example:**
```php
$build['links'] = [
  '#theme' => 'item_list',
  '#items' => [
    $this->t('First'),
    $this->t('Second'),
  ],
];

$build['cta'] = [
  '#type' => 'link',
  '#title' => $this->t('Go to cart'),
  '#url' => Url::fromRoute('commerce_cart.page'),
];
```

**Bad Example:**
```php
// ❌ role="list" on a #type list, role="button" on a link/button
$build['links'] = [
  '#theme' => 'item_list',
  '#items' => [...],
  '#attributes' => ['role' => 'list'],
];
```

---

### ACC022: Never Put Interactive Elements in `#markup`

**Severity:** `high` | **WCAG:** 4.1.2 (Level A)

`#markup` (and `#prefix`/`#suffix`) is for inert content. The moment your string contains a `<button>`, `<a href>`, `<input>`, `<select>`, `<details>`, or any focusable element, switch to a render array. Interactive HTML in `#markup` bypasses Drupal's attribute system, theme layer, and escaper.

**Good Example:**
```php
$build['cta'] = [
  '#type' => 'link',
  '#title' => $this->t('Go to cart'),
  '#url' => Url::fromRoute('commerce_cart.page'),
  '#attributes' => ['class' => ['button']],
];
```

**Bad Example:**
```php
// ❌ Interactive markup as a string — the #1 source of "buttons that are actually divs"
$build['cta'] = [
  '#markup' => '<a href="/cart" class="button">' . $this->t('Go to cart') . '</a>',
];
```

---

### ACC023: Hide Form Elements with `#access`, Not CSS or `#states`

**Severity:** `high` | **WCAG:** 1.3.1, 4.1.2 (Level A)

To hide a form element from the current user, set `#access => FALSE`. CSS (`display:none`, `.hidden`, `#attributes['style']`) removes the element visually but leaves it in the accessibility tree, where assistive tech still encounters it. `#access => FALSE` removes it from the DOM and the accessibility tree, and prevents the value from being submitted.

`#states` wires user-driven progressive disclosure but hides with CSS (`display:none`) under the hood — hidden elements *remain in the accessibility tree* and can still receive focus. Use `#states` for user-driven show/hide; use `#access` for permission-based or unconditional hiding. Do not mix the two on the same element.

**Good Example:**
```php
// Permission-based hiding — removed from DOM and a11y tree.
$form['internal_id'] = [
  '#type' => 'hidden',
  '#value' => $entity->id(),
  '#access' => $this->currentUser()->hasPermission('administer content'),
];

// Progressive disclosure driven by user input — #states is correct here.
$form['opt_in'] = [
  '#type' => 'checkbox',
  '#title' => $this->t('I want email updates'),
];
$form['email_frequency'] = [
  '#type' => 'select',
  '#title' => $this->t('How often?'),
  '#options' => ['daily' => $this->t('Daily'), 'weekly' => $this->t('Weekly')],
  '#states' => [
    'visible' => [':input[name="opt_in"]' => ['checked' => TRUE]],
  ],
];
```

**Bad Example:**
```php
// ❌ Hiding a permission-gated field with CSS — still in the a11y tree, still submittable
$form['internal_id'] = [
  '#type' => 'hidden',
  '#value' => $entity->id(),
  '#attributes' => ['style' => 'display:none'],
];

// ❌ Using #states for something that should be unconditionally inaccessible
$form['secret'] = [
  '#type' => 'textfield',
  '#states' => ['visible' => [':input[name="never"]' => ['checked' => TRUE]]],
];
```

For an entire fieldset, set `#access` on the container — one flag hides the group and all children correctly.

---

## Theme Layer Accessibility (Twig and CSS)

These standards apply to browser-facing markup and styles — `*.html.twig`, `*.css`, `*.pcss`, `*.scss`, library declarations, and layout/region definitions. Drupal ships explicit utilities for most of this and they are not interchangeable; pick the wrong one and assistive tech either announces hidden content or skips visible content.

### ACC024: Hide Content with the Right Drupal Utility

**Severity:** `high` | **WCAG:** 1.3.1, 4.1.2 (Level A)

Drupal's [hide-content-properly](https://www.drupal.org/docs/getting-started/accessibility/hide-content-properly) utilities are the most misapplied accessibility tool in AI-generated theme code. Each has a specific meaning:

| Utility | Sighted users | Assistive tech | Use for |
|---|---|---|---|
| `.visually-hidden` | hidden | visible | Skip-link text, off-screen labels, SR-only context |
| `.visually-hidden.focusable` | visible on focus | visible | Skip links that appear when a keyboard user tabs to them |
| `.hidden` / `[hidden]` | hidden | hidden | Content that should not be perceived at all in this state |
| `aria-hidden="true"` | visible | hidden | Decorative content next to a text label (rarely correct) |
| `.js-show` / `.js-hide` + `@media (scripting)` | progressive enhancement | — | Content that should only appear when JS runs |

Core ships these classes — **do not redefine `.visually-hidden`, `.hidden`, `.js-show`, or `.js-hide` in theme CSS.** Redefinition causes drift across themes.

**Good Example:**
```css
/* Progressive enhancement: assume no scripting by default. */
.js-show { display: none; }
.js-hide { display: block; }

@media (scripting: enabled) {
  .js-show { display: block; }
  .js-hide { display: none; }
}
```

```twig
{# Icon-only button — visually-hidden label, icon hidden from AT #}
<button type="button">
  <svg aria-hidden="true" focusable="false"><use href="#icon-cart"/></svg>
  <span class="visually-hidden">{{ 'View cart'|t }}</span>
</button>
```

**Bad Example:**
```html
<!-- ❌ aria-hidden on a focusable element creates a "ghost" focus the SR can't describe -->
<a href="/cart" aria-hidden="true">Cart</a>

<!-- ❌ Toggling display:none and expecting the screen reader to notice the change -->
```

From a render array, prefer the `[hidden]` HTML attribute over the `.hidden` class: `'#attributes' => ['hidden' => TRUE]`. Do not toggle `.js-show`/`.js-hide` by adding a `.js-enabled` class to `<html>` from `Drupal.behaviors` — the `@media (scripting)` query handles it without a flash of incorrect content.

---

### ACC030: Meet Target Size (Minimum) — 24×24 CSS px

**Severity:** `high` | **WCAG:** 2.5.8 (Level AA)

SC 2.5.8 is new in WCAG 2.2 and frequently missed. Every pointer/touch target — buttons, menu links, icon-only controls, tabs, pagination, form toggles — must occupy at least **24×24 CSS pixels** of hit area, unless a spec exception applies (inline links inside a paragraph, default user-agent controls, or targets whose centres are ≥24 px apart).

What matters is the clickable region, not the visible glyph. Use padding to expand the hit area without enlarging the visual element.

**Good Example:**
```css
.toolbar__icon-button {
  /* The icon is 16×16, but the button hit area is 24×24. */
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 24px;
  min-height: 24px;
  padding: 4px;
}
```

**Bad Example:**
```css
/* ❌ A 16×16 icon button with no padding — hit area below the 24×24 minimum */
.icon-button {
  width: 16px;
  height: 16px;
}
```

When stacking targets vertically (menu items, tag lists), either give each a 24×24 hit area or ensure 24 px between target centres. Do not regress to the 44×44 of WCAG 2.1 SC 2.5.5 — that is a separate, stricter AAA criterion, not a substitute.

---

### ACC031: Support Light, Dark, and Forced-Colour Modes

**Severity:** `high` | **WCAG:** 1.4.3, 1.4.11 (Level AA)

Core themes (Olivero, Claro) increasingly support dark mode and forced colours. New theme CSS must work in light, dark, and the user's forced-colours palette. Contrast must hold in every mode, not just the one you designed in.

**Good Example:**
```css
:root {
  --color-text:       #1a1a1a;
  --color-background: #ffffff;
  --color-link:       #0066cc;
  --color-focus:      #004499;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-text:       #e8e8e8;
    --color-background: #1a1a1a;
    --color-link:       #66aaff;
    --color-focus:      #99ccff;
  }
}

/* Forced colours (Windows High Contrast): use system colour keywords. */
@media (forced-colors: active) {
  .card         { border: 1px solid CanvasText; }
  :focus-visible { outline: 2px solid Highlight; outline-offset: 2px; }
}
```

```twig
{# SVG icons inherit the active text colour in both modes #}
<svg fill="currentColor" aria-hidden="true" focusable="false"><use href="#icon-star"/></svg>
```

**Bad Example:**
```css
/* ❌ Absolute light-mode zebra stripes on a dark page — excessive luminance contrast */
tr:nth-child(even) { background: #f2f2f2; }

/* ❌ Baking the icon colour into the SVG so it can't adapt to the mode */
.icon { fill: #333; }
```

Define zebra stripes relative to the background (a 5–10% step) and switch the tokens with the rest of the theme. In forced-colours mode stripes vanish, so add a row border (`border-bottom: 1px solid CanvasText`) so the table stays scannable.

---

### ACC032: Keep Focus Visible and Honour Reduced Motion

**Severity:** `high` | **WCAG:** 2.4.7, 2.4.13, 2.3.3 (Level AA)

Use `:focus-visible` (not `:focus`) and never strip the outline without a replacement that meets 3:1 contrast in both light and dark modes (SC 2.4.7, SC 2.4.13). Gate transitions, animations, and transforms behind `prefers-reduced-motion` — vestibular disorders are not an edge case.

**Good Example:**
```css
:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

@media (prefers-reduced-motion: no-preference) {
  .card { transition: transform 200ms ease; }
  .card:hover { transform: translateY(-4px); }
}
```

**Bad Example:**
```css
/* ❌ Killing the outline with no :focus-visible replacement */
:focus { outline: 0; }
button:focus { outline: none; }

/* ❌ Animating unconditionally, ignoring the user's reduced-motion preference */
.card { transition: transform 200ms ease; }
```

---

### ACC033: Use the `Attribute` Object and Native Semantics in Twig

**Severity:** `medium` | **WCAG:** 4.1.2 (Level A)

When the server already produced a `<nav>`, `<main>`, `<button>`, `<ul>`, `<table>`, or `<details>`, the template's job is to place it, not re-decorate it with ARIA. Twig is where AI output most often adds `role="navigation"` to a `<nav>` or `role="button"` to a `<button>`. Use Drupal's `Attribute` object so classes and ARIA states merge correctly across preprocess hooks and overrides — do not rebuild `attributes.toString()` by hand.

**Good Example:**
```twig
{# Native semantics; the Render API emits a real button #}
<nav aria-label="{{ 'Main'|t }}">
  {{ button }}
</nav>

<article{{ attributes.addClass('node', 'node--' ~ node.bundle) }}>
  {{ content }}
</article>
```

**Bad Example:**
```twig
{# ❌ Redundant role and a fake button #}
<nav role="navigation" aria-label="{{ 'Main'|t }}">
  <div role="button" tabindex="0" onclick="...">{{ 'Open'|t }}</div>
</nav>
```

`aria-label` on a landmark is appropriate only when more than one of the same landmark exists on the page — it disambiguates; `role` should not be restated.

---

### ACC034: Accessible Tables in Twig

**Severity:** `high` | **WCAG:** 1.3.1 (Level A)

Prefer `{{ table }}` from a `#type => 'table'` render element (see [ACC020](#acc020-use-type--table-for-data-tables)) so the Render API handles `<caption>`, `<th scope>`, `<thead>`/`<tbody>`, and the empty state. When a template genuinely must emit `<table>` markup (external data, custom layouts the Render API cannot model), the non-negotiables are: `<caption>` as the first child, `<th>` with explicit `scope` on every header cell, and `<thead>`/`<tbody>` present.

**Good Example:**
```twig
{# Wrap wide tables in a keyboard-scrollable region so zoomed users can pan #}
<div role="region"
     aria-labelledby="{{ table_id }}-caption"
     tabindex="0"
     class="table-responsive">
  <table>
    <caption id="{{ table_id }}-caption">{{ caption|t }}</caption>
    <thead>
      <tr><th scope="col">{{ 'Month'|t }}</th><th scope="col">{{ 'Revenue'|t }}</th></tr>
    </thead>
    <tbody>{# … #}</tbody>
  </table>
</div>
```

**Bad Example:**
```twig
{# ❌ No caption, no scope, no thead/tbody #}
<table>
  <tr><td>Month</td><td>Revenue</td></tr>
</table>

{# ❌ Column sort implemented with a div + click handler instead of a <button> in the <th> #}
```

Put `aria-sort` (`ascending`/`descending`/`none`) on the currently-sorted `<th>`; Views output already does this. Never use tables for layout — if a legacy template must, mark it `role="presentation"` and ensure the content linearises without CSS.

---

### ACC035: SVG Icons Adjacent to Text Are Decorative

**Severity:** `medium` | **WCAG:** 1.1.1, 4.1.2 (Level A)

When an SVG icon appears next to a visible text label (button, menu link, tab), the icon is decorative and must be hidden from assistive tech with `aria-hidden="true"` so the screen reader announces the text label once, not "icon-name [pause] label". When the icon is the *only* label, `aria-hidden` on the button would strip its accessible name — provide a `.visually-hidden` label or `aria-label` instead.

**Good Example:**
```twig
{# Icon + visible label — icon is decorative #}
<button type="button">
  <svg aria-hidden="true" focusable="false"><use href="#icon-cart"/></svg>
  {{ 'View cart'|t }}
</button>

{# Icon-only button — provide an accessible name #}
<button type="button" aria-label="{{ 'View cart'|t }}">
  <svg aria-hidden="true" focusable="false"><use href="#icon-cart"/></svg>
</button>
```

**Bad Example:**
```twig
{# ❌ aria-hidden on an icon-only button strips its only accessible name #}
<button type="button" aria-hidden="true">
  <svg><use href="#icon-cart"/></svg>
</button>
```

Also set `focusable="false"` on the `<svg>` — some older rendering engines placed SVGs in the tab order.

---

### ACC036: Reflect Visual State with `aria-current` and `aria-expanded` in Templates

**Severity:** `medium` | **WCAG:** 4.1.2 (Level A)

Some ARIA states belong in templates because they reflect visual state the server knows about. Use `aria-current` for the active item in a navigation set, and `aria-expanded` on the *trigger* (a `<button>` or `<summary>`, never the panel) of a disclosure widget.

**Good Example:**
```twig
{# Current page in a menu #}
<a href="{{ url }}" {{ item.in_active_trail ? 'aria-current="page"' : '' }}>
  {{ item.title }}
</a>

{# Disclosure trigger #}
<button type="button"
        aria-expanded="{{ is_open ? 'true' : 'false' }}"
        aria-controls="{{ panel_id }}">
  {{ label }}
</button>
<div id="{{ panel_id }}" {{ is_open ? '' : 'hidden' }}>{{ content }}</div>
```

**Bad Example:**
```twig
{# ❌ A static aria-expanded that never changes when the user interacts —
   worse than no attribute at all. Toggle it in JS on interaction. #}
<button aria-expanded="false" aria-controls="panel">{{ label }}</button>
```

---

## Dynamic Content (Drupal JavaScript, AJAX, and Focus)

These standards apply to JavaScript shipped to Drupal pages (`*.js`, behaviours, AJAX commands, modal/dialog code). Prefer Drupal's runtime APIs over hand-rolled ARIA — they produce correct, tested output.

### ACC025: Announce Changes with `Drupal.announce()`, Not Hand-Rolled `aria-live`

**Severity:** `medium` | **WCAG:** 4.1.3 (Level AA)

Core ships a single shared, polite live region via `Drupal.announce()`. Use it for any state change a sighted user sees but a screen-reader user would otherwise miss — AJAX content loaded, filters applied, validation errors revealed, items added to a cart. A hand-rolled `<div aria-live>` conflicts with the core region, races the polite queue, and frequently announces the wrong thing.

**Good Example:**
```javascript
((Drupal, once) => {
  Drupal.behaviors.cartUpdate = {
    attach(context) {
      once('cart-update', '[data-cart-add]', context).forEach((el) => {
        el.addEventListener('click', () => {
          // Polite: queues behind anything the user is currently reading.
          Drupal.announce(Drupal.t('Item added to your cart.'));
        });
      });
    },
  };
})(Drupal, once);

// Assertive only for genuinely time-critical information.
Drupal.announce(Drupal.t('Your session will expire in 1 minute.'), 'assertive');
```

**Bad Example:**
```javascript
// ❌ Hand-rolled live region conflicts with Drupal's shared one
const region = document.createElement('div');
region.setAttribute('aria-live', 'polite');
document.body.appendChild(region);
region.textContent = 'Item added.';
```

Do not call `Drupal.announce()` to narrate every UI event the user is already seeing and reading — it is for changes the screen reader would otherwise miss, not a play-by-play.

---

### ACC026: Build Modals with `Drupal.dialog`

**Severity:** `high` | **WCAG:** 2.4.3, 2.1.2 (Level A)

Use `Drupal.dialog` / `Drupal.dialog.ajax` for modal content. It traps Tab/Shift+Tab inside the dialog, sets `aria-modal="true"`, moves focus to the first focusable element on open, returns focus to the trigger on close, and closes on Escape. Do not build a modal from a `<div>` plus your own `keydown` handler unless the issue queue has accepted that core dialog cannot be used — and if you must, replicate the full focus contract explicitly and document why.

**Good Example:**
```javascript
const dialog = Drupal.dialog(content, {
  title: Drupal.t('Confirm deletion'),
  dialogClass: 'confirm-dialog',
  modal: true,
});
dialog.showModal();
```

**Bad Example:**
```javascript
// ❌ A div-based modal with no focus trap, no focus return, no aria-modal, no Escape
const modal = document.querySelector('.my-modal');
modal.style.display = 'block';
```

---

### ACC027: Return Focus After AJAX with `FocusCommand`

**Severity:** `high` | **WCAG:** 2.4.3 (Level A)

When an AJAX command replaces the element the user just interacted with (a "Load more" button replaced by loaded content, an inline-edit form swapped for the saved value), the rebuilt DOM must place focus somewhere meaningful — usually the new equivalent of the trigger, otherwise the page heading or the containing landmark. Use core's `FocusCommand` rather than a client-side `element.focus()`, so refocusing happens after the command queue settles.

**Good Example:**
```php
use Drupal\Core\Ajax\FocusCommand;

// In an AJAX response, move focus to the rebuilt element.
$response->addCommand(new FocusCommand('.commerce-cart-form'));

// AJAX form error — move focus to the first error so SR users know validation failed.
$response->addCommand(new FocusCommand('[data-drupal-selector="edit-email"].error'));
```

When only a client-side handler is available, use the `drupalAjaxSuccess` event:
```javascript
document.addEventListener('drupalAjaxSuccess', function onSuccess(e) {
  document.removeEventListener('drupalAjaxSuccess', onSuccess);
  const newItem = document.querySelector('[data-new-item]');
  if (newItem) { newItem.focus(); }
});
```

**Bad Example:**
```javascript
// ❌ "Load more" disappears with no focus return — keyboard users are stranded on <body>.
// This is the single most common AJAX a11y regression.
button.addEventListener('click', () => { button.remove(); loadMore(); });
```

---

### ACC028: Constrain Focus with `Drupal.tabbingManager`, Not Hand-Rolled Traps

**Severity:** `medium` | **WCAG:** 2.1.2 (Level A)

When a complex non-modal widget (mega-menu, date picker, off-canvas tray) must constrain Tab focus to a sub-tree, use `Drupal.tabbingManager`. It manages a stack of tabbable sets so multiple widgets can coexist without clobbering each other's focus contract. Hand-rolled `keydown` + `tabIndex` trapping breaks when more than one widget is open at once.

**Good Example:**
```javascript
// Restrict Tab to the off-canvas tray while it is open.
const tabbingContext = Drupal.tabbingManager.constrain($('.off-canvas-tray'));

// Release the constraint when the tray closes.
tabbingContext.release();
```

**Bad Example:**
```javascript
// ❌ Manual tab trap — breaks when a second widget opens simultaneously
tray.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') { /* manual first/last cycling */ }
});
```

---

## Testing

### ACC016: Automated and Manual Testing

**Severity:** `high`

Test accessibility with both automated tools and manual checks. Automated tools catch roughly a **third** of WCAG issues — a passing automated scan is not a fix. Run tools first, then cover what they miss with manual keyboard, screen-reader, zoom, and forced-colours checks.

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
- [ ] Content visible at 200% zoom (400% for SC 1.4.10 reflow)

## Content Testing
- [ ] Link text is descriptive
- [ ] Language is set on page
- [ ] Error messages are helpful
- [ ] Instructions are clear
```

---

### ACC037: Test with Playwright and Axe-core, Not Nightwatch

**Severity:** `high`

Per Drupal core issue [#3553673](https://www.drupal.org/project/drupal/issues/3553673), Nightwatch is being removed. New browser-level accessibility coverage uses Playwright with `@axe-core/playwright`. Do not extend Nightwatch tests; convert them when you touch them. Tag `wcag22aa` so SC 2.5.8 (target size) and SC 2.4.13 (focus appearance) are exercised, and pair every scan with at least one keyboard-flow assertion — Axe alone is not a green light.

No single tool catches everything. Layer them:

| Tool | WCAG rule checks | Announcement quality | CI-ready | Notes |
|---|---|---|---|---|
| `@axe-core/playwright` | ~30% of WCAG | ❌ | ✅ | Start here; structural violations |
| Lighthouse CI | subset of axe | ❌ | ✅ | Quality gate; `minScore: 1` to block on regression |
| Playwright ARIA snapshots | partial | ✅ | ✅ | Validates exact announcement text |
| Guidepup virtual SR | ❌ | ✅ exact | ✅ | Real screen reader in CI, no hardware |

**Good Example:**
```javascript
// tests/playwright/a11y/cart.spec.js
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('cart page has no detectable WCAG 2.2 AA violations', async ({ page }) => {
  await page.goto('/cart');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});

test('Load more returns focus to the rebuilt trigger', async ({ page }) => {
  await page.goto('/news');
  await page.getByRole('button', { name: /load more/i }).click();
  await expect(page.getByRole('button', { name: /load more/i })).toBeFocused();
});
```

Use `getByRole` semantic queries rather than CSS selectors — they mirror how AT navigates and fail loudly when semantics break.

**Bad Example:**
```javascript
// ❌ Axe with no keyboard-flow assertion — a passing scan is not a fix
test('page is accessible', async ({ page }) => {
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations.length).toBe(0);
});

// ❌ Extending Nightwatch coverage for new tests (it is being removed)
```

---

### ACC038: Scan Every Colour Mode; Validate Announcements

**Severity:** `medium`

Axe rules that depend on colour (notably `color-contrast`) only inspect what the browser renders. A theme that supports dark mode needs Axe scans in **both** modes, plus a forced-colours pass when the visual change is in scope. Use Playwright's `emulateMedia` inside a single spec rather than three separate files. When a ticket says "the screen reader announces the wrong text", Axe will not catch it — use Playwright ARIA snapshots (`toMatchAriaSnapshot`) or Guidepup's virtual screen reader.

**Good Example:**
```javascript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

for (const colorScheme of ['light', 'dark']) {
  test(`cart page passes WCAG 2.2 AA (${colorScheme})`, async ({ page }) => {
    await page.emulateMedia({ colorScheme });
    await page.goto('/cart');
    const results = await new AxeBuilder({ page })
      .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
      .analyze();
    expect(results.violations).toEqual([]);
  });
}

test('cart survives forced-colours mode', async ({ page }) => {
  await page.emulateMedia({ forcedColors: 'active' });
  await page.goto('/cart');
  await page.getByRole('button', { name: /checkout/i }).focus();
  await expect(page.getByRole('button', { name: /checkout/i }))
    .toHaveCSS('outline-style', /(?!none).+/);
});

test('accordion announces expanded state', async ({ page }) => {
  await page.goto('/faq');
  const accordion = page.getByRole('button', { name: /What is Haven/ });
  await expect(accordion).toMatchAriaSnapshot(`- button "What is Haven" [expanded=false]`);
  await accordion.click();
  await expect(accordion).toMatchAriaSnapshot(`- button "What is Haven" [expanded=true]`);
});
```

When the theme does not yet support dark mode, write the dark-mode test anyway and mark it `test.fixme()` against the tracking issue, so the gap shows in the output rather than being silently skipped.

Per core issue [#3338664](https://www.drupal.org/project/drupal/issues/3338664), render-array output should be scanned inside PHPUnit — this catches markup regressions earlier than a full Playwright run:

```php
#[RunTestsInSeparateProcesses]
class TeaserAccessibilityTest extends KernelTestBase {
  use AxeRenderArrayTrait; // Proposed in #3338664; check status if unavailable.

  public function testTeaserRendersWithoutAxeViolations(): void {
    $build = [
      '#theme' => 'my_module_teaser',
      '#title' => $this->t('Volunteer day'),
    ];
    $this->assertAxeClean($build, ['wcag2a', 'wcag2aa', 'wcag22aa']);
  }
}
```

**Shift-left layers** (each cheaper than the next): **pre-commit** (under 30s on changed files — `stylelint-a11y`, `twig-cs-fixer`, a grep for banned strings like `aria-live=`, `<div role="button"`, `extends NightwatchTestBase`, `outline:\s*0` without a `:focus-visible` companion) → **MR CI gate** (PHPUnit Axe trait + Playwright colour-mode suite + `pa11y-ci`) → **scheduled** (nightly full-site Axe crawl, Lighthouse budgets) → **manual** (rotating human SR/high-contrast/keyboard walk). Pre-commit and MR layers fail the build; scheduled scans file issues, they do not block deploys.

---

## Accessibility QA and Issue Authoring

These standards govern accessibility issues on drupal.org, MR descriptions, and change records.

### ACC039: Disclose AI Assistance on Accessibility Artefacts

**Severity:** `high`

Any issue, MR, or change record where an AI tool contributed must disclose it, name a human reviewer, and map findings to specific WCAG success criteria. AI-generated alt text, patches, and issue text are acceptable as a starting point but must be human-reviewed before they ship.

**Required block (verbatim):**
```
**AI disclosure**

This contribution was prepared with assistance from an AI coding tool.
- Tool: <tool name and version, e.g. Claude Code>
- Used for: <specific tasks, e.g. drafting the patch, generating tests, drafting this issue>
- Reviewed by: <human reviewer's drupal.org username>
- Skills loaded: drupal-accessibility (sub-skills: <comma-separated list>)
```

The reviewed-by line is required before the issue is posted. When drafting before a reviewer is known, use `- Reviewed by: [pending — assign before posting]` as a placeholder and do not post until it names a real drupal.org username.

---

### ACC040: Tools First, Then Manual, AI Last — Structured Issue Reports

**Severity:** `high`

Follow a strict detection order. Automated tools (`@axe-core/playwright`, Lighthouse CI, pa11y-ci) run **first, every time** — they produce stable rule IDs and CSS selectors and are the authoritative source of truth for whether a fix worked. Manual AT testing covers what tools miss (focus order, announcement quality, reflow). AI code review is **last** and is a hypothesis, not a detection method: never file an issue based solely on AI inspection of markup or PHP.

Every issue opens with a structured field block. Required fields:

- **Bug ID** — a stable `[PREFIX]-[8-char hex]` (e.g. `DRP-` core, `DRPC-<short>` contrib). Two levels: `instance_id` (page path + CSS selector + rule ID + screen type) and `pattern_id` (CSS selector + rule ID + screen type, the deduplication key). Hash the CSS selector from `axe-core` `node.target`, not XPath.
- **URL** — full, including query and fragment.
- **XPath (simplified) and full DOM path.**
- **WCAG SC** — number, name, and level, with a link to the W3C Understanding doc. **One issue, one criterion** — a PR fixing three SCs is three issues, linked via *Related issues*.
- **Rule** — tool name/version and the flagged rule ID (`target-size`, `button-name`).
- **Severity** — Critical (cannot complete a core task) / High (blocks a key workflow) / Medium (workaround exists) / Low (minimal impact). Frequency amplifies severity.
- **Frequency** — "N instances on this page; M of P pages affected." **Deduplicate before filing** — file one issue with a count, not 200 identical `image-alt` issues.
- **Screen type and colour mode** — desktop/mobile and light/dark; both feed the hash.
- **HTML snippet** — minimal failing fragment, captured at scan time.

**Reproducible scan command + Definition of Done.** Every automated finding includes the exact command to re-run it (with `@axe-core/playwright`, `@playwright/test` versions and the `withTags` array), plus this checklist:
```
- [ ] Run the verification scan command above against the patched site
- [ ] Confirm the rule ID no longer appears in axe output for this page
- [ ] Confirm no new violations introduced on the same page
- [ ] Manual AT check completed (if the issue was originally manual)
```

**Other requirements.** Name affected disability groups specifically ("keyboard-only users", "NVDA users", "low-vision users at 200% zoom") — generic "users with disabilities" is not enough. Include AT/browser pairs when the issue depends on AT (NVDA+Chrome, JAWS+Edge, VoiceOver+Safari, TalkBack+Chrome, or "keyboard only"); write `AT: n/a (keyboard only)` rather than leaving it blank. Mark axe `incomplete` results `Confidence: Needs manual confirmation` until a human verifies them. Cite the sub-skill whose rule applies in the suggested fix. Manual checks (keyboard walk, SR pass, 200%/400% zoom, forced colours) must pass before RTBC.

**ATAG 2.0 scope.** Drupal's admin interface and content-editor tools are *authoring tools* and must meet [ATAG 2.0](https://www.w3.org/TR/ATAG20/) in addition to WCAG 2.2 AA. When filing against the admin toolbar, node edit forms, CKEditor, or Layout Builder, note whether the issue is a Part A failure (inaccessible authoring UI) or a Part B failure (inaccessible content output) — the fix strategy differs.
