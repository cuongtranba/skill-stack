---
name: wcag-verify
description: Post-task WCAG 2.1 A/AA verification - checks modified frontend files for accessibility issues with color contrast analysis including interactive states
---

# WCAG Verify Skill

## Overview

Verify frontend files for WCAG 2.1 Level A and AA compliance after coding tasks complete.

**Announce:** "Checking [scope] for WCAG 2.1 A/AA compliance..."

## When to Use

- After completing frontend development work
- Before committing UI changes
- When reviewing accessibility of components

## Scope Detection

Parse the instruction argument to determine what files to analyze:

| Instruction contains | Action |
|---------------------|--------|
| "uncommitted" / "changed" / empty | Run `git diff --name-only` |
| "staged" | Run `git diff --cached --name-only` |
| file path (e.g., `src/Button.tsx`) | Analyze that specific file |
| folder path (e.g., `src/components/`) | Find all frontend files in folder |
| "all" / "entire project" | Scan entire project |

**Frontend file extensions:** `*.html`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`

**Example scope commands:**
```bash
# Uncommitted changes
git diff --name-only | grep -E '\.(html|jsx|tsx|vue|svelte|css|scss)$'

# Staged changes
git diff --cached --name-only | grep -E '\.(html|jsx|tsx|vue|svelte|css|scss)$'

# Folder scan
find src/components -type f \( -name "*.tsx" -o -name "*.jsx" -o -name "*.vue" \)
```

If no frontend files found, report: "No frontend files found in [scope]. Nothing to verify."

## Automated Checks

Read each file and check for these WCAG violations:

### CRITICAL - Blocks access for some users

**1.1.1 Non-text Content (Level A)**
- Images missing `alt` attribute
- Images with empty `alt=""` that are not decorative
- `<svg>` without `aria-label` or `<title>`
- `<canvas>` without fallback text
- Icon fonts without text alternative

```jsx
// FAIL: Missing alt
<img src="photo.jpg" />

// PASS: Descriptive alt
<img src="photo.jpg" alt="Team photo from company retreat" />

// PASS: Decorative (explicitly empty)
<img src="decoration.svg" alt="" />
```

**1.3.1 Info and Relationships (Level A)**
- Form inputs without associated `<label>` or `aria-label`
- Tables without `<th>` headers
- Fieldsets without `<legend>`
- Related inputs not grouped

```jsx
// FAIL: Input without label
<input type="email" name="email" />

// PASS: With label
<label>Email <input type="email" name="email" /></label>

// PASS: With aria-label
<input type="email" aria-label="Email address" />
```

**2.1.1 Keyboard (Level A)**
- `onClick` without keyboard equivalent (`onKeyDown`/`onKeyPress`)
- Non-interactive elements with click handlers (missing `tabIndex`)
- Custom controls without keyboard support

```jsx
// FAIL: Click-only
<div onClick={handleClick}>Click me</div>

// PASS: Keyboard accessible
<button onClick={handleClick}>Click me</button>

// PASS: Div with keyboard support
<div onClick={handleClick} onKeyDown={handleKey} tabIndex={0} role="button">
  Click me
</div>
```

**4.1.2 Name, Role, Value (Level A)**
- Buttons containing only icons without `aria-label`
- Links without discernible text
- Custom components without ARIA roles
- Toggles without state indication (`aria-pressed`, `aria-expanded`)

```jsx
// FAIL: Icon-only button
<button><SearchIcon /></button>

// PASS: With aria-label
<button aria-label="Search"><SearchIcon /></button>

// PASS: With visually-hidden text
<button>
  <SearchIcon />
  <span className="sr-only">Search</span>
</button>
```

### MAJOR - Significant barriers

**1.4.3 Contrast Minimum (Level AA)**
- Text contrast ratio < 4.5:1 for normal text
- Text contrast ratio < 3:1 for large text (18pt+ or 14pt bold)
- See "Color Contrast Analysis" section for full details

**1.4.11 Non-text Contrast (Level AA)**
- UI component boundaries < 3:1 against background
- Focus indicators < 3:1 against background
- Graphical elements conveying information < 3:1

**2.4.4 Link Purpose (Level A)**
- Links with generic text: "click here", "read more", "learn more", "here"
- Multiple links with same text but different destinations
- Links that don't describe destination

```jsx
// FAIL: Generic text
<a href="/pricing">Click here</a>

// PASS: Descriptive
<a href="/pricing">View pricing plans</a>

// PASS: Context via aria-label
<a href="/article/123" aria-label="Read full article about React hooks">
  Read more
