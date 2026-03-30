# Drupal Standards — Claude Skill
A Claude skill providing on-demand coding standards for Drupal 10/11 development.
Covers backend PHP, security, dependency injection, testing, REST APIs, hooks/events,
the Drupal AI module (including Anthropic/Claude provider), and frontend CSS/JS/Twig.

## What's Included

| Area | Files | Standards |
|------|-------|-----------|
| PHP / OOP / Documentation | 1 | 24 |
| Security | 1 | 19 |
| Dependency Injection (deep-dive) | 6 | 115 |
| Database API | 1 | 7 |
| Forms API | 1 | 8 |
| REST / Entity API | 1 | 7 |
| Hooks & Events | 1 | 7 |
| Testing (PHPUnit) | 1 | 9 |
| Drupal AI + Anthropic/Claude | 1 | 18 |
| CSS (formatting, BEM, RTL, units) | 5 | 84 |
| JavaScript / Drupal behaviors | 2 | 35 |
| Twig templates | 2 | 44 |
| Accessibility (WCAG 2.2) | 1 | 16 |
| DevOps / CI | 1 | 10 |
| **Total** | **26** | **414+** |

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
- 414+ standards across 26 reference files
- Full Dependency Injection deep-dive (AutowireTrait, service tags, decoration)
- Drupal AI module integration with Anthropic/Claude provider
- Complete CSS coverage: BEM/SMACSS, RTL, units, Doxygen comments
- Extended Twig and JavaScript behavior standards
- Pre-commit checklist with AI-specific checks

### Assets
- `drupal-standards.skill` — install directly into Claude
