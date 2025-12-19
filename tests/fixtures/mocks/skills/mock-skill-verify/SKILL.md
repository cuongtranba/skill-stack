---
name: mock-skill-verify
description: Use when testing skill-stack workflows - mock verification skill for completion checks
---

# Mock Skill Verify

## Overview

Mock verification skill that simulates the verification-before-completion workflow.

## When to Use

- Testing verification steps
- Testing pre-completion checks
- Testing workflow gates

## Behavior

When invoked:
1. Announce "Mock Verify: Running checks..."
2. List simulated checks
3. Report pass/fail status
4. Complete

## Outputs

- `all_checks_passed`: boolean (configurable via args)
- `failed_checks`: array (empty if passed)

## Test Output

```
✓ mock-skill-verify executed
  Checks run: 5
  Passed: 5
  Failed: 0
  Status: PASS
```