</a>
```

**1.3.5 Identify Input Purpose (Level AA)**
- Common inputs missing `autocomplete` attribute
- Applies to: name, email, tel, address, cc-number, etc.

```jsx
// FAIL: Missing autocomplete
<input type="email" name="email" />

// PASS: With autocomplete
<input type="email" name="email" autocomplete="email" />
```

**2.5.3 Label in Name (Level A)**
- Visible label text not included in accessible name
- `aria-label` that doesn't match visible text

```jsx
// FAIL: Mismatch
<button aria-label="Submit form">Send</button>

// PASS: Matches
<button aria-label="Send message">Send</button>
```

### MINOR - Improvements recommended

**1.4.4 Resize Text (Level AA)**
- Font sizes in fixed `px` units instead of relative (`rem`, `em`)
- Line heights in fixed units
- Container heights that could clip text

```css
/* FAIL: Fixed px */
font-size: 14px;

/* PASS: Relative units */
font-size: 0.875rem;
```

**2.4.6 Headings and Labels (Level AA)**
- Empty headings (`<h1></h1>`)
- Headings with only whitespace
- Non-descriptive headings ("Section 1", "Untitled")
- Skipped heading levels (h1 → h3)

```jsx
// FAIL: Empty
<h2></h2>

// FAIL: Skipped level
<h1>Title</h1>
<h3>Subsection</h3>  // Should be h2

// PASS: Descriptive hierarchy
<h1>Product Catalog</h1>
<h2>Electronics</h2>
```

**1.4.10 Reflow (Level AA)**
- Fixed widths > 320px that cause horizontal scroll
- `overflow-x: scroll` on content containers
- Viewport-dependent layouts without flexibility

```css
/* FAIL: Fixed width */
.container { width: 1200px; }

/* PASS: Flexible */
.container { max-width: 1200px; width: 100%; }
```

## Color Contrast Analysis

### Finding Colors in Code

Look for color definitions in:

**1. Inline styles (JSX/HTML)**
```jsx
<div style={{ color: '#333', backgroundColor: 'var(--bg-primary)' }}>
<p style="color: rgb(100, 100, 100)">
```

**2. Tailwind classes**
```jsx
<p className="text-gray-600 bg-white">
<button className="bg-blue-500 hover:bg-blue-400 text-white">
```

**3. CSS classes**
```jsx
<span className="error-message">
<div className="card-header">
```

### Tracing to Source Values

Resolve colors through the chain:

**Tailwind → Config:**
```
text-gray-600 → tailwind.config.js → colors.gray[600] → #4B5563
bg-blue-500 → tailwind.config.js → colors.blue[500] → #3B82F6
```

**CSS Variables → Definition:**
```
var(--bg-primary) → :root { --bg-primary: #FAFAFA }
var(--text-muted) → :root { --text-muted: var(--gray-500) } → #6B7280
```

**SCSS Variables → Definition:**
```
$error-red → _variables.scss → $error-red: #DC2626
color: $text-secondary → $text-secondary: #64748B
```

**Design Tokens → Source:**
```
--color-primary → tokens.json → { "color": { "primary": { "value": "#3B82F6" } } }
```

### Contrast Ratio Computation

Use WCAG 2.1 relative luminance formula:

```
Relative luminance L = 0.2126 * R + 0.7152 * G + 0.0722 * B
(where R, G, B are linearized: value <= 0.03928 ? value/12.92 : ((value+0.055)/1.055)^2.4)

Contrast ratio = (L1 + 0.05) / (L2 + 0.05)
(where L1 is lighter, L2 is darker)
```

**Requirements:**
- Normal text (< 18pt or < 14pt bold): 4.5:1 minimum
- Large text (≥ 18pt or ≥ 14pt bold): 3:1 minimum
- UI components & graphics: 3:1 minimum

### Common Tailwind Color Contrast Reference

| Text Class | On White | On Gray-100 | On Gray-900 |
|------------|----------|-------------|-------------|
| gray-400 (#9CA3AF) | 2.68:1 ✗ | 2.45:1 ✗ | 5.48:1 ✓ |
| gray-500 (#6B7280) | 4.54:1 ✓ | 4.15:1 ✗ | 3.23:1 ✗ |
| gray-600 (#4B5563) | 7.08:1 ✓ | 6.47:1 ✓ | 2.07:1 ✗ |
| gray-700 (#374151) | 10.31:1 ✓ | 9.43:1 ✓ | 1.42:1 ✗ |
