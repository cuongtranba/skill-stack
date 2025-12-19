---
name: mock-skill-alpha
description: Use when testing skill-stack workflows - a general purpose mock skill for test scenarios
---

# Mock Skill Alpha

## Overview

This is a mock skill used for testing the skill-stack plugin. It simulates a general-purpose workflow skill.

## When to Use

- Testing skill-stack fixture generation
- Testing stack execution with skill steps
- Integration testing

## Behavior

When invoked, this skill will:
1. Announce "Mock Skill Alpha activated"
2. Wait for user confirmation
3. Complete with success message

## Test Mode

In test mode, this skill simply echoes back that it was called successfully.

```
✓ mock-skill-alpha executed successfully
```
