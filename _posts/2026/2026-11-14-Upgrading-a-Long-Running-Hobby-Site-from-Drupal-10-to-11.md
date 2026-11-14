---
layout: post
title: "Upgrading a Long-Running Hobby Site from Drupal 10 to 11"
description: "A practical walkthrough of an in-place upgrade from Drupal 10.6 to 11.4 in two days—covering two-stage Composer preparation, Lando database updates, jQuery 4 compatibility with Bootstrap 4, and subtle contrib module breaking changes."
categories: web devops php
tags: [drupal, php, devops, ai]
---

## Background: Three Generations of Drupal Upgrades

I have maintained a long-running Drupal hobby site across several major versions: first upgrading from **Drupal 7 to 9**, later from **Drupal 9 to 10**, and most recently from **Drupal 10.6 to 11.4**.

Each transition had a very different engineering profile:

- **Drupal 7 → 9** took a significant amount of time. Because Drupal 8+ introduced a completely different architecture built on Symfony, Twig, and an entity/configuration system, moving off Drupal 7 was not an in-place upgrade—it required rebuilding the theme and running a full data and configuration migration.
- **Drupal 9 → 10** was much simpler by comparison, primarily involving deprecated API replacements and Composer dependency updates.
- **Drupal 10 → 11** (`10.6.21` → `11.4.12`) took **just 2 days total** from initial codebase audit and local Lando testing to production deployment.

Working with an AI coding agent during this upgrade compressed the timeline considerably. Before I ran a single Composer command, the agent audited all custom modules, theme templates, JavaScript libraries, and contributed module constraints, organized the work into a two-stage checklist, and flagged several subtle breaking changes that would have otherwise taken hours to debug manually.

---

## What It Takes: An In-Place Upgrade

Unlike the Drupal 7 migration era, upgrading from Drupal 10 to Drupal 11 is a true **in-place upgrade**. All content, users, taxonomy terms, book outlines, and entity schemas remain in the existing database. The upgrade is executed through Composer package updates followed by `drush updatedb` and `drush cr`.

### 1. Environment & Database Prerequisites

Drupal 11 raises the minimum runtime requirements to **PHP 8.3+** and **MySQL 8.0+ / MariaDB 10.6+**.

- **Production:** My production server was already running **PHP 8.4** and **MariaDB 10.11**, so no OS or database server upgrades were needed on the host.
- **Local Development (Lando):** My local Lando environment was still configured with `mysql:5.7` from an older recipe. Updating `.lando.yml` to use `database: mysql:8.0` and importing a fresh production database dump aligned the local environment with Drupal 11's requirements.

### 2. `settings.php` Updates for Drupal 11

To clear Drupal 11 status report warnings and follow current database best practices, three adjustments were added to `sites/default/settings.php`:

1. **Transaction Isolation Level (`READ COMMITTED`):** Configured via `init_commands` on the database connection array to avoid unnecessary gap locks:
   ```php
   $databases['default']['default']['init_commands'] = [
     'isolation_level' => "SET SESSION transaction_isolation='READ-COMMITTED'",
   ];
   ```
2. **Explicit Database Driver Autoloading:** Added the explicit `Drupal\mysql\Driver\Database\mysql` namespace and `autoload` path (`core/modules/mysql/src/Driver/Database/mysql/`).
3. **State Cache:** Enabled `$settings['state_cache'] = TRUE;`, which Drupal 11 recommends for sites with a small state table to reduce database queries on every request.

---

## Two-Stage Upgrade Strategy

Rather than jumping directly to Drupal 11 in a single Composer transaction, splitting the upgrade into two distinct stages kept dependency resolution predictable and allowed database update hooks to run cleanly.

| Stage | Target Core | Key Actions |
| :--- | :--- | :--- |
| **Stage A: Drupal 10 Prep** | `10.6.21` | Transition removed core modules (`book`, `tour`), upgrade blocking contrib packages, update custom code for D11 compatibility |
| **Stage B: Drupal 11 Upgrade** | `11.4.12` | Upgrade `drupal/core-*`, `drush/drush`, Symfony `7.4`, and add jQuery 4 compatibility for the legacy Bootstrap 4 theme |

### Stage A: Preparation on Drupal 10.6

