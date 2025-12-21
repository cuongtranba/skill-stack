# WCAG Verify Skill Design

**Date:** 2025-12-21
**Status:** Approved

## Overview

**wcag-verify** is a post-task WCAG 2.1 A/AA verification skill for Skill Stack. It checks modified frontend files for accessibility issues with comprehensive color contrast analysis including interactive states.

## Design Decisions

| Aspect | Decision |
|--------|----------|
| **Location** | `/skills/wcag-verify/SKILL.md` |
| **Trigger** | After coding tasks, via natural language instruction |
| **Detection** | Git diff to find changed frontend files |
| **Analysis** | Claude reads code directly, no external tools |
| **Color contrast** | Full tracing: tokens → variables → components |
| **State checking** | hover, active, focus, disabled, placeholder, etc. |
| **Output** | Severity-grouped (critical → major → minor) |
| **Fixes** | Interactive, one-by-one, highest severity first |
| **Manual review** | Guided checklist for non-automatable criteria |
| **Coverage** | Full WCAG 2.1 Level A + AA (~50 criteria) |

## Scope Detection

The skill interprets the instruction argument to determine what to analyze:

| Instruction contains | Scope |
|---------------------|-------|
| "uncommitted" / "changed" / no instruction | `git diff --name-only` |
| "staged" | `git diff --cached --name-only` |
| file path | That specific file |
| folder path | All frontend files in folder |
| "all" / "entire project" | Full project scan |

**File filtering:** Only processes `*.html`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte`, `*.css`, `*.scss`

**Announcement:** "Checking [scope] for WCAG 2.1 A/AA compliance..."

## Automated Checks

Claude analyzes code directly to check these automatable criteria:

### Critical (blocks access)

- **1.1.1 Non-text Content** - Images missing `alt`, decorative images missing `alt=""`
- **1.3.1 Info & Relationships** - Form inputs missing labels, tables missing headers
- **2.1.1 Keyboard** - Click handlers without keyboard equivalents (`onClick` without `onKeyDown`)
- **4.1.2 Name, Role, Value** - Interactive elements missing accessible names

### Major (significant barriers)

- **1.4.3 Contrast (Minimum)** - Text/background ratio < 4.5:1 (normal) or < 3:1 (large)
- **1.4.11 Non-text Contrast** - UI components/graphics ratio < 3:1
- **2.4.4 Link Purpose** - Links with generic text ("click here", "read more")
- **1.3.5 Identify Input Purpose** - Form inputs missing `autocomplete` attributes
- **2.5.3 Label in Name** - Visible label doesn't match accessible name

### Minor (improvements)

- **1.4.4 Resize Text** - Fixed `px` font sizes instead of relative units
- **2.4.6 Headings & Labels** - Empty or non-descriptive headings
- **1.4.10 Reflow** - Horizontal scroll indicators (fixed widths > 320px)

## Color Contrast Analysis

### Step 1 - Find color usage in components

```jsx
// Inline styles
<div style={{ color: '#333', backgroundColor: 'var(--bg-primary)' }}>

// Tailwind classes
<p className="text-gray-600 bg-white">

