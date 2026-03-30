# API Development Standards

Standards for building REST APIs, JSON:API usage, and custom resource plugins in Drupal.

## Table of Contents

1. [Entity API](#entity-api)
2. [REST Resource Plugins](#rest-resource-plugins)
3. [JSON:API](#jsonapi)
4. [Authentication](#authentication)
5. [Versioning and Compatibility](#versioning-and-compatibility)
6. [Error Handling](#error-handling)

---

## Entity API

### API001: Use Entity API — Never Raw SQL for Entities

**Severity:** `critical`

Always load, query, and save entities through the Entity API (`EntityTypeManager`). Raw SQL on entity tables bypasses field hooks, access checks, and cache invalidation.

**Good Example:**
```php
use Drupal\Core\Entity\EntityTypeManagerInterface;

class MyService {

  public function __construct(
    protected EntityTypeManagerInterface $entityTypeManager,
  ) {}

  public function getPublishedArticles(): array {
    return $this->entityTypeManager->getStorage('node')
      ->loadByProperties([
        'type' => 'article',
        'status' => 1,
      ]);
  }

  public function createRecord(array $values): EntityInterface {
    $entity = $this->entityTypeManager
      ->getStorage('mymodule_record')
      ->create($values);
    $entity->save();
    return $entity;
  }

}
```

**Bad Example:**
```php
// ❌ Raw SQL on entity tables — bypasses access, hooks, and caching.
$nids = \Drupal::database()->query("SELECT nid FROM {node_field_data} WHERE type = 'article'")->fetchCol();
```

---

### API002: Use Entity Queries for Complex Lookups

**Severity:** `high`

Use `entityTypeManager->getStorage()->getQuery()` for filtered entity lookups. It respects access control and field storage.

**Good Example:**
```php
$query = $this->entityTypeManager->getStorage('node')->getQuery()
  ->condition('type', 'article')
  ->condition('status', 1)
  ->condition('field_category', $categoryId)
  ->sort('created', 'DESC')
  ->range(0, 10)
  ->accessCheck(TRUE); // Always explicitly set access check.

$nids = $query->execute();
$nodes = $this->entityTypeManager->getStorage('node')->loadMultiple($nids);
```

**Bad Example:**
```php
// ❌ Missing explicit access check — security risk in Drupal 10+.
$query = \Drupal::entityQuery('node')->condition('type', 'article');
```

---

## REST Resource Plugins

### API003: Implement REST Resources as Plugins

**Severity:** `high`

Use `@RestResource` annotation plugins for custom REST endpoints. Define supported formats and authentication providers.

**Good Example:**
```php
namespace Drupal\mymodule\Plugin\rest\resource;

use Drupal\rest\Plugin\ResourceBase;
use Drupal\rest\ResourceResponse;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * Provides a REST resource for mymodule records.
 *
 * @RestResource(
 *   id = "mymodule_record",
 *   label = @Translation("MyModule Record"),
 *   uri_paths = {
 *     "canonical" = "/api/mymodule/record/{id}",
 *     "create" = "/api/mymodule/record"
 *   }
 * )
 */
class MyModuleRecordResource extends ResourceBase {

  public function get(int $id): ResourceResponse {
    $record = $this->loadRecord($id);
    if (!$record) {
      throw new NotFoundHttpException("Record $id not found.");
    }
    $response = new ResourceResponse($record);
    $response->addCacheableDependency($record);
    return $response;
  }

  public function post(array $data): ResourceResponse {
    if (empty($data['title'])) {
      throw new BadRequestHttpException('Title is required.');
    }
    $record = $this->createRecord($data);
    return new ResourceResponse($record, 201);
  }

}
```

---

## JSON:API

### API004: Prefer JSON:API for Entity CRUD

**Severity:** `medium`

For standard entity CRUD operations, use Drupal's built-in JSON:API module instead of building custom REST endpoints. JSON:API is enabled by default in Drupal 8.7+ core.

**Endpoint pattern:**
```
GET    /jsonapi/node/article          → List articles
GET    /jsonapi/node/article/{uuid}   → Get single article
POST   /jsonapi/node/article          → Create article
PATCH  /jsonapi/node/article/{uuid}   → Update article
DELETE /jsonapi/node/article/{uuid}   → Delete article
```

**Filtering example:**
```
GET /jsonapi/node/article?filter[status]=1&filter[field_category.id]={uuid}&sort=-created&page[limit]=10
```

---

## Authentication

### API005: Use Proper Authentication Providers

**Severity:** `high`

Always specify supported authentication methods in your REST resource annotation. Never expose API endpoints without authentication unless they are intentionally public.

**Good Example:**
```php
// In your resource, declare auth providers:
// (Configured via REST UI or config/install/rest.resource.*.yml)

# rest.resource.mymodule_record.yml
id: mymodule_record
plugin_id: mymodule_record
granularity: resource
configuration:
  GET:
    supported_formats:
      - json
    supported_auth:
      - basic_auth
      - oauth2
  POST:
    supported_formats:
      - json
    supported_auth:
      - oauth2
```

---

## Versioning and Compatibility

### API006: Version Your Custom APIs

**Severity:** `medium`

Include a version prefix in custom API routes to allow backwards-compatible evolution.

**Good Example:**
```yaml
# mymodule.routing.yml
mymodule.api.v1.records:
  path: '/api/v1/mymodule/records'
  defaults:
    _controller: '\Drupal\mymodule\Controller\ApiController::list'
  requirements:
    _permission: 'access mymodule api'
```

---

## Error Handling

### API007: Use Symfony HTTP Exceptions

**Severity:** `high`

Throw Symfony HTTP exceptions from REST resources so Drupal serializes them correctly for the client.

**Good Example:**
```php
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\UnprocessableEntityHttpException;

// 400
throw new BadRequestHttpException('Missing required field: title.');

// 403
throw new AccessDeniedHttpException('You do not have permission to access this resource.');

// 404
throw new NotFoundHttpException("Record $id does not exist.");

// 422
throw new UnprocessableEntityHttpException('Validation failed: title must be under 255 characters.');
```

**Bad Example:**
```php
// ❌ Returns a 200 with an error payload — not RESTful.
return new ResourceResponse(['error' => 'Not found'], 200);
```
