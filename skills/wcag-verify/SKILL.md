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
