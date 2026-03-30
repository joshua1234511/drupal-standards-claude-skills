# Database Standards

Standards for using Drupal's Database API, Schema API, and database migrations.

## Table of Contents

1. [Database API](#database-api)
2. [Parameterized Queries](#parameterized-queries)
3. [Schema API](#schema-api)
4. [Database Updates (hook_update_N)](#database-updates)
5. [Migrations](#migrations)

---

## Database API

### DB001: Use Drupal's Database API

**Severity:** `critical`

Always use Drupal's database abstraction layer. Never use raw PDO, MySQLi, or deprecated `db_*` functions.

**Good Example:**
```php
// Inject the database connection service.
use Drupal\Core\Database\Connection;

class MyService {
  public function __construct(protected Connection $database) {}

  public function getActiveUsers(): array {
    return $this->database->select('users_field_data', 'u')
      ->fields('u', ['uid', 'name', 'mail'])
      ->condition('u.status', 1)
      ->orderBy('u.name')
      ->execute()
      ->fetchAll();
  }
}
```

**Bad Example:**
```php
// ❌ Raw SQL without API.
$result = \PDO::query("SELECT * FROM users WHERE status = 1");

// ❌ Deprecated global function.
$result = db_select('users', 'u')->execute();
```

---

## Parameterized Queries

### DB002: Always Use Parameterized Queries

**Severity:** `critical`

**Never concatenate user input into SQL.** Always use placeholders or the Query Builder to prevent SQL injection.

**Good Example:**
```php
// ✅ Query Builder (preferred).
$query = $this->database->select('node_field_data', 'n')
  ->fields('n', ['nid', 'title'])
  ->condition('n.type', $nodeType)
  ->condition('n.status', 1)
  ->condition('n.uid', $uid);

// ✅ Parameterized raw query (when Query Builder is insufficient).
$result = $this->database->query(
  "SELECT nid, title FROM {node_field_data} WHERE type = :type AND uid = :uid",
  [':type' => $nodeType, ':uid' => $uid]
);
```

**Bad Example:**
```php
// ❌ CRITICAL: SQL injection vulnerability.
$result = $this->database->query(
  "SELECT * FROM {node_field_data} WHERE type = '" . $_GET['type'] . "'"
);
```

---

### DB003: Use Table Placeholders

**Severity:** `high`

Wrap table names in `{}` in raw queries so Drupal can apply the database prefix.

**Good Example:**
```php
$this->database->query("SELECT * FROM {node_field_data} WHERE nid = :nid", [':nid' => $nid]);
```

**Bad Example:**
```php
// ❌ Hard-coded table name breaks prefixed databases.
$this->database->query("SELECT * FROM node_field_data WHERE nid = :nid", [':nid' => $nid]);
```

---

### DB004: Transactions

**Severity:** `high`

Use transactions for operations that must succeed or fail atomically.

**Good Example:**
```php
$transaction = $this->database->startTransaction();
try {
  $this->database->insert('mymodule_records')->fields($data)->execute();
  $this->database->update('mymodule_status')
    ->fields(['processed' => 1])
    ->condition('id', $id)
    ->execute();
  // Transaction commits when $transaction goes out of scope.
}
catch (\Exception $e) {
  $transaction->rollBack();
  throw $e;
}
```

---

## Schema API

### DB005: Define Schema in hook_schema()

**Severity:** `high`

Define custom tables in `hook_schema()` in your `.install` file. Use Drupal's Schema API types, not SQL-specific types.

**Good Example:**
```php
// mymodule.install
function mymodule_schema(): array {
  $schema['mymodule_records'] = [
    'description' => 'Stores mymodule records.',
    'fields' => [
      'id' => [
        'type' => 'serial',
        'unsigned' => TRUE,
        'not null' => TRUE,
        'description' => 'Primary key.',
      ],
      'uid' => [
        'type' => 'int',
        'unsigned' => TRUE,
        'not null' => TRUE,
        'default' => 0,
        'description' => 'The {users}.uid of the owner.',
      ],
      'data' => [
        'type' => 'blob',
        'size' => 'big',
        'not null' => FALSE,
        'description' => 'Serialized data.',
      ],
      'created' => [
        'type' => 'int',
        'not null' => TRUE,
        'default' => 0,
        'description' => 'Unix timestamp when record was created.',
      ],
    ],
    'primary key' => ['id'],
    'indexes' => [
      'uid' => ['uid'],
      'created' => ['created'],
    ],
  ];

  return $schema;
}
```

---

## Database Updates

### DB006: Use hook_update_N() for Schema Changes

**Severity:** `high`

Use numbered update hooks to modify the database schema. Never modify schema outside of these hooks.

**Good Example:**
```php
/**
 * Add 'processed' column to mymodule_records table.
 */
function mymodule_update_10001(): void {
  $spec = [
    'type' => 'int',
    'size' => 'tiny',
    'not null' => TRUE,
    'default' => 0,
    'description' => 'Whether the record has been processed.',
  ];
  \Drupal::database()->schema()->addField('mymodule_records', 'processed', $spec);
}
```

---

## Migrations

### DB007: Use Drupal Migrate API

**Severity:** `medium`

Use the Migrate API (`migrate`, `migrate_drupal`) for data migrations. Do not write one-off PHP scripts that directly manipulate tables.

**Good Example:**
```yaml
# config/install/migrate_plus.migration.mymodule_import.yml
id: mymodule_import
label: 'Import mymodule records'
source:
  plugin: csv
  path: 'public://import/records.csv'
  ids:
    - id
process:
  field_title: title
  field_body/value: body
  uid:
    plugin: default_value
    default_value: 1
destination:
  plugin: 'entity:node'
  default_bundle: article
```
