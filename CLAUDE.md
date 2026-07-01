# CLAUDE.md — Static SEO Site Build Guide

Full workflow: from brief to GitHub Pages deploy.
Applies to all static HTML ranking/review/editorial sites.

---

## 1. File Architecture

```
├── index.html                  ← Built output (never edit directly)
├── about/index.html            ← Built output
├── editorial-policy/index.html ← Built output
├── contact/index.html          ← Built output
├── cookie-policy/index.html    ← Built output
├── components/
│   ├── header.html             ← Shared nav (no <html>/<head> boilerplate)
│   └── footer.html             ← Shared footer
├── content/
│   ├── main-ranking.html       ← Main page body content
│   ├── about.html
│   ├── editorial-policy.html
│   ├── contact.html
│   └── cookie-policy.html
├── css/
│   ├── global.css              ← Reset, typography, header, footer, layout
│   └── ranking.css             ← Page-specific styles (one per unique layout)
├── images/                     ← All images here
│   └── logo.svg
├── js/
│   └── nav.js                  ← Mobile nav toggle only
├── build.sh                    ← Assembles all pages
├── .nojekyll                   ← Required for GitHub Pages (disables Jekyll)
├── README.md
└── CLAUDE.md                   ← This file
```

**Rule:** Only edit files in `content/`, `components/`, `css/`, `js/`, `images/`.
Run `bash build.sh` after every change. Never edit built `index.html` files directly.

---

## 2. build.sh — Key Patterns

### Relative paths (required for GitHub Pages)

Pages live at different depths:
- `index.html` → depth 0 → BASE = `""`
- `about/index.html` → depth 1 → BASE = `"../"`

Pass depth as 9th argument to `build_page`. The function auto-converts all
`/css/`, `/images/`, `/js/`, nav `href="/..."` to relative equivalents via `sed`.

### Active nav injection + path conversion in one sed pass

```bash
sed \
  -e "s|href=\"$ACTIVE_NAV\"|href=\"$ACTIVE_NAV\" class=\"active\"|g" \
  -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
  -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
  -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
  "$HEADER" > "$TMP_HEADER"
```

Apply the same sed (minus active class) to footer and content files.

### Always use temp files, never heredoc for complex content

Heredoc breaks on special characters in variables (JSON-LD, descriptions with quotes).
Use `{ echo ...; cat ...; } > "$OUT"` pattern instead.

---

## 3. CSS — Base Rules

### global.css must define

```css
:root {
  --max-width: 1160px;   /* content width */
  --color-primary: ...;
  --color-text: ...;
  --radius: ...;
}

*, *::before, *::after { box-sizing: border-box; }

.container {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 1.5rem;
}

/* Header */
.site-header .container { height: 64px; display: flex; align-items: center; }

/* Logo */
.site-logo__img { height: 52px; width: auto; display: block; }
```

### Mobile-first, single breakpoint

```css
/* Mobile default styles */
@media (min-width: 768px) {
  /* Desktop overrides */
}
```

### Full-width sections inside a constrained layout

If a grid/sidebar layout constrains content width but you need a full-width table
or banner — move it **outside** the grid container into its own `.container` div.
Do not try to break out of CSS Grid with negative margins.

---

## 4. SVG Logo

### Critical: always set explicit width + height on `<img>`

SVG with only `viewBox` and no `width`/`height` attributes renders at 0×0 in browsers.

```html
<!-- CORRECT -->
<img src="images/logo.svg" height="52" width="281" alt="...">

<!-- WRONG — disappears -->
<img src="images/logo.svg" alt="...">
```

Width must be proportional to viewBox: `width = height × (viewBox_width / viewBox_height)`.

### Logo font should match nav font

Nav uses Inter 500–600. Logo wordmark: `font-weight="600"`. Tagline: `font-weight="400"`.
Do not use `font-weight="800"` or `'Arial Black'` in logo — it looks heavier than nav.

---

## 5. Images

### Always use object-fit + object-position for cards

```html
<figure class="operator-card__image">
  <img src="images/photo.jpg" alt="..." loading="lazy"
       style="object-position: center 65%" width="820" height="320">
</figure>
```

```css
.operator-card__image img {
  width: 100%;
  aspect-ratio: 820 / 320;
  object-fit: cover;
  display: block;
}
```

Default `object-position: center center` often cuts the subject. Adjust per image:
- Horizon/sky images: `center 65–72%` (pulls frame down, shows more of subject)
- Underwater/low subjects: `center 30–40%`

