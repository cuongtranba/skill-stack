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

**CRITICAL: You MUST use the `AskUserQuestion` tool for EVERY question. NEVER output plain text questions.**

```
❌ WRONG - Plain text:
"What's your primary role?
- Fullstack developer
- Backend developer"

✅ CORRECT - Use AskUserQuestion tool:
AskUserQuestion(questions=[{
  question: "What's your primary role?",
  header: "Role",
  options: [
    {label: "Fullstack developer", description: "Full-stack web development"},
    {label: "Backend developer", description: "APIs, services, data"},
    {label: "Frontend developer", description: "UI/UX implementation"},
    {label: "DevOps/SRE", description: "Infrastructure, deployment"}
  ],
  multiSelect: false
}])
```

### Phase 1: Context Gathering

**Use AskUserQuestion with these questions (one at a time):**

| Question | Header | Options |
|----------|--------|---------|
| "What's your primary role?" | Role | Fullstack, Backend, Frontend, DevOps/SRE |
| "What kind of task is this stack for?" | Task type | New feature, Bug fix, Code review, Deployment, Planning |

### Phase 2: Pain Point Discovery

| Question | Header | Options |
|----------|--------|---------|
| "What slows you down in your current workflow?" | Pain points | Forgetting steps, Manual repetition, Context switching, Quality issues |
| "Which steps do you sometimes skip?" | Skipped steps | (multiSelect: true, derive from role) |

### Phase 3: Workflow Building

| Question | Header | Options |
|----------|--------|---------|
| "For [task type], what do you do first?" | First step | (derive from discovered skills) |
| "After [previous step], what comes next?" | Next step | (filter by context) |
| "Should any steps run in parallel?" | Parallel | Yes - show me how, No - keep sequential |
| "Should this loop until something passes?" | Looping | Yes (test-fix cycle), No |

### Phase 4: Refinement

Show current steps first, then ask:

| Question | Header | Options |
|----------|--------|---------|
| "What would you like to do?" | Refine | Add step, Remove step, Reorder, Looks good |
| "How should transitions work?" | Transitions | Ask before each (prompt), Run automatically (auto), Mix |

### Phase 5: Finalization

| Question | Header | Options |
|----------|--------|---------|
| "Save as personal or project stack?" | Location | Personal (~/.claude/stacks/), Project (.claude/stacks/) |
| "What should we name this stack?" | Name | (suggest 2-3 names based on task type) |

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

## Mermaid Diagram Generation

**Save diagram as separate file: `[name].diagram.md`**

```markdown
# [Stack Name] Workflow

```mermaid
flowchart TD
  [Generate nodes for each step]
  [Generate subgraphs for parallel/loop]
  [Generate edges with labels]
`` `
```

**Node format by type:**
- skill: `name[name\nskill:ref]`
- bash: `name[name\ncmd]`
- command: `name[name\n/cmd]`
- parallel: `subgraph name [Parallel] ... end`
- loop: `name[name]` with self-referencing edge

## Checksum Generation

After generating YAML content (excluding `_meta.checksum`):
1. Compute SHA256 of content below `_meta` block
2. Store as `_meta.checksum: sha256:[hash]`

## Save and Confirm

```bash
# Create directory if needed
mkdir -p ~/.claude/stacks  # or .claude/stacks

# Write YAML file
cat > [path]/[name].yaml << 'EOF'
[Generated YAML]
EOF

# Write diagram file
cat > [path]/[name].diagram.md << 'EOF'
[Generated Mermaid markdown]
EOF
```

**Confirm to user:**
```
Stack '[name]' saved to [path]
  - [name].yaml (workflow definition)
  - [name].diagram.md (visual flowchart)

You can run it anytime with:
  /stack [name]

Or I'll suggest it when you're working on matching tasks.
```

**Then display the diagram inline for preview.**

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
4. After changes, regenerate checksum and diagram file
5. Save both .yaml and .diagram.md files

## Validation Before Save

Always invoke stack-validate skill before saving:
- If errors -> show and help fix
- If warnings -> show and ask to proceed
- If valid -> save

## Guidelines

- ONE question at a time via `AskUserQuestion` tool
- Prefer multiple choice (easier to answer)
- Show progress ("Step 3 of 5...")
- Allow going back
- Validate before saving
- Always generate Mermaid diagram as separate .diagram.md file

## Red Flags - STOP

If you catch yourself doing any of these, STOP and use `AskUserQuestion`:

| Wrong | Right |
|-------|-------|
| Writing "Question 1:" as text | Use AskUserQuestion tool |
| Listing options with bullet points | Use options array in tool |
| Asking "Which do you prefer?" in prose | Use tool with header + options |
| Batching multiple questions at once | One question per tool call |

**Plain text questions = skill violation. Always use the tool.**
