# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Skill Stack is a Claude Code plugin that lets users build and run personalized skill workflows. Users define workflows in YAML that chain skills, commands, bash scripts, and nested stacks with support for parallel execution, loops, and conditional branching.

## Commands

- `/stack` - Show menu and available options
- `/stack build` - Build a new stack through Socratic guidance
- `/stack <name>` - Run a saved stack
- `/stack edit <name>` - Edit an existing stack
- `/stack list` - List all available stacks

## Testing

```bash
# Full test suite (prepares fixtures, validates structure)
./tests/run-tests.sh

# Plugin structure validation only
./tests/validate-structure.sh

# Prepare test fixtures (discovers resources, generates YAML, installs mocks)
./tests/scripts/prepare-fixtures.sh
```

## Stack Locations

- Personal: `~/.claude/stacks/*.yaml`
- Project: `.claude/stacks/*.yaml`

## Architecture

```
/stack command → agents/stack.md (orchestrator) → skills/
                                                   ├── stack-build/   (Socratic builder)
                                                   ├── stack-run/     (execution engine)
                                                   └── stack-validate/ (validation)
```

**Flow:**
1. `/commands/stack.md` routes user input to the agent
2. `agents/stack.md` detects mode (build/edit/list/run) and coordinates skills
3. Skills handle specific tasks: `stack-build` for creation, `stack-validate` before execution, `stack-run` for running

**Key references:**
- `references/yaml-schema.md` - Complete YAML specification
- `references/step-types.md` - skill, command, bash, stack step types
- `references/loop-patterns.md` - Loop implementation patterns

## YAML Stack Structure

```yaml
_meta:
  checksum: sha256  # Auto-computed from content
  diagram: |        # Auto-generated Mermaid flowchart
    flowchart TD
      ...

name: my-stack      # Required
description: ...
steps:              # Required - array of steps
  - name: step1
    type: skill     # skill|command|bash|stack
    ref: skill-name
```

**Step types:** skill (invoke skill), command (invoke /command), bash (shell), stack (nested)

**Control flow:** parallel blocks (wait: all|any|none), loops (until/while/times/for_each), branches (if/then/else)

**Safety limits:** max_iterations ≤ 20, parallel branches ≤ 5, nesting ≤ 3 levels

## Validation

`stack-validate` checks:
1. Schema (name and steps required)
2. References (skill/command/stack existence with fuzzy matching)
3. Logic (no circular refs, loops have exit conditions, branch targets exist)
4. Safety (iteration/parallel/nesting limits)
5. Checksum (SHA256 integrity)
