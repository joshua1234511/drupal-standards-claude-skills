# Security Standards

Critical security standards for Drupal development. **Severity levels: critical, high, medium, low**

## Table of Contents

1. [SQL Injection Prevention](#sql-injection-prevention)
2. [Cross-Site Scripting (XSS) Prevention](#xss-prevention)
3. [Cross-Site Request Forgery (CSRF)](#csrf-protection)
4. [Access Control](#access-control)
5. [File Upload Security](#file-upload-security)
6. [Cryptography & Secrets](#cryptography--secrets)
7. [Server-Side Request Forgery (SSRF)](#ssrf-prevention)
8. [Security Headers](#security-headers)
9. [Authentication & Sessions](#authentication--sessions)
10. [Dependency Management](#dependency-management)
11. [Security Logging](#security-logging)
12. [File Permissions](#file-permissions)

---

## SQL Injection Prevention

### SEC001: Use Parameterized Queries

**Severity:** `critical`

Always use Drupal's Database API with placeholders. Never concatenate user input into SQL strings.

**Good Example:**
```php
// Using Query Builder (preferred)
$results = $this->database->select('users_field_data', 'u')
  ->fields('u', ['uid', 'name', 'mail'])
  ->condition('status', 1)
  ->condition('name', $username)
  ->execute()
  ->fetchAll();

// Using placeholders with query()
$results = $this->database->query(
  "SELECT uid, name FROM {users_field_data} WHERE name = :name AND status = :status",
  [':name' => $username, ':status' => 1]
)->fetchAll();

// Dynamic table names - use Database::escapeTable()
$table = $this->database->escapeTable($userProvidedTable);
$results = $this->database->query("SELECT * FROM {{$table}}");

// LIKE queries with proper escaping
$results = $this->database->select('node_field_data', 'n')
  ->fields('n', ['nid', 'title'])
  ->condition('title', '%' . $this->database->escapeLike($search) . '%', 'LIKE')
  ->execute();
```

**Bad Example:**
```php
// ❌ CRITICAL: Direct concatenation
$results = db_query("SELECT * FROM users WHERE name = '" . $_GET['name'] . "'");

// ❌ CRITICAL: String interpolation
$results = $this->database->query("SELECT * FROM {users} WHERE uid = $uid");

// ❌ CRITICAL: Using format strings
$query = sprintf("SELECT * FROM users WHERE name = '%s'", $name);
```

**References:**
- https://www.drupal.org/docs/security-in-drupal/writing-secure-code-for-drupal
- https://owasp.org/www-community/attacks/SQL_Injection

---

### SEC002: Use Database API for Dynamic Queries

**Severity:** `critical`

Use the Query Builder for complex, dynamic queries to ensure proper escaping.

**Good Example:**
```php
$query = $this->database->select('node_field_data', 'n');
$query->fields('n', ['nid', 'title', 'created']);
$query->join('users_field_data', 'u', 'n.uid = u.uid');
$query->addField('u', 'name', 'author_name');

// Dynamic conditions
if ($type) {
  $query->condition('n.type', $type);
}
if ($status !== NULL) {
  $query->condition('n.status', $status);
}
if ($tags) {
  $query->condition('n.nid', $this->getNodesByTags($tags), 'IN');
}

// Sorting with validation
$allowed_sorts = ['title', 'created', 'changed'];
if (in_array($sort_field, $allowed_sorts, TRUE)) {
  $query->orderBy('n.' . $sort_field, $sort_direction === 'desc' ? 'DESC' : 'ASC');
}

$query->range(0, 50);
$results = $query->execute()->fetchAll();
```

**Bad Example:**
```php
// ❌ Building query strings
$sql = "SELECT * FROM {node} WHERE 1=1";
if ($type) {
  $sql .= " AND type = '$type'";
}
$results = $this->database->query($sql);
```

---

## XSS Prevention

### SEC003: Escape All Output

**Severity:** `critical`

Always escape user-provided content before rendering. Use appropriate Drupal utilities.

**Good Example:**
```php
use Drupal\Component\Utility\Html;
use Drupal\Component\Utility\Xss;
use Drupal\Core\Render\Markup;

// Plain text escaping
$safe_text = Html::escape($user_input);

// HTML with allowed tags
$allowed_html = Xss::filter($user_html);

// Admin-level HTML filtering
$admin_html = Xss::filterAdmin($user_html);

// In render arrays - let Drupal handle escaping
$build['content'] = [
  '#markup' => $this->t('Hello @name', ['@name' => $user_name]), // @ escapes
];

// Placeholders in t()
// @variable - escaped (use for user input)
// %variable - escaped and wrapped in <em> (use for emphasized text)  
// :variable - escaped and suitable for URLs (use in href/src)
$message = $this->t('User @name visited %page at :url', [
  '@name' => $user->getDisplayName(),
  '%page' => $page_title,
  ':url' => $url->toString(),
]);

// When you MUST output raw HTML (pre-sanitized only!)
$pre_sanitized = Markup::create($already_safe_html);
```

**Bad Example:**
```php
// ❌ CRITICAL: Direct output without escaping
print "<div>" . $user_input . "</div>";

// ❌ CRITICAL: Using ! placeholder (passes through unescaped)
$this->t('Welcome !name', ['!name' => $user_input]);

// ❌ CRITICAL: Marking untrusted content as safe
$build['content'] = ['#markup' => Markup::create($user_input)];
```

---

### SEC004: Twig Template Security

**Severity:** `critical`

Twig auto-escapes by default. Never bypass without sanitization.

**Good Example:**
```twig
{# Auto-escaped (safe) #}
<h1>{{ title }}</h1>
<p>{{ node.body.value }}</p>

{# Explicitly escape if needed #}
<div class="{{ class_name|e('html_attr') }}">
  {{ content|e }}
</div>

{# Safe URL output #}
<a href="{{ url|e('url') }}">{{ link_text }}</a>

{# Render pre-sanitized Drupal render arrays #}
{{ content.field_body }}  {# Drupal handles escaping #}

{# Translate with escaping #}
{{ 'Welcome @name'|t({'@name': user.displayname}) }}
```

**Bad Example:**
```twig
{# ❌ CRITICAL: Bypassing auto-escape with user input #}
{{ user_input|raw }}

{# ❌ CRITICAL: Unsafe attribute output #}
<div class="{{ user_class }}">  {# Use |e('html_attr') #}

{# ❌ CRITICAL: Building HTML in Twig #}
{% set html = '<script>' ~ user_input ~ '</script>' %}
{{ html|raw }}
```

---

## CSRF Protection

### SEC005: Use Form API for All User Actions

**Severity:** `critical`

All forms must use Drupal's Form API which includes automatic CSRF token validation.

**Good Example:**
```php
namespace Drupal\mymodule\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;

class SecureActionForm extends FormBase {

  public function getFormId(): string {
    return 'mymodule_secure_action';
  }

  public function buildForm(array $form, FormStateInterface $form_state): array {
    // CSRF token is automatically added
    
    $form['item_id'] = [
      '#type' => 'hidden',
      '#value' => $this->getRouteMatch()->getParameter('item_id'),
    ];

    $form['actions']['submit'] = [
      '#type' => 'submit',
      '#value' => $this->t('Delete item'),
    ];

    return $form;
  }

  public function submitForm(array &$form, FormStateInterface $form_state): void {
    // Safe - CSRF validated before this runs
    $item_id = $form_state->getValue('item_id');
    $this->deleteItem($item_id);
  }
}
```

**Bad Example:**
```php
// ❌ CRITICAL: Action links without CSRF protection
function mymodule_delete_item($item_id) {
  // Anyone can visit /mymodule/delete/123 to delete items!
  $this->entityTypeManager->getStorage('item')->delete([$item_id]);
}

// ❌ CRITICAL: Custom form without token
<form action="/mymodule/action" method="post">
  <input type="hidden" name="action" value="delete">
  <button type="submit">Delete</button>
</form>
```

---

### SEC006: CSRF Tokens for AJAX/API Actions

**Severity:** `high`

Use Drupal's CSRF token service for non-form AJAX actions.

**Good Example:**
```php
// In controller - generate token
use Drupal\Core\Access\CsrfTokenGenerator;

class MyController extends ControllerBase {

  public function __construct(
    protected CsrfTokenGenerator $csrfToken,
  ) {}

  public function ajaxEndpoint(): array {
    return [
      '#attached' => [
        'drupalSettings' => [
          'mymodule' => [
            'csrfToken' => $this->csrfToken->get('mymodule_ajax'),
          ],
        ],
      ],
    ];
  }
}

// In routing.yml with CSRF requirement
mymodule.ajax_action:
  path: '/mymodule/ajax-action'
  defaults:
    _controller: '\Drupal\mymodule\Controller\MyController::ajaxAction'
  requirements:
    _csrf_token: 'TRUE'  # Validates X-CSRF-Token header

// In JavaScript
(function (Drupal, drupalSettings) {
  Drupal.behaviors.mymoduleAjax = {
    attach: function (context, settings) {
      const token = settings.mymodule.csrfToken;
      
      fetch('/mymodule/ajax-action', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token,
        },
        body: JSON.stringify({ action: 'update' }),
      });
    }
  };
})(Drupal, drupalSettings);
```

---

## Access Control

### SEC007: Define Route Access Requirements

**Severity:** `critical`

Every route must have explicit access requirements.

**Good Example:**
```yaml
# mymodule.routing.yml

# Permission-based access
mymodule.admin:
  path: '/admin/mymodule'
  defaults:
    _controller: '\Drupal\mymodule\Controller\AdminController::overview'
    _title: 'My Module Administration'
  requirements:
    _permission: 'administer mymodule'

# Role-based access
mymodule.editor_only:
  path: '/mymodule/editor'
  defaults:
    _controller: '\Drupal\mymodule\Controller\EditorController::dashboard'
  requirements:
    _role: 'editor+administrator'  # + means OR

# Custom access check
mymodule.entity_view:
  path: '/mymodule/entity/{entity}'
  defaults:
    _controller: '\Drupal\mymodule\Controller\EntityController::view'
  requirements:
    _custom_access: '\Drupal\mymodule\Access\EntityAccessCheck::access'
  options:
    parameters:
      entity:
        type: entity:mymodule_entity

# Multiple requirements (AND logic)
mymodule.restricted:
  path: '/mymodule/restricted'
  defaults:
    _controller: '\Drupal\mymodule\Controller\RestrictedController::page'
  requirements:
    _permission: 'access mymodule'
    _custom_access: '\Drupal\mymodule\Access\IpAccessCheck::access'
```

**Bad Example:**
```yaml
# ❌ CRITICAL: No access requirements - publicly accessible!
mymodule.danger:
  path: '/mymodule/admin/delete-all'
  defaults:
    _controller: '\Drupal\mymodule\Controller\DangerController::deleteAll'
```

---

### SEC008: Entity Access Checks

**Severity:** `critical`

Always verify entity access before operations.

**Good Example:**
```php
use Drupal\Core\Access\AccessResult;
use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Session\AccountInterface;

class MyController extends ControllerBase {

  public function viewEntity(EntityInterface $entity): array {
    // Check access - returns 403 if denied
    if (!$entity->access('view')) {
      throw new AccessDeniedHttpException();
    }
    
    return $this->entityTypeManager
      ->getViewBuilder($entity->getEntityTypeId())
      ->view($entity);
  }

  public function editEntity(EntityInterface $entity): array {
    // For edit forms, check 'update' operation
    if (!$entity->access('update')) {
      throw new AccessDeniedHttpException();
    }
    
    return $this->entityFormBuilder()->getForm($entity, 'edit');
  }

  public function deleteEntity(EntityInterface $entity): RedirectResponse {
    // Check delete access
    if (!$entity->access('delete')) {
      throw new AccessDeniedHttpException();
    }
    
    $entity->delete();
    return $this->redirect('<front>');
  }
}

// Custom access handler
class MyEntityAccessControlHandler extends EntityAccessControlHandler {

  protected function checkAccess(EntityInterface $entity, $operation, AccountInterface $account): AccessResult {
    $admin = AccessResult::allowedIfHasPermission($account, 'administer myentity');
    
    if ($admin->isAllowed()) {
      return $admin;
    }

    return match ($operation) {
      'view' => AccessResult::allowedIfHasPermission($account, 'view myentity')
        ->andIf(AccessResult::allowedIf($entity->isPublished())),
      'update' => AccessResult::allowedIf($entity->getOwnerId() === $account->id())
        ->andIf(AccessResult::allowedIfHasPermission($account, 'edit own myentity')),
      'delete' => AccessResult::allowedIf($entity->getOwnerId() === $account->id())
        ->andIf(AccessResult::allowedIfHasPermission($account, 'delete own myentity')),
      default => AccessResult::neutral(),
    };
  }
}
```

**Bad Example:**
```php
// ❌ CRITICAL: Loading entity without access check
public function viewNode($nid) {
  $node = Node::load($nid);
  return node_view($node);  // No access check!
}

// ❌ CRITICAL: Checking wrong operation
if ($entity->access('view')) {
  $entity->delete();  // Should check 'delete', not 'view'!
}
```

---

### SEC009: Use AccessResult Properly

**Severity:** `high`

Use AccessResult methods with proper cacheability metadata.

**Good Example:**
```php
use Drupal\Core\Access\AccessResult;
use Drupal\Core\Access\AccessResultInterface;

class MyAccessCheck implements AccessInterface {

  public function access(AccountInterface $account, NodeInterface $node = NULL): AccessResultInterface {
    // Permission check - cacheable per permissions
    $permission = AccessResult::allowedIfHasPermission($account, 'access content');
    
    // User-specific check - cacheable per user
    $owner = AccessResult::allowedIf($node && $node->getOwnerId() === $account->id())
      ->addCacheContexts(['user'])
      ->addCacheableDependency($node);
    
    // Combine with OR
    $result = $permission->orIf($owner);
    
    // Add cache tags so access is recalculated when node changes
    return $result->addCacheableDependency($node);
  }
}

// Common patterns
AccessResult::allowed();                                    // Always allow
AccessResult::forbidden('Reason for denial');              // Always deny
AccessResult::neutral();                                    // No opinion
AccessResult::allowedIfHasPermission($account, 'perm');    // Permission check
AccessResult::allowedIf($condition);                       // Conditional
AccessResult::forbiddenIf($condition, 'Reason');           // Conditional deny

// Combining
$result->andIf($other);  // Both must allow
$result->orIf($other);   // Either can allow
```

---

## File Upload Security

### SEC010: Validate File Extensions

**Severity:** `critical`

Always validate file extensions and MIME types for uploads.

**Good Example:**
```php
use Drupal\file\FileInterface;
use Drupal\Core\File\FileSystemInterface;

class FileUploadHandler {

  private const ALLOWED_EXTENSIONS = ['pdf', 'doc', 'docx', 'txt'];
  private const ALLOWED_MIMES = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  ];

  public function validateUpload(FileInterface $file): array {
    $errors = [];
    
    // Check extension
    $extension = pathinfo($file->getFilename(), PATHINFO_EXTENSION);
    if (!in_array(strtolower($extension), self::ALLOWED_EXTENSIONS, TRUE)) {
      $errors[] = $this->t('Invalid file extension. Allowed: @extensions', [
        '@extensions' => implode(', ', self::ALLOWED_EXTENSIONS),
      ]);
    }
    
    // Check MIME type (don't trust Content-Type header alone)
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $detected_mime = finfo_file($finfo, $file->getFileUri());
    finfo_close($finfo);
    
    if (!in_array($detected_mime, self::ALLOWED_MIMES, TRUE)) {
      $errors[] = $this->t('Invalid file type detected.');
    }
    
    // Check for double extensions
    if (preg_match('/\.(php|phtml|phar|exe|sh|bat)/i', $file->getFilename())) {
      $errors[] = $this->t('Potentially dangerous file detected.');
    }
    
    // Limit file size
    if ($file->getSize() > 10 * 1024 * 1024) { // 10MB
      $errors[] = $this->t('File exceeds maximum size of 10MB.');
    }
    
    return $errors;
  }
}

// In form build
$form['document'] = [
  '#type' => 'managed_file',
  '#title' => $this->t('Upload document'),
  '#upload_location' => 'private://documents/',  // Use private for sensitive files
  '#upload_validators' => [
    'file_validate_extensions' => ['pdf doc docx txt'],
    'file_validate_size' => [10 * 1024 * 1024],
  ],
];
```

**Bad Example:**
```php
// ❌ CRITICAL: No extension validation
$form['file'] = [
  '#type' => 'managed_file',
  '#upload_location' => 'public://uploads/',  // And public location!
];

// ❌ CRITICAL: Trusting user-provided filename
$filename = $_FILES['upload']['name'];
move_uploaded_file($_FILES['upload']['tmp_name'], "public://$filename");
```

---

### SEC011: Use Private File System for Sensitive Files

**Severity:** `high`

Store sensitive uploads in the private file system.

**Good Example:**
```php
// settings.php
$settings['file_private_path'] = '/var/www/private';

// In form
$form['sensitive_document'] = [
  '#type' => 'managed_file',
  '#upload_location' => 'private://user_documents/' . $this->currentUser()->id(),
  '#upload_validators' => [
    'file_validate_extensions' => ['pdf'],
  ],
];

// Serving private files with access check
function mymodule_file_download($uri) {
  // Check if this is our file
  if (strpos($uri, 'private://user_documents/') !== 0) {
    return NULL;
  }
  
  // Parse user ID from path
  $parts = explode('/', $uri);
  $owner_uid = $parts[3] ?? NULL;
  
  // Check access
  $current_user = \Drupal::currentUser();
  if ($current_user->id() != $owner_uid && !$current_user->hasPermission('administer files')) {
    return -1; // Deny access
  }
  
  // Return file info to allow download
  return [
    'Content-Type' => 'application/pdf',
    'Content-Disposition' => 'attachment',
  ];
}
```

---

## Cryptography & Secrets

### SEC012: Store Secrets in Environment Variables

**Severity:** `critical`

Never commit secrets to code. Use environment variables.

**Good Example:**
```php
// settings.php
$databases['default']['default'] = [
  'driver' => 'mysql',
  'host' => getenv('DB_HOST') ?: 'localhost',
  'database' => getenv('DB_NAME') ?: 'drupal',
  'username' => getenv('DB_USER') ?: 'drupal',
  'password' => getenv('DB_PASS'),  // Required from env
];

// API keys
$config['mymodule.settings']['api_key'] = getenv('MYMODULE_API_KEY');

// Or use Key module
$key_value = \Drupal::service('key.repository')->getKey('api_key')->getKeyValue();

// In .env file (not committed)
DB_PASS=secure_password_here
MYMODULE_API_KEY=sk_live_xxxxx

// In .gitignore
.env
.env.local
settings.local.php
```

**Bad Example:**
```php
// ❌ CRITICAL: Hardcoded credentials
$databases['default']['default']['password'] = 'production_password123';

// ❌ CRITICAL: API key in code
$api_key = 'sk_live_1234567890abcdef';
```

---

### SEC013: Use Proper Hashing

**Severity:** `high`

Use appropriate hashing algorithms for different purposes.

**Good Example:**
```php
use Drupal\Core\Password\PasswordInterface;

// Password hashing - use Drupal's service
class AuthService {

  public function __construct(
    protected PasswordInterface $passwordHasher,
  ) {}

  public function setPassword(UserInterface $user, string $password): void {
    // Uses bcrypt/argon2 internally
    $user->setPassword($password);
    $user->save();
  }

  public function verifyPassword(string $password, string $hash): bool {
    return $this->passwordHasher->check($password, $hash);
  }
}

// Non-password data hashing
$data_hash = hash('sha256', $sensitive_data);

// HMAC for data integrity
$secret_key = \Drupal::service('key.repository')->getKey('hmac_key')->getKeyValue();
$hmac = hash_hmac('sha256', $data, $secret_key);

// Token generation
$token = Crypt::randomBytesBase64(32);
```

**Bad Example:**
```php
// ❌ CRITICAL: MD5 for passwords
$hash = md5($password);

// ❌ CRITICAL: Weak hashing
$hash = sha1($password);

// ❌ CRITICAL: No salt
$hash = hash('sha256', $password);
```

---

## SSRF Prevention

### SEC014: Validate External URLs

**Severity:** `high`

Validate and restrict URLs before making HTTP requests.

**Good Example:**
```php
use Drupal\Component\Utility\UrlHelper;
use GuzzleHttp\ClientInterface;

class ExternalApiClient {

  private const ALLOWED_HOSTS = [
    'api.example.com',
    'cdn.example.com',
  ];

  public function __construct(
    protected ClientInterface $httpClient,
  ) {}

  public function fetchUrl(string $url): ?string {
    // Validate URL format
    if (!UrlHelper::isValid($url, TRUE)) {
      throw new \InvalidArgumentException('Invalid URL format');
    }

    // Parse and validate host
    $parsed = parse_url($url);
    $host = $parsed['host'] ?? '';
    
    // Allowlist check
    if (!in_array($host, self::ALLOWED_HOSTS, TRUE)) {
      throw new \InvalidArgumentException('Host not allowed');
    }
    
    // Block internal/private IPs
    $ip = gethostbyname($host);
    if ($this->isPrivateIp($ip)) {
      throw new \InvalidArgumentException('Internal addresses not allowed');
    }

    // Make request with timeout
    try {
      $response = $this->httpClient->request('GET', $url, [
        'timeout' => 10,
        'allow_redirects' => ['max' => 3],
      ]);
      return (string) $response->getBody();
    }
    catch (\Exception $e) {
      $this->logger->error('External request failed: @message', ['@message' => $e->getMessage()]);
      return NULL;
    }
  }

  private function isPrivateIp(string $ip): bool {
    return filter_var($ip, FILTER_VALIDATE_IP, 
      FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) === FALSE;
  }
}
```

---

## Security Headers

### SEC015: Configure Security Headers

**Severity:** `high`

Set proper security headers in settings.php or .htaccess.

**Good Example:**
```php
// settings.php
$settings['x_frame_options'] = 'SAMEORIGIN';

// Or in .htaccess / nginx config
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' cdn.example.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' api.example.com"

// Trusted host patterns (prevent host header injection)
$settings['trusted_host_patterns'] = [
  '^www\.example\.com$',
  '^example\.com$',
];
```

---

## Authentication & Sessions

### SEC016: Secure Session Configuration

**Severity:** `high`

Configure secure session handling.

**Good Example:**
```php
// settings.php

// Force HTTPS
$settings['https'] = TRUE;

// Secure cookie settings
ini_set('session.cookie_secure', TRUE);
ini_set('session.cookie_httponly', TRUE);
ini_set('session.cookie_samesite', 'Strict');

// Session timeout (in seconds)
ini_set('session.gc_maxlifetime', 1800); // 30 minutes

// Use strict session mode
ini_set('session.use_strict_mode', TRUE);

// Regenerate session ID on privilege escalation
function mymodule_user_login(UserInterface $account) {
  // Drupal does this automatically, but for custom auth:
  \Drupal::service('session_manager')->regenerate();
}
```

---

## Dependency Management

### SEC017: Keep Dependencies Updated

**Severity:** `high`

Regularly update Drupal core and contributed modules.

**Good Example:**
```bash
# composer.json - require security advisories package
{
  "require-dev": {
    "drupal/core-security-advisories": "^10"
  }
}

# Check for security updates
composer audit

# Update Drupal core
composer update drupal/core "drupal/core-*" --with-all-dependencies

# Check for Drupal security updates
drush pm:security

# Automated security monitoring
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

---

## Security Logging

### SEC018: Log Security Events

**Severity:** `high`

Log authentication and authorization events for audit trails.

**Good Example:**
```php
use Drupal\Core\Logger\LoggerChannelInterface;

class SecurityAuditLogger {

  public function __construct(
    protected LoggerChannelInterface $logger,
  ) {}

  public function logLogin(AccountInterface $account, Request $request): void {
    $this->logger->info('User login: @name (uid: @uid) from @ip', [
      '@name' => $account->getAccountName(),
      '@uid' => $account->id(),
      '@ip' => $request->getClientIp(),
    ]);
  }

  public function logFailedLogin(string $username, Request $request): void {
    $this->logger->warning('Failed login attempt for @name from @ip', [
      '@name' => $username,
      '@ip' => $request->getClientIp(),
    ]);
  }

  public function logAccessDenied(AccountInterface $account, string $resource): void {
    $this->logger->warning('Access denied: @name attempted to access @resource', [
      '@name' => $account->getAccountName(),
      '@resource' => $resource,
    ]);
  }

  public function logAdminAction(AccountInterface $account, string $action, array $context = []): void {
    $this->logger->notice('Admin action by @name: @action', [
      '@name' => $account->getAccountName(),
      '@action' => $action,
    ] + $context);
  }
}
```

---

## File Permissions

### SEC019: Set Correct File Permissions

**Severity:** `high`

Ensure proper file system permissions.

**Good Example:**
```bash
# Directory permissions
chmod 755 sites/default
chmod 755 sites/default/files

# File permissions
chmod 444 sites/default/settings.php
chmod 444 sites/default/services.yml

# Automated check script
#!/bin/bash
# check_permissions.sh

SETTINGS_PERMS=$(stat -c %a sites/default/settings.php)
if [ "$SETTINGS_PERMS" != "444" ]; then
  echo "WARNING: settings.php should be 444, found $SETTINGS_PERMS"
  exit 1
fi

# Verify with Drush
drush status-report --severity=2
```

```php
// Verify in code
function mymodule_requirements($phase) {
  $requirements = [];
  
  if ($phase === 'runtime') {
    $settings_file = DRUPAL_ROOT . '/sites/default/settings.php';
    $perms = fileperms($settings_file) & 0777;
    
    if ($perms !== 0444) {
      $requirements['settings_permissions'] = [
        'title' => t('Settings.php permissions'),
        'value' => decoct($perms),
        'description' => t('settings.php should have 444 permissions.'),
        'severity' => REQUIREMENT_WARNING,
      ];
    }
  }
  
  return $requirements;
}
```
