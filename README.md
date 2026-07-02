# Drupal Standards — Claude Skill
A Claude skill providing on-demand coding standards for Drupal 10/11 development.
Covers backend PHP, security, dependency injection, configuration, testing,
documentation, common mistakes, REST APIs, hooks/events, the Drupal AI module
(including Anthropic/Claude provider), and frontend CSS/JS/Twig, the render
pipeline, and accessibility.

## What's Included

| Area | Files | Standards |
|------|-------|-----------|
| PHP / OOP / Documentation | 1 | 24 |
| Security | 1 | 19 |
| Dependency Injection (deep-dive) | 6 | 115 |
| Configuration (Config API, schema) | 1 | 12 |
| Documentation (DocBlocks, README) | 1 | 15 |
| Common mistakes / corrections | 1 | 12 |
| Database API | 1 | 7 |
| Forms API | 1 | 8 |
| REST / Entity API | 1 | 7 |
| Hooks & Events | 1 | 7 |
| Testing (PHPUnit) | 1 | 20 |
| Drupal AI + Anthropic/Claude | 1 | 18 |
| CSS (formatting, BEM, RTL, units) | 5 | 84 |
| JavaScript / Drupal behaviors | 2 | 35 |
| Twig templates | 2 | 44 |
| Render pipeline (caching, BigPipe) | 1 | 19 |
| Accessibility (WCAG 2.2) | 1 | 40 |
| DevOps / CI + Drupal.org contribution | 1 | 23 |
| **Total** | **30** | **520+** |

## Installation

1. Download `drupal-standards.skill` 
2. In Claude, go to **Settings → Skills**
3. Upload the `.skill` file
4. The skill activates automatically when you work on Drupal code

## Usage

Once installed, Claude will automatically load the relevant standards
based on your task. You can also ask explicitly:

- *"Review this service class for DI best practices"*
- *"Check my Twig template against Drupal standards"*
- *"Help me integrate the Drupal AI module with Anthropic"*
- *"Write a PHPUnit test for this service"*

## Maintainer

**Joshua Fernandes**
- 🌐 [fernandesjoshua.com](https://fernandesjoshua.com)
- 🔵 [drupal.org/u/joshua1234511](https://www.drupal.org/u/joshua1234511)
- 🐙 [github.com/joshua1234511](https://github.com/joshua1234511)
- 💼 [linkedin.com/in/joshua1234511](https://www.linkedin.com/in/joshua1234511)

### Highlights
- 520+ standards across 30 reference files
- Full Dependency Injection deep-dive (AutowireTrait, service tags, decoration)
- Configuration, render pipeline, documentation, and common-mistakes references synced from [`project/ai_best_practices`](https://git.drupalcode.org/project/ai_best_practices)
- Drupal AI module integration with Anthropic/Claude provider
- Complete CSS coverage: BEM/SMACSS, RTL, units, Doxygen comments
- Extended Twig and JavaScript behavior standards
- Expanded accessibility (WCAG 2.2 AA) and Drupal.org contribution/GitLab workflow
- Pre-commit checklist with AI-specific checks

### Assets
- `drupal-standards.skill` — install directly into Claude
