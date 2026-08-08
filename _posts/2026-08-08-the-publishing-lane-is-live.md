---
title: "The publishing lane is live"
categories: [blog]
lede: "A test of the Website 4.0 markdown publishing path: one file, correct branding, no manual steps."
---

This post exists to prove one thing: a markdown file dropped into `_posts` publishes as a fully branded page with no hand-built HTML and no manual upload.

If you are reading this on `staging.hybridhelix.net` and the header, footer, and colors match the homepage, the acceptance test for **30.6.5** passed.

## What this proves

1. **Navigation is centralized.** The header above is rendered from `_includes/header.html`, driven by `_data/navigation.yml`. One edit changes every page on the site.
2. **Crawl protection is inherited.** Every layout-based page carries `noindex, nofollow` automatically. Nobody has to remember it.
3. **URLs are stable.** This page lives at `/blog/the-publishing-lane-is-live/`. No dates in the path, so re-dating a draft never breaks a link.
4. **Reports have their own lane.** Setting `categories: [reports]` in front matter routes a post to `/reports/<slug>/` instead, with no second content system to maintain.

## What a post needs

Three lines of front matter and a body:

```
---
title: "Your headline"
categories: [blog]
lede: "One sentence that shows up on the index page."
---
```

That is the whole authoring contract. Everything else is inherited.

## What it does not prove

This is staging. It is deliberately hidden from search engines, and the root domain is untouched. The cutover to `hybridhelix.net` is gated on a complete redirect map and a dated search baseline, not on a date.
