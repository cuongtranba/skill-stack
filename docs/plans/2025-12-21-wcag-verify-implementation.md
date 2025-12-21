# WCAG Verify Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create the wcag-verify skill that checks modified frontend files for WCAG 2.1 Level A/AA compliance with comprehensive color contrast analysis.

**Architecture:** Single SKILL.md file containing all instructions for Claude to perform accessibility verification. Claude reads code directly (no external tools), traces colors through variables/tokens, and provides severity-grouped output with interactive fixes.

**Tech Stack:** Markdown skill definition, Git for file detection, Claude's code analysis capabilities.

---

## Task 1: Create Skill Directory and Frontmatter

**Files:**
- Create: `skills/wcag-verify/SKILL.md`

**Step 1: Create the skill directory**

```bash
mkdir -p skills/wcag-verify
```

**Step 2: Create SKILL.md with frontmatter and overview**

```markdown
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
```

**Step 3: Verify file exists**

Run: `cat skills/wcag-verify/SKILL.md`
Expected: Shows frontmatter and overview section

**Step 4: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): create skill with frontmatter and overview"
```

---

## Task 2: Add Scope Detection Section

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add scope detection logic**

Append to SKILL.md:

```markdown
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
```

**Step 2: Verify content added**

Run: `grep -c "Scope Detection" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add scope detection section"
```

---

## Task 3: Add Critical Automated Checks

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add critical checks section**

Append to SKILL.md:

```markdown
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
```

**Step 2: Verify content added**

Run: `grep -c "CRITICAL" skills/wcag-verify/SKILL.md`
Expected: 1 or more

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add critical automated checks (1.1.1, 1.3.1, 2.1.1, 4.1.2)"
```

---

## Task 4: Add Major Automated Checks

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add major checks section**

Append to SKILL.md:

```markdown
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
```

**Step 2: Verify content added**

Run: `grep -c "MAJOR" skills/wcag-verify/SKILL.md`
Expected: 1 or more

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add major automated checks (1.4.3, 1.4.11, 2.4.4, 1.3.5, 2.5.3)"
```

---

## Task 5: Add Minor Automated Checks

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add minor checks section**

Append to SKILL.md:

```markdown
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
```

**Step 2: Verify content added**

Run: `grep -c "MINOR" skills/wcag-verify/SKILL.md`
Expected: 1 or more

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add minor automated checks (1.4.4, 2.4.6, 1.4.10)"
```

---

## Task 6: Add Color Contrast Analysis Section

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add color contrast section**

Append to SKILL.md:

```markdown
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
```

**Step 2: Verify content added**

Run: `grep -c "Contrast Ratio Computation" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add color contrast analysis section"
```

---

## Task 7: Add State-Based Contrast Checking

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add state-based contrast section**

Append to SKILL.md:

```markdown
## State-Based Contrast Checking

Check ALL interactive states, not just default:

| State | CSS Selector | Common Issues |
|-------|--------------|---------------|
| Default | (none) | Base colors |
| Hover | `:hover` | Often lighter, loses contrast |
| Active | `:active` | Subtle change, same as hover |
| Focus | `:focus`, `:focus-visible` | Ring/outline too light |
| Visited | `:visited` | Purple on dark backgrounds |
| Disabled | `:disabled`, `[disabled]` | Needs 3:1 for UI components |
| Placeholder | `::placeholder` | Notorious for failing |
| Selection | `::selection` | Often forgotten |

### Tracing States in CSS

```css
.button {
  background: #3B82F6;    /* ← Check default */
  color: white;
}
.button:hover {
  background: #60A5FA;    /* ← Check: lighter blue, may fail */
}
.button:active {
  background: #2563EB;    /* ← Check active */
}
.button:focus {
  outline: 2px solid #93C5FD;  /* ← Check focus ring contrast */
}
.button:disabled {
  background: #E5E7EB;
  color: #9CA3AF;         /* ← Check: needs 3:1 minimum */
}
```

### Tracing States in Tailwind

```jsx
<button className="
  bg-blue-500 text-white           // default
  hover:bg-blue-400                 // hover - lighter!
  active:bg-blue-600                // active
  focus:ring-2 focus:ring-blue-300  // focus ring
  disabled:bg-gray-200 disabled:text-gray-400  // disabled
