---
description: Audit Go code for style violations and best practices
allowed-tools: Glob, Grep, Read, Bash, Skill
argument-hint: "[path|package]"
---

Invoke the `skill-stack:golang` skill to audit Go code. Run the `/go:audit` workflow as defined in the skill — scan Go files for violations of Uber Go Style Guide, Effective Go, and generics guidelines, then display results in a priority table (P0-P3).

If an argument is provided, scope the audit to that path or package.
