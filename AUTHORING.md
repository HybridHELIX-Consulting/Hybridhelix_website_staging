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

## Rule 2 — Images are files in `images/`, not pasted markup

Every image lives under `images/`, in the directory that matches who owns the mark:

| Directory | Contents |
| --- | --- |
| `images/hhc/` | HybridHELIX brand assets — logo, wordmark, icons, original graphics |
| `images/clickup-verified/` | ClickUp Verified Consultant badges (ClickUp's marks, licensed to us) |

Upload the real file and reference it through `relative_url` so the path survives a
base URL change:

```liquid
<img src="{{ '/images/hhc/logo.png' | relative_url }}" width="34" height="34" alt="HybridHELIX">
```

Do not paste image markup, inline SVG approximations, or base64 blobs copied from
another tool. The homepage logo failed on first deploy for exactly this reason.

**The ClickUp badges are not ours to modify.** Do not recolor, crop, stretch, or add
effects, and do not place one where it implies ClickUp endorses a specific claim,
outcome, or price. See `images/clickup-verified/README.md` before using one.

## Rule 3 — URL structure is locked

`permalink: /:categories/:slug/` in `_config.yml`. Posts land at `/blog/<slug>/`
or `/reports/<slug>/` depending on their `categories` front matter. No dates in
URLs. Changing this rule after pages exist creates redirect debt, so it does not
change without a `DEC-W4-nnn` entry.

**Legal collection** uses a separate permalink: `/legal/:slug/`. Same lock applies.

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

**Known limitation:** the agent route can currently write to a branch but cannot
open or merge a pull request. Until that permission is granted, a human has to
file and merge every agent-authored change.

## Rule 6 — Legal/policy pages use the `_legal` collection

The `_legal` collection renders structured documents (legal, policy, public
statements, corrections) at `/legal/<slug>/`. It shares the layout system with
blog/reports but is a **separate collection** — no RSS feed, no author byline,
no related-posts logic.

### Front-matter schema

```yaml
---
title: "Privacy Policy"
effective_date: 2026-08-09
last_updated: 2026-08-09
summary: "How we collect and use personal data."
index: true
---
```

| Field | Required | Purpose |
| --- | --- | --- |
| `title` | Yes | Page heading and listing title |
| `effective_date` | Yes | When the document takes effect. Rendered automatically. |
| `last_updated` | When revised | Shows "Last updated" in the header. Omit on first publish. |
| `summary` | Recommended | One-line description for the `/legal/` index listing |
| `index` | No (defaults `true`) | Set `false` to hide from the `/legal/` listing page |

`layout: legal` is applied automatically by `_config.yml` defaults. Do not
override it unless you have a reason.

### Adding a new legal/policy page

1. Create a file in `_legal/` named `your-slug.md` (lowercase, dashes for spaces).
2. Add the front-matter block above with correct dates.
3. Write the body in Markdown below the closing `---`.
4. The page publishes at `/legal/your-slug/` and appears in the `/legal/` index.

### What not to do

- Do not put legal documents in `_posts/`. They are not blog posts.
- Do not add `categories` — legal pages route by collection, not by category.
- Do not add `author` or `tags` — these fields are ignored by the legal layout.

## Rule 7 — Assume everything you commit is being read by a stranger

The repository can be made private. **The site cannot.** Every word that reaches
`_legal/`, `_posts/`, a layout, or a root `.html` file is being published to
anyone who asks for it, including scrapers that never leave a log entry.

CI enforces a floor. `.github/scripts/disclosure-scan.sh` runs on every pull
request and inspects everything destined for `_site` in two tiers.

**Blocking — these fail the build.** Categorical items that have no legitimate
place on a marketing site:

| Class | What it catches |
| --- | --- |
| Tax identification | Federal EIN, whether labelled or bare |
| Personal identifiers | Social Security number patterns |
| Unsigned instruments | Blank fill-in fields and contract execution clauses |
| Credentials | Token, key, and private-key shapes |

**Advisory — these annotate the pull request without failing it.** Items that are
sometimes exactly what we intend to publish, and sometimes a leak:

| Class | Why it is a judgment call |
| --- | --- |
| Phone numbers | A published contact number is normal. An internal line is not. |
| Rates and retainers | Public pricing is a choice. One engagement's terms are not. |
| Contract vocabulary | Signals a document class that may not belong at this URL. |
| Street and suite detail | Legitimate on a legal page — just needs to be current. |

### Why the split

A pattern matcher can be certain that a signature block does not belong on a
website. It cannot be certain whether a price is one we mean to publish. Blocking
on the second class would produce a gate people learn to route around, which is
worse than no gate — a disabled check still looks green.

So the machine stops what is categorically wrong and shows a person what is
contextually questionable. **The judgment layer is still yours.** No scan will
ever ask the question that actually mattered on 8/9/2026: *is this the right kind
of document to be sitting at this URL at all?*

### Waiving a finding

Two ways, both visible in a diff:

1. Add the literal flagged text to `.disclosure-allow` with a comment naming who
   approved it and why.
2. Put the marker `disclosure-ok` on the same line.

Waiving is legitimate. Publishing a contact number should be possible. The point
is that it becomes a decision somebody made on purpose, in a reviewable diff,
rather than something that arrived by paste and left by accident.

**Never allowlist a credential.** Rotate it.

### Before you paste an exported document

Every incident this rule exists to prevent began the same way: an export from
another tool, pasted in good faith, published without being read end to end. Read
the whole thing first. Ask what class of document it is, who it was written for,
and whether that audience is the public.

## Where things live

| Path | Purpose |
| --- | --- |
| `_config.yml` | Site settings, collections, and the locked permalink rule |
| `_data/navigation.yml` | Global nav. Edit once, changes everywhere. `live: false` hides a planned link |
| `_includes/` | `head`, `header`, `footer`, `custom-head` (noindex) |
| `_layouts/` | `default`, `page`, `post`, `legal`, `solution`, `credibility` |
| `_posts/` | Markdown blog and reports. Filename: `YYYY-MM-DD-slug.md` |
| `_legal/` | Legal, policy, and public-statement documents. Filename: `slug.md` |
| `legal/index.html` | The `/legal/` listing page (auto-renders from `_legal` entries) |
| `assets/css/site.css` | Shared brand tokens and interior styles |
| `images/hhc/` | HybridHELIX brand assets |
| `images/clickup-verified/` | ClickUp Verified Consultant badges |
| `index.html` | Standalone homepage, fixed-width, not yet on the layout system |
| `.disclosure-allow` | Values explicitly approved for publication (Rule 7) |
| `.github/scripts/` | CI helper scripts, including the disclosure scan |
