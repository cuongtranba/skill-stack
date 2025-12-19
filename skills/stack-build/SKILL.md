---
name: stack-build
description: Use when creating or editing skill workflow stacks - guides through Socratic discovery to build personalized YAML configs
---

# Stack Build Skill

## Overview

Guide users through creating skill workflow stacks via Socratic questioning. One question at a time, prefer multiple choice.

**Announce:** "I'm using the stack-build skill to help you create a workflow."

## Discovery Phase

**First, discover available resources:**

```bash
# Personal skills
ls ~/.claude/skills/*/SKILL.md 2>/dev/null | while read f; do
  name=$(dirname "$f" | xargs basename)
  desc=$(grep -A1 "^description:" "$f" 2>/dev/null | tail -1 | head -c 50)
  echo "personal:$name - $desc"
done

# Plugin skills
ls ~/.claude/plugins/cache/*/*/skills/*/SKILL.md 2>/dev/null | while read f; do
  plugin=$(echo "$f" | sed 's|.*/cache/\([^/]*\)/.*|\1|')
  name=$(dirname "$f" | xargs basename)
  echo "plugin:$plugin:$name"
done

# Commands
ls ~/.claude/commands/*.md 2>/dev/null | xargs -I{} basename {} .md

# Existing stacks
ls ~/.claude/stacks/*.yaml .claude/stacks/*.yaml 2>/dev/null
```

Store discovery results for reference during building.

## Socratic Flow

**Ask ONE question at a time. Use AskUserQuestion tool with multiple choice options.**

### Phase 1: Context Gathering

```
Question 1: "What's your primary role?"
Options:
- Fullstack developer
- Backend developer
- Frontend developer
- DevOps/SRE
- Project Manager
- Other (describe)

Question 2: "What kind of task is this stack for?"
Options:
- New feature development
- Bug fixing
- Code review
- Deployment
- Planning/Documentation
- Other (describe)
```

### Phase 2: Pain Point Discovery

```
Question 3: "What slows you down in your current workflow?"
Options:
- Forgetting steps
- Manual repetition
- Context switching
- Quality issues
- Other (describe)

Question 4: "Which steps do you sometimes skip?"
(Open-ended, or suggest based on role)
```

### Phase 3: Workflow Building

```
Question 5: "For [task type], what do you do first?"
Options: [Based on discovered skills]

Question 6: "After [previous step], what comes next?"
Options: [Filtered by context]

Question 7: "Should any steps run in parallel?"
Options:
- Yes, show me how
- No, keep it sequential

Question 8: "Should this loop until something passes?"
Options:
- Yes (e.g., test-fix cycle)
- No
```

### Phase 4: Refinement

```
Question 9: "Here's your stack so far:
[Show current steps]

What would you like to do?"
Options:
- Add another step
- Remove a step
- Reorder steps
- Looks good, continue

Question 10: "How should transitions work?"
Options:
- Ask before each step (prompt)
- Run automatically (auto)
- Mix (I'll specify per step)
```

### Phase 5: Finalization

```
Question 11: "Save as personal or project stack?"
Options:
- Personal (~/.claude/stacks/) - available everywhere
- Project (.claude/stacks/) - shared with team

Question 12: "What should we name this stack?"
(Suggest based on task type)
```

## YAML Generation

After collecting answers, generate stack YAML:

```yaml
_meta:
  version: 1.0
  created_by: skill-stack-builder
  created_at: [ISO timestamp]
  modified_at: [ISO timestamp]
  checksum: [generate after content]
  diagram: |
    [Generate Mermaid flowchart]

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

## Mermaid Diagram Generation

**Generate flowchart after building steps:**

```
flowchart TD
  classDef skill fill:#e1f5fe,stroke:#01579b
  classDef bash fill:#f3e5f5,stroke:#4a148c
  classDef command fill:#e8f5e9,stroke:#1b5e20

  [Generate nodes for each step]
  [Generate subgraphs for parallel/loop]
  [Generate edges with labels]
```

**Node format by type:**
- skill: `name[name\n skill:ref]:::skill`
- bash: `name[name\n cmd]:::bash`
- command: `name[name\n /cmd]:::command`

## Checksum Generation

After generating YAML content (excluding `_meta.checksum`):
1. Compute SHA256 of content below `_meta` block
2. Store as `_meta.checksum: sha256:[hash]`

## Save and Confirm

```bash
# Create directory if needed
mkdir -p ~/.claude/stacks  # or .claude/stacks

# Write file
cat > [path]/[name].yaml << 'EOF'
[Generated YAML]
EOF
```

**Confirm to user:**
```
Stack '[name]' saved to [path]

You can run it anytime with:
  /stack [name]

Or I'll suggest it when you're working on matching tasks.

[Show generated Mermaid diagram]
```

## Edit Mode

When editing an existing stack:

1. Load and parse existing YAML
2. Show current structure:
   ```
   Current '[name]' stack:

   Steps:
   1. [step-name] ([type]: [ref])
   2. [step-name] ([type]: [ref])
   ...

   What would you like to change?
   ```
3. Options:
   - Add a step
   - Remove a step
   - Reorder steps
   - Change step settings
   - Change defaults
4. After changes, regenerate checksum and diagram
5. Save and confirm

## Validation Before Save

Always invoke stack-validate skill before saving:
- If errors -> show and help fix
- If warnings -> show and ask to proceed
- If valid -> save

## Guidelines

- ONE question at a time
- Prefer multiple choice (easier to answer)
- Show progress ("Step 3 of 5...")
- Allow going back
- Validate before saving
- Always generate Mermaid diagram
