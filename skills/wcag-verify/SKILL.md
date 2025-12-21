---
name: wcag-verify
description: Post-task WCAG 2.1 A/AA verification - checks modified frontend files for accessibility issues with color contrast analysis including interactive states
---

# WCAG Verify Skill

Verify frontend files for WCAG 2.1 Level A/AA compliance after coding tasks.

**Announce:** "Checking [scope] for WCAG 2.1 A/AA compliance..."

## Scope Detection

| Instruction | Action |
|-------------|--------|
| empty / "uncommitted" / "changed" | `git diff --name-only` |
| "staged" | `git diff --cached --name-only` |
| file/folder path | Analyze specified path |
| "all" | Full project scan |

Filter for: `*.html`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`

## Automated Checks

### CRITICAL (Level A) - Blocks access
- **1.1.1** Images missing `alt` (or empty alt on non-decorative)
- **1.3.1** Form inputs without labels, tables without headers
- **2.1.1** `onClick` without keyboard support (`onKeyDown`/`tabIndex`)
- **4.1.2** Icon-only buttons without `aria-label`, missing ARIA states

### MAJOR (Level A/AA) - Significant barriers
- **1.4.3** Text contrast < 4.5:1 (or < 3:1 for large text)
- **1.4.11** UI component contrast < 3:1
- **2.4.4** Generic link text ("click here", "read more")
- **1.3.5** Inputs missing `autocomplete` attribute
- **2.5.3** `aria-label` doesn't match visible text

### MINOR (Level AA) - Improvements
- **1.4.4** Font sizes in `px` instead of `rem`/`em`
- **2.4.6** Empty headings, skipped heading levels
- **1.4.10** Fixed widths > 320px causing horizontal scroll

## Color Contrast Analysis

**Trace colors through:** inline styles → Tailwind classes → CSS variables → SCSS variables → design tokens

**Check ALL states:** default, `:hover`, `:active`, `:focus`, `:disabled`, `::placeholder`

**Requirements:** Normal text 4.5:1, large text 3:1, UI components 3:1

**Common Tailwind issues:**
- `gray-400` fails on white (2.68:1) - use `gray-500`+
- `hover:bg-blue-400` often fails - use darker shade
- `placeholder-gray-400` fails - use `placeholder-gray-500`+

## Output Format

Group by severity: CRITICAL → MAJOR → MINOR

For each issue show: criterion, file:line, code snippet, fix suggestion

## Fix Flow

1. Present severity-grouped report
2. Offer to fix CRITICAL first, then MAJOR, then MINOR
3. For each: show current code, offer fix options, apply with Edit tool
4. Track: fixed / skipped / declined

## Manual Checklist

After automated fixes, walk through items needing human judgment:

**Perceivable:** 1.2.1 Media alternatives, 1.3.3 Sensory instructions, 1.4.1 Color-only meaning
**Operable:** 2.1.2 Keyboard trap, 2.2.1 Timing, 2.3.1 Flashes, 2.4.3 Focus order, 2.4.7 Focus visible
**Understandable:** 3.1.1 Lang attribute, 3.2.1/3.2.2 Context changes, 3.3.1/3.3.2 Error handling
**Robust:** 4.1.1 Valid HTML (no duplicate IDs)

Filter checklist by file content (skip media items if no video/audio).

## Guidelines

- Read files thoroughly before flagging
- Be specific: file path + line number + actual code
- Trace colors fully through all layers
- Check ALL interactive states for contrast
- Offer fixes with exact replacement code
- Ask when criteria need human judgment
