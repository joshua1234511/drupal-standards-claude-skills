# Form API Standards

Standards for building forms using Drupal's Form API (FAPI), including validation, AJAX, and the States API.

## Table of Contents

1. [Form Structure](#form-structure)
2. [Validation](#validation)
3. [Submission](#submission)
4. [AJAX Forms](#ajax-forms)
5. [States API](#states-api)
6. [Config Forms](#config-forms)
7. [Security](#security)

---

## Form Structure

### FORM001: Extend FormBase or ConfigFormBase

**Severity:** `high`

Always extend `FormBase` (or `ConfigFormBase` for settings forms) rather than implementing `FormInterface` directly.

**Good Example:**
```php
namespace Drupal\mymodule\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class MyForm extends FormBase {

  public static function create(ContainerInterface $container): static {
    $instance = parent::create($container);
    // Inject services here.
    return $instance;
  }

  public function getFormId(): string {
    return 'mymodule_my_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $form['name'] = [
      '#type' => 'textfield',
      '#title' => $this->t('Name'),
      '#required' => TRUE,
      '#maxlength' => 255,
      '#description' => $this->t('Enter your full name.'),
    ];

    $form['actions'] = ['#type' => 'actions'];
    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Submit'),
    ];

    return $form;
  }

  public function validateForm(array &$form, FormStateInterface $form_state): void {
    $name = trim($form_state->getValue('name'));
    if (empty($name)) {
      $form_state->setErrorByName('name', $this->t('Name cannot be blank.'));
    }
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->messenger()->addStatus($this->t('Submitted successfully.'));
  }

}
```

---

### FORM002: Use Proper Element Types

**Severity:** `medium`

Choose the correct `#type` for each field. Never use `textfield` for structured data that has a dedicated element type.

| Data Type | Use `#type` |
|-----------|-------------|
| Short text | `textfield` |
| Long text | `textarea` |
| True/false | `checkbox` |
| One of many | `radios` or `select` |
| Many of many | `checkboxes` |
| Date | `date` |
| Email | `email` |
| URL | `url` |
| Number | `number` |
| File upload | `managed_file` |
| Entity reference | `entity_autocomplete` |

---

## Validation

### FORM003: Validate in validateForm()

**Severity:** `high`

Perform all validation in `validateForm()`. Never validate in `submitForm()`.

**Good Example:**
```php
public function validateForm(array &$form, FormStateInterface $form_state): void {
  $email = $form_state->getValue('email');
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $form_state->setErrorByName('email', $this->t('Please enter a valid email address.'));
  }

  $count = (int) $form_state->getValue('item_count');
  if ($count < 1 || $count > 100) {
    $form_state->setErrorByName('item_count', $this->t('Count must be between 1 and 100.'));
  }
}
```

---

## Submission

### FORM004: Use $form_state for Redirects

**Severity:** `medium`

Use `$form_state->setRedirect()` for post-submission redirects. Never use `drupal_goto()` (removed) or header().

**Good Example:**
```php
public function submitForm(array &$form, FormStateInterface $form_state): void {
  // Save data…
  $form_state->setRedirect('mymodule.listing');
}
```

---

## AJAX Forms

### FORM005: Use #ajax Correctly

**Severity:** `medium`

AJAX callbacks must return a render array or `AjaxResponse`. Always specify a `#wrapper` element.

**Good Example:**
```php
$form['category'] = [
  '#type' => 'select',
  '#title' => $this->t('Category'),
  '#options' => $this->getCategories(),
  '#ajax' => [
    'callback' => '::updateSubcategories',
    'wrapper' => 'subcategory-wrapper',
    'event' => 'change',
    'progress' => ['type' => 'throbber'],
  ],
];

$form['subcategory_wrapper'] = [
  '#type' => 'container',
  '#attributes' => ['id' => 'subcategory-wrapper'],
];

// Callback returns the re-rendered wrapper element.
public function updateSubcategories(array &$form, FormStateInterface $form_state): array {
  return $form['subcategory_wrapper'];
}
```

---

## States API

### FORM006: Use #states for Conditional Visibility

**Severity:** `low`

Use the `#states` property rather than custom JavaScript for simple show/hide logic.

**Good Example:**
```php
$form['has_address'] = [
  '#type' => 'checkbox',
  '#title' => $this->t('I have a mailing address'),
];

$form['address'] = [
  '#type' => 'textfield',
  '#title' => $this->t('Address'),
  '#states' => [
    'visible' => [
      ':input[name="has_address"]' => ['checked' => TRUE],
    ],
    'required' => [
      ':input[name="has_address"]' => ['checked' => TRUE],
    ],
  ],
];
```

---

## Config Forms

### FORM007: Extend ConfigFormBase for Settings

**Severity:** `medium`

Use `ConfigFormBase` for any module settings form. It handles config loading/saving automatically.

**Good Example:**
```php
use Drupal\Core\Form\ConfigFormBase;

class MySettingsForm extends ConfigFormBase {

  protected function getEditableConfigNames(): array {
    return ['mymodule.settings'];
  }

  public function getFormId(): string {
    return 'mymodule_settings_form';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    $config = $this->config('mymodule.settings');

    $form['api_key'] = [
      '#type' => 'textfield',
      '#title' => $this->t('API Key'),
      '#default_value' => $config->get('api_key'),
      '#required' => TRUE,
    ];

    return parent::buildForm($form, $form_state);
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    $this->config('mymodule.settings')
      ->set('api_key', $form_state->getValue('api_key'))
      ->save();

    parent::submitForm($form, $form_state);
  }

}
```

---

## Security

### FORM008: CSRF Protection is Automatic

**Severity:** `high`

The Form API includes CSRF protection automatically via form tokens. Do not bypass it with `'#token' => FALSE` unless you have a very specific reason (e.g., embedding a form in a cached block).

**Good Example:**
```php
// ✅ Default: CSRF token included automatically.
public function buildForm(array $form, FormStateInterface $form_state): array {
  // No need to set #token — it's on by default.
  return $form;
}
```

**Bad Example:**
```php
// ❌ Disabling CSRF protection.
$form['#token'] = FALSE;
```
