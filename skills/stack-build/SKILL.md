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

**Use Claude Code's built-in `/skills` command for reliable skill discovery:**

### Step 1: Discover Skills (Primary Method)

Run the `/skills` command to get all available skills:

```
/skills
```

This returns a complete list with:
- Skill name
- Description
- Source (user/project/plugin)

**Example output:**
```
Available Skills:
  brainstorming (plugin:superpowers)
    Explore ideas and requirements before implementation

  test-driven-development (plugin:superpowers)
    Write tests first, then implementation

  my-custom-skill (user)
    Project-specific workflow helper
```

### Step 2: Discover Commands and Stacks

```bash
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

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
```

Store discovery results for reference during building. The `/skills` command provides the most reliable and complete list of available skills across all sources (user, project, plugin).

## Socratic Flow

**CRITICAL:** Use `AskUserQuestion` tool for ALL questions. Never plain text. One question at a time.

### Phase 1: Context Gathering

| Question | Header | Options |
|----------|--------|---------|
| "What's your primary role?" | Role | Fullstack, Backend, Frontend, DevOps/SRE |
| "What kind of task is this stack for?" | Task type | New feature, Bug fix, Code review, Deployment, Planning |

### Phase 2: Pain Points

| Question | Header | Options |
|----------|--------|---------|
| "What slows you down?" | Pain points | Forgetting steps, Manual repetition, Context switching, Quality issues |
| "Which steps do you sometimes skip?" | Skipped | (multiSelect: true, derive from role) |

### Phase 3: Intelligent Skill Suggestion

**After gathering context, analyze and suggest relevant skills:**

#### Skill Mapping by Task Type

| Task Type | Recommended Skills | Reasoning |
|-----------|-------------------|-----------|
| **New feature** | brainstorming → writing-plans → test-driven-development → verification-before-completion | Creative exploration, then structured implementation |
| **Bug fix** | systematic-debugging → test-driven-development → verification-before-completion | Investigate first, then fix with tests |
| **Code review** | requesting-code-review → receiving-code-review → verification-before-completion | Review cycle with verification |
| **Deployment** | verification-before-completion → finishing-a-development-branch | Verify then ship |
| **Planning** | brainstorming → writing-plans | Explore then document |

#### Skill Mapping by Role

| Role | Additional Skills to Suggest |
|------|------------------------------|
| **Fullstack** | frontend-design, test-driven-development |
| **Backend** | systematic-debugging, test-driven-development |
| **Frontend** | frontend-design, wcag-verify |
| **DevOps/SRE** | devops, verification-before-completion |

#### Skill Mapping by Pain Point

| Pain Point | Skills to Prioritize |
|------------|---------------------|
| **Forgetting steps** | verification-before-completion, dev-verify |
| **Quality issues** | test-quality-verify, wcag-verify, dev-verify |
| **Context switching** | writing-plans, executing-plans |
| **Manual repetition** | dispatching-parallel-agents, subagent-driven-development |

#### Suggestion Algorithm

1. **Start with task type mapping** → Get base workflow
2. **Augment with role-specific skills** → Add relevant extras
3. **Prioritize by pain points** → Emphasize what user struggles with
4. **Filter by discovered skills** → Only suggest what's available
5. **Present as recommended workflow** with option to customize

**Present suggestion:**
```
Based on your context (Backend developer, Bug fix, Quality issues):

Recommended workflow:
1. systematic-debugging - Investigate the issue
2. test-driven-development - Write test, then fix
3. test-quality-verify - Ensure tests are meaningful
4. verification-before-completion - Final checks

Would you like to use this workflow, or customize it?
```

### Phase 3b: Create Custom Skill or Command (When No Match)

**Trigger:** When user needs a step that doesn't exist in discovered skills/commands.

| Question | Header | Options |
|----------|--------|---------|
| "No matching skill found. Would you like to create one?" | Create | Create custom skill, Create custom command, Skip this step, Describe what you need |

#### Creating a Custom Skill

Guide through minimal viable skill creation:

| Question | Header | Purpose |
|----------|--------|---------|
| "What should this skill be called?" | Name | kebab-case identifier |
| "Briefly describe what this skill does" | Description | Trigger phrases and purpose |
| "What should Claude do when this skill is invoked?" | Instructions | Core behavior (2-5 sentences) |

**Generate skill file (saved to local repository):**

```bash
SKILL_NAME="[user-provided-name]"
mkdir -p ".claude/skills/$SKILL_NAME"
```

```markdown
# Save to .claude/skills/[name]/SKILL.md (project-local)
---
name: [skill-name]
description: [user-provided-description]
---

# [Skill Name]

[User-provided instructions]

## Guidelines

- Follow the instructions above
- Ask for clarification if needed
- Report completion when done
```

**Confirm creation:**
```
Created skill '[name]' at .claude/skills/[name]/SKILL.md

This skill is saved in your project repository and can be:
- Shared with your team via git
- Used in any workflow in this project
```

#### Creating a Custom Command

Guide through minimal command creation:

| Question | Header | Purpose |
|----------|--------|---------|
| "What should this command be called?" | Name | kebab-case identifier |
| "Briefly describe what this command does" | Description | For /help listing |
| "What should Claude do when this command runs?" | Instructions | Core behavior |

**Generate command file (saved to local repository):**

```markdown
# Save to .claude/commands/[name].md (project-local)
---
description: [user-provided-description]
---

[User-provided instructions]
```

**Confirm creation:**
```
Created command '/[name]' at .claude/commands/[name].md

This command is saved in your project repository and can be:
- Shared with your team via git
- Run with /[name] in this project
```

#### "Describe What You Need" Option

If user selects "Describe what you need":

1. Ask: "What do you want this step to accomplish?"
2. Analyze the description
3. Check if any existing skill/command could work (fuzzy match)
4. If match found → suggest it
5. If no match → offer to create custom skill/command with pre-filled content based on description

**Example flow:**
```
User: "I need something to check our API response times"

Analysis: No direct match found.

Suggested custom skill:
  Name: api-performance-check
  Description: Check API response times and identify slow endpoints
  Instructions: Run API performance tests, measure response times,
                report any endpoints exceeding thresholds.

Create this skill? [Yes / Modify / No]
```

### Phase 4: Workflow Building

| Question | Header | Options |
|----------|--------|---------|
| "Use recommended workflow or customize?" | Workflow | Use recommended, Customize from scratch, Modify recommended |
| "After [step], what comes next?" | Next step | (filtered by context + "Create new skill/command" option) |
| "Should any steps run in parallel?" | Parallel | Yes, No |
| "Should this loop until something passes?" | Looping | Yes, No |

**When user selects "Create new skill/command"** → Go to Phase 3b, then return.

### Phase 5: Refinement

| Question | Header | Options |
|----------|--------|---------|
| "What would you like to do?" | Refine | Add step, Remove step, Reorder, Create custom step, Looks good |
| "How should transitions work?" | Transitions | prompt, auto, Mix |

**When user selects "Create custom step"** → Go to Phase 3b to create skill/command, then add to workflow.

### Phase 6: Finalize

| Question | Header | Options |
|----------|--------|---------|
| "What should we name this stack?" | Name | (suggest 2-3 names based on task type) |
| "Where should I save '[name]'?" | Location | Personal, Project |

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