1. **Handling Core Modules Removed in Drupal 11:**
   - **`book` module:** Drupal 11 moved the core Book module to contrib (`drupal/book`). While still on Drupal 10.6, requiring `drupal/book:^2.0` via Composer allowed the contributed module to take over existing `book` database tables and outlines without data loss.
   - **`tour` module:** The core Tour module was also removed in Drupal 11. Because the site did not use it, running `drush pm:uninstall tour -y` on Drupal 10 cleanly removed its configuration before upgrading core.
2. **Upgrading Blocking Contrib Packages:**
   - Upgraded `composer/installers` (`v1.12` → `v2.3`)
   - Upgraded `drupal/field_validation` (`1.x` → `3.0.0`)
   - Upgraded `drupal/google_cse` (`3.x` → `5.0.6`)
3. **Custom Module & Theme Compatibility:**
   - Updated custom module and subtheme `.info.yml` files to `core_version_requirement: ^10 || ^11`.
   - Replaced the deprecated `user_load_by_name()` helper in custom form validation code (removed in Drupal 11) with the entity storage query:
     ```php
     $users = \Drupal::entityTypeManager()
       ->getStorage('user')
       ->loadByProperties(['name' => $entered_name]);
     $account = reset($users);
     ```

### Stage B: Upgrading Core to Drupal 11.4

With all contrib modules and custom code compatible with both Drupal 10 and 11, the core upgrade in `composer.json` was straightforward:

- `drupal/core-recommended`, `drupal/core-composer-scaffold`, and `drupal/core-project-message`: `10.6.21` → `11.4.12` (bringing in **Symfony 7.4**)
- `drush/drush`: `^12.5` → `^13.8`
- `drupal/bootstrap_barrio`: `5.5.20` → `5.5.22`

Running `composer update -W` and `drush updatedb -y` completed the core schema and configuration updates cleanly.

---

## Subtle Issues Caught Along the Way

Several non-obvious issues surfaced during local testing and deployment. Having an AI agent inspect the plugin definitions, display configurations, and browser console errors saved significant troubleshooting time.

### 1. `drupal/book 2.0` Hid the Book Outline Navigation

After switching from the core `book` module to contrib `drupal/book 2.0.x` and running `drush updatedb`, the book navigation block at the bottom of book pages (the child page tree and previous/up/next links) disappeared.

**Cause:** `drupal/book 2.0` converts the hardcoded book navigation into a configurable extra field (`book_navigation`) on the node entity view display, and its update hook places that component in the `hidden` region by default.

**Fix:** Re-enabling the `book_navigation` component on the `node.book.default` entity view display restored the bottom navigation immediately without modifying any Twig templates:

```bash
drush php:eval "
\$display = \Drupal::entityTypeManager()
  ->getStorage('entity_view_display')
  ->load('node.book.default');
\$display->setComponent('book_navigation', [
  'weight' => 100,
  'region' => 'content',
])->save();
"
```

### 2. `drupal/field_validation` 1.x → 3.0.0 (`PluginNotFoundException`)

Upgrading `drupal/field_validation` from `1.x` to `3.0.0` initially failed during `drush updatedb` with:

```text
Drupal\Component\Plugin\Exception\PluginNotFoundException: The "regex_field_validation_rule" plugin does not exist.
```

**Cause:** Version `3.0.0` renamed its core validation plugins and moved the legacy `1.x` plugin IDs (`regex_field_validation_rule`, `length_field_validation_rule`) into a bundled `field_validation_legacy` submodule.

**Fix:** Enabling the legacy submodule (`drush pm:enable field_validation_legacy -y`) before running `drush updatedb` allowed existing field validation rule sets to continue working without recreating configuration.

### 3. jQuery 4.0 in Drupal 11 vs. Legacy Bootstrap 4 Theme

The site uses a custom subtheme based on `bootstrap_barrio` with **Bootstrap 4.5.0**. Upgrading to Drupal 11 broke interactive Bootstrap 4 components (such as modal dialogs) due to two separate changes:

