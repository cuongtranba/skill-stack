---
name: mock-skill-debug
description: Use when testing skill-stack workflows - mock debugging skill for loop/fix scenarios
---

# Mock Skill Debug

## Overview

Mock debugging skill that simulates the systematic-debugging workflow for testing fix loops.

## When to Use

- Testing dev loops (implement → test → fix)
- Testing conditional skill invocation
- Testing error recovery workflows

## Behavior

When invoked with error context:
1. Announce "Mock Debug: Analyzing issues..."
2. Report "Found N issues"
3. Report "Applying fixes..."
4. Complete with "Fixes applied"

## Outputs

- `issues_found`: number (simulated)
- `fixes_applied`: boolean (always true in mock)

## Test Output

```
✓ mock-skill-debug executed
  Issues analyzed: 3 (simulated)
  Fixes applied: true
```
