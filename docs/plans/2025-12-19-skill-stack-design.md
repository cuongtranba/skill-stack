# Skill Stack Design

**Date:** 2025-12-19
**Status:** Approved

## Overview

Skill Stack is a Claude Code plugin that enables users to build and run personalized skill workflows through Socratic guidance. It solves the problem of manually remembering and chaining skills in a specific order (e.g., plan → implement → verify).

## Problem Statement

Users have many skills available but must manually:
- Remember which skills to use for each task type
- Chain skills in the correct order
- Switch between skills at the right time

Different roles (backend, frontend, BA, PM) need different workflows, making a one-size-fits-all approach inadequate.

## Solution

A plugin providing:
1. **`/stack` command** - Single entry point for all stack operations
2. **Socratic builder** - Guides users through creating personalized workflows via questions
3. **Stack runner** - Executes saved workflows with support for loops, parallel execution, and branching
4. **Conversational validation** - Detects manual edits and offers guided fixes

## Plugin Structure

```
skill-stack/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── commands/
│   └── stack.md
├── agents/
│   └── stack.md
├── skills/
│   ├── stack-build/SKILL.md
│   ├── stack-run/SKILL.md
│   └── stack-validate/SKILL.md
├── references/
│   ├── yaml-schema.md
│   ├── step-types.md
│   ├── example-stacks.md
│   └── loop-patterns.md
├── CLAUDE.md
├── README.md
└── VERSION
```

## Component Design

### Command: `/stack` (commands/stack.md)

Simple router that delegates to the stack agent.

### Agent: `stack` (agents/stack.md)

Main orchestrator with modes:

| User Intent | Mode | Action |
|-------------|------|--------|
| `/stack` | Menu | Show context-aware options |
| `/stack <name>` | Run | Execute stack via stack-run skill |
| `/stack build` | Build | Invoke stack-build skill |
| `/stack edit <name>` | Edit | Invoke stack-build in edit mode |
| `/stack list` | List | Show available stacks |

### Skill: `stack-build` (skills/stack-build/SKILL.md)

Socratic builder that:
1. Discovers available skills, commands, stacks
2. Asks questions one at a time (prefer multiple choice)
3. Guides through: context → pain points → workflow → refinement
4. Generates valid YAML and saves to chosen location

### Skill: `stack-run` (skills/stack-run/SKILL.md)

Execution engine supporting:
- Sequential steps
- Parallel branches (via subagents)
- Loops (until/while/times/for-each)
- Conditional branching (if/else)
- Per-step error handling

### Skill: `stack-validate` (skills/stack-validate/SKILL.md)

Validation with conversational fixes:
- Schema validation
- Reference checking (skills, commands exist)
- Logic validation (no circular refs, loops have exits)
- Checksum integrity detection

## Stack YAML Format

```yaml
_meta:
  version: 1.0
  created_by: skill-stack-builder
  created_at: 2025-12-19T10:30:00Z
  modified_at: 2025-12-19T10:30:00Z
  checksum: sha256:a1b2c3d4e5f6...

name: my-workflow
description: Description of the workflow
scope: personal  # or "project"

default_for:
  - task: new-feature
    keywords: ["add", "create", "implement"]

extends: base-stack  # optional

defaults:
  on_error: ask
  transition: prompt

steps:
  # Sequential step
  - name: brainstorm
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    description: Explore requirements

  # Parallel block
  - parallel:
      name: implementation
      wait: all  # all | any | none
      branches:
        - name: backend
          type: skill
          ref: superpowers:test-driven-development
          args: "backend implementation"
        - name: frontend
          type: skill
          ref: superpowers:test-driven-development
          args: "frontend implementation"

  # Loop block
  - loop:
      name: dev-cycle
      until: "{{ tests_pass }}"
      max_iterations: 10
      steps:
        - name: implement
          type: skill
          ref: superpowers:test-driven-development
        - name: test
          type: bash
          run: npm test
          outputs:
            - tests_pass
        - name: fix
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not tests_pass }}"

  # Conditional branching
  - name: review
    type: skill
    ref: superpowers:requesting-code-review
    branch:
      if: "{{ review_passed }}"
      then: finish
      else: dev-cycle
```

## Step Types

| Type | Ref Format | Example |
|------|------------|---------|
| `skill` | `plugin:skill-name` or `skill-name` | `superpowers:brainstorming` |
| `command` | command name or `/command` | `/commit` |
| `bash` | inline with `run:` | `npm test` |
| `stack` | stack name (nested) | `verify-stack` |

## Execution Flow

### Sequential Step
```
Execute skill/command → check transition → next step
```

### Parallel Block
```
Spawn subagents for each branch → wait per mode → collect outputs → next step
```

### Loop Block
```
Execute steps → evaluate condition → if not met, repeat → if met or max reached, exit
```

### Branching
```
Evaluate condition → jump to target step name
```

## Error Handling

Per-step `on_error`:
- `stop` - Halt stack, show error
- `continue` - Log warning, proceed
- `retry` - Retry up to max_retries
- `ask` - Prompt user for decision

## Context Sharing

- **Default:** Conversation-based (Claude's natural memory)
- **Optional:** `outputs:` field for explicit data handoff between steps

## Storage Locations

- **Personal:** `~/.claude/stacks/*.yaml`
- **Project:** `.claude/stacks/*.yaml`
- User chooses during creation

## Validation & Integrity

### Checksum Detection
```yaml
_meta:
  checksum: sha256:...  # Hash of content below _meta
```

### On Manual Edit Detection
```
"This stack was modified outside the builder.
Let me validate it...

Found 1 issue:
• 'superpowers:brianstorm' - did you mean 'superpowers:brainstorming'?

1. Yes, fix it
2. Open in builder to review"
```

## Installation

```bash
# Add marketplace
/plugin marketplace add your-name/skill-stack

# Install plugin
/plugin install skill-stack@skill-stack-marketplace
```

## User Flow

```
/stack              → Smart menu (context-aware)
/stack <name>       → Run stack directly
/stack build        → Socratic builder
/stack edit <name>  → Edit existing stack
/stack list         → Show all stacks
```

## Decisions Made

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Discovery | Scan all locations + runtime list | Comprehensive |
| UX | Socratic questioning | Personalized, not templates |
| Storage | User chooses scope | Flexibility |
| Invocation | Single `/stack` entry | Simple UX |
| Composition | extends + includes | Reusability |
| Loops | until/while/times/for-each | Cover all patterns |
| Parallel | Subagents with wait modes | True concurrency |
| Context | Conversation + optional outputs | Simple default, powerful option |
| Validation | Conversational | User-friendly |
| Templates | Examples in docs only | Builder creates, not imports |

## Files to Implement

1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `commands/stack.md`
4. `agents/stack.md`
5. `skills/stack-build/SKILL.md`
6. `skills/stack-run/SKILL.md`
7. `skills/stack-validate/SKILL.md`
8. `references/yaml-schema.md`
9. `references/step-types.md`
10. `references/example-stacks.md`
11. `references/loop-patterns.md`
12. `CLAUDE.md`
13. `README.md`
14. `VERSION`

## Next Steps

1. Create plugin directory structure
2. Implement manifests (plugin.json, marketplace.json)
3. Implement command and agent
4. Implement skills (build, run, validate)
5. Write reference documentation
6. Test locally
7. Publish to marketplace
