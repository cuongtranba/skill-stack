---
name: mock-skill-beta
description: Use when testing skill-stack workflows - secondary mock skill for parallel execution tests
---

# Mock Skill Beta

## Overview

Secondary mock skill for testing parallel execution in skill-stack.

## When to Use

- Testing parallel branch execution
- Testing multiple skills in sequence
- Load testing with multiple skills

## Behavior

When invoked:
1. Announce "Mock Skill Beta activated"
2. Simulate work (brief pause)
3. Complete with success

## Test Output

```
✓ mock-skill-beta executed successfully
  Duration: ~1s (simulated)
```
