# Testing Standards

Testing standards for Drupal modules covering PHPUnit, Kernel, Functional, and Behat tests.

## Table of Contents

1. [When and What to Test](#when-and-what-to-test)
2. [Choosing the Right Test Type](#choosing-the-right-test-type)
3. [Test Organization](#test-organization)
4. [Unit Tests](#unit-tests)
5. [Kernel Tests](#kernel-tests)
6. [Functional Tests](#functional-tests)
7. [JavaScript Testing](#javascript-testing)
8. [Behat/BDD Testing](#behatbdd-testing)
9. [Test Data and Fixtures](#test-data-and-fixtures)
10. [Mocking and Stubs](#mocking-and-stubs)
11. [Running Tests](#running-tests)

---

## When and What to Test

### TEST010: Cover Bug Fixes and Behaviour Changes with Tests

**Severity:** `high`

A bug fix almost always needs a test. Without one, the same bug can silently
regress later. Behaviour changes almost always need a test as well.
Configuration-only changes usually do not.

- If you are modifying an **existing feature**, find the existing test first and
  update it rather than adding a parallel one.
- If you are adding a **new feature**, write a new test covering the happy path
  and at least the most likely error paths.

**Good Example:**
```php
// Fixing a bug where empty input silently returned []. Add a regression test
// that fails before the fix and passes after it.
public function testProcessRejectsEmptyInput(): void {
  $this->expectException(\InvalidArgumentException::class);
  $this->dataProcessor->process([]);
}
```

**Bad Example:**
```php
// Bug fixed in the service, but no test added. The bug can silently return
// on any future refactor with nothing to catch it.
```

---

## Choosing the Right Test Type

### TEST011: Prefer Functional and Kernel Tests Over Unit Tests

**Severity:** `high`

Drupal has five test types. Reach for **Functional** or **Kernel** first. General
PHP and AI-generated advice frequently suggests Unit tests as the starting point;
in Drupal that advice is usually wrong. Most Drupal code integrates services,
hooks, and entities through the dependency injection container, which makes
integration-level tests far more valuable than heavily mocked unit tests.

| Test type | Base class | Use when |
| --- | --- | --- |
| Functional | `\Drupal\Tests\BrowserTestBase` | **Best default.** Boots a real site, installs modules with config and schema; tests PHP APIs and the UI, HTTP requests, forms, pages. |
| Kernel | `\Drupal\KernelTests\KernelTestBase` | Services, APIs, and hook implementations that do not need a UI. Faster than Functional, but a minimal environment. |
| FunctionalJavascript | `\Drupal\FunctionalJavascriptTests\WebDriverTestBase` | Only when the UI interaction involves JavaScript (AJAX, modals, dynamic visibility). |
| Unit | `\Drupal\Tests\UnitTestCase` | Only for pure functions with **no** container dependencies. Uncommon in Drupal. |
| Build | `\Drupal\BuildTests\Framework\BuildTestBase` | Codebase-layout scenarios such as Composer dependency resolution. Advanced and uncommon. |

**Bad Example:**
```php
// Unit-testing a service that depends on the container. This requires extensive
// mocking that breaks on any refactor. A Kernel test would be simpler and more
// robust here.
class OrderServiceTest extends UnitTestCase {
  public function testPlaceOrder(): void {
    // 40 lines of prophecy mocks for entity type manager, storage, queue,
    // logger, config factory... just to test one integration path.
  }
}
```

---

### TEST012: Declare Required PHPUnit Class Attributes

**Severity:** `high`

Kernel, Functional, and FunctionalJavascript test classes should declare the
`#[RunTestsInSeparateProcesses]` attribute. This became a **hard requirement in
Drupal 11.3** and is strongly recommended on 10.x. Unit tests run in-process and
do not need it.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\mymodule\Kernel;

use Drupal\KernelTests\KernelTestBase;
use PHPUnit\Framework\Attributes\RunTestsInSeparateProcesses;

/**
 * @group mymodule
 */
#[RunTestsInSeparateProcesses]
class DataProcessorKernelTest extends KernelTestBase {
  // ...
}
```

**Bad Example:**
```php
// Missing #[RunTestsInSeparateProcesses]: fails on Drupal 11.3+.
class DataProcessorKernelTest extends KernelTestBase {
  // ...
}
```

---

### TEST013: Use the Exact Test Namespace

**Severity:** `high`

Tests must live in the correct namespace or the test runner will not discover
them. The namespace segment must match the test type exactly, including the
`FunctionalJavascript` capitalisation.

**Good Example:**
```php
namespace Drupal\Tests\mymodule\Unit;                 // Unit
namespace Drupal\Tests\mymodule\Kernel;               // Kernel
namespace Drupal\Tests\mymodule\Functional;           // Functional
namespace Drupal\Tests\mymodule\FunctionalJavascript; // FunctionalJavascript
```

**Bad Example:**
```php
// Wrong capitalisation: test is silently not discovered and never runs.
namespace Drupal\Tests\mymodule\FunctionalJavaScript;
namespace Drupal\Tests\mymodule\Functionaljavascript;
```

---

## Test Organization

### TEST001: Test Directory Structure

**Severity:** `medium`

Organize tests in the proper directory structure.

**Good Example:**
```
modules/custom/mymodule/
├── src/
│   ├── Service/
│   │   └── DataProcessor.php
│   └── Controller/
│       └── MyController.php
├── tests/
│   ├── src/
│   │   ├── Unit/                          # Unit tests
│   │   │   ├── Service/
│   │   │   │   └── DataProcessorTest.php
│   │   │   └── MyModuleUnitTestBase.php   # Base class for unit tests
│   │   ├── Kernel/                        # Kernel tests
│   │   │   ├── Service/
│   │   │   │   └── DataProcessorKernelTest.php
│   │   │   └── MyModuleKernelTestBase.php
│   │   ├── Functional/                    # Functional tests
│   │   │   ├── Controller/
│   │   │   │   └── MyControllerTest.php
│   │   │   └── MyModuleFunctionalTestBase.php
│   │   └── FunctionalJavascript/          # JavaScript tests
│   │       └── MyModuleJsTest.php
│   └── modules/                           # Test-only modules
│       └── mymodule_test/
│           ├── mymodule_test.info.yml
│           └── mymodule_test.module
└── mymodule.info.yml
```

---

### TEST002: Test Class Naming

**Severity:** `medium`

Follow naming conventions for test classes.

**Good Example:**
```php
<?php

// Unit test naming: {ClassName}Test
namespace Drupal\Tests\mymodule\Unit\Service;
class DataProcessorTest extends UnitTestCase {}

// Kernel test naming: {ClassName}Test or {Feature}KernelTest
namespace Drupal\Tests\mymodule\Kernel\Service;
class DataProcessorKernelTest extends KernelTestBase {}

// Functional test naming: {Feature}Test
namespace Drupal\Tests\mymodule\Functional;
class UserRegistrationTest extends BrowserTestBase {}

// JavaScript test naming: {Feature}Test
namespace Drupal\Tests\mymodule\FunctionalJavascript;
class AjaxFormTest extends WebDriverTestBase {}
```

---

## Unit Tests

### TEST003: Writing Unit Tests

**Severity:** `high`

Unit tests should test isolated logic with mocked dependencies.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\mymodule\Unit\Service;

use Drupal\Core\Cache\CacheBackendInterface;
use Drupal\Core\Entity\EntityStorageInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\Core\Logger\LoggerChannelInterface;
use Drupal\mymodule\Service\DataProcessor;
use Drupal\Tests\UnitTestCase;
use Prophecy\Argument;
use Prophecy\PhpUnit\ProphecyTrait;

/**
 * Tests the DataProcessor service.
 *
 * @coversDefaultClass \Drupal\mymodule\Service\DataProcessor
 * @group mymodule
 */
class DataProcessorTest extends UnitTestCase {

  use ProphecyTrait;

  /**
   * The data processor service under test.
   *
   * @var \Drupal\mymodule\Service\DataProcessor
   */
  protected DataProcessor $dataProcessor;

  /**
   * Mock entity type manager.
   *
   * @var \Drupal\Core\Entity\EntityTypeManagerInterface|\Prophecy\Prophecy\ObjectProphecy
   */
  protected $entityTypeManager;

  /**
   * Mock cache backend.
   *
   * @var \Drupal\Core\Cache\CacheBackendInterface|\Prophecy\Prophecy\ObjectProphecy
   */
  protected $cache;

  /**
   * Mock logger.
   *
   * @var \Drupal\Core\Logger\LoggerChannelInterface|\Prophecy\Prophecy\ObjectProphecy
   */
  protected $logger;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    $this->entityTypeManager = $this->prophesize(EntityTypeManagerInterface::class);
    $this->cache = $this->prophesize(CacheBackendInterface::class);
    $this->logger = $this->prophesize(LoggerChannelInterface::class);

    $this->dataProcessor = new DataProcessor(
      $this->entityTypeManager->reveal(),
      $this->cache->reveal(),
      $this->logger->reveal()
    );
  }

  /**
   * Tests process() with valid data.
   *
   * @covers ::process
   */
  public function testProcessWithValidData(): void {
    $input = ['key' => 'value', 'count' => 5];
    $expected = ['key' => 'VALUE', 'count' => 5, 'processed' => TRUE];

    // Cache miss
    $this->cache->get(Argument::any())->willReturn(FALSE);
    $this->cache->set(Argument::any(), Argument::any(), Argument::any(), Argument::any())->shouldBeCalled();

    $result = $this->dataProcessor->process($input);

    $this->assertEquals($expected, $result);
  }

  /**
   * Tests process() returns cached data when available.
   *
   * @covers ::process
   */
  public function testProcessReturnsCachedData(): void {
    $input = ['key' => 'value'];
    $cached_data = ['key' => 'CACHED_VALUE', 'processed' => TRUE];

    // Set up cache hit
    $cache_item = (object) ['data' => $cached_data];
    $this->cache->get(Argument::any())->willReturn($cache_item);

    // Cache set should NOT be called
    $this->cache->set(Argument::any(), Argument::any(), Argument::any(), Argument::any())->shouldNotBeCalled();

    $result = $this->dataProcessor->process($input);

    $this->assertEquals($cached_data, $result);
  }

  /**
   * Tests process() with empty input throws exception.
   *
   * @covers ::process
   */
  public function testProcessWithEmptyInputThrowsException(): void {
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('Input data cannot be empty');

    $this->dataProcessor->process([]);
  }

  /**
   * Tests process() logs errors on failure.
   *
   * @covers ::process
   */
  public function testProcessLogsErrorOnFailure(): void {
    $input = ['invalid' => TRUE];

    $this->cache->get(Argument::any())->willReturn(FALSE);
    
    // Expect error logging
    $this->logger->error(Argument::containingString('Processing failed'), Argument::any())
      ->shouldBeCalled();

    $this->expectException(\RuntimeException::class);
    $this->dataProcessor->process($input);
  }

  /**
   * Data provider for testProcessTransformsValues.
   *
   * @return array
   *   Test cases.
   */
  public static function transformDataProvider(): array {
    return [
      'lowercase string' => [
        ['value' => 'hello'],
        ['value' => 'HELLO', 'processed' => TRUE],
      ],
      'mixed case' => [
        ['value' => 'HeLLo WoRLd'],
        ['value' => 'HELLO WORLD', 'processed' => TRUE],
      ],
      'with numbers' => [
        ['value' => 'test123'],
        ['value' => 'TEST123', 'processed' => TRUE],
      ],
    ];
  }

  /**
   * Tests value transformation.
   *
   * @dataProvider transformDataProvider
   * @covers ::process
   */
  public function testProcessTransformsValues(array $input, array $expected): void {
    $this->cache->get(Argument::any())->willReturn(FALSE);
    $this->cache->set(Argument::any(), Argument::any(), Argument::any(), Argument::any())->shouldBeCalled();

    $result = $this->dataProcessor->process($input);

    $this->assertEquals($expected, $result);
  }

}
```

---

## Kernel Tests

### TEST004: Writing Kernel Tests

**Severity:** `high`

Kernel tests boot a minimal Drupal environment for testing with real services.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\mymodule\Kernel\Service;

use Drupal\KernelTests\KernelTestBase;
use Drupal\mymodule\Service\DataProcessor;
use Drupal\node\Entity\Node;
use Drupal\node\Entity\NodeType;
use Drupal\user\Entity\User;

/**
 * Kernel tests for the DataProcessor service.
 *
 * @coversDefaultClass \Drupal\mymodule\Service\DataProcessor
 * @group mymodule
 */
class DataProcessorKernelTest extends KernelTestBase {

  /**
   * {@inheritdoc}
   */
  protected static $modules = [
    'system',
    'user',
    'node',
    'field',
    'text',
    'filter',
    'mymodule',
  ];

  /**
   * The data processor service.
   *
   * @var \Drupal\mymodule\Service\DataProcessor
   */
  protected DataProcessor $dataProcessor;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    // Install schemas
    $this->installSchema('system', ['sequences']);
    $this->installSchema('node', ['node_access']);
    
    // Install entity schemas
    $this->installEntitySchema('user');
    $this->installEntitySchema('node');
    
    // Install config
    $this->installConfig(['system', 'node', 'filter', 'mymodule']);

    // Create content type
    $this->createContentType(['type' => 'article']);

    // Get service from container
    $this->dataProcessor = $this->container->get('mymodule.data_processor');
  }

  /**
   * Tests processing nodes.
   *
   * @covers ::processNodes
   */
  public function testProcessNodes(): void {
    // Create test user
    $user = User::create([
      'name' => 'test_user',
      'mail' => 'test@example.com',
      'status' => 1,
    ]);
    $user->save();

    // Create test nodes
    $node1 = Node::create([
      'type' => 'article',
      'title' => 'Test Article 1',
      'uid' => $user->id(),
      'status' => 1,
    ]);
    $node1->save();

    $node2 = Node::create([
      'type' => 'article',
      'title' => 'Test Article 2',
      'uid' => $user->id(),
      'status' => 1,
    ]);
    $node2->save();

    // Test processing
    $result = $this->dataProcessor->processNodes(['article']);

    $this->assertCount(2, $result);
    $this->assertEquals('Test Article 1', $result[0]['title']);
    $this->assertEquals('Test Article 2', $result[1]['title']);
  }

  /**
   * Tests database operations.
   *
   * @covers ::saveProcessedData
   */
  public function testSaveProcessedData(): void {
    $data = [
      'key' => 'test_key',
      'value' => 'test_value',
      'timestamp' => time(),
    ];

    $this->dataProcessor->saveProcessedData($data);

    // Verify data was saved
    $database = $this->container->get('database');
    $result = $database->select('mymodule_processed_data', 'm')
      ->fields('m')
      ->condition('key', 'test_key')
      ->execute()
      ->fetchAssoc();

    $this->assertNotEmpty($result);
    $this->assertEquals('test_value', $result['value']);
  }

  /**
   * Tests cache integration.
   *
   * @covers ::process
   */
  public function testCacheIntegration(): void {
    $input = ['type' => 'article'];

    // First call should populate cache
    $result1 = $this->dataProcessor->process($input);

    // Verify cache was set
    $cache = $this->container->get('cache.default');
    $cached = $cache->get('mymodule:processed:' . md5(serialize($input)));
    $this->assertNotFalse($cached);

    // Second call should return cached data
    $result2 = $this->dataProcessor->process($input);
    $this->assertEquals($result1, $result2);
  }

  /**
   * Creates a content type.
   *
   * @param array $values
   *   The values for the content type.
   */
  protected function createContentType(array $values): void {
    $type = NodeType::create($values + [
      'name' => $values['type'],
    ]);
    $type->save();
    node_add_body_field($type);
  }

}
```

---

### TEST014: Explicitly Install Schema and Config in Kernel Tests

**Severity:** `high`

Kernel tests provide a **minimal** environment: no config is installed, no entity
database tables are created, and module dependencies are not resolved
automatically. You must set these up explicitly in `setUp()`. If a Kernel test
throws "table does not exist" or similar errors, a missing install call is almost
always the cause.

**Good Example:**
```php
protected function setUp(): void {
  parent::setUp();

  // Create entity storage tables you rely on.
  $this->installEntitySchema('user');
  $this->installEntitySchema('node');

  // Create module-defined schema tables (e.g. hook_schema()).
  $this->installSchema('node', ['node_access']);

  // Import default config for the listed modules.
  $this->installConfig(['system', 'node', 'filter', 'mymodule']);
}
```

**Bad Example:**
```php
protected function setUp(): void {
  parent::setUp();
  // Assumes tables and config already exist. Node::create()->save() will fail
  // with "Base table or view not found" because no schema was installed.
  $node = Node::create(['type' => 'article', 'title' => 'X']);
  $node->save();
}
```

---

## Functional Tests

### TEST005: Writing Functional Tests

**Severity:** `high`

Functional tests use a full Drupal installation for end-to-end testing.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\mymodule\Functional;

use Drupal\Tests\BrowserTestBase;
use Drupal\node\Entity\Node;

/**
 * Tests the mymodule user interface.
 *
 * @group mymodule
 */
class MyModuleUserInterfaceTest extends BrowserTestBase {

  /**
   * {@inheritdoc}
   */
  protected $defaultTheme = 'stark';

  /**
   * {@inheritdoc}
   */
  protected static $modules = [
    'node',
    'mymodule',
  ];

  /**
   * A user with admin permissions.
   *
   * @var \Drupal\user\UserInterface
   */
  protected $adminUser;

  /**
   * A regular authenticated user.
   *
   * @var \Drupal\user\UserInterface
   */
  protected $authenticatedUser;

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    // Create content type
    $this->drupalCreateContentType(['type' => 'article']);

    // Create users
    $this->adminUser = $this->drupalCreateUser([
      'access administration pages',
      'administer mymodule',
      'create article content',
      'edit any article content',
    ]);

    $this->authenticatedUser = $this->drupalCreateUser([
      'access content',
      'view mymodule content',
    ]);
  }

  /**
   * Tests the settings form.
   */
  public function testSettingsForm(): void {
    // Anonymous user cannot access settings
    $this->drupalGet('/admin/config/mymodule/settings');
    $this->assertSession()->statusCodeEquals(403);

    // Login as admin
    $this->drupalLogin($this->adminUser);

    // Access settings page
    $this->drupalGet('/admin/config/mymodule/settings');
    $this->assertSession()->statusCodeEquals(200);
    $this->assertSession()->pageTextContains('My Module Settings');

    // Test form elements exist
    $this->assertSession()->fieldExists('api_endpoint');
    $this->assertSession()->fieldExists('cache_lifetime');

    // Submit form
    $this->submitForm([
      'api_endpoint' => 'https://api.example.com',
      'cache_lifetime' => '7200',
    ], 'Save configuration');

    // Verify success message
    $this->assertSession()->pageTextContains('The configuration options have been saved.');

    // Verify values were saved
    $config = $this->config('mymodule.settings');
    $this->assertEquals('https://api.example.com', $config->get('api_endpoint'));
    $this->assertEquals(7200, $config->get('cache_lifetime'));
  }

  /**
   * Tests content listing page.
   */
  public function testContentListing(): void {
    // Create test content
    $node1 = $this->drupalCreateNode([
      'type' => 'article',
      'title' => 'First Article',
      'status' => 1,
    ]);

    $node2 = $this->drupalCreateNode([
      'type' => 'article',
      'title' => 'Second Article',
      'status' => 1,
    ]);

    // Login
    $this->drupalLogin($this->authenticatedUser);

    // Visit listing page
    $this->drupalGet('/mymodule/content');
    $this->assertSession()->statusCodeEquals(200);

    // Verify content is displayed
    $this->assertSession()->pageTextContains('First Article');
    $this->assertSession()->pageTextContains('Second Article');

    // Test links
    $this->clickLink('First Article');
    $this->assertSession()->addressEquals('/node/' . $node1->id());
  }

  /**
   * Tests access control.
   */
  public function testAccessControl(): void {
    // Create private content
    $private_node = $this->drupalCreateNode([
      'type' => 'article',
      'title' => 'Private Content',
      'status' => 0,
    ]);

    // Anonymous user cannot view
    $this->drupalGet('/node/' . $private_node->id());
    $this->assertSession()->statusCodeEquals(403);

    // Authenticated user cannot view unpublished
    $this->drupalLogin($this->authenticatedUser);
    $this->drupalGet('/node/' . $private_node->id());
    $this->assertSession()->statusCodeEquals(403);

    // Admin can view
    $this->drupalLogin($this->adminUser);
    $this->drupalGet('/node/' . $private_node->id());
    $this->assertSession()->statusCodeEquals(200);
  }

  /**
   * Tests form validation.
   */
  public function testFormValidation(): void {
    $this->drupalLogin($this->adminUser);
    $this->drupalGet('/admin/config/mymodule/settings');

    // Submit with invalid URL
    $this->submitForm([
      'api_endpoint' => 'not-a-valid-url',
    ], 'Save configuration');

    // Check for validation error
    $this->assertSession()->pageTextContains('Please enter a valid URL');

    // Form should still be on the same page
    $this->assertSession()->addressEquals('/admin/config/mymodule/settings');
  }

}
```

---

### TEST015: Beware the Dual-Container Trap in Functional Tests

**Severity:** `high`

Functional tests run **two separate Drupal instances** that share the same
database but have separate PHP memory spaces: one in the PHPUnit process and one
in the web server that serves the requests. State set in the test process (such
as registering a service, setting a static variable, or overriding a container
parameter) is **not** visible to the web server process, and vice versa. This
causes confusing bugs around caching and service registration.

**Bad Example:**
```php
// Sets a value in the PHPUnit process only. The page request runs in the web
// server process and never sees it.
public function testFeatureFlag(): void {
  \Drupal::state()->set('mymodule.feature_enabled', TRUE);
  $this->drupalGet('/mymodule/feature');
  // Fails intermittently: the served request had its own memory space.
}
```

**Good Example:**
```php
// Persist to the shared database (state API writes to DB), then let the request
// read it. If you must rebuild the container, do it explicitly and comment why.
public function testFeatureFlag(): void {
  // State is DB-backed, so this IS visible to the web server process.
  $this->container->get('state')->set('mymodule.feature_enabled', TRUE);

  // If a change requires the served process to rebuild its container, force it
  // and document the reason for the next reader.
  // Rebuild needed: service definition changed after the site was installed.
  $this->rebuildContainer();

  $this->drupalGet('/mymodule/feature');
  $this->assertSession()->pageTextContains('Feature enabled');
}
```

---

## JavaScript Testing

### TEST006: Writing JavaScript Tests

**Severity:** `medium`

Use WebDriverTestBase for testing JavaScript interactions.

**Good Example:**
```php
<?php

declare(strict_types=1);

namespace Drupal\Tests\mymodule\FunctionalJavascript;

use Drupal\FunctionalJavascriptTests\WebDriverTestBase;

/**
 * Tests JavaScript functionality of mymodule.
 *
 * @group mymodule
 */
class MyModuleJavascriptTest extends WebDriverTestBase {

  /**
   * {@inheritdoc}
   */
  protected $defaultTheme = 'stark';

  /**
   * {@inheritdoc}
   */
  protected static $modules = [
    'node',
    'mymodule',
  ];

  /**
   * {@inheritdoc}
   */
  protected function setUp(): void {
    parent::setUp();

    $this->drupalCreateContentType(['type' => 'article']);
    
    $user = $this->drupalCreateUser([
      'access content',
      'create article content',
    ]);
    $this->drupalLogin($user);
  }

  /**
   * Tests AJAX form submission.
   */
  public function testAjaxFormSubmission(): void {
    $this->drupalGet('/mymodule/ajax-form');

    $page = $this->getSession()->getPage();
    $assert_session = $this->assertSession();

    // Fill in form
    $page->fillField('title', 'Test Title');
    $page->fillField('description', 'Test Description');

    // Click AJAX button
    $page->pressButton('Submit');

    // Wait for AJAX to complete
    $assert_session->assertWaitOnAjaxRequest();

    // Verify success message appeared
    $assert_session->pageTextContains('Form submitted successfully');
    
    // Verify form was reset
    $this->assertEquals('', $page->findField('title')->getValue());
  }

  /**
   * Tests dynamic form elements.
   */
  public function testDynamicFormElements(): void {
    $this->drupalGet('/mymodule/dynamic-form');

    $page = $this->getSession()->getPage();
    $assert_session = $this->assertSession();

    // Initial state - subcategory field should not exist
    $assert_session->fieldNotExists('subcategory');

    // Select category
    $page->selectFieldOption('category', 'electronics');
    $assert_session->assertWaitOnAjaxRequest();

    // Subcategory field should now appear
    $assert_session->fieldExists('subcategory');

    // Verify subcategory options
    $subcategory = $page->findField('subcategory');
    $options = $subcategory->findAll('css', 'option');
    $this->assertCount(4, $options);
  }

  /**
   * Tests autocomplete functionality.
   */
  public function testAutocomplete(): void {
    // Create test nodes for autocomplete
    for ($i = 1; $i <= 5; $i++) {
      $this->drupalCreateNode([
        'type' => 'article',
        'title' => "Test Article $i",
        'status' => 1,
      ]);
    }

    $this->drupalGet('/mymodule/search');

    $page = $this->getSession()->getPage();
    $assert_session = $this->assertSession();

    // Type in autocomplete field
    $autocomplete = $page->findField('search');
    $autocomplete->setValue('Test');

    // Wait for autocomplete suggestions
    $assert_session->waitForElementVisible('css', '.ui-autocomplete');

    // Verify suggestions appear
    $suggestions = $page->findAll('css', '.ui-autocomplete li');
    $this->assertGreaterThan(0, count($suggestions));

    // Click first suggestion
    $suggestions[0]->click();

    // Verify field was populated
    $this->assertStringContainsString('Test Article', $autocomplete->getValue());
  }

  /**
   * Tests modal dialog.
   */
  public function testModalDialog(): void {
    $this->drupalGet('/mymodule/modal-test');

    $page = $this->getSession()->getPage();
    $assert_session = $this->assertSession();

    // Open modal
    $page->pressButton('Open Modal');

    // Wait for modal to appear
    $assert_session->waitForElementVisible('css', '.ui-dialog');

    // Verify modal content
    $modal = $page->find('css', '.ui-dialog');
    $this->assertNotNull($modal);
    $this->assertStringContainsString('Modal Title', $modal->getText());

    // Close modal
    $modal->pressButton('Close');

    // Wait for modal to disappear
    $assert_session->waitForElementRemoved('css', '.ui-dialog');
  }

  /**
   * Tests drag and drop functionality.
   */
  public function testDragAndDrop(): void {
    $this->drupalGet('/mymodule/sortable');

    $page = $this->getSession()->getPage();
    $driver = $this->getSession()->getDriver();

    // Get sortable items
    $items = $page->findAll('css', '.sortable-item');
    $this->assertCount(3, $items);

    // Get initial order
    $initial_order = [];
    foreach ($items as $item) {
      $initial_order[] = $item->getAttribute('data-id');
    }

    // Drag first item to last position
    $source = $items[0];
    $target = $items[2];

    // Perform drag and drop
    $driver->evaluateScript("
      var source = document.querySelector('.sortable-item[data-id=\"{$initial_order[0]}\"]');
      var target = document.querySelector('.sortable-item[data-id=\"{$initial_order[2]}\"]');
      target.parentNode.insertBefore(source, target.nextSibling);
      source.dispatchEvent(new Event('dragend', {bubbles: true}));
    ");

    // Wait for AJAX save
    $this->assertSession()->assertWaitOnAjaxRequest();

    // Verify new order was saved
    $this->assertSession()->pageTextContains('Order saved');
  }

}
```

---

### TEST016: Always Assert the Result of waitForElement

**Severity:** `high`

FunctionalJavascript interactions are asynchronous and prone to flakiness.
`waitForElement()`, `waitForElementVisible()`, and similar methods return `NULL`
when the element never appears. Calling them bare, without asserting the return
value, produces a **false-passing** test that always passes even when the element
never showed up. After pressing a button that triggers AJAX, wait for the
expected element and then assert.

**Bad Example:**
```php
// Does not assert the result. If #page-title never appears, the test still
// passes silently.
$this->assertSession()->waitForElement('css', '#page-title');
```

**Good Example:**
```php
// Waits AND asserts the result, so a missing element fails the test.
$this->assertNotEmpty(
  $this->assertSession()->waitForElement('css', '#page-title')
);

// After an AJAX-triggering action:
$page->pressButton('Save');
$this->assertNotEmpty(
  $this->assertSession()->waitForElementVisible('css', '.messages--status')
);
```

---

### TEST017: Avoid Nightwatch; Prefer PHPUnit JavaScript Tests

**Severity:** `low`

Do not write new Nightwatch tests. They are JavaScript-based, prone to flakiness,
and the Drupal community is moving toward Playwright as the replacement. Use
`WebDriverTestBase` (FunctionalJavascript) for JavaScript coverage today, and
prefer Playwright over Nightwatch where a browser-driven JS runner is required.

---

## Behat/BDD Testing

### TEST007: Writing Behat Tests

**Severity:** `medium`

Use Behat for behavior-driven development and acceptance testing.

**Good Example:**
```gherkin
# features/content_management.feature
@api
Feature: Content Management
  As a content editor
  I want to create and manage articles
  So that I can publish content on the website

  Background:
    Given I am logged in as a user with the "editor" role
    And "article" content:
      | title           | status | created    |
      | Published Post  | 1      | -1 day     |
      | Draft Post      | 0      | -2 days    |

  @javascript
  Scenario: Create a new article with AJAX preview
    When I go to "/node/add/article"
    And I fill in "Title" with "Test Article"
    And I fill in "Body" with "This is the article content."
    And I press "Preview"
    And I wait for AJAX to finish
    Then I should see "Test Article" in the ".node-preview" element
    When I press "Save"
    Then I should see "Article Test Article has been created."

  Scenario: Edit existing content
    Given I am viewing a "article" content:
      | title | My Article |
      | body  | Original content |
    When I click "Edit"
    And I fill in "Title" with "Updated Article"
    And I press "Save"
    Then I should see "Article Updated Article has been updated."

  Scenario: Verify content listing
    When I go to "/admin/content"
    Then I should see "Published Post" in the "table" element
    And I should see "Draft Post" in the "table" element
    And I should see the text "Published" in the "Published Post" row
    And I should see the text "Unpublished" in the "Draft Post" row

  @api
  Scenario: Verify access control
    Given I am an anonymous user
    When I go to "/node/add/article"
    Then the response status code should be 403

  Scenario Outline: Create content with different types
    When I go to "/node/add/<content_type>"
    And I fill in "Title" with "<title>"
    And I press "Save"
    Then I should see "<content_type> <title> has been created."

    Examples:
      | content_type | title          |
      | article      | News Article   |
      | page         | About Page     |
```

**Context Class:**
```php
<?php

// features/bootstrap/MyModuleContext.php

use Behat\Behat\Context\Context;
use Behat\MinkExtension\Context\RawMinkContext;
use Drupal\DrupalExtension\Context\DrupalContext;

/**
 * Custom context for mymodule testing.
 */
class MyModuleContext extends RawMinkContext implements Context {

  /**
   * @Given I wait for AJAX to finish
   */
  public function iWaitForAjaxToFinish(): void {
    $this->getSession()->wait(10000, '(typeof jQuery !== "undefined" && jQuery.active === 0)');
  }

  /**
   * @Then I should see the text :text in the :row row
   */
  public function iShouldSeeTextInRow(string $text, string $row): void {
    $page = $this->getSession()->getPage();
    
    $row_element = $page->find('xpath', "//tr[contains(., '$row')]");
    if (!$row_element) {
      throw new \Exception("Row containing '$row' not found");
    }
    
    if (strpos($row_element->getText(), $text) === FALSE) {
      throw new \Exception("Text '$text' not found in row '$row'");
    }
  }

  /**
   * @Given I fill in the WYSIWYG editor :field with :value
   */
  public function iFillInWysiwygEditor(string $field, string $value): void {
    $this->getSession()->executeScript("
      CKEDITOR.instances['$field'].setData('$value');
    ");
  }

  /**
   * @Then I should see :count items in the :selector element
   */
  public function iShouldSeeItemsInElement(int $count, string $selector): void {
    $page = $this->getSession()->getPage();
    $elements = $page->findAll('css', "$selector > *");
    
    if (count($elements) !== $count) {
      throw new \Exception("Expected $count items, found " . count($elements));
    }
  }

}
```

---

## Test Data and Fixtures

### TEST008: Creating Test Data

**Severity:** `medium`

Use proper methods for creating test data.

**Good Example:**
```php
<?php

namespace Drupal\Tests\mymodule\Traits;

use Drupal\node\Entity\Node;
use Drupal\taxonomy\Entity\Term;
use Drupal\taxonomy\Entity\Vocabulary;
use Drupal\user\Entity\User;

/**
 * Provides methods for creating test content.
 */
trait MyModuleTestTrait {

  /**
   * Creates test articles.
   *
   * @param int $count
   *   Number of articles to create.
   * @param array $defaults
   *   Default values for all articles.
   *
   * @return \Drupal\node\NodeInterface[]
   *   Array of created nodes.
   */
  protected function createTestArticles(int $count, array $defaults = []): array {
    $nodes = [];
    
    for ($i = 1; $i <= $count; $i++) {
      $values = $defaults + [
        'type' => 'article',
        'title' => "Test Article $i",
        'status' => 1,
        'uid' => 1,
      ];
      
      $node = Node::create($values);
      $node->save();
      $nodes[] = $node;
    }
    
    return $nodes;
  }

  /**
   * Creates test taxonomy terms.
   *
   * @param string $vocabulary
   *   Vocabulary machine name.
   * @param array $names
   *   Array of term names.
   *
   * @return \Drupal\taxonomy\TermInterface[]
   *   Array of created terms.
   */
  protected function createTestTerms(string $vocabulary, array $names): array {
    // Ensure vocabulary exists
    if (!Vocabulary::load($vocabulary)) {
      Vocabulary::create([
        'vid' => $vocabulary,
        'name' => ucfirst($vocabulary),
      ])->save();
    }
    
    $terms = [];
    foreach ($names as $name) {
      $term = Term::create([
        'vid' => $vocabulary,
        'name' => $name,
      ]);
      $term->save();
      $terms[] = $term;
    }
    
    return $terms;
  }

  /**
   * Creates a test user with specific roles and permissions.
   *
   * @param array $permissions
   *   Array of permissions.
   * @param array $values
   *   Additional user values.
   *
   * @return \Drupal\user\UserInterface
   *   The created user.
   */
  protected function createTestUser(array $permissions = [], array $values = []): User {
    $values += [
      'name' => $this->randomMachineName(),
      'mail' => $this->randomMachineName() . '@example.com',
      'status' => 1,
    ];
    
    $user = User::create($values);
    
    if (!empty($permissions)) {
      $role = $this->drupalCreateRole($permissions);
      $user->addRole($role);
    }
    
    $user->save();
    
    return $user;
  }

}

// Using the trait in a test
class MyFeatureTest extends BrowserTestBase {
  
  use MyModuleTestTrait;
  
  public function testFeature(): void {
    $articles = $this->createTestArticles(5, ['status' => 1]);
    $terms = $this->createTestTerms('tags', ['PHP', 'Drupal', 'Testing']);
    $editor = $this->createTestUser(['edit any article content']);
    
    // Test with created data...
  }

}
```

---

## Mocking and Stubs

### TEST009: Effective Mocking

**Severity:** `medium`

Use mocking effectively to isolate units under test.

**Good Example:**
```php
<?php

namespace Drupal\Tests\mymodule\Unit;

use Drupal\Core\Entity\EntityStorageInterface;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Drupal\node\NodeInterface;
use Drupal\Tests\UnitTestCase;
use Prophecy\Argument;
use Prophecy\PhpUnit\ProphecyTrait;

class MockingExampleTest extends UnitTestCase {

  use ProphecyTrait;

  /**
   * Tests with Prophecy mocks.
   */
  public function testWithProphecy(): void {
    // Create mock node
    $node = $this->prophesize(NodeInterface::class);
    $node->id()->willReturn(123);
    $node->label()->willReturn('Test Node');
    $node->bundle()->willReturn('article');
    $node->isPublished()->willReturn(TRUE);

    // Mock entity storage
    $storage = $this->prophesize(EntityStorageInterface::class);
    $storage->load(123)->willReturn($node->reveal());
    $storage->loadMultiple([1, 2, 3])->willReturn([
      $node->reveal(),
    ]);

    // Mock with argument matching
    $storage->loadByProperties(Argument::type('array'))
      ->willReturn([$node->reveal()]);

    // Mock with callback
    $storage->create(Argument::any())->will(function ($args) {
      $mock = $this->prophesize(NodeInterface::class);
      $mock->id()->willReturn(999);
      return $mock->reveal();
    });

    // Mock entity type manager
    $entityTypeManager = $this->prophesize(EntityTypeManagerInterface::class);
    $entityTypeManager->getStorage('node')->willReturn($storage->reveal());

    // Use mocks in test
    $storage_instance = $entityTypeManager->reveal()->getStorage('node');
    $loaded_node = $storage_instance->load(123);
    
    $this->assertEquals(123, $loaded_node->id());
    $this->assertEquals('Test Node', $loaded_node->label());
  }

  /**
   * Tests with PHPUnit mocks (alternative approach).
   */
  public function testWithPhpUnitMocks(): void {
    // Create mock
    $node = $this->createMock(NodeInterface::class);
    
    // Configure mock
    $node->method('id')->willReturn(123);
    $node->method('label')->willReturn('Test Node');
    
    // With consecutive returns
    $node->method('isPublished')
      ->willReturnOnConsecutiveCalls(TRUE, FALSE, TRUE);
    
    // With callback
    $node->method('get')
      ->willReturnCallback(function ($field_name) {
        return match ($field_name) {
          'title' => (object) ['value' => 'Test'],
          'status' => (object) ['value' => 1],
          default => NULL,
        };
      });

    // Verify calls
    $node->expects($this->once())
      ->method('save');
    
    $node->expects($this->exactly(2))
      ->method('id');
    
    // Use mock
    $this->assertEquals(123, $node->id());
    $node->id(); // Second call
    $node->save();
  }

  /**
   * Tests verifying method calls with Prophecy.
   */
  public function testVerifyingCalls(): void {
    $service = $this->prophesize(SomeServiceInterface::class);
    
    // Should be called once
    $service->process(Argument::any())->shouldBeCalledOnce();
    
    // Should be called with specific arguments
    $service->save('test_key', Argument::type('array'))
      ->shouldBeCalled();
    
    // Should NOT be called
    $service->delete(Argument::any())->shouldNotBeCalled();
    
    // Should be called specific number of times
    $service->log(Argument::any())->shouldBeCalledTimes(3);

    // Get revealed mock and use it
    $revealed = $service->reveal();
    
    // ... test code that uses $revealed ...
  }

}
```

---

### TEST018: Reduce Repetition with Data Providers and #[TestWith]

**Severity:** `medium`

When you have multiple similar test cases, use `setUp()`, a data provider, or the
`#[TestWith]` attribute rather than copy-pasting near-identical test methods.
Data providers give each case a readable label in the test output; `#[TestWith]`
is convenient for a small number of inline cases.

**Good Example:**
```php
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\TestWith;

// Inline cases with #[TestWith].
#[TestWith(['hello', 'HELLO'])]
#[TestWith(['MiXeD', 'MIXED'])]
#[TestWith(['test123', 'TEST123'])]
public function testUppercase(string $input, string $expected): void {
  $this->assertSame($expected, strtoupper($input));
}

// Larger or labelled cases with a data provider (static, per PHPUnit 10+).
public static function slugProvider(): array {
  return [
    'spaces to dashes' => ['Hello World', 'hello-world'],
    'strips punctuation' => ['A, B & C!', 'a-b-c'],
  ];
}

#[DataProvider('slugProvider')]
public function testSlug(string $input, string $expected): void {
  $this->assertSame($expected, $this->slugger->slug($input));
}
```

**Bad Example:**
```php
// Three copy-pasted methods that differ only by input/expected values.
public function testUppercaseHello(): void {
  $this->assertSame('HELLO', strtoupper('hello'));
}
public function testUppercaseMixed(): void {
  $this->assertSame('MIXED', strtoupper('MiXeD'));
}
public function testUppercaseDigits(): void {
  $this->assertSame('TEST123', strtoupper('test123'));
}
```

---

## Running Tests

### TEST019: Set SIMPLETEST_BASE_URL and SIMPLETEST_DB

**Severity:** `high`

Kernel, Functional, and FunctionalJavascript tests require two environment
variables to be set, or PHPUnit will either fail or silently skip the tests. Run
tests through DDEV (or your local environment) with both defined.

- `SIMPLETEST_BASE_URL`: the local HTTP address of your Drupal site.
- `SIMPLETEST_DB`: the database connection string.

**Good Example:**
```bash
# Inside DDEV, export both then run the tests.
export SIMPLETEST_BASE_URL="http://web"
export SIMPLETEST_DB="mysql://db:db@db/db"

# Run a module's whole test suite.
vendor/bin/phpunit -c web/core web/modules/custom/mymodule

# Run a single group.
vendor/bin/phpunit -c web/core --group mymodule

# Run one test file.
vendor/bin/phpunit -c web/core \
  web/modules/custom/mymodule/tests/src/Kernel/DataProcessorKernelTest.php
```

**Bad Example:**
```bash
# No SIMPLETEST_* variables: Kernel/Functional tests fail to bootstrap or are
# silently skipped, giving a false sense of a passing suite.
vendor/bin/phpunit web/modules/custom/mymodule
```

---

### TEST020: Group Tests with @group / #[Group]

**Severity:** `medium`

Give every test a group so it can be selected with `--group` and included in
targeted CI runs. Use the module machine name as the group, and add a domain
group where useful.

**Good Example:**
```php
use PHPUnit\Framework\Attributes\Group;

#[Group('mymodule')]
class DataProcessorKernelTest extends KernelTestBase {
  // ...
}

// Annotation form (still valid, common in existing code):
/**
 * @group mymodule
 */
class DataProcessorTest extends UnitTestCase {}
```

**Bad Example:**
```php
// No group: the test cannot be selected with --group and is easily missed in
// scoped CI runs.
class DataProcessorKernelTest extends KernelTestBase {}
```
