# Drupal AI Module Standards

Standards for developing with the [Drupal AI module](https://www.drupal.org/project/ai) (v1.2.x).
The AI module provides the core abstraction layer for integrating any LLM or AI provider into Drupal.

> 📖 Official docs: https://project.pages.drupalcode.org/ai/1.2.x/
> 📖 Developer reference: https://project.pages.drupalcode.org/ai/1.2.x/developers/developer_information/

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Installation & Providers](#installation--providers)
3. [Making AI Calls](#making-ai-calls)
4. [Operation Types](#operation-types)
5. [AI Events](#ai-events)
6. [Function Call Plugins (Tools)](#function-call-plugins-tools)
7. [Writing a Custom AI Provider](#writing-a-custom-ai-provider)
8. [Submodules Quick Reference](#submodules-quick-reference)
9. [Anthropic Provider (Claude)](#anthropic-provider-claude)
10. [Security Considerations](#security-considerations)
11. [Testing AI Code](#testing-ai-code)

---

## Architecture Overview

### AI001: Understand the Provider Abstraction

**Severity:** `high`

The AI module abstracts all AI service calls behind **Operation Types**. Your code never calls a specific provider (OpenAI, Anthropic, etc.) directly — it calls an operation type, and the configured provider handles it. Providers can be swapped without changing your module code.

```
Your Module
    ↓ calls operation type (e.g. chat, embeddings)
AI Core (ai.provider service)
    ↓ routes to configured provider plugin
Provider Plugin (e.g. ai_provider_anthropic)
    ↓ calls external API
Claude / GPT / Gemini / etc.
```

**Key principle:** Always build against the AI module's interfaces — never hardcode a specific provider.

---

## Installation & Providers

### AI002: Declare the AI Module as a Dependency

**Severity:** `high`

```yaml
# mymodule.info.yml
name: My AI Module
type: module
core_version_requirement: ^10 || ^11
dependencies:
  - drupal:ai
  # Only add ai_provider_anthropic if you specifically require Claude.
  # For public modules, keep provider-agnostic.
```

---

### AI003: Configure Providers via the Key Module

**Severity:** `high`

API keys must be stored using the Key module — never hardcoded in code or config.

**Setup for Anthropic (Claude):**
```bash
composer require drupal/ai drupal/ai_provider_anthropic drupal/key
drush en ai ai_provider_anthropic key
```
1. Create API key entry: `/admin/config/system/keys`
2. Connect it: `/admin/config/ai/providers/anthropic`
3. Set defaults per operation type: `/admin/config/ai/settings`

---

## Making AI Calls

### AI004: Always Inject `ai.provider` via DI

**Severity:** `critical`

Inject `ai.provider` through the constructor. Never call `\Drupal::service('ai.provider')` inside a class that supports DI.

**Good Example:**
```php
namespace Drupal\mymodule\Service;

use Drupal\ai\AiProviderPluginManager;
use Drupal\ai\OperationType\Chat\ChatInput;
use Drupal\ai\OperationType\Chat\ChatMessage;

class ContentSummarizer {

  public function __construct(
    protected AiProviderPluginManager $aiProvider,
  ) {}

  public function summarize(string $text): string {
    [$providerId, $modelId] = $this->aiProvider->getDefaultProviderForOperationType('chat');
    $provider = $this->aiProvider->createInstance($providerId);

    $messages = new ChatInput([
      new ChatMessage('user', 'Summarize the following: ' . $text),
    ]);
    $messages->setSystemPrompt('You are a concise summarization assistant.');

    $response = $provider->chat($messages, $modelId, ['mymodule', 'summary']);
    return $response->getNormalized()->getText();
  }

}
```

```yaml
# mymodule.services.yml
services:
  mymodule.content_summarizer:
    class: Drupal\mymodule\Service\ContentSummarizer
    arguments:
      - '@ai.provider'
```

**Bad Example:**
```php
// ❌ Hardcoded provider — site may not have OpenAI installed.
$provider = \Drupal::service('ai.provider')->createInstance('openai');
```

---

### AI005: Use the Default Provider — Don't Hardcode

**Severity:** `medium`

Use `getDefaultProviderForOperationType()` so site admins control which provider is used. Required for any publicly distributed module.

**Good Example:**
```php
$default = $this->aiProvider->getDefaultProviderForOperationType('chat');
if (!$default) {
  throw new \RuntimeException('No default chat AI provider configured. Visit /admin/config/ai/settings.');
}
[$providerId, $modelId] = $default;
$provider = $this->aiProvider->createInstance($providerId);
```

---

### AI006: Always Tag AI Calls

**Severity:** `medium`

The third argument of every operation call is a `tags` array. Always include at least your module name. Tags power the Events system — without them, logging, moderation, and event subscribers cannot target your calls.

```php
// ✅ Module name + context.
$response = $provider->chat($messages, $modelId, ['mymodule', 'content-summary']);
$response = $provider->embeddings($input, $modelId, ['mymodule', 'rag-index']);

// ❌ Empty tags — invisible to logging and moderation.
$response = $provider->chat($messages, $modelId, []);
```

---

## Operation Types

### AI007: Match Operation Type to Your Goal

**Severity:** `high`

| Operation Type | Use for | Key Output Method |
|----------------|---------|-------------------|
| `chat` | Text generation, conversation | `->getNormalized()->getText()` |
| `embeddings` | Vectors for RAG / semantic search | `->getNormalized()->getVector()` |
| `text_to_image` | Image generation | `->getNormalized()->getImages()` |
| `text_to_speech` | Text to audio | `->getNormalized()->getAudio()` |
| `speech_to_text` | Audio transcription | `->getNormalized()->getText()` |
| `moderation` | Content safety classification | `->getNormalized()->isFlagged()` |
| `translate_text` | Language translation | `->getNormalized()->getText()` |
| `image_classification` | Image labelling | `->getNormalized()->getLabels()` |

**Chat Example:**
```php
use Drupal\ai\OperationType\Chat\ChatInput;
use Drupal\ai\OperationType\Chat\ChatMessage;

$messages = new ChatInput([new ChatMessage('user', 'What is Drupal?')]);
$messages->setSystemPrompt('You are a helpful Drupal documentation assistant.');
$response = $provider->chat($messages, $modelId, ['mymodule']);
$text = $response->getNormalized()->getText();
```

**Embeddings Example (RAG):**
```php
use Drupal\ai\OperationType\Embeddings\EmbeddingsInput;

$input = new EmbeddingsInput($textChunk);
$response = $provider->embeddings($input, $modelId, ['mymodule', 'rag']);
$vector = $response->getNormalized()->getVector(); // float[]
// Store in Milvus, Pinecone, etc.
```

---

### AI008: Use Streaming for UI Responses

**Severity:** `low`

For browser-facing output, enable streaming to flush tokens as they arrive.

```php
$messages = new ChatInput([new ChatMessage('user', $prompt)]);
$messages->setStreamedOutput(TRUE);

$response = $provider->chat($messages, $modelId, ['mymodule', 'streaming']);
foreach ($response->getNormalized() as $chunk) {
  echo $chunk->getText();
  ob_flush();
  flush();
}
```

---

## AI Events

### AI009: Use AI Events for Cross-Cutting Concerns

**Severity:** `medium`

Subscribe to AI module events to add logging, prompt enrichment, or response filtering — without touching calling code.

| Event | When | Use |
|-------|------|-----|
| `PreGenerateResponseEvent` | Before API call | Modify/log outgoing prompt |
| `PostGenerateResponseEvent` | After API call | Log usage, filter response |
| `StreamResponseEvent` | After stream ends | Audit streamed output |
| `ProviderDisabledEvent` | Provider disabled | Fallback logic |

**Example — Inject site context into prompts:**
```php
namespace Drupal\mymodule\EventSubscriber;

use Drupal\ai\Event\PreGenerateResponseEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class AiPromptEnricher implements EventSubscriberInterface {

  public static function getSubscribedEvents(): array {
    return [PreGenerateResponseEvent::class => ['enrichPrompt', 10]];
  }

  public function enrichPrompt(PreGenerateResponseEvent $event): void {
    // Only modify calls from your module.
    if (!in_array('mymodule', $event->getTags())) {
      return;
    }
    $existing = $event->getSystemPrompt() ?? '';
    $event->setSystemPrompt('Site: Acme Corp. Language: en. ' . $existing);
  }

}
```

```yaml
services:
  mymodule.ai_prompt_enricher:
    class: Drupal\mymodule\EventSubscriber\AiPromptEnricher
    tags:
      - { name: event_subscriber }
```

---

## Function Call Plugins (Tools)

### AI010: Implement FunctionCall Plugins for Tool Use

**Severity:** `medium`

When you want an LLM to call Drupal functionality (search, create content, query data), implement a `FunctionCall` plugin. This is the Drupal AI equivalent of "tool use" in the Anthropic API.

```php
namespace Drupal\mymodule\Plugin\AiFunctionCall;

use Drupal\ai\Attribute\AiFunctionCall;
use Drupal\ai\PluginInterfaces\AiFunctionCallInterface;
use Drupal\Core\Plugin\PluginBase;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[AiFunctionCall(
  id: 'mymodule_search_nodes',
  label: new TranslatableMarkup('Search Nodes'),
  description: new TranslatableMarkup('Search Drupal nodes by keyword and optional content type.'),
  group: 'mymodule',
)]
class SearchNodesFunction extends PluginBase implements AiFunctionCallInterface {

  public function getContextDefinitions(): array {
    return [
      'keyword' => new ContextDefinition('string', label: 'Search keyword', required: TRUE),
      'content_type' => new ContextDefinition('string', label: 'Content type', required: FALSE),
    ];
  }

  public function execute(): mixed {
    $keyword = $this->getContextValue('keyword');
    $type = $this->getContextValue('content_type');
    return $this->doSearch($keyword, $type);
  }

  public function getReadableOutput(): string {
    return json_encode($this->execute(), JSON_PRETTY_PRINT);
  }

}
```

---

## Writing a Custom AI Provider

### AI011: Extend AiProviderClientBase

**Severity:** `high`

To integrate an unsupported AI service, create a provider plugin. Only implement the operation type interfaces your service supports.

```php
/**
 * @AiProvider(
 *   id = "myprovider",
 *   label = @Translation("My Custom Provider"),
 * )
 */
class MyProvider extends AiProviderClientBase implements ChatInterface {

  public function chat(ChatInput $input, string $model_id, array $tags = []): ChatOutput {
    $responseText = $this->callMyExternalApi($input, $model_id);
    return new ChatOutput(
      new ChatMessage('assistant', $responseText),
      [], // raw response
      []  // metadata
    );
  }

  public function getSupportedOperationTypes(): array {
    return ['chat'];
  }

  public function getModels(string $operation_type): array {
    return match ($operation_type) {
      'chat' => ['myprovider-v1' => 'My Provider v1'],
      default => [],
    };
  }

}
```

---

## Submodules Quick Reference

### AI012: Submodule Selection Guide

**Severity:** `low`

| Submodule | Use When |
|-----------|----------|
| **AI Core** | Always — base requirement |
| **AI Explorer** | Test prompts/models in Drupal admin without code |
| **AI Automators** | Populate fields with AI output (low-code/no-code) |
| **AI Search** | Semantic search + RAG with vector DBs (Milvus, Pinecone) |
| **AI Assistants API + Chatbot** | Build configurable chatbot UIs |
| **AI CKEditor** | AI writing assistance inside CKEditor 5 |
| **AI Content** | Tone adjustment, summarization, taxonomy suggestions |
| **AI Logging** | Audit/log all AI requests in production |
| **AI ECA** | Trigger AI from ECA (Event-Condition-Action) workflows |
| **AI Translate** | AI-powered content translation |
| **AI Validations** | Content moderation and validation rules |

---

## Anthropic Provider (Claude)

### AI013: Configuring and Using the Anthropic Provider

**Severity:** `medium`

The [Anthropic Provider module](https://www.drupal.org/project/ai_provider_anthropic) integrates Claude models into Drupal AI. Used on 3,600+ sites.

**Installation:**
```bash
composer require drupal/ai_provider_anthropic
drush en ai_provider_anthropic
# Then: /admin/config/ai/providers/anthropic → connect API key
```

**Supported Claude models (2025):**

| Model ID | Best for |
|----------|----------|
| `claude-opus-4-20250514` | Complex reasoning, long-form analysis |
| `claude-sonnet-4-20250514` | Balanced — recommended default |
| `claude-haiku-4-5-20251001` | High-volume, low-latency tasks |

**Good Example:**
```php
// Site-specific code where you know Claude is the configured provider:
$provider = $this->aiProvider->createInstance('anthropic');
$messages = new ChatInput([
  new ChatMessage('user', 'Explain Drupal dependency injection in one paragraph.'),
]);
$messages->setSystemPrompt('You are a senior Drupal developer and educator.');
$response = $provider->chat($messages, 'claude-sonnet-4-20250514', ['mymodule', 'explainer']);
echo $response->getNormalized()->getText();
```

> ⚠️ **For public/contributed modules:** Use `getDefaultProviderForOperationType('chat')` (AI005) instead of hardcoding `'anthropic'`.

---

## Security Considerations

### AI014: Sanitize User Input — Prevent Prompt Injection

**Severity:** `critical`

Prompt injection is a real attack vector. Malicious users craft inputs that override your instructions or exfiltrate data. Always sanitize before including user content in prompts.

```php
// ✅ Sanitize and cap length.
$userQuery = Html::escape(substr(strip_tags($rawInput), 0, 500));
$prompt = 'Answer only questions about our product catalog: ' . $userQuery;

// ❌ NEVER: Raw user input directly in prompt.
$messages = new ChatInput([new ChatMessage('user', $_POST['question'])]);
```

---

### AI015: Never Include Sensitive Data in Prompts

**Severity:** `critical`

AI provider APIs transmit data to external servers. Never include passwords, API keys, PII, health data, or confidential business information in any prompt.

```php
// ✅ Only public content fields.
$prompt = 'Summarize: ' . $node->getTitle() . ' — ' . strip_tags($node->body->value);

// ❌ Full entity serialization may expose private fields and user data.
$prompt = 'Analyze: ' . serialize($node);
```

---

### AI016: Enable AI Logging in Production

**Severity:** `medium`

```bash
drush en ai_logging
# Configure retention/filtering at: /admin/config/ai/logging
```

Required for compliance, cost monitoring, and incident debugging.

---

## Testing AI Code

### AI017: Mock AI Providers in All Tests

**Severity:** `high`

Never make live API calls in unit or kernel tests. Use PHPUnit mocks.

```php
class ContentSummarizerTest extends UnitTestCase {

  public function testSummarize(): void {
    $mockMessage = $this->createMock(ChatMessage::class);
    $mockMessage->method('getText')->willReturn('A great summary.');

    $mockOutput = $this->createMock(ChatOutput::class);
    $mockOutput->method('getNormalized')->willReturn($mockMessage);

    $mockProvider = $this->createMock(\Drupal\ai\Plugin\AiProviderInterface::class);
    $mockProvider->method('chat')->willReturn($mockOutput);

    $mockManager = $this->createMock(AiProviderPluginManager::class);
    $mockManager->method('createInstance')->willReturn($mockProvider);
    $mockManager->method('getDefaultProviderForOperationType')
      ->willReturn(['mock', 'mock-model']);

    $summarizer = new ContentSummarizer($mockManager);
    $this->assertEquals('A great summary.', $summarizer->summarize('Long text...'));
  }

}
```

---

### AI018: Use AI Explorer for Manual Prompt Development

**Severity:** `low`

```bash
drush en ai_api_explorer
# Navigate to: /admin/config/ai/explorers/chat-generation
```

Iterate on prompts interactively and get the exact PHP code to replicate the call in your module.