1. **Missing `core/jquery` Dependency in `bootstrap_barrio`:** Starting in `bootstrap_barrio 5.5.20`, the base theme dropped `core/jquery` from its `global-styling` library definition. On pages where no other module requested jQuery, `bootstrap.min.js` loaded without `window.jQuery`. Adding explicit `core/jquery` and `core/drupal` dependencies to the subtheme's `.libraries.yml` ensured jQuery always loaded before Bootstrap.
2. **Bootstrap 4's Hardcoded jQuery Version Check & Removed Helpers:** Drupal 11 upgraded core jQuery from `3.7.1` to **`4.0.0`**. Bootstrap 4.5.0 runs `Util.jQueryDetection()` on load, which checks the major version and throws:
   ```text
   TypeError: Bootstrap's JavaScript requires at least jQuery v1.9.1 but less than v4.0.0
   ```
   Additionally, Bootstrap 4 calls legacy jQuery utility methods (`$.isArray`, `$.trim`, `$.camelCase`) that were deprecated in jQuery 3 and removed in jQuery 4.0.

**Fix:** Rather than turning a 2-day core upgrade into a full Bootstrap 5 theme rewrite, we added an 18-line compatibility shim (`jquery4-bootstrap4-compat.js`) loaded immediately before `bootstrap.min.js` in the subtheme library:

```javascript
(function ($) {
  'use strict';
  if (!$) return;

  if (typeof $.isArray !== 'function') {
    $.isArray = Array.isArray;
  }
  if (typeof $.trim !== 'function') {
    $.trim = function (text) {
      return text == null ? '' : (text + '').trim();
    };
  }
  if (typeof $.camelCase !== 'function') {
    $.camelCase = function (string) {
      return (string + '')
        .replace(/^-ms-/, 'ms-')
        .replace(/-([a-z])/g, function (_all, letter) {
          return letter.toUpperCase();
        });
    };
  }
  if ($.fn && $.fn.jquery && $.fn.jquery.indexOf('4.') === 0) {
    $.fn.jquery = '3.7.1-compat (' + $.fn.jquery + ')';
  }
})(window.jQuery);
```

This polyfilled the three removed functions and satisfied Bootstrap 4's version check while keeping Drupal 11's native jQuery 4 runtime intact.

### 4. Post-Deploy Cron & `sites/default/files` Ownership

Shortly after deploying to production, Drupal's log reported a cron failure from the Feeds module:

```text
RuntimeException: Feeds directory "public://feeds/in_progress/..." either cannot be created or is not writable.
```

**Cause:** The server's user crontab was executing `drush cron` as the SSH user rather than the web server user (`www-data`). Whenever CLI cron created subdirectories inside `sites/default/files/feeds`, they were owned by the SSH user with `0755` permissions, preventing Apache (`www-data`) from writing to them on subsequent web requests.

**Fix:** Setting ownership of `sites/default/files` to `www-data:www-data` with the setgid bit (`chmod 2775`) and updating the crontab entry to run Drush as `sudo -u www-data` permanently prevented permission drift between CLI and web processes.

---

## Production Deployment

Because all dependency conflicts and schema updates were validated locally against a copy of the production database first, the production cutover took less than 15 minutes:

```bash
# 1. Back up database and enable maintenance mode
drush sql:dump --gzip --result-file=~/backups/pre-d11-upgrade.sql
drush state:set system.maintenance_mode 1 --input-format=integer
drush cr

# 2. Pull two-stage commits and install production dependencies
git pull origin main
composer install --no-dev --optimize-autoloader

# 3. Apply database updates and disable maintenance mode
drush updatedb -y
drush cr
drush state:set system.maintenance_mode 0 --input-format=integer
drush cr
```

---

## Key Takeaways

1. **Modern Drupal major upgrades are incremental:** Unlike the Drupal 7 → 9 migration, upgrading from Drupal 10 to 11 is an in-place Composer and database update operation that can be completed in a weekend.
2. **Bridge Drupal 10 and 11 in two stages:** Switching removed core modules (`book`, `tour`) and upgrading contrib blockers while still on Drupal 10.6 isolates module-level quirks (like `field_validation_legacy` and `book_navigation`) from the core upgrade itself.
3. **You don't have to rewrite a Bootstrap 4 theme just for jQuery 4:** A tiny compatibility shim for `$.isArray`, `$.trim`, `$.camelCase`, and `$.fn.jquery` lets legacy Bootstrap 4 JavaScript run smoothly on Drupal 11.
4. **AI agents excel at upgrade pre-flight checks:** Having an agent cross-reference custom code, `.info.yml` files, library definitions, and contrib upgrade paths upfront turned what is normally a tedious manual audit into a predictable checklist.
