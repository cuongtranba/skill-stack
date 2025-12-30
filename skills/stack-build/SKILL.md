---
name: stack-build
description: Use when creating or editing skill workflow stacks - guides through Socratic discovery to build personalized YAML configs
---

# Stack Build Skill

## Overview

Guide users through creating skill workflow stacks via Socratic questioning.

**REQUIREMENT:** Use `AskUserQuestion` tool for ALL questions. Never output plain text questions.

**Announce:** "I'm using the stack-build skill to help you create a workflow."

## Discovery Phase

**First, discover available resources with explicit error handling:**

```bash
# Set base paths
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

echo "=== Discovering Resources ==="

# Personal skills
echo "Personal skills:"
if [ -d "$CLAUDE_HOME/skills" ] && ls "$CLAUDE_HOME/skills"/*/SKILL.md >/dev/null 2>&1; then
  for f in "$CLAUDE_HOME/skills"/*/SKILL.md; do
    name=$(dirname "$f" | xargs basename)
    desc=$(grep -A1 "^description:" "$f" 2>/dev/null | tail -1 | head -c 50)
    echo "  - $name: $desc"
  done
else
  echo "  (none found)"
fi

# Plugin skills
echo "Plugin skills:"
if ls "$CLAUDE_HOME/plugins/cache"/*/*/skills/*/SKILL.md >/dev/null 2>&1; then
  for f in "$CLAUDE_HOME/plugins/cache"/*/*/skills/*/SKILL.md; do
    plugin=$(echo "$f" | sed 's|.*/cache/\([^/]*\)/.*|\1|')
    name=$(dirname "$f" | xargs basename)
    echo "  - $plugin:$name"
  done
else
  echo "  (none found)"
fi

# Commands
echo "Commands:"
if [ -d "$CLAUDE_HOME/commands" ] && ls "$CLAUDE_HOME/commands"/*.md >/dev/null 2>&1; then
  for f in "$CLAUDE_HOME/commands"/*.md; do
    basename "$f" .md
  done | sed 's/^/  - /'
else
  echo "  (none found)"
fi

# Existing stacks
echo "Existing stacks:"
found_stacks=0
if [ -d "$CLAUDE_HOME/stacks" ] && ls "$CLAUDE_HOME/stacks"/*.yaml >/dev/null 2>&1; then
  echo "  Personal:"
  ls "$CLAUDE_HOME/stacks"/*.yaml | xargs -I{} basename {} .yaml | sed 's/^/    - /'
  found_stacks=1
fi
if [ -d ".claude/stacks" ] && ls .claude/stacks/*.yaml >/dev/null 2>&1; then
  echo "  Project:"
  ls .claude/stacks/*.yaml | xargs -I{} basename {} .yaml | sed 's/^/    - /'
  found_stacks=1
fi
[ $found_stacks -eq 0 ] && echo "  (none found)"

echo "=== Discovery Complete ==="
```

Store discovery results for reference during building. If discovery finds no resources, inform the user but continue - they can still build a stack with manually specified references.

## Socratic Flow

**CRITICAL:** Use `AskUserQuestion` tool for ALL questions. Never plain text. One question at a time.

### Phases (All Questions via AskUserQuestion)

| Phase | Question | Header | Options |
|-------|----------|--------|---------|
| **1. Context** | "What's your primary role?" | Role | Fullstack, Backend, Frontend, DevOps/SRE |
| | "What kind of task is this stack for?" | Task type | New feature, Bug fix, Code review, Deployment, Planning |
| **2. Pain Points** | "What slows you down?" | Pain points | Forgetting steps, Manual repetition, Context switching, Quality issues |
| | "Which steps do you sometimes skip?" | Skipped | (multiSelect: true, derive from role) |
| **3. Workflow** | "For [task], what do you do first?" | First step | (from discovered skills) |
| | "After [step], what comes next?" | Next step | (filter by context) |
| | "Should any steps run in parallel?" | Parallel | Yes, No |
| | "Should this loop until something passes?" | Looping | Yes, No |
| **4. Refinement** | "What would you like to do?" | Refine | Add step, Remove step, Reorder, Looks good |
| | "How should transitions work?" | Transitions | prompt, auto, Mix |
| **5. Finalize** | "What should we name this stack?" | Name | (suggest 2-3 names) |
| | "Where should I save '[name]'?" | Location | Personal, Project |

**Location options:**
- **Personal** (`~/.claude/stacks/`): Only you, works in any project
- **Project** (`.claude/stacks/`): Checked into repo, shared with team

After confirmation: `Saving to [location]: [full path]`

## YAML Generation

After collecting answers, generate stack YAML:

```yaml
_meta:
  version: 1.0
  created_by: skill-stack-builder
  created_at: [ISO timestamp]
  modified_at: [ISO timestamp]
  checksum: [generate after content]
  diagram: ./[name].diagram.md

name: [user-provided-name]
description: [generated from context]
scope: [personal|project]

default_for:
  - task: [task-type]
    keywords: [relevant keywords]

defaults:
  on_error: ask
  transition: [user choice]

steps:
  [Generated steps based on answers]
```

## Diagram & Checksum

**Mermaid diagram:** Save as `[name].diagram.md` with flowchart TD format.
- Node types: skill `[name\nskill:ref]`, bash `[name\ncmd]`, command `[name\n/cmd]`
- Parallel: `subgraph [Parallel] ... end`
- Loop: self-referencing edge

**Checksum:** Compute SHA256 of content below `_meta` block, store as `_meta.checksum: sha256:[hash]`

## Save and Confirm

Save both files to the user-confirmed location, then confirm:
```
Stack '[name]' saved to [path]
  - [name].yaml (workflow definition)
  - [name].diagram.md (visual flowchart)

Run anytime with: /stack [name]
```

Display the diagram inline for preview.

## Edit Mode

1. Load existing YAML, show structure: `Steps: 1. [name] ([type]: [ref]) ...`
2. Ask via AskUserQuestion: Add, Remove, Reorder, Change settings, Change defaults
3. Regenerate checksum and diagram
4. Save both files

## Validation Before Save

Always invoke stack-validate skill before saving:
- Errors → show and help fix
- Warnings → show and ask to proceed
- Valid → save

## Guidelines

- ONE question at a time via `AskUserQuestion` tool
- Prefer multiple choice, show progress ("Step 3 of 5...")
- Allow going back, validate before saving
- Always generate Mermaid diagram as separate .diagram.md file

## Red Flags - STOP

| Wrong | Right |
|-------|-------|
| Plain text questions | Use AskUserQuestion tool |
| Batching multiple questions | One question per tool call |
| Saving without asking location | Ask location first via tool |

**Plain text questions = skill violation. Always use the tool.**