// CSS classes
<span className="error-message">
```

### Step 2 - Trace to source values

```
text-gray-600 → tailwind.config.js → #4B5563
var(--bg-primary) → tokens.css → --bg-primary: #FAFAFA
.error-message → styles.scss → color: $error-red → #DC2626
```

### Step 3 - Compute and evaluate

```
Contrast Analysis:
┌─────────────────────────────────────────────────────┐
│ Location: src/components/Card.tsx:24                │
│ Text: #4B5563 (gray-600)                           │
│ Background: #FAFAFA (bg-primary)                   │
│ Ratio: 5.74:1                                      │
│ Result: ✓ PASS (AA requires 4.5:1)                 │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Location: src/components/Alert.tsx:12              │
│ Text: #FCA5A5 (red-300)                            │
│ Background: #FEE2E2 (red-100)                      │
│ Ratio: 1.53:1                                      │
│ Result: ✗ FAIL (AA requires 4.5:1, need #B91C1C)  │
└─────────────────────────────────────────────────────┘
```

### Step 4 - Suggest fixes

- Recommend accessible color alternatives
- Show exact hex values that would pass
- Preserve design intent (suggest closest passing shade)

## State-Based Contrast Checking

Check all interactive states for contrast compliance:

| State | Trigger | Common issues |
|-------|---------|---------------|
| `:hover` | Mouse over | Lighter colors, low contrast |
| `:active` | Clicking/pressing | Subtle feedback, same as hover |
| `:focus` | Keyboard navigation | Missing or low-contrast ring |
| `:focus-visible` | Keyboard only focus | Often forgotten entirely |
| `:visited` | Clicked links | Purple on dark backgrounds |
| `:disabled` | Inactive elements | Intentionally low (but still needs 3:1 for UI) |
| `::placeholder` | Input hints | Notorious for failing contrast |
| `::selection` | Text selection | Often ignored |

### How Claude traces states

```css
/* In CSS/SCSS */
.button {
  background: #3B82F6;
  color: white;           /* ← Check default */
}
.button:hover {
  background: #60A5FA;    /* ← Check hover: lighter blue */
}
.button:active {
  background: #2563EB;    /* ← Check active */
}
.button:disabled {
  background: #E5E7EB;
  color: #9CA3AF;         /* ← Check: needs 3:1 minimum */
}
```

```jsx
/* In Tailwind */
<button className="bg-blue-500 hover:bg-blue-400 active:bg-blue-600
                   focus:ring-2 focus:ring-blue-300
                   disabled:bg-gray-200 disabled:text-gray-400">
```

### State contrast output

```
State Contrast Analysis: src/components/Button.tsx

State        │ Text      │ Background │ Ratio  │ Required │ Status
─────────────┼───────────┼────────────┼────────┼──────────┼────────
default      │ #FFFFFF   │ #3B82F6    │ 4.68:1 │ 4.5:1    │ ✓ PASS
:hover       │ #FFFFFF   │ #60A5FA    │ 2.98:1 │ 4.5:1    │ ✗ FAIL
:active      │ #FFFFFF   │ #2563EB    │ 5.32:1 │ 4.5:1    │ ✓ PASS
:focus       │ ring #93C5FD on #3B82F6        │ 1.74:1 │ 3:1      │ ✗ FAIL
:disabled    │ #9CA3AF   │ #E5E7EB    │ 2.15:1 │ 3:1 (UI) │ ✗ FAIL
::placeholder│ #9CA3AF   │ #FFFFFF    │ 2.57:1 │ 4.5:1    │ ✗ FAIL

3 states failing. Suggested fixes:
• :hover → Use #2563EB instead of #60A5FA
• :focus → Use ring-blue-600 instead of ring-blue-300
• ::placeholder → Use #6B7280 (gray-500) or darker
```

## Output Format

```
═══════════════════════════════════════════════════════════════
WCAG 2.1 A/AA Verification Report
Files analyzed: 5 (from uncommitted changes)
═══════════════════════════════════════════════════════════════

CRITICAL (3 issues) - Blocks access for some users
───────────────────────────────────────────────────────────────
1. [1.1.1] Missing alt text
   src/components/ProductCard.tsx:18
   <img src={product.image} />
   Fix: Add alt={product.name} or alt="" if decorative

2. [2.1.1] Click without keyboard support
   src/components/Modal.tsx:45
   <div onClick={handleClose}>×</div>
   Fix: Use <button> or add onKeyDown + tabIndex

3. [4.1.2] Button missing accessible name
   src/components/IconButton.tsx:12
   <button><SearchIcon /></button>
   Fix: Add aria-label="Search"

MAJOR (5 issues) - Significant barriers
───────────────────────────────────────────────────────────────
4. [1.4.3] Contrast fail: :hover state
   src/components/Button.tsx:34
   Ratio: 2.98:1 (need 4.5:1)
   Fix: Use #2563EB instead of #60A5FA

5. [1.4.3] Contrast fail: ::placeholder
   src/components/Input.tsx:22
   ...

MINOR (2 issues) - Improvements recommended
───────────────────────────────────────────────────────────────
8. [1.4.4] Fixed font size
   src/styles/global.css:15
   font-size: 14px
   Fix: Use rem units (0.875rem)

═══════════════════════════════════════════════════════════════
Summary: 3 critical, 5 major, 2 minor
Manual checklist: 8 items pending

Proceed with fixes? (critical first)
```

## Fix Flow

After showing the report, Claude offers to fix issues by severity:

```
Starting with CRITICAL issues (3 total):

Issue 1/3: [1.1.1] Missing alt text
src/components/ProductCard.tsx:18

Current:  <img src={product.image} />

Options:
1. Add descriptive alt → <img src={product.image} alt={product.name} />
2. Mark as decorative → <img src={product.image} alt="" />
3. Skip (I'll fix manually)

Which approach?
```

After each fix, Claude applies the change and moves to the next issue.

## Manual Checklist

After automated fixes, transition to manual review:

```
═══════════════════════════════════════════════════════════════
Automated fixes complete: 8/10 issues resolved

Proceeding to manual review checklist...
═══════════════════════════════════════════════════════════════

Based on your changes, 8 manual checks apply:

PERCEIVABLE (3)
☐ 1.3.3 Sensory - Instructions don't rely on shape/color alone?
☐ 1.4.1 Color Use - Meaning conveyed beyond color?
☐ 1.4.13 Hover Content - Hover content dismissible/persistent?

OPERABLE (2)
☐ 2.4.3 Focus Order - Tab order logical?
☐ 2.4.7 Focus Visible - Focus indicator visible?

Let's start: Does your UI convey meaning using color alone?
(e.g., red for errors without text/icon)
```

### Manual item flow

1. Claude asks specific question
2. User answers yes/no/unsure
3. If issue found → Claude suggests fix
4. Mark pass/fail/not-applicable
5. Continue until complete

### Context-aware filtering

Only show checklist items relevant to the file types changed (e.g., skip audio/video criteria if no media files)

## File Structure

```
skills/wcag-verify/
└── SKILL.md          # Main skill definition (~400-500 lines)
```

## Key Differentiators

- **No external dependencies** - Pure code analysis by Claude
- **State-aware contrast checking** - Catches :hover, :focus, :disabled failures
- **Full color resolution chain** - Tailwind, CSS vars, design tokens
- **Checklist-driven** - Ensures completeness for non-automatable criteria
- **Severity-prioritized** - Critical issues fixed first
