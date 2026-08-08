# Site images

Every image used on the site lives here, sorted by who owns the mark.

| Directory | Contents | Ownership |
| --- | --- | --- |
| `hhc/` | HybridHELIX brand assets — logo, wordmark, icons, original graphics | Ours. We control these. |
| `clickup-verified/` | ClickUp Verified Consultant badges | ClickUp's marks, licensed to us. Usage rules apply. |

## Rules

**Reference images by relative path from the site root.** For example
`/images/hhc/logo.png`. In a Jekyll layout or include, use the `relative_url`
filter so the path survives a base URL change:

```liquid
<img src="{{ '/images/hhc/logo.png' | relative_url }}" alt="HybridHELIX">
```

**Upload the actual file.** Do not paste inline SVG approximations, base64
blobs, or image markup copied out of another tool. The homepage logo failed on
its first deploy for exactly that reason.

**Never mix the two directories.** ClickUp's badges are ClickUp's marks. Keeping
them in their own lane means we can audit our usage against their brand terms
without untangling them from our own assets first.

**Always set meaningful `alt` text.** Decorative images get `alt=""`. Everything
else gets a real description.
