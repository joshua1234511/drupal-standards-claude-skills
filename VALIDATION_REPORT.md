# Validation Report: Drupal Standards Skill v3.1

**Maintained by [Joshua Fernandes](https://fernandesjoshua.com)**  
🌐 [drupal.org/u/joshua1234511](https://www.drupal.org/u/joshua1234511) · 🐙 [github.com/joshua1234511](https://github.com/joshua1234511)

---

## Summary

| Item | Value |
|------|-------|
| Skill version | 2.1 |
| Total reference files | 13 (of 16 planned) |
| Total coded standards | **163+** |
| Drupal versions covered | 10, 11 |
| Last validated | March 2026 |

---

## Standards Coverage by File

### Back-End (`references/backend/`)

| File | Standards | Category Codes | Topics Covered |
|------|-----------|----------------|----------------|
| `php-standards.md` | **24** | PHP, DS | Formatting, naming, type hints, namespaces, DocBlocks, modern PHP 8.x |
| `security.md` | **19** | SEC | Input sanitization, SQL injection, XSS, CSRF, access control, file uploads, encryption |
| `services.md` | **11** | SVC, DI | Service definitions, constructor injection, ContainerInjectionInterface, plugin system, events |
| `testing.md` | **9** | TEST | PHPUnit unit/kernel/functional, Behat, mocking, fixtures, JS testing |
| `api.md` | **7** | API | Entity API, Entity Query, REST plugins, JSON:API, auth providers, versioning, HTTP exceptions |
| `database.md` | **7** | DB | Database API, parameterized queries, table prefixes, transactions, Schema API, hook_update_N, migrations |
| `hooks.md` | **7** | HOOK | Events over hooks, hook implementation, alter hooks, hook_module_implements_alter, mymodule.api.php |
| `forms-api.md` | **8** | FORM | FormBase, element types, validation, AJAX, States API, ConfigFormBase, CSRF |
| `drupal-ai.md` | **18** | AI | AI module architecture, making calls, operation types, function call plugins, AI events, custom providers, Anthropic/Claude, prompt management, prompt injection security, testing |

**Back-End Total: 110 standards**

### Front-End (`references/frontend/`)

| File | Standards | Category Codes | Topics Covered |
|------|-----------|----------------|----------------|
| `accessibility.md` | **16** | ACC | WCAG 2.2 (A/AA/AAA), ARIA, keyboard navigation, semantic HTML, colour contrast, focus management |
| `javascript.md` | **13** | JS | Drupal behaviors, jQuery, ES6+, AJAX, module patterns, performance |
| `twig.md` | **14** | TWIG | Template syntax, filters, security (`\|escape`), performance, preprocess hooks |

**Front-End Total: 43 standards**

> ⚠️ **Missing files** (referenced in SKILL.md task detection but not yet created):
> - `frontend/css.md` — CSS, Tailwind, BEM, responsive design, Drupal libraries
> - `frontend/react.md` — React hooks, state management, optimisation patterns
> - `frontend/vue.md` — Vue.js Composition API, TypeScript, best practices
>
> These are listed in the task detection routing table. Until created, Claude falls back to general knowledge for those topics.

### DevOps (`references/devops.md`)

| File | Standards | Topics Covered |
|------|-----------|----------------|
| `devops.md` | **10** | GitHub Actions v4, build optimisation, config management, deployment, environment variables |

**DevOps Total: 10 standards**

---

## Grand Total: 163+ Standards

| Area | Count | vs v2.0 |
|------|-------|---------|
| Back-End | 110 | ↑ +63 (new: database, forms-api, api, hooks, drupal-ai) |
| Front-End | 43 | → unchanged (css/react/vue pending) |
| DevOps | 10 | → unchanged |
| **Total** | **163** | ↑ from ~100 coded standards in v2.0 |

> **Note on count accuracy:** The original v2.0 report cited "280+ standards" — that figure referenced the original CSV source entries, not the coded `### STDXXX:` standards actually present in the skill files. The 163 figure is the accurate count of distinct numbered standards in the current skill. Real coverage depth is higher because each standard includes multiple good/bad examples, severity ratings, and cross-references.

---

## File Structure (Actual State)

```
drupal-backend-standards/
├── SKILL.md                              # Main entry, routing, principles, quick reference
├── VALIDATION_REPORT.md                  # This file
├── references/
│   ├── backend/
│   │   ├── php-standards.md              # ✅ 24 standards — PHP, DocBlocks, modern PHP 8.x
│   │   ├── security.md                   # ✅ 19 standards — input/output, access control
│   │   ├── services.md                   # ✅ 11 standards — DI, service container, events
│   │   ├── testing.md                    # ✅  9 standards — PHPUnit, Behat, mocking
│   │   ├── api.md                        # ✅  7 standards — Entity API, REST, JSON:API
│   │   ├── database.md                   # ✅  7 standards — DB API, schema, migrations
│   │   ├── hooks.md                      # ✅  7 standards — hooks vs events, alter hooks
│   │   ├── forms-api.md                  # ✅  8 standards — FAPI, AJAX, states, CSRF
│   │   └── drupal-ai.md                  # ✅ 18 standards — AI module, Anthropic/Claude
│   ├── frontend/
│   │   ├── accessibility.md              # ✅ 16 standards — WCAG 2.2, ARIA, keyboard
│   │   ├── javascript.md                 # ✅ 13 standards — behaviors, ES6+, AJAX
│   │   ├── twig.md                       # ✅ 14 standards — templates, filters, security
│   │   ├── css.md                        # ❌ MISSING — CSS/Tailwind/BEM (create next)
│   │   ├── react.md                      # ❌ MISSING — React/hooks standards
│   │   └── vue.md                        # ❌ MISSING — Vue.js Composition API
│   └── devops.md                         # ✅ 10 standards — CI/CD, GitHub Actions v4
└── scripts/
    ├── drupal_validator.py               # ✅ Python validator (phpcs, phpmd, phpstan)
    ├── drupal_lint.sh                    # ✅ Shell linting wrapper
    └── setup_drupal_dev.sh              # ✅ Dev environment setup
```

---

## What Changed in v2.1 (vs v2.0)

### New Reference Files Added

| File | Standards | Reason Added |
|------|-----------|--------------|
| `backend/database.md` | 7 | Referenced in SKILL.md task table but was missing |
| `backend/forms-api.md` | 8 | Referenced in SKILL.md task table but was missing |
| `backend/api.md` | 7 | Referenced in SKILL.md task table but was missing |
| `backend/hooks.md` | 7 | Referenced in SKILL.md task table but was missing |
| `backend/drupal-ai.md` | 18 | New — full Drupal AI module coverage (drupal/ai + ai_provider_anthropic) |

### SKILL.md Updates

| Change | Detail |
|--------|--------|
| Key Principles table | Added 9 principles including Drupal AI (was missing entirely) |
| Task Detection table | Added Drupal AI, hooks, and corrected missing file rows |
| Quick Reference Loading | Added `# For Drupal AI / LLM integration` block |
| Standards overview table | Added `drupal-ai.md` row |
| Pre-commit checklist | Added Drupal AI section (6 checks) |
| Pre-commit checklist | Updated testing item — explicitly flags SimpleTest removal |
| Quick rule tip | Updated to mention `ai.provider` |

### Personalization Added

| Item | Value |
|------|-------|
| SKILL.md frontmatter | `metadata.author`, `metadata.drupal_org`, `metadata.github`, `metadata.linkedin`, `metadata.website`, `metadata.location` |
| Skill body header | Visible maintainer callout with all profile links |

---

## Coverage Gaps Remaining

| Gap | Priority | Action Required |
|-----|----------|----------------|
| `frontend/css.md` missing | **High** | Create with CSS, Tailwind, BEM, responsive design, Drupal library standards |
| `frontend/react.md` missing | Medium | Create with React hooks, state management, optimisation patterns |
| `frontend/vue.md` missing | Medium | Create with Vue.js Composition API, TypeScript, best practices |
| Performance / caching standards | Medium | No dedicated `performance.md` — PERF/CACHE currently scattered across php-standards.md |
| Config / CMI standards | Low | No dedicated `config.md` — CONFIG touched briefly in services.md |
| Drupal AI: Agent-building | Low | Extend `drupal-ai.md` with `agents/` section as the AI agents API stabilises |
| Validator script: AI patterns | Low | `drupal_validator.py` does not yet check for AI-specific anti-patterns (hardcoded keys, untagged calls) |

---

## Validation Against Official Sources

| Source | Applied To |
|--------|-----------|
| Drupal Coding Standards (drupal.org/docs/develop/standards) | php-standards.md, security.md |
| WCAG 2.2 (w3.org/TR/WCAG22) | accessibility.md |
| OWASP Top 10 (owasp.org) | security.md |
| PSR-12 (php-fig.org/psr/psr-12) | php-standards.md |
| Drupal AI Developer Docs 1.2.x (project.pages.drupalcode.org/ai) | drupal-ai.md |
| Anthropic Provider module (drupal.org/project/ai_provider_anthropic) | drupal-ai.md |
| Drupal API Reference (api.drupal.org/api/drupal/11.x) | api.md, database.md, forms-api.md |
| Symfony Event Dispatcher docs | hooks.md, services.md |

---

## Task to File Mapping (Complete)

| User Request | Primary Files to Load |
|-------------|----------------------|
| Review a PHP service class | `backend/php-standards.md`, `backend/services.md` |
| Security review of a form | `backend/security.md`, `backend/forms-api.md` |
| Write a REST or JSON:API endpoint | `backend/api.md`, `backend/security.md` |
| Database queries or schema changes | `backend/database.md` |
| Write hooks or event subscribers | `backend/hooks.md`, `backend/services.md` |
| Write PHPUnit or Behat tests | `backend/testing.md` |
| Integrate AI / LLM into Drupal | `backend/drupal-ai.md`, `backend/security.md` |
| Use Anthropic / Claude models | `backend/drupal-ai.md` (§ Anthropic Provider) |
| Build tool use / function calling | `backend/drupal-ai.md` (§ Function Call Plugins) |
| Fix accessibility issues | `frontend/accessibility.md` |
| Review a Twig template | `frontend/twig.md`, `frontend/accessibility.md` |
| JavaScript / Drupal behaviors | `frontend/javascript.md` |
| CSS / theming | `frontend/css.md` ⚠️ *file not yet created* |
| React component | `frontend/react.md` ⚠️ *file not yet created* |
| Vue.js component | `frontend/vue.md` ⚠️ *file not yet created* |
| CI/CD or deployment | `references/devops.md` |
| Full-stack feature | `backend/php-standards.md`, `backend/forms-api.md`, `frontend/javascript.md` |

---

## Validation Status

| Check | Status | Notes |
|-------|--------|-------|
| All SKILL.md referenced files exist | ⚠️ Partial | css.md, react.md, vue.md missing |
| All task detection routes resolve | ⚠️ Partial | Same three files |
| Standards use `### CODE: Title` format | ✅ | Consistent across all files |
| Each standard has Good/Bad examples | ✅ | With syntax highlighting |
| Each standard has Severity rating | ✅ | critical / high / medium / low |
| All previously missing backend files created | ✅ | database, forms-api, api, hooks |
| Drupal AI coverage added | ✅ | 18 standards in drupal-ai.md |
| Anthropic / Claude provider documented | ✅ | Full section in drupal-ai.md |
| Prompt injection security covered | ✅ | AI013 in drupal-ai.md |
| Key Principles table in SKILL.md | ✅ | 9 principles |
| Pre-commit checklist includes AI checks | ✅ | 6 AI-specific items |
| Author metadata present | ✅ | Joshua Fernandes, all profile links |
| Drupal 10 / 11 compatibility | ✅ | Verified throughout |
| Modern PHP 8.x patterns | ✅ | Constructor promotion, named args, match |
| SimpleTest deprecation noted | ✅ | Testing checklist updated |
| Validation report accurate | ✅ | This document |

---

## v3.1 Integration Update (March 2026)

### Skills Integrated

Two external skills were merged into this skill package:

#### 1. drupal-dependency-injection.skill

**6 reference files integrated** under `references/backend/di/`:

| File | Sections | Key Content |
|------|----------|-------------|
| `di/services-definition.md` | 19 | Full services.yml syntax: arguments, properties, factories, aliases, optional deps, abstract services, interface aliases |
| `di/dependency-injection-forms.md` | 10 | DI in FormBase, ConfigFormBase, AutowireTrait (Drupal 10.2+), ContainerInjectionInterface |
| `di/dependency-injection-plugins.md` | 17 | DI in Block, FieldFormatter, FieldWidget, QueueWorker, ContainerFactoryPluginInterface |
| `di/service-tags.md` | 17 | Service tags: event_subscriber, cache.bin, access_check, breadcrumb_builder; collectors |
| `di/altering-services.md` | 18 | ServiceProviderInterface, service decoration, altering existing services |
| `di/best-practices.md` | 34 | Anti-patterns, private vs protected, lazy loading, circular deps, testing with DI |

**DI subtotal: 115 sections**

**Relationship to existing `services.md`:** The existing `services.md` (11 standards) provides a concise overview and Event Subscriber patterns. The new `di/` files provide deep-dive references for each specific DI context. Both are retained — `services.md` as the quick entry point, `di/` files for task-specific depth.

#### 2. drupal-frontend-standards.skill

**7 reference files integrated** under `references/frontend/`:

| File | Sections | Key Content | Relationship to Existing |
|------|----------|-------------|--------------------------|
| `css-formatting.md` | 21 | Indentation, selectors, quotes, semicolons, vendor prefix order | Fills `css.md` gap ✅ |
| `css-architecture.md` | 9 | SMACSS, BEM (.component, .component--mod, .component__el), .is- states, .js- hooks | Fills `css.md` gap ✅ |
| `css-units.md` | 8 | rem over px, omit units for zero, em for relative | Fills `css.md` gap ✅ |
| `css-rtl.md` | 17 | LTR comments, :dir() pseudo-class, logical properties, i18n | New — not previously covered |
| `css-comments.md` | 29 | Doxygen @file/@defgroup/@addtogroup, section dividers | New — not previously covered |
| `javascript-extended.md` | 22 | once(), Drupal.t(), strict mode, detach, full behavior patterns | Extends existing `javascript.md` |
| `twig-extended.md` | 30 | Attributes object deep dive, BEM in Twig, escaping patterns, common template patterns | Extends existing `twig.md` |

**Frontend subtotal: 136 new sections**

Also included: `frontend-standards-index.csv` — a machine-readable index of all 28 frontend standards with IDs, categories, severities, and reference file pointers.

**Previously Missing Files Now Resolved:**
- ✅ `css.md` → split into 5 focused files: `css-formatting.md`, `css-architecture.md`, `css-units.md`, `css-rtl.md`, `css-comments.md`
- ⚠️ `react.md` — still missing (not in uploaded skills)
- ⚠️ `vue.md` — still missing (not in uploaded skills)

---

## Updated Overall Counts (v3.1)

| Area | Files | Sections | Status |
|------|-------|----------|--------|
| Backend PHP | 9 files | 110 | ✅ Complete |
| Backend DI (deep-dive) | 6 files | 115 | ✅ **New in v3.1** |
| Frontend (existing) | 3 files | 43 | ✅ Complete |
| Frontend (integrated) | 7 files | 136 | ✅ **New in v3.1** |
| DevOps | 1 file | 10 | ✅ Complete |
| **TOTAL** | **26 files** | **414** | **⚠️ react.md, vue.md still pending** |