### Hero background image

```css
.hero {
  background-image: url('images/hero.jpg');
  background-size: cover;
  background-position: center;
  position: relative;
}
.hero::after {
  content: '';
  position: absolute; inset: 0;
  background: linear-gradient(to bottom, rgba(0,0,0,.45), rgba(0,0,0,.2));
}
```

---

## 6. HTML — Required Elements

### Every page must have

```html
<meta name="description" content="...">
<link rel="canonical" href="https://domain.com/page/">
<meta property="og:type" content="article">
<meta property="og:title" content="...">
<meta property="og:description" content="...">
<meta property="og:url" content="...">
```

### Structured data (index.html)

Include both Article and FAQPage JSON-LD schemas in `<head>`.
Define them as a bash variable using `$(cat <<'JSONLD' ... JSONLD)` to avoid
shell interpolation of `$` in JSON.

### Accordion FAQ — no JS needed

```html
<details>
  <summary>Question text</summary>
  <p>Answer text</p>
</details>
```

### Comparison table

Wrap table in its own `.container` div outside any sidebar grid.
Set `overflow-x: auto` on the wrapper for mobile scroll.
`th:first-child` (rank #) → `width: 36px; min-width: 36px`.
`th:nth-child(2)` (name) → `min-width: 160px`.

---

## 7. JS

Only one file: `nav.js` for mobile hamburger toggle.
No JS required for content rendering — everything works without JS.

```js
const btn = document.querySelector('.nav-toggle');
const nav = document.querySelector('.site-nav');
btn?.addEventListener('click', () => {
  const open = btn.getAttribute('aria-expanded') === 'true';
  btn.setAttribute('aria-expanded', String(!open));
  nav.classList.toggle('is-open');
});
```

---

## 8. GitHub Pages Deploy

### One-time setup

```bash
# In project root
git init -b main
git config user.name "username"
git config user.email "username@users.noreply.github.com"
touch .nojekyll          # REQUIRED — disables Jekyll, enables direct file serving
git add .
git commit -m "Initial build"
git remote add origin https://github.com/USERNAME/REPO.git
git push -u origin main  # requires Personal Access Token as password
```

### Enable Pages

Repo → Settings → Pages → Source: `Deploy from branch` → `main` / `/(root)` → Save.

URL: `https://USERNAME.github.io/REPO/`

### .nojekyll is mandatory

Without it, GitHub Pages runs Jekyll which can silently break CSS loading.
Always commit an empty `.nojekyll` file at the repo root.

### Relative paths are mandatory

Absolute paths (`/css/global.css`) resolve to the domain root, not the repo subfolder.
On GitHub Pages `https://user.github.io/repo/`, the subfolder is `/repo/` so:
- `/css/global.css` → tries `https://user.github.io/css/global.css` → 404
- `css/global.css` → resolves to `https://user.github.io/repo/css/global.css` ✓

### Push updates

```bash
bash build.sh
git add -A
git commit -m "Description of change"
git push
```

GitHub Pages redeploys in ~1 minute after push.

### Custom domain (optional)

Add a `CNAME` file at repo root containing the domain:
```
best-antarctica-cruise-companies.com
```
Then point the domain's DNS to GitHub Pages IPs. Free, works with apex domains.

---

## 9. Common Pitfalls

| Problem | Cause | Fix |
|---|---|---|
| Site has no styles locally | Absolute paths `/css/...` break on `file://` | Use relative paths |
| Site has no styles on GitHub Pages | Absolute paths or Jekyll processing | Relative paths + `.nojekyll` |
| SVG logo invisible | No `width`/`height` on `<img>` tag | Add `height="52" width="281"` |
| Table too narrow | Table inside sidebar grid column | Move table outside grid |
| Image cuts subject | Default `object-position: center` | Add inline `style="object-position: center 65%"` |
| `git push` auth fails | No credentials configured | Use Personal Access Token as password |
| Bold text in descriptions | Automatic `<strong>` tags | Remove with `perl -0777 -i -pe 's|<strong>(.*?)</strong>|\1|gs'` |

---

## 10. SEO Checklist

- [ ] Unique `<title>` per page (≤60 chars)
- [ ] Unique `<meta name="description">` per page (≤160 chars)
- [ ] `<link rel="canonical">` with full URL on every page
- [ ] JSON-LD Article schema on main page
- [ ] JSON-LD FAQPage schema if FAQ section exists
- [ ] All images have descriptive `alt` text
- [ ] `loading="lazy"` on all below-fold images
- [ ] `<nav role="navigation" aria-label="Main navigation">`
- [ ] `<main>`, `<header role="banner">`, `<footer role="contentinfo">`
- [ ] Mobile viewport meta tag
- [ ] No affiliate links disclosed if present; if none, state it in footer



# CLAUDE.md — Frontend Website Rules

## Always Do First
- **Invoke the `frontend-design` skill** before writing any frontend code, every session, no exceptions.

## Reference Images
- **Always check `images/` folder first** before writing any CSS or HTML — reference files (reference.webp, reference.png) may already be there.
- If a reference image exists: extract its color palette, typography, spacing rhythm, and overall aesthetic — then apply those to the existing content and structure. Do not copy the reference layout verbatim; adapt it to fit the actual page content and keep the current page structure intact.
- If no reference image: design from scratch with high craft (see guardrails below).
- Screenshot your output, compare against reference, fix mismatches, re-screenshot. Do at least 2 comparison rounds. Stop only when the aesthetic direction clearly matches or user says so.

## Local Server
- **Always serve on localhost** — never screenshot a `file:///` URL.
- Start the dev server: `node serve.mjs` (serves the project root at `http://localhost:3000`)
- `serve.mjs` lives in the project root. Start it in the background before taking any screenshots.
- If the server is already running, do not start a second instance.

## Screenshot Workflow
- Puppeteer is installed at `/Users/vladimir/.npm-global/lib/node_modules/puppeteer`. Chrome cache is at `/Users/vladimir/.cache/puppeteer/chrome/mac_arm-150.0.7871.24/chrome-mac-arm64/`.
- **Always screenshot from localhost:** `node screenshot.mjs http://localhost:3000`
- Screenshots are saved automatically to `./temporary screenshots/screenshot-N.png` (auto-incremented, never overwritten).
- Optional label suffix: `node screenshot.mjs http://localhost:3000 label` → saves as `screenshot-N-label.png`
- `screenshot.mjs` lives in the project root. Use it as-is.
- After screenshotting, read the PNG from `temporary screenshots/` with the Read tool — Claude can see and analyze the image directly.
- When comparing, be specific: "heading is 32px but reference shows ~24px", "card gap is 16px but should be 24px"
- Check: spacing/padding, font size/weight/line-height, colors (exact hex), alignment, border-radius, shadows, image sizing
- Before first screenshot run `npm install puppeteer` in project root if `node_modules` is missing.

## Output Defaults
- Single `index.html` file, all styles inline, unless user says otherwise
- Tailwind CSS via CDN: `<script src="https://cdn.tailwindcss.com"></script>`
- Placeholder images: `https://placehold.co/WIDTHxHEIGHT`
- Mobile-first responsive

## Brand Assets
- Always check the `brand_assets/` folder before designing. It may contain logos, color guides, style guides, or images.
- If assets exist there, use them. Do not use placeholders where real assets are available.
- If a logo is present, use it. If a color palette is defined, use those exact values — do not invent brand colors.

## Anti-Generic Guardrails
- **Colors:** Never use default Tailwind palette (indigo-500, blue-600, etc.). Pick a custom brand color and derive from it.
- **Shadows:** Never use flat `shadow-md`. Use layered, color-tinted shadows with low opacity.
- **Typography:** Never use the same font for headings and body. Pair a display/serif with a clean sans. Apply tight tracking (`-0.03em`) on large headings, generous line-height (`1.7`) on body.
- **Gradients:** Layer multiple radial gradients. Add grain/texture via SVG noise filter for depth.
- **Animations:** Only animate `transform` and `opacity`. Never `transition-all`. Use spring-style easing.
- **Interactive states:** Every clickable element needs hover, focus-visible, and active states. No exceptions.
- **Images:** Add a gradient overlay (`bg-gradient-to-t from-black/60`) and a color treatment layer with `mix-blend-multiply`.
- **Spacing:** Use intentional, consistent spacing tokens — not random Tailwind steps.
- **Depth:** Surfaces should have a layering system (base → elevated → floating), not all sit at the same z-plane.

## Hard Rules
- Do not add sections, features, or content not in the reference
- Do not "improve" a reference design — match it
- Do not stop after one screenshot pass
- Do not use `transition-all`
- Do not use default Tailwind blue/indigo as primary color