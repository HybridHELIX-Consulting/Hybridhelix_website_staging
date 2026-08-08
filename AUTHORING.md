# Authoring rules — HybridHELIX Website 4.0

Seed input for the publish runbook (**30.6.8 / MARKETING-920**). This file is the
technical contract. The runbook is the plain-language version for non-developers.

---

## Rule 1 — Every page uses a layout, or you add the noindex line yourself

Crawl protection lives in `_includes/custom-head.html` and is only applied to pages
rendered through a Jekyll layout. **A raw `.html` file dropped into the repository
root publishes with no crawl protection and no warning.**

There is no third option. Either the file starts with front matter naming a layout:

```
---
layout: page
title: Your page title
---
```

or you paste this line into its `<head>` yourself:

```html
<meta name="robots" content="noindex, nofollow">
```

CI enforces this. `.github/workflows/publish-safety.yml` fails the build on any
root-level `.html` file that has neither. This applies to agent-authored commits
exactly as it applies to human ones.

## Rule 2 — Images are files in the repo, not pasted markup

Upload the image file to the repository and reference it by relative path:

```html
<img src="/logo.png" width="34" height="34" alt="HybridHELIX">
```

Do not paste image markup, inline SVG approximations, or base64 blobs copied from
another tool. The homepage logo failed on first deploy for exactly this reason.

## Rule 3 — URL structure is locked

`permalink: /:categories/:slug/` in `_config.yml`. Posts land at `/blog/<slug>/`
or `/reports/<slug>/` depending on their `categories` front matter. No dates in
URLs. Changing this rule after pages exist creates redirect debt, so it does not
change without a `DEC-W4-nnn` entry.

## Rule 4 — Nothing goes to `main` without a pull request

Per **DEC-W4-004**. Direct-to-main is not authorized for humans or agents.
Loosening it requires a new decision register entry, not an informal relaxation.

## Rule 5 — Three publish routes exist, and you should know all three

| Route | Who | When |
| --- | --- | --- |
| Browser edit via `github.dev` (press `.` on the repo) | Any publisher, iPad friendly | Copy changes, new posts |
| Pull request review and merge | Certified publishers | Every change, always the last step |
| Agent-authored commit via the GitHub MCP server | Brain and Andrew-configured agents | Bulk or generated content |

A publisher who does not know an agent may also be committing will eventually be
surprised by a change they did not make. Expect PRs you did not open.

## Where things live

| Path | Purpose |
| --- | --- |
| `_config.yml` | Site settings and the locked permalink rule |
| `_data/navigation.yml` | Global nav. Edit once, changes everywhere. `live: false` hides a planned link |
| `_includes/` | `head`, `header`, `footer`, `custom-head` (noindex) |
| `_layouts/` | `default`, `page`, `post`, `solution`, `credibility` |
| `_posts/` | Markdown blog and reports. Filename: `YYYY-MM-DD-slug.md` |
| `assets/css/site.css` | Shared brand tokens and interior styles |
| `index.html` | Standalone homepage, fixed-width, not yet on the layout system |
