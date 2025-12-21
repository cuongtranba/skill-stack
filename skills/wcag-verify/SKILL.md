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
