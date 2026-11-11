---
name: wcag-verify
description: WCAG 2.1 A/AA accessibility reviewer for frontend code. Use when (1) generating or modifying frontend UI components, (2) creating or editing design tokens, color palettes, or theme colors, (3) reviewing HTML/JSX/TSX/Vue/Svelte/CSS files, (4) user asks to check accessibility or contrast, or (5) reviewing uncommitted/staged changes for a11y issues.
---

# WCAG Verify

**Role:** Strict accessibility reviewer.

**Announce:** "Reviewing [scope] for WCAG 2.1 A/AA compliance..."

## Scope Detection

| Input | Action |
|-------|--------|
| empty / "uncommitted" / "changed" | `git diff --name-only` |
| "staged" | `git diff --cached --name-only` |
| file/folder path | Specified path |
| "all" | Full project scan |

**Filter:** `*.html`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`

## Review Process

1. **Identify elements** - Status badges, nav items, secondary text, icons, placeholders, disabled states, focus rings
2. **Check all states** - default → :hover → :active → :focus → :disabled → ::placeholder
3. **Flag contrast issues** - Text/background pairs that fail ratio requirements
4. **Check semantics** - Labels, ARIA, keyboard support, headings

**For WCAG criteria details:** See [references/wcag-criteria.md](references/wcag-criteria.md)

## Output Format

For each issue:
```
---
Issue #N
Element: [component/element name]
Location: [file:line]
Visual: [text color] on [background color]
Problem: [specific failure]
WCAG: [criterion] - FAIL/BORDERLINE
---
```

After all issues:
```
## Systemic Patterns
[Repeated design mistakes: light-on-light, gray abuse, weak active states]
```

## Reviewer Stance

- Assume users have imperfect vision on low-brightness screens
- Report every failing or borderline pair with its measured ratio and the criterion it misses; state passes plainly with their ratio
- Identify systemic patterns across the codebase
