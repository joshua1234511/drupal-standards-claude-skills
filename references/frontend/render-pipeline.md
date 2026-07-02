# Render Pipeline Standards

Standards for working with Drupal's render pipeline, covering render arrays, render element types, render caching, cacheability metadata and bubbling, lazy builders, BigPipe, theme hooks and preprocessing, attachments, and the flow from controller to response.

## Table of Contents

1. [The Render Pipeline Flow](#the-render-pipeline-flow)
2. [Render Arrays](#render-arrays)
3. [Render Element Types](#render-element-types)
4. [Render Caching](#render-caching)
5. [Cacheability Metadata and Bubbling](#cacheability-metadata-and-bubbling)
6. [Lazy Builders, Placeholders, and BigPipe](#lazy-builders-placeholders-and-bigpipe)
7. [Theme Hooks and Preprocessing](#theme-hooks-and-preprocessing)
8. [Attachments](#attachments)

---

## The Render Pipeline Flow

### RND001: Understand the Render Pipeline Flow

**Severity:** `medium`

HTML output in Drupal flows through a defined pipeline: a controller (or block, field formatter, preprocess) returns a structured render array; the render system resolves render elements and delegates to theme templates; cacheability metadata bubbles up the tree; and the result is wrapped into a response. Understanding this flow explains why bypassing any stage (raw HTML, string concatenation, `Response` objects) silently discards cacheability metadata and breaks caching in production.

**Good Example:**
```php
// Controller returns a render array. Drupal handles theming, caching,
// and the response wrapper for you.
public function view(): array {
  return [
    '#theme' => 'my_report',
    '#items' => $this->loadItems(),
    '#cache' => [
      'tags' => ['node_list'],
      'contexts' => ['user.permissions'],
    ],
  ];
}
```

The stages, in order:

- **Controller / builder** returns a render array (structured data, not HTML).
- **Render system** processes render elements (`#type`, `#theme`), invokes
  preprocess functions, and renders children.
- **Theme layer** maps `#theme` hooks to Twig templates and produces markup.
- **Cacheability** metadata (tags, contexts, max-age) bubbles up the tree.
- **Response** the top-level render array is wrapped into an `HtmlResponse`,
  with attachments (libraries, `<head>` tags) and cache metadata applied.

**Bad Example:**
```php
// ❌ Bypasses the pipeline. No cacheability metadata can be attached;
// the page becomes uncacheable or caches incorrectly.
public function view(): Response {
  $html = '<div class="report">' . $this->buildHtml() . '</div>';
  return new Response($html);
}
```

---

### RND002: Return Render Arrays, Not HTML Strings

**Severity:** `high`

Page controllers that serve HTML must return render arrays, not raw HTML strings or `Response` objects. Render arrays preserve cacheability metadata through the pipeline. Return a `Response` only when intentionally bypassing the render system (JSON endpoints, file downloads) and handling caching yourself. For JSON endpoints, use `CacheableJsonResponse` to attach cache metadata to non-HTML responses.

**Good Example:**
```php
// HTML page: return a render array.
public function myPage(): array {
  return [
    '#theme' => 'my_template',
    '#title' => $this->t('Page title'),
    '#items' => $this->loadItems(),
    '#cache' => [
      'tags' => ['node_list'],
      'contexts' => ['user.permissions'],
    ],
  ];
}

// JSON endpoint: use a cacheable response and attach metadata explicitly.
public function apiData(): CacheableJsonResponse {
  $response = new CacheableJsonResponse($this->loadData());
  $response->addCacheableDependency(
    (new CacheableMetadata())->addCacheTags(['node_list'])
  );
  return $response;
}
```

**Bad Example:**
```php
// ❌ Raw Response from an HTML controller loses all cacheability metadata.
public function myPage(): Response {
  return new Response('<h1>' . $this->getTitle() . '</h1>');
}
```

---

## Render Arrays

### RND003: Structure Output as Render Arrays

**Severity:** `high`

A render array is an associative array of properties (prefixed with `#`) and child elements. Build output as nested render arrays so the render system can process elements, apply theming, and bubble metadata. Do not concatenate HTML into a single `#markup` blob when structured elements are available.

**Good Example:**
```php
$build = [];

$build['heading'] = [
  '#type' => 'html_tag',
  '#tag' => 'h2',
  '#value' => $this->t('Latest articles'),
];

$build['list'] = [
  '#theme' => 'item_list',
  '#items' => $items,
  '#cache' => [
    'tags' => ['node_list'],
  ],
];

return $build;
```

**Bad Example:**
```php
// ❌ Everything crammed into one markup string. Loses structure,
// theming, and per-child cacheability.
$html = '<h2>' . $this->t('Latest articles') . '</h2><ul>';
foreach ($items as $item) {
  $html .= '<li>' . $item . '</li>';
}
$html .= '</ul>';
return ['#markup' => $html];
```

---

## Render Element Types

### RND004: Use the Correct Render Element Type

**Severity:** `high`

Drupal has several render element types that are frequently confused. Choose the one that matches your output, and never use `#markup` for user-generated content.

- **`#theme`**: delegates to a theme template. The standard choice for
  structured output backed by a Twig template.
- **`#type`**: uses a render element plugin (form elements, tables, links,
  `html_tag`, `item_list`).
- **`#markup`**: filtered HTML run through `Xss::filterAdmin()`, which allows a
  limited set of tags. Use only for trusted admin HTML.
- **`#plain_text`**: escaped text. Use for user-generated content that should
  not contain any HTML.
- **`inline_template`** (`#type => 'inline_template'`): renders a Twig snippet
  inline without a separate template file. Use for small dynamic fragments that
  do not warrant a full theme template.

**Good Example:**
```php
// Structured template output.
$build['card'] = [
  '#theme' => 'my_card',
  '#title' => $node->label(),
];

// User content: escaped, no HTML allowed.
$build['comment'] = [
  '#plain_text' => $user_supplied_comment,
];

// Small dynamic fragment without a dedicated template.
$build['badge'] = [
  '#type' => 'inline_template',
  '#template' => '<span class="badge">{{ label }}</span>',
  '#context' => ['label' => $label],
];
```

**Bad Example:**
```php
// ❌ #markup for user content. It allows HTML tags through the filter.
$build['comment'] = ['#markup' => $user_supplied_comment];
```

---

### RND005: Never Bypass the XSS Filter with Markup::create()

**Severity:** `critical`

Values that already implement `MarkupInterface` (from `t()`, `Markup::create()`, etc.) bypass the `Xss::filterAdmin()` filter that `#markup` applies. Do not wrap user input in `Markup::create()` to suppress escaping warnings — this silently defeats the XSS filter and creates a vulnerability.

**Good Example:**
```php
// User content is escaped.
$build['name'] = ['#plain_text' => $user_input];

// Markup::create() only for trusted, pre-sanitized values.
$build['icon'] = ['#markup' => Markup::create($trusted_svg_from_theme)];
```

**Bad Example:**
```php
// ❌ CRITICAL: bypasses Xss::filterAdmin() entirely — XSS vulnerability.
$build['name'] = ['#markup' => Markup::create($user_input)];
```

---

## Render Caching

### RND006: Declare Cache Keys, Contexts, Tags, and Max-Age

**Severity:** `high`

The `#cache` property controls how a render array participates in caching. It has four sub-properties, each with a distinct role.

- **`keys`**: an identifier that makes the render array individually stored in
  the render cache. Without keys, a render array's metadata still bubbles to
  parents, but the array itself is not cached independently.
- **`contexts`**: dimensions of variation (user role, URL, language). If output
  differs by user permission, add `user.permissions`.
- **`tags`**: data dependencies. If output includes node 42, add `node:42`;
  when that node changes, the cache entry is invalidated.
- **`max-age`**: time-based expiration in seconds. Use `0` for uncacheable,
  `Cache::PERMANENT` (`-1`) for no time limit.

**Good Example:**
```php
$build['teaser'] = [
  '#theme' => 'node_teaser',
  '#node' => $node,
  '#cache' => [
    // Individually cacheable under this identity.
    'keys' => ['node_teaser', $node->id()],
    // Varies by these dimensions.
    'contexts' => ['user.permissions', 'languages:language_interface'],
    // Invalidated when the node changes.
    'tags' => ['node:' . $node->id()],
    // No time-based expiry.
    'max-age' => Cache::PERMANENT,
  ],
];
```

**Bad Example:**
```php
// ❌ No cache metadata. Missing tags cause stale content in production;
// missing contexts cause personalization leaks.
$build['teaser'] = [
  '#theme' => 'node_teaser',
  '#node' => $node,
];
```

---

### RND007: Do Not Assume Immediate Physical Eviction on Invalidation

**Severity:** `medium`

Cache tag invalidation is two-phase. When a tag is invalidated (for example, a node is saved), Drupal updates the tag's checksum immediately but does not eagerly delete cached items. On the next read, the stored checksum no longer matches, so the cache returns a miss and the item is regenerated. The stale entry may remain in the backend until overwritten or expired. This is a deliberate performance design: mass invalidation writes one checksum row instead of N deletes.

**Good Example:**
```php
// Correct: rely on the read returning a miss after invalidation.
$node->save(); // Invalidates node:42.
// Next render of anything tagged node:42 regenerates automatically.
```

**Bad Example:**
```php
// ❌ Assumes the cached item is physically gone right after invalidation.
$node->save();
$item = $cache->get($cid);
assert($item === FALSE); // Wrong: the old data may still exist in the backend.
```

---

## Cacheability Metadata and Bubbling

### RND008: Rely on Automatic Bubbling — But Keep the Chain Intact

**Severity:** `high`

Cacheability metadata propagates automatically up the render tree. When a child declares `node:42` as a cache tag, the parent inherits it. This only works when the entire output chain uses render arrays. Bypassing the render system at any level (raw HTML, string concatenation, a `Response`) silently loses metadata from that subtree.

**Good Example:**
```php
// Child declares its dependency; the parent inherits it automatically.
$build['content']['teaser'] = [
  '#theme' => 'node_teaser',
  '#node' => $node,
  '#cache' => ['tags' => ['node:' . $node->id()]],
];
// No need to re-declare node:42 on the parent — it bubbles up.
```

**Bad Example:**
```php
// ❌ Rendering the child to a string breaks the chain. node:42 never
// bubbles to the parent, so the page caches without the dependency.
$build['content']['teaser'] = [
  '#markup' => \Drupal::service('renderer')->render($teaser_build),
];
```

---

### RND009: Use CacheableMetadata for Non-Trivial Merging

**Severity:** `medium`

For non-trivial cache metadata operations — especially merging metadata across render arrays and non-render-array objects (`AccessResult`, config overrides, REST responses) — use the `CacheableMetadata` value object rather than manipulating raw `#cache` array keys. It handles correct merging of tags, contexts, and max-age (including minimum-wins bubbling) and prevents subtle merge bugs.

**Good Example:**
```php
$cache_metadata = CacheableMetadata::createFromRenderArray($build);
$cache_metadata->addCacheTags(['node:42']);
$cache_metadata->addCacheContexts(['user.permissions']);
$cache_metadata->merge(CacheableMetadata::createFromObject($access_result));
$cache_metadata->applyTo($build);
```

**Bad Example:**
```php
// ❌ Manual merging risks losing contexts/tags and mishandling max-age
// when combining with an AccessResult's cacheability.
$build['#cache']['tags'][] = 'node:42';
// AccessResult cacheability silently dropped.
```

---

### RND010: Understand Minimum-Wins Max-Age Bubbling

**Severity:** `high`

Max-age uses minimum-wins bubbling: when a child render array has `max-age: 0`, it propagates up and forces the entire parent — and ultimately the whole page — to be uncacheable. This is why lazy builders exist: without them, a single personalized element with `max-age: 0` makes the whole page uncacheable.

**Good Example:**
```php
// Personalized element isolated behind a lazy builder so its max-age: 0
// does not bubble up and poison the page cache.
$build['greeting'] = [
  '#lazy_builder' => ['my_module.greeting:build', [$account_id]],
  '#create_placeholder' => TRUE,
];
```

**Bad Example:**
```php
// ❌ max-age: 0 bubbles up and makes the entire page uncacheable.
$build['greeting'] = [
  '#markup' => $this->t('Hello, @name', ['@name' => $account->getDisplayName()]),
  '#cache' => ['max-age' => 0],
];
```

---

### RND011: Attach Cacheability Explicitly Where Bubbling Does Not Reach

**Severity:** `high`

Several subsystems require explicit cache metadata attachment; automatic bubbling does not cover them. Missing metadata here causes silent caching bugs where access decisions or overrides are cached without the correct variation.

- **Access results**: `AccessResult` objects carry their own cacheability. An
  access check that varies by permission must declare `user.permissions`.
- **Config overrides**: config override classes must declare the contexts and
  tags their overrides depend on.
- **Entity translations**: runtime language-negotiation contexts are added via
  the entity's `getCacheContexts()`.

The `#access` property controls whether an element is processed. It accepts booleans and `AccessResult` objects; with an `AccessResult`, its cacheability is merged into the render tree. A plain boolean conveys no cacheability, which can cause access decisions to be cached without the correct variation.

**Good Example:**
```php
// AccessResult carries cacheability into the render tree via #access.
$access = AccessResult::allowedIf($account->hasPermission('view reports'))
  ->addCacheContexts(['user.permissions']);

$build['report'] = [
  '#theme' => 'report',
  '#access' => $access,
];
```

**Bad Example:**
```php
// ❌ Plain boolean conveys no cacheability. The decision may be cached
// without varying by user.permissions.
$build['report'] = [
  '#theme' => 'report',
  '#access' => $account->hasPermission('view reports'),
];
```

---

## Lazy Builders, Placeholders, and BigPipe

### RND012: Use Lazy Builders for Personalized Content

**Severity:** `high`

The Dynamic Page Cache caches full page render arrays, replacing personalized sections with placeholders. Lazy builders mark a section as "fill this in per-request". Without them, any personalized content (username, cart count, user-specific messages) forces the entire page to be uncacheable.

**Good Example:**
```php
$build['user_greeting'] = [
  '#lazy_builder' => [
    'my_module.greeting_builder:build',
    [$account_id],
  ],
  '#create_placeholder' => TRUE,
];
```

**Bad Example:**
```php
// ❌ Personalized value placed directly in the render array. The page
// cannot be cached across users.
$build['user_greeting'] = [
  '#markup' => $this->t('Welcome, @name', [
    '@name' => $this->currentUser->getDisplayName(),
  ]),
];
```

---

### RND013: Pass Only Scalar Arguments to Lazy Builders

**Severity:** `high`

Lazy builder arguments must be scalar values only (strings, integers, floats, booleans, or NULL). Arguments are serialized into the placeholder markup, so arrays, objects, and render arrays cannot be passed. Pass an entity ID and reload inside the builder, not the entity object.

**Good Example:**
```php
// Pass the ID; reload the entity inside the builder callback.
$build['actions'] = [
  '#lazy_builder' => ['my_module.actions:build', [$node->id()]],
  '#create_placeholder' => TRUE,
];

// The builder reloads from the scalar argument.
public function build(int $nid): array {
  $node = $this->entityTypeManager->getStorage('node')->load($nid);
  // ...
}
```

**Bad Example:**
```php
// ❌ Passing an object. It cannot be serialized into the placeholder.
$build['actions'] = [
  '#lazy_builder' => ['my_module.actions:build', [$node]],
  '#create_placeholder' => TRUE,
];
```

---

### RND014: Do Not Defeat BigPipe by Pre-Rendering Placeholders

**Severity:** `medium`

BigPipe is the production consumer of the placeholder system. It streams the page HTML immediately and replaces lazy builder placeholders via chunked transfer as they resolve. Code that renders placeholder content into strings before BigPipe can intercept it defeats this mechanism and reintroduces the latency BigPipe removes.

**Good Example:**
```php
// Leave placeholders in place; BigPipe streams and fills them.
$build['sidebar'] = [
  '#lazy_builder' => ['my_module.sidebar:build', [$account_id]],
  '#create_placeholder' => TRUE,
];
```

**Bad Example:**
```php
// ❌ Forcing a render to string resolves the placeholder too early,
// bypassing BigPipe's streaming.
$build['sidebar'] = [
  '#markup' => \Drupal::service('renderer')->render($lazy_build),
];
```

---

### RND015: Render Correctly Outside the Request Pipeline

**Severity:** `medium`

When rendering in contexts outside the normal HTTP request (queue workers, Drush commands, cron), cacheability bubbling behaves differently. Use `renderInIsolation()` (or `renderPlain()` on older APIs) instead of `render()` to avoid attaching metadata to a non-existent request context.

**Good Example:**
```php
// Inside a queue worker or Drush command.
$html = $this->renderer->renderInIsolation($build);
```

**Bad Example:**
```php
// ❌ render() inside a queue worker attaches metadata to a request
// context that does not exist.
$html = $this->renderer->render($build);
```

---

## Theme Hooks and Preprocessing

### RND016: Register Theme Hooks with hook_theme()

**Severity:** `medium`

To use a custom `#theme` value, register the theme hook with `hook_theme()`, declaring its variables and default values (and a template or callback). This connects the render array to a Twig template and defines the variables available to it.

**Good Example:**
```php
/**
 * Implements hook_theme().
 */
function my_module_theme(): array {
  return [
    'my_card' => [
      'variables' => [
        'title' => NULL,
        'url' => NULL,
        'summary' => NULL,
      ],
      // Resolves to templates/my-card.html.twig.
    ],
  ];
}
```

```php
// Rendered via the registered hook.
$build['card'] = [
  '#theme' => 'my_card',
  '#title' => $node->label(),
  '#url' => $node->toUrl(),
];
```

**Bad Example:**
```php
// ❌ Using #theme => 'my_card' without registering it in hook_theme().
// Drupal cannot find the template and throws "Theme hook not found".
$build['card'] = ['#theme' => 'my_card', '#title' => $node->label()];
```

---

### RND017: Prepare Template Variables in Preprocess Functions

**Severity:** `medium`

Use `hook_preprocess_HOOK()` to compute and normalize variables before they reach the template, and to add cacheability metadata. Keep derived logic in PHP so templates stay focused on presentation, and add cache tags/contexts for any data the preprocess introduces.

**Good Example:**
```php
/**
 * Implements hook_preprocess_HOOK() for my_card.
 */
function my_module_preprocess_my_card(array &$variables): void {
  // Normalize a value for the template.
  $variables['summary'] = $variables['summary']
    ? Unicode::truncate($variables['summary'], 200, TRUE, TRUE)
    : '';

  // Add cacheability for data introduced here.
  $variables['#cache']['contexts'][] = 'user.permissions';
  $variables['#cache']['tags'][] = 'node_list';
}
```

**Bad Example:**
```php
// ❌ Fetching extra data in preprocess without declaring its cacheability.
function my_module_preprocess_my_card(array &$variables): void {
  $variables['related'] = \Drupal::entityTypeManager()
    ->getStorage('node')->loadMultiple($ids);
  // Missing #cache tags — related content goes stale.
}
```

---

## Attachments

### RND018: Attach Assets with #attached, Not Inline Tags

**Severity:** `high`

Attach CSS/JS libraries and `<head>` elements via the `#attached` render property so they are aggregated, deduplicated, and their placement is managed by Drupal. Never hardcode `<script>` or `<link>` tags into markup. Libraries are declared in a `*.libraries.yml` file and referenced by `module/library` name.

**Good Example:**
```php
$build['widget'] = [
  '#theme' => 'my_widget',
  '#attached' => [
    'library' => ['my_module/widget'],
    // Pass settings to drupalSettings.
    'drupalSettings' => ['myModule' => ['widgetId' => $id]],
    // Add a head element (e.g. meta tag).
    'html_head' => [
      [
        [
          '#tag' => 'meta',
          '#attributes' => ['name' => 'robots', 'content' => 'noindex'],
        ],
        'my_module_robots',
      ],
    ],
  ],
];
```

**Bad Example:**
```php
// ❌ Hardcoded asset tags bypass aggregation and deduplication and
// break under caching.
$build['widget'] = [
  '#markup' => '<link rel="stylesheet" href="/path/widget.css">'
    . '<script src="/path/widget.js"></script>'
    . '<div class="widget"></div>',
];
```

---

### RND019: Attachments Bubble — Attach at Any Level

**Severity:** `medium`

Like cacheability metadata, `#attached` libraries bubble up the render tree. Attach a library on the specific element that needs it rather than forcing it onto the page globally; it will still be collected and placed in the response. This keeps assets scoped to the output that actually renders and avoids loading them on pages where the element is absent.

**Good Example:**
```php
// Library attached to the element that uses it; bubbles to the page.
$build['map'] = [
  '#theme' => 'my_map',
  '#attached' => ['library' => ['my_module/map']],
];
```

**Bad Example:**
```php
// ❌ Attaching globally in every page/preprocess so the asset loads
// even when the map element is not rendered.
function my_module_page_attachments(array &$attachments): void {
  $attachments['#attached']['library'][] = 'my_module/map';
}
```
