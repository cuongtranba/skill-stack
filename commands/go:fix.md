---
description: Auto-fix Go style violations found by audit
allowed-tools: Glob, Grep, Read, Edit, Write, Bash, Skill
argument-hint: "[P0|P1|P2|P3|all]"
---

Invoke the `skill-stack:golang` skill to fix Go code violations. Run the `/go:fix` workflow as defined in the skill — apply fixes for issues found during audit.

If a priority argument is provided (e.g., `P0`), only fix violations at that priority level.