">
```

Map each state prefix to its color and check contrast.

### State Contrast Output Format

```
State Contrast Analysis: src/components/Button.tsx

State        │ Foreground │ Background │ Ratio  │ Required │ Status
─────────────┼────────────┼────────────┼────────┼──────────┼────────
default      │ #FFFFFF    │ #3B82F6    │ 4.68:1 │ 4.5:1    │ ✓ PASS
:hover       │ #FFFFFF    │ #60A5FA    │ 2.98:1 │ 4.5:1    │ ✗ FAIL
:active      │ #FFFFFF    │ #2563EB    │ 5.32:1 │ 4.5:1    │ ✓ PASS
:focus-ring  │ #93C5FD    │ #3B82F6    │ 1.74:1 │ 3:1      │ ✗ FAIL
:disabled    │ #9CA3AF    │ #E5E7EB    │ 2.15:1 │ 3:1      │ ✗ FAIL
::placeholder│ #9CA3AF    │ #FFFFFF    │ 2.57:1 │ 4.5:1    │ ✗ FAIL

Suggested fixes:
• :hover → Use bg-blue-600 (#2563EB) instead of bg-blue-400
• :focus-ring → Use ring-blue-600 instead of ring-blue-300
• :disabled → Use text-gray-500 (#6B7280) for 3:1 minimum
• ::placeholder → Use placeholder-gray-500 or darker
```
```

**Step 2: Verify content added**

Run: `grep -c "State-Based Contrast" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add state-based contrast checking"
```

---

## Task 8: Add Output Format Section

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add output format section**

Append to SKILL.md:

```markdown
## Output Format

Present findings grouped by severity:

```
═══════════════════════════════════════════════════════════════════════
WCAG 2.1 A/AA Verification Report
Files analyzed: N (from [scope description])
═══════════════════════════════════════════════════════════════════════

CRITICAL (N issues) - Blocks access for some users
───────────────────────────────────────────────────────────────────────
1. [1.1.1] Missing alt text
   src/components/ProductCard.tsx:18
   <img src={product.image} />
   Fix: Add alt={product.name} or alt="" if decorative

2. [2.1.1] Click handler without keyboard support
   src/components/Modal.tsx:45
   <div onClick={handleClose}>×</div>
   Fix: Use <button> or add onKeyDown + tabIndex + role="button"

MAJOR (N issues) - Significant barriers
───────────────────────────────────────────────────────────────────────
3. [1.4.3] Contrast fail: :hover state
   src/components/Button.tsx:34
   Text #FFFFFF on background #60A5FA
   Ratio: 2.98:1 (need 4.5:1)
   Fix: Use #2563EB (bg-blue-600) instead

4. [1.4.3] Contrast fail: ::placeholder
   src/components/Input.tsx:22
   Placeholder #9CA3AF on background #FFFFFF
   Ratio: 2.57:1 (need 4.5:1)
   Fix: Use #6B7280 (gray-500) or darker

MINOR (N issues) - Improvements recommended
───────────────────────────────────────────────────────────────────────
5. [1.4.4] Fixed font size
   src/styles/global.css:15
   font-size: 14px
   Fix: Use 0.875rem instead

═══════════════════════════════════════════════════════════════════════
Summary: N critical, N major, N minor
Manual checklist: N items to review

Proceed with fixes? (Starting with CRITICAL)
═══════════════════════════════════════════════════════════════════════
```

### No Issues Found

```
═══════════════════════════════════════════════════════════════════════
WCAG 2.1 A/AA Verification Report
Files analyzed: N (from [scope])
═══════════════════════════════════════════════════════════════════════

✓ No automated issues found!

Proceeding to manual checklist...
═══════════════════════════════════════════════════════════════════════
```
```

**Step 2: Verify content added**

Run: `grep -c "Output Format" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add output format section"
```

---

## Task 9: Add Fix Flow Section

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add fix flow section**

Append to SKILL.md:

```markdown
## Fix Flow

After presenting the report, offer to fix issues by severity (CRITICAL first):

### Fixing Pattern

```
Starting with CRITICAL issues (N total):

────────────────────────────────────────────────────────────────
Issue 1/N: [1.1.1] Missing alt text
File: src/components/ProductCard.tsx:18
────────────────────────────────────────────────────────────────

Current code:
  <img src={product.image} />

Options:
1. Add descriptive alt → <img src={product.image} alt={product.name} />
2. Mark as decorative → <img src={product.image} alt="" role="presentation" />
3. Skip (I'll fix manually)

Which approach?
```

### After User Selection

Apply the fix using the Edit tool, then continue:

```
✓ Fixed: Added alt={product.name}

────────────────────────────────────────────────────────────────
Issue 2/N: [2.1.1] Click without keyboard support
File: src/components/Modal.tsx:45
────────────────────────────────────────────────────────────────
...
```

### Completion

```
═══════════════════════════════════════════════════════════════════════
CRITICAL issues: 3/3 fixed
MAJOR issues: 4/5 fixed (1 skipped)
MINOR issues: 0/2 fixed (user declined)
═══════════════════════════════════════════════════════════════════════

Proceeding to manual review checklist...
```

### Fix Suggestions by Issue Type

**Missing alt text:**
1. Add descriptive alt from context (variable name, nearby text)
2. Mark as decorative with `alt="" role="presentation"`

**Keyboard accessibility:**
1. Replace `<div>` with `<button>`
2. Add `onKeyDown`, `tabIndex={0}`, `role="button"`

**Contrast issues:**
1. Suggest specific darker/lighter color that passes
2. Provide both hex code and Tailwind class name

**Missing labels:**
1. Wrap input with `<label>`
2. Add `aria-label` attribute
3. Add `id` and connect with `htmlFor`
```

**Step 2: Verify content added**

Run: `grep -c "Fix Flow" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add fix flow section"
```

---

## Task 10: Add Manual Checklist Section

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add manual checklist section**

Append to SKILL.md:

```markdown
## Manual Review Checklist

After automated fixes, walk through items requiring human judgment:

### Checklist Presentation

```
═══════════════════════════════════════════════════════════════════════
Manual Review Checklist
Based on file types changed, N items apply
═══════════════════════════════════════════════════════════════════════

PERCEIVABLE
☐ 1.2.1 Audio/Video Alternatives - Media has captions/transcripts?
☐ 1.3.3 Sensory Characteristics - Instructions use more than shape/color?
☐ 1.4.1 Use of Color - Meaning conveyed beyond color alone?
☐ 1.4.13 Content on Hover - Hover content dismissible/hoverable/persistent?

OPERABLE
☐ 2.1.2 No Keyboard Trap - Can tab out of all components?
☐ 2.2.1 Timing Adjustable - Time limits can be extended?
☐ 2.3.1 Three Flashes - Nothing flashes more than 3x/second?
☐ 2.4.3 Focus Order - Tab order is logical?
☐ 2.4.7 Focus Visible - Focus indicator always visible?

UNDERSTANDABLE
☐ 3.1.1 Language of Page - Has lang attribute?
☐ 3.2.1 On Focus - Focus doesn't cause unexpected changes?
☐ 3.2.2 On Input - Input doesn't cause unexpected changes?
☐ 3.3.1 Error Identification - Errors described in text?
☐ 3.3.2 Labels or Instructions - Form fields have instructions?

ROBUST
☐ 4.1.1 Parsing - Valid HTML (no duplicate IDs)?

Let's review: [First applicable item]
```

### Context-Aware Filtering

Only show items relevant to changed files:

| File Types Changed | Show These Checklist Items |
|-------------------|---------------------------|
| Has `<video>` or `<audio>` | 1.2.1 Audio/Video Alternatives |
| Has forms | 3.3.1, 3.3.2 Error/Labels |
| Has animations/transitions | 2.3.1 Three Flashes |
| Has modals/dialogs | 2.1.2 No Keyboard Trap |
| Has timed content | 2.2.1 Timing Adjustable |

### Walking Through Items

For each item:

```
────────────────────────────────────────────────────────────────
☐ 1.4.1 Use of Color (Level A)
────────────────────────────────────────────────────────────────

Question: Does your UI convey information using color alone?

Examples that fail:
• "Required fields are marked in red" (no icon/asterisk)
• Error states only shown by red border (no text/icon)
• Active tab only distinguished by color

Looking at your changes in:
• src/components/Form.tsx - has form inputs
• src/components/Alert.tsx - has status indicators

Does any of this convey meaning through color alone?
[Yes / No / Unsure - let me check]
```

### Recording Results

```
Manual Review Progress:

PERCEIVABLE
✓ 1.3.3 Sensory - PASS (no shape/color-only instructions)
✓ 1.4.1 Color Use - PASS (errors have icons + text)
☐ 1.4.13 Hover Content - checking...

OPERABLE
✓ 2.4.3 Focus Order - PASS
✗ 2.4.7 Focus Visible - FAIL (modal close button)
  → Added to fix list

Remaining: 3 items
```

### Completion

```
═══════════════════════════════════════════════════════════════════════
Manual Review Complete
═══════════════════════════════════════════════════════════════════════

Results:
• PASS: 12 items
• FAIL: 1 item (fix applied)
• N/A: 2 items (not applicable to changes)

All WCAG 2.1 A/AA checks complete!
```
```

**Step 2: Verify content added**

Run: `grep -c "Manual Review Checklist" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add manual review checklist section"
```

---

## Task 11: Add Guidelines and WCAG Reference

**Files:**
- Modify: `skills/wcag-verify/SKILL.md`

**Step 1: Add guidelines section**

Append to SKILL.md:

```markdown
## Guidelines

- **Announce scope** at start: "Checking [N files] from [scope]..."
- **Read files thoroughly** before flagging issues
- **Be specific** with locations: file path + line number
- **Show actual code** that has the issue
- **Offer fixes** with exact replacement code
- **Prioritize by severity** - CRITICAL blocks users entirely
- **Skip non-applicable** checklist items based on file content
- **Trace colors fully** through variables, tokens, and configs
- **Check ALL states** for contrast, not just default
- **Ask when unsure** - some criteria need human judgment

## Quick Reference: WCAG 2.1 A/AA Criteria

### Level A (Must fix - basic accessibility)

| # | Criterion | Quick Check |
|---|-----------|-------------|
| 1.1.1 | Non-text Content | All images have alt |
| 1.2.1 | Audio/Video Only | Media has alternatives |
| 1.3.1 | Info & Relationships | Forms have labels, tables have headers |
| 1.3.2 | Meaningful Sequence | DOM order matches visual |
| 1.3.3 | Sensory Characteristics | Instructions don't rely on shape/color |
| 1.4.1 | Use of Color | Color isn't only indicator |
| 1.4.2 | Audio Control | Auto-playing audio can be paused |
| 2.1.1 | Keyboard | All interactive elements keyboard accessible |
| 2.1.2 | No Keyboard Trap | Can tab out of everything |
| 2.1.4 | Character Key Shortcuts | Single-key shortcuts can be turned off |
| 2.2.1 | Timing Adjustable | Time limits can be extended |
| 2.2.2 | Pause, Stop, Hide | Moving content can be paused |
| 2.3.1 | Three Flashes | Nothing flashes > 3x/second |
| 2.4.1 | Bypass Blocks | Skip links or landmarks present |
| 2.4.2 | Page Titled | Pages have descriptive titles |
| 2.4.3 | Focus Order | Tab order is logical |
| 2.4.4 | Link Purpose | Link text is descriptive |
| 2.5.1 | Pointer Gestures | Complex gestures have alternatives |
| 2.5.2 | Pointer Cancellation | Actions on up-event, can abort |
| 2.5.3 | Label in Name | Visible label in accessible name |
| 2.5.4 | Motion Actuation | Motion controls have alternatives |
| 3.1.1 | Language of Page | HTML has lang attribute |
| 3.2.1 | On Focus | Focus doesn't change context |
| 3.2.2 | On Input | Input doesn't change context unexpectedly |
| 3.3.1 | Error Identification | Errors described in text |
| 3.3.2 | Labels or Instructions | Form inputs have instructions |
| 4.1.1 | Parsing | Valid HTML |
| 4.1.2 | Name, Role, Value | Custom controls have ARIA |

### Level AA (Should fix - enhanced accessibility)

| # | Criterion | Quick Check |
|---|-----------|-------------|
| 1.3.4 | Orientation | Works in portrait and landscape |
| 1.3.5 | Identify Input Purpose | Inputs have autocomplete |
| 1.4.3 | Contrast (Minimum) | Text 4.5:1, large text 3:1 |
| 1.4.4 | Resize Text | Works at 200% zoom |
| 1.4.5 | Images of Text | Use real text, not images |
| 1.4.10 | Reflow | No horizontal scroll at 320px |
| 1.4.11 | Non-text Contrast | UI components 3:1 |
| 1.4.12 | Text Spacing | Works with increased spacing |
| 1.4.13 | Content on Hover | Hover content dismissible |
| 2.4.5 | Multiple Ways | Multiple ways to find pages |
| 2.4.6 | Headings and Labels | Descriptive headings |
| 2.4.7 | Focus Visible | Focus indicator visible |
| 3.1.2 | Language of Parts | Language changes marked |
| 3.2.3 | Consistent Navigation | Navigation consistent |
| 3.2.4 | Consistent Identification | Components consistent |
| 3.3.3 | Error Suggestion | Suggest corrections |
| 3.3.4 | Error Prevention | Confirm/review important actions |
| 4.1.3 | Status Messages | Status changes announced |
```

**Step 2: Verify content added**

Run: `grep -c "Quick Reference" skills/wcag-verify/SKILL.md`
Expected: 1

**Step 3: Commit**

```bash
git add skills/wcag-verify/SKILL.md
git commit -m "feat(wcag-verify): add guidelines and WCAG reference"
```

---

## Task 12: Final Validation and Test

**Files:**
- Verify: `skills/wcag-verify/SKILL.md`

**Step 1: Check file structure**

Run: `head -20 skills/wcag-verify/SKILL.md`
Expected: Shows frontmatter with name and description

**Step 2: Check all sections present**

Run: `grep "^## " skills/wcag-verify/SKILL.md`
Expected output:
```
## Overview
## When to Use
## Scope Detection
## Automated Checks
## Color Contrast Analysis
## State-Based Contrast Checking
## Output Format
## Fix Flow
## Manual Review Checklist
## Guidelines
## Quick Reference: WCAG 2.1 A/AA Criteria
```

**Step 3: Count lines (should be ~400-500)**

Run: `wc -l skills/wcag-verify/SKILL.md`
Expected: 400-600 lines

**Step 4: Validate plugin structure**

Run: `./tests/validate-structure.sh`
Expected: All checks pass

**Step 5: Final commit**

```bash
git add -A
git commit -m "feat(wcag-verify): complete WCAG 2.1 A/AA verification skill

- Scope detection from natural language instruction
- Critical/Major/Minor automated checks
- Full color contrast analysis with tracing
- State-based contrast checking (hover, focus, disabled, etc.)
- Severity-grouped output format
- Interactive fix flow
- Manual review checklist with context filtering
- Complete WCAG 2.1 A/AA criteria reference"
```

---

## Summary

| Task | Description | Key Files |
|------|-------------|-----------|
| 1 | Create directory and frontmatter | `skills/wcag-verify/SKILL.md` |
| 2 | Add scope detection | Parse instruction, git diff |
| 3 | Add critical checks | 1.1.1, 1.3.1, 2.1.1, 4.1.2 |
| 4 | Add major checks | 1.4.3, 1.4.11, 2.4.4, 1.3.5, 2.5.3 |
| 5 | Add minor checks | 1.4.4, 2.4.6, 1.4.10 |
| 6 | Add contrast analysis | Color tracing, ratio computation |
| 7 | Add state-based contrast | hover, focus, disabled, placeholder |
| 8 | Add output format | Severity-grouped report |
| 9 | Add fix flow | Interactive fixes by severity |
| 10 | Add manual checklist | Guided review, context filtering |
| 11 | Add guidelines/reference | WCAG A/AA quick reference |
| 12 | Validate and test | Structure check, final commit |

**Total estimated tasks:** 12
**Commits:** 12 (one per task)
