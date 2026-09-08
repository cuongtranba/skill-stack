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

# Distribution invariants only (front matter, version sync, skill declarations)
./tests/validate-distribution.sh

# Prepare test fixtures (discovers resources, generates YAML, installs mocks)
./tests/scripts/prepare-fixtures.sh
```

## Distribution

The repo ships through two channels and `tests/validate-distribution.sh` enforces
the invariants both depend on. Run it after touching any SKILL.md front matter,
`.claude-plugin/*`, `VERSION`, or `release-please-config.json`.

1. **Claude Code plugin** — `.claude-plugin/marketplace.json`; ships commands,
   agent, and all 8 skills.
2. **Skills CLI** — [`vercel-labs/skills`](https://github.com/vercel-labs/skills),
   `npx skills add cuongtranba/skill-stack#<tag>`; ships skills only.

**Invariants:**

- **Front matter must be valid YAML with string `name` + `description`.** The CLI
  parses it with a real YAML parser and *silently drops* a skill that fails —
  there is no error the author will see. A description containing `": "` must be
  single-quoted, or YAML reads it as a nested mapping. This is how `golang` was
  invisible to the CLI before v1.6.0.
- **`.claude-plugin/plugin.json` `skills[]` mirrors `skills/*/`**, one `./`-prefixed
  entry per directory. The CLI uses it to group skills under the plugin name.
- **Skills that need `/stack` or `/go:*` carry `metadata.internal: true`**, which
  hides them from CLI discovery (they remain installable when named explicitly, and
  Claude Code ignores the key). Currently: `stack-build`, `stack-run`,
  `stack-validate`.
- **release-please owns every version.** `VERSION` (via `version-file`),
  `plugin.json` and `marketplace.json` (via `extra-files`) are all written from
  `.release-please-manifest.json`. Never hand-edit them; a version file that is not
  listed in `release-please-config.json` will drift, which is exactly what happened
  to `VERSION`.
- **Users pin with the release-please tag**: the `#v1.6.0` fragment is a git ref,
  recorded per-skill in the lockfile and honoured by `npx skills update`.

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
