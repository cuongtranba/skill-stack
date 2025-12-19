# Skill Stack Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the skill-stack Claude Code plugin that enables personalized skill workflow automation.

**Architecture:** Markdown-based plugin with command → agent → skills delegation. Agent orchestrates modes (menu, run, build, edit, list). Skills handle specific workflows (build via Socratic questions, run via execution engine, validate via schema checking).

**Tech Stack:** Claude Code plugin (Markdown, YAML), Shell scripts for validation

---

## Phase 1: Plugin Foundation

### Task 1: Create Plugin Manifests

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`

**Step 1: Create plugin directory**

```bash
mkdir -p .claude-plugin
```

**Step 2: Create plugin.json**

Create `.claude-plugin/plugin.json`:
```json
{
  "name": "skill-stack",
  "description": "Build and run personalized skill workflows through Socratic guidance",
  "version": "1.0.0",
  "author": {
    "name": "skill-stack-team"
  },
  "homepage": "https://github.com/skill-stack/skill-stack",
  "repository": "https://github.com/skill-stack/skill-stack",
  "license": "MIT",
  "keywords": ["workflow", "skills", "automation", "stack"],
  "commands": "./commands"
}
```

**Step 3: Create marketplace.json**

Create `.claude-plugin/marketplace.json`:
```json
{
  "name": "skill-stack-marketplace",
  "description": "Skill workflow automation plugin marketplace",
  "owner": {
    "name": "skill-stack-team"
  },
  "plugins": [
    {
      "name": "skill-stack",
      "description": "Build and run personalized skill workflows through Socratic guidance",
      "version": "1.0.0",
      "source": "./"
    }
  ]
}
```

**Step 4: Verify structure**

```bash
ls -la .claude-plugin/
cat .claude-plugin/plugin.json
```

**Step 5: Commit**

```bash
git add .claude-plugin/
git commit -m "feat: add plugin manifests"
```

---

### Task 2: Create Root Documentation Files

**Files:**
- Create: `VERSION`
- Create: `CLAUDE.md`
- Create: `README.md`

**Step 1: Create VERSION file**

Create `VERSION`:
```
1.0.0
```

**Step 2: Create CLAUDE.md**

Create `CLAUDE.md`:
```markdown
# Skill Stack Plugin Instructions

This plugin provides the `/stack` command for building and running skill workflows.

## Commands

- `/stack` - Show menu and available options
- `/stack build` - Build a new stack through Socratic guidance
- `/stack <name>` - Run a saved stack
- `/stack edit <name>` - Edit an existing stack
- `/stack list` - List all available stacks

## Stack Locations

- Personal stacks: `~/.claude/stacks/*.yaml`
- Project stacks: `.claude/stacks/*.yaml`

## Skills

- `stack-build` - Socratic builder for creating stacks
- `stack-run` - Execution engine for running stacks
- `stack-validate` - Validation and integrity checking
```

**Step 3: Create README.md**

Create `README.md`:
```markdown
# Skill Stack

Build and run personalized skill workflows through Socratic guidance.

## Installation

```bash
# Add marketplace
/plugin marketplace add ./

# Install plugin
/plugin install skill-stack@skill-stack-marketplace
```

## Quick Start

```bash
# Build your first stack
/stack build

# Run a stack
/stack my-workflow

# List all stacks
/stack list
```

## Features

- **Socratic Builder** - Guided workflow creation through questions
- **Parallel Execution** - Run multiple skills simultaneously via subagents
- **Loops** - Iterative workflows (until/while/times/for-each)
- **Branching** - Conditional flow control (if/else)
- **Auto-Validation** - Detect and fix issues conversationally
- **Mermaid Diagrams** - Visual workflow representation

## Documentation

- [Design Document](docs/plans/2025-12-19-skill-stack-design.md)
- [YAML Schema](references/yaml-schema.md)
- [Step Types](references/step-types.md)
- [Examples](references/example-stacks.md)

## License

MIT
```

**Step 4: Commit**

```bash
git add VERSION CLAUDE.md README.md
git commit -m "docs: add root documentation files"
```

---

### Task 3: Create Command Router

**Files:**
- Create: `commands/stack.md`

**Step 1: Create commands directory**

```bash
mkdir -p commands
```

**Step 2: Create stack.md command**

Create `commands/stack.md`:
```markdown
---
description: Build and run personalized skill workflows
---

Use the `stack` agent to manage skill workflows.

The stack agent handles all workflow operations including building, running, editing, and listing stacks.
```

**Step 3: Verify**

```bash
cat commands/stack.md
```

**Step 4: Commit**

```bash
git add commands/
git commit -m "feat: add /stack command router"
```

---

## Phase 2: Stack Agent

### Task 4: Create Stack Agent

**Files:**
- Create: `agents/stack.md`

**Step 1: Create agents directory**

```bash
mkdir -p agents
```

**Step 2: Create stack.md agent**

Create `agents/stack.md`:
```markdown
---
name: stack
description: |
  Skill workflow orchestrator. Use for building, running, editing stacks.
  Trigger phrases: "stack", "workflow", "run stack", "build stack".
tools: Glob, Grep, Read, Write, Edit, Bash, Task, Skill, AskUserQuestion, TodoWrite
model: sonnet
---

You are the Skill Stack orchestrator - the single entry point for all workflow management.

## Mode Detection

Parse the user's input to determine mode:

| Input Pattern | Mode | Action |
|---------------|------|--------|
| `/stack` (no args) | Menu | Show context-aware options |
| `/stack build` | Build | Invoke stack-build skill |
| `/stack edit <name>` | Edit | Invoke stack-build skill with edit context |
| `/stack list` | List | Show all available stacks |
| `/stack <name>` | Run | Load and execute stack via stack-run skill |

## Startup Checks

First, check for existing stacks:

```bash
ls ~/.claude/stacks/*.yaml 2>/dev/null || echo "NO_PERSONAL_STACKS"
ls .claude/stacks/*.yaml 2>/dev/null || echo "NO_PROJECT_STACKS"
```

## Mode: Menu (no arguments)

**If no stacks exist:**
```
Welcome to Skill Stack!

A stack chains skills and commands into a reusable workflow.
For example: brainstorm → plan → implement → test → verify

What would you like to do?

1. Build your first stack (I'll guide you with questions)
2. Learn more about how stacks work
```

**If stacks exist, show context-aware menu:**
```
What would you like to do?

1. Run a stack
2. Build new stack
3. Edit existing stack
4. List all stacks

Your stacks:
• [stack-name] - [description]
• ...
```

Use AskUserQuestion tool to present options.

## Mode: Build

Invoke the stack-build skill:
```
Use the stack-build skill to guide the user through creating a new workflow stack.
```

**Pass context:**
- Available skills (from discovery)
- Available commands
- Existing stacks (for extends/includes)

## Mode: Edit

Invoke stack-build skill with edit context:
```
Use the stack-build skill to edit the existing stack at [path].
Load the current stack and show its structure before asking what to change.
```

## Mode: List

Show all available stacks:

```
Your stacks:

Personal (~/.claude/stacks/):
• [name] - [description]
  [compact flow: step1 → step2 → ...]

Project (.claude/stacks/):
• [name] - [description]
  [compact flow: step1 → step2 → ...]
```

For compact flow, use icons:
- `⚡` for parallel blocks
- `🔄` for loops
- `❓` for branches

## Mode: Run

1. Load stack YAML from path
2. Invoke stack-validate skill to check integrity
3. If validation fails → show errors, offer to fix
4. If validation passes → invoke stack-run skill

```
Starting '[stack-name]' workflow...

[Show Mermaid diagram if available]

Steps: [count] total ([parallel count] parallel, [loop count] loops)

Ready to begin with '[first-step-name]'?
```

## Error Handling

If stack not found:
```
Stack '[name]' not found.

Did you mean one of these?
• [similar-name-1]
• [similar-name-2]

Or run `/stack build` to create a new stack.
```

## Guidelines

- Fast for list/menu operations
- Delegate to skills for complex work (build, run, validate)
- Always validate before running
- Context-aware suggestions based on git branch, recent activity
- Show Mermaid diagrams when available
```

**Step 3: Verify**

```bash
wc -l agents/stack.md
head -20 agents/stack.md
```

**Step 4: Commit**

```bash
git add agents/
git commit -m "feat: add stack agent orchestrator"
```

---

## Phase 3: Skills

### Task 5: Create stack-build Skill

**Files:**
- Create: `skills/stack-build/SKILL.md`

**Step 1: Create skills directory structure**

```bash
mkdir -p skills/stack-build skills/stack-run skills/stack-validate
```

**Step 2: Create SKILL.md**

Create `skills/stack-build/SKILL.md`:
```markdown
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
- skill: `name[name\n🧠 ref]:::skill`
- bash: `name[name\n💻 cmd]:::bash`
- command: `name[name\n⌨️ /cmd]:::command`

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
✅ Stack '[name]' saved to [path]

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
- If errors → show and help fix
- If warnings → show and ask to proceed
- If valid → save

## Guidelines

- ONE question at a time
- Prefer multiple choice (easier to answer)
- Show progress ("Step 3 of 5...")
- Allow going back
- Validate before saving
- Always generate Mermaid diagram
```

**Step 3: Verify**

```bash
wc -l skills/stack-build/SKILL.md
```

**Step 4: Commit**

```bash
git add skills/stack-build/
git commit -m "feat: add stack-build skill with Socratic flow"
```

---

### Task 6: Create stack-run Skill

**Files:**
- Create: `skills/stack-run/SKILL.md`

**Step 1: Create SKILL.md**

Create `skills/stack-run/SKILL.md`:
```markdown
---
name: stack-run
description: Use when executing a skill workflow stack - handles sequential, parallel, loop, and branching execution
---

# Stack Run Skill

## Overview

Execute skill workflow stacks with support for sequential, parallel, loop, and branching patterns.

**Announce:** "I'm using the stack-run skill to execute this workflow."

## Pre-Execution

1. **Load stack YAML** from provided path
2. **Parse structure** including steps, defaults, extends
3. **Resolve includes** if stack references other stacks
4. **Show execution plan:**

```
Starting '[stack-name]' workflow...

📊 Workflow Overview:
[Mermaid diagram from _meta.diagram]

Steps: [N] total
- Sequential: [N]
- Parallel blocks: [N]
- Loops: [N]

Ready to begin with '[first-step]'?
```

## Execution Engine

### Step Execution Order

```
For each item in steps:
  If item is regular step:
    Execute step
    Handle transition
  If item is parallel block:
    Execute parallel block
  If item is loop block:
    Execute loop block
```

### Regular Step Execution

```python
def execute_step(step):
    announce(f"Running step: {step.name}")

    if step.when and not evaluate(step.when):
        announce(f"Skipping {step.name} (condition not met)")
        return

    match step.type:
        case "skill":
            invoke_skill(step.ref, step.args)
        case "command":
            invoke_command(step.ref)
        case "bash":
            run_bash(step.run)
        case "stack":
            run_nested_stack(step.ref)

    capture_outputs(step.outputs)

    if step.branch:
        handle_branch(step.branch)
    else:
        handle_transition(step.transition)
```

### Parallel Block Execution

```python
def execute_parallel(block):
    announce(f"Starting parallel block: {block.name}")
    announce(f"Spawning {len(block.branches)} subagents...")

    # Use Task tool to spawn subagents
    tasks = []
    for branch in block.branches:
        task = spawn_subagent(
            name=branch.name,
            prompt=f"Execute: {branch}",
            run_in_background=True
        )
        tasks.append(task)

    # Wait based on mode
    match block.wait:
        case "all":
            wait_for_all(tasks)
        case "any":
            wait_for_any(tasks)
        case "none":
            pass  # Continue immediately

    announce(f"Parallel block '{block.name}' complete")
```

**Subagent prompt template:**
```
Execute this workflow step:

Name: [branch.name]
Type: [branch.type]
Reference: [branch.ref]
Args: [branch.args]

Context from parent workflow:
[relevant context/outputs]

Execute and report results.
```

### Loop Block Execution

```python
def execute_loop(block):
    announce(f"Starting loop: {block.name}")
    iteration = 0
    max_iter = block.max_iterations or 10

    while iteration < max_iter:
        iteration += 1
        announce(f"Loop iteration {iteration}/{max_iter}")

        # Execute loop steps
        for step in block.steps:
            execute_step(step)

        # Check exit condition
        if block.until and evaluate(block.until):
            announce(f"Loop '{block.name}' complete (condition met)")
            break
        elif block.while_ and not evaluate(block.while_):
            announce(f"Loop '{block.name}' complete (while false)")
            break
        elif block.times and iteration >= block.times:
            announce(f"Loop '{block.name}' complete ({block.times} iterations)")
            break
    else:
        # Max iterations reached
        match block.on_max_reached:
            case "ask":
                ask_user("Max iterations reached. Continue or stop?")
            case "stop":
                raise LoopMaxReached()
            case "continue":
                pass
```

### Branch Handling

```python
def handle_branch(branch):
    condition_result = evaluate(branch.if_)

    if condition_result:
        target = branch.then
    else:
        target = branch.else_

    if target:
        jump_to_step(target)
```

### Transition Handling

```python
def handle_transition(transition):
    match transition:
        case "auto":
            pass  # Continue immediately
        case "prompt":
            ask_user("Ready for next step?")
        case "pause":
            ask_user("Paused. Type 'continue' to proceed.")
```

## Error Handling

```python
def handle_error(step, error):
    on_error = step.on_error or defaults.on_error

    match on_error:
        case "stop":
            announce(f"Error in {step.name}: {error}")
            raise WorkflowError()
        case "continue":
            announce(f"Warning in {step.name}: {error}")
            announce("Continuing to next step...")
        case "retry":
            for attempt in range(step.max_retries or 3):
                try:
                    execute_step(step)
                    return
                except:
                    continue
            raise WorkflowError("Max retries exceeded")
        case "ask":
            choice = ask_user(f"""
Error in {step.name}: {error}

Options:
1. Retry this step
2. Skip and continue
3. Stop workflow
4. Jump to specific step
""")
            handle_user_choice(choice)
```

## Output Capture

For steps with `outputs:` field:
```python
def capture_outputs(outputs):
    if not outputs:
        return

    for output_name in outputs:
        # Outputs are captured from:
        # 1. Bash exit codes and stdout
        # 2. Skill completion messages
        # 3. User responses

        value = extract_output(output_name)
        context[output_name] = value
```

## Condition Evaluation

For `when:`, `until:`, `if:` conditions:
```python
def evaluate(condition):
    # Simple template evaluation
    # {{ variable }} → lookup in context
    # {{ not variable }} → negate
    # Supports: and, or, not, ==, !=

    resolved = template_substitute(condition, context)
    return eval_boolean(resolved)
```

## Progress Tracking

Use TodoWrite to show progress:
```python
def track_progress(steps):
    todos = []
    for i, step in enumerate(steps):
        todos.append({
            "content": step.name,
            "status": "pending" if i > 0 else "in_progress",
            "activeForm": f"Running {step.name}"
        })
    TodoWrite(todos)
```

Update as each step completes.

## Completion

```
✅ Workflow '[stack-name]' complete!

Summary:
- Steps executed: [N]
- Parallel blocks: [N]
- Loop iterations: [N]
- Time: [duration]

Outputs:
- [output_name]: [value]
- ...
```

## Guidelines

- Show clear progress indicators
- Use TodoWrite for step tracking
- Spawn subagents for parallel work
- Respect transition modes
- Capture and pass outputs between steps
- Handle errors per step configuration
```

**Step 2: Commit**

```bash
git add skills/stack-run/
git commit -m "feat: add stack-run execution engine skill"
```

---

### Task 7: Create stack-validate Skill

**Files:**
- Create: `skills/stack-validate/SKILL.md`

**Step 1: Create SKILL.md**

Create `skills/stack-validate/SKILL.md`:
```markdown
---
name: stack-validate
description: Use when validating stack YAML files - checks schema, references, and offers conversational fixes
---

# Stack Validate Skill

## Overview

Validate stack YAML files and help fix issues conversationally.

**Announce:** "I'm validating the stack configuration..."

## Validation Checks

### 1. Schema Validation

**Required fields:**
- `name` - Stack identifier
- `steps` - Array of workflow steps

**Optional fields:**
- `_meta` - Metadata block
- `description` - Stack description
- `scope` - personal or project
- `default_for` - Auto-suggest triggers
- `defaults` - Default settings
- `extends` - Base stack to inherit

**Step schema:**
```yaml
# Regular step
- name: string (required)
  type: skill | command | bash | stack (required)
  ref: string (required for skill/command/stack)
  run: string (required for bash)
  args: string (optional)
  transition: auto | prompt | pause (optional)
  on_error: stop | continue | retry | ask (optional)
  when: string (optional, condition)
  outputs: array (optional)
  branch: object (optional)

# Parallel block
- parallel:
    name: string (required)
    wait: all | any | none (required)
    branches: array of steps (required)

# Loop block
- loop:
    name: string (required)
    until: string (optional, condition)
    while: string (optional, condition)
    times: number (optional)
    for_each: string (optional)
    max_iterations: number (optional)
    on_max_reached: ask | stop | continue (optional)
    steps: array (required)
```

### 2. Reference Validation

**Check skill refs exist:**
```bash
# For each skill ref in stack
ref="superpowers:brainstorming"
plugin=$(echo "$ref" | cut -d: -f1)
skill=$(echo "$ref" | cut -d: -f2)

# Check plugin skills
ls ~/.claude/plugins/cache/$plugin/*/skills/$skill/SKILL.md 2>/dev/null

# Check personal skills
ls ~/.claude/skills/$skill/SKILL.md 2>/dev/null
```

**Check command refs exist:**
```bash
# For each command ref
ls ~/.claude/commands/$ref.md 2>/dev/null
```

**Check stack refs exist (for nested/extends):**
```bash
ls ~/.claude/stacks/$ref.yaml .claude/stacks/$ref.yaml 2>/dev/null
```

### 3. Logic Validation

**No circular references:**
- Stack A extends B, B extends A → ERROR
- Stack A includes B, B includes A → ERROR

**Loops have exit conditions:**
- Every loop must have: `until`, `while`, `times`, or `for_each`

**Branch targets exist:**
- `then` and `else` must reference valid step names

**No orphan steps:**
- Steps after unconditional branch are unreachable

### 4. Safety Validation

**Limits:**
- `max_iterations` ≤ 20 (or warning)
- Parallel branches ≤ 5 (or warning)
- Nested stack depth ≤ 3

### 5. Checksum Validation

```python
def validate_checksum(yaml_content):
    meta = yaml_content.get('_meta', {})
    stored_checksum = meta.get('checksum', '')

    if not stored_checksum:
        return "missing", None

    # Compute checksum of content below _meta
    content_without_meta = remove_meta_block(yaml_content)
    computed = sha256(content_without_meta)

    if stored_checksum != f"sha256:{computed}":
        return "mismatch", computed

    return "valid", computed
```

## Validation Output

**If valid:**
```
✅ Stack '[name]' is valid.

Schema: ✓
References: ✓ (N skills, M commands)
Logic: ✓
Checksum: ✓
```

**If errors found:**
```
❌ Stack '[name]' has errors:

1. [Line N] Missing required field: steps
2. [Line M] Unknown skill ref: 'superpowers:brianstorm'
   Did you mean: 'superpowers:brainstorming'?
3. [Line P] Loop 'dev-cycle' has no exit condition
   Add 'until:', 'while:', or 'times:'

Would you like me to fix these?
```

**If warnings found:**
```
⚠️ Stack '[name]' has warnings:

1. max_iterations (25) exceeds recommended limit (20)
2. 6 parallel branches may impact performance

Proceed anyway?
```

## Conversational Fixes

When user agrees to fix:

**Typo in skill ref:**
```
Fixing 'superpowers:brianstorm' → 'superpowers:brainstorming'
```

**Missing exit condition:**
```
Loop 'dev-cycle' needs an exit condition.

Options:
1. Add 'until: "{{ condition }}"' - exit when true
2. Add 'times: N' - fixed iterations
3. Add 'max_iterations: N' - safety limit only
```

**Missing required field:**
```
The stack is missing 'steps'.

Would you like to:
1. Add steps now (I'll guide you)
2. Open in builder (/stack edit [name])
```

## Checksum Mismatch Handling

```
⚠️ This stack was modified outside the builder.

The checksum doesn't match, indicating manual edits.

Options:
1. Validate and update checksum (keep changes)
2. Open in builder to review
3. Run anyway (skip checksum)
```

If user chooses option 1:
- Run full validation
- If valid, update checksum
- Save file

## Auto-Fix Mode

For minor issues, offer automatic fixes:
```
Found 2 auto-fixable issues:
1. Typo in skill ref (brianstorm → brainstorming)
2. Missing checksum

Apply automatic fixes?
```

## Guidelines

- Be helpful, not blocking
- Suggest fixes, don't just report errors
- Fuzzy match for typos
- Allow override for warnings
- Always explain why something is invalid
```

**Step 2: Commit**

```bash
git add skills/stack-validate/
git commit -m "feat: add stack-validate skill with conversational fixes"
```

---

## Phase 4: Reference Documentation

### Task 8: Create YAML Schema Reference

**Files:**
- Create: `references/yaml-schema.md`

**Step 1: Create references directory**

```bash
mkdir -p references
```

**Step 2: Create yaml-schema.md**

Create `references/yaml-schema.md`:
```markdown
# Stack YAML Schema Reference

## Complete Schema

```yaml
# Metadata (auto-generated)
_meta:
  version: 1.0                    # Schema version
  created_by: skill-stack-builder # Creator
  created_at: ISO8601             # Creation timestamp
  modified_at: ISO8601            # Last modified
  checksum: sha256:...            # Content hash
  diagram: |                      # Mermaid flowchart
    flowchart TD
      ...

# Stack identity
name: string                      # Required: unique identifier
description: string               # Optional: human description
scope: personal | project         # Optional: storage location

# Auto-suggest triggers
default_for:                      # Optional
  - task: string                  # Task type
    keywords: [string]            # Trigger words

# Inheritance
extends: string                   # Optional: base stack name

# Default settings
defaults:                         # Optional
  on_error: stop | continue | retry | ask
  transition: auto | prompt | pause

# Workflow steps
steps:                            # Required: array of steps
  - <step>
  - <parallel-block>
  - <loop-block>
```

## Step Types

### Regular Step

```yaml
- name: string                    # Required: step identifier
  type: skill | command | bash | stack  # Required
  ref: string                     # Required for skill/command/stack
  run: string                     # Required for bash (multiline supported)
  args: string                    # Optional: arguments
  description: string             # Optional: human description
  transition: auto | prompt | pause  # Optional
  on_error: stop | continue | retry | ask  # Optional
  max_retries: number             # Optional: for retry mode
  when: string                    # Optional: condition to execute
  outputs: [string]               # Optional: values to capture
  branch:                         # Optional: conditional flow
    if: string                    # Condition
    then: string                  # Step name if true
    else: string                  # Step name if false
```

### Parallel Block

```yaml
- parallel:
    name: string                  # Required: block identifier
    wait: all | any | none        # Required: completion mode
    branches:                     # Required: parallel steps
      - name: string
        type: skill | command | bash | stack
        ref: string
        # ... other step fields
```

### Loop Block

```yaml
- loop:
    name: string                  # Required: loop identifier
    until: string                 # Condition to exit (true = exit)
    while: string                 # Condition to continue (false = exit)
    times: number                 # Fixed iteration count
    for_each: string              # Iterate over list variable
    as: string                    # Loop variable name (for for_each)
    max_iterations: number        # Safety limit (default: 10)
    on_max_reached: ask | stop | continue
    steps:                        # Required: steps to repeat
      - <step>
```

## Conditions

Conditions use template syntax:

```yaml
when: "{{ variable }}"            # Truthy check
when: "{{ not variable }}"        # Falsy check
when: "{{ a and b }}"             # Logical AND
when: "{{ a or b }}"              # Logical OR
when: "{{ a == 'value' }}"        # Equality
when: "{{ a != 'value' }}"        # Inequality
```

## Examples

See `references/example-stacks.md` for complete examples.
```

**Step 3: Commit**

```bash
git add references/yaml-schema.md
git commit -m "docs: add YAML schema reference"
```

---

### Task 9: Create Step Types Reference

**Files:**
- Create: `references/step-types.md`

**Step 1: Create step-types.md**

Create `references/step-types.md`:
```markdown
# Step Types Reference

## skill

Invoke a Claude Code skill.

```yaml
- name: brainstorm
  type: skill
  ref: superpowers:brainstorming
  args: "Explore feature requirements"
  transition: prompt
```

**ref formats:**
- `plugin:skill-name` - Plugin skill (e.g., `superpowers:brainstorming`)
- `skill-name` - Personal skill (e.g., `my-custom-skill`)

---

## command

Invoke a Claude Code command.

```yaml
- name: commit-changes
  type: command
  ref: /commit
  transition: prompt
```

**ref formats:**
- `/command-name` - Built-in or custom command
- `command-name` - Without slash

---

## bash

Run a shell command.

```yaml
- name: run-tests
  type: bash
  run: npm test
  on_error: continue
  outputs:
    - tests_pass
```

**Multiline:**
```yaml
- name: setup
  type: bash
  run: |
    npm install
    npm run build
    npm test
```

---

## stack

Run a nested stack.

```yaml
- name: verification-flow
  type: stack
  ref: verify-stack
  transition: prompt
```

Nested stacks inherit context from parent.

---

## Comparison

| Type | Use When | Execution |
|------|----------|-----------|
| skill | Need Claude assistance | Invokes skill, waits for completion |
| command | Simple command invocation | Runs command directly |
| bash | Shell operations | Runs in shell, captures output |
| stack | Reusable sub-workflows | Loads and executes nested stack |
```

**Step 2: Commit**

```bash
git add references/step-types.md
git commit -m "docs: add step types reference"
```

---

### Task 10: Create Example Stacks Reference

**Files:**
- Create: `references/example-stacks.md`

**Step 1: Create example-stacks.md**

Create `references/example-stacks.md`:
```markdown
# Example Stack Patterns

These examples show what's possible. Use `/stack build` to create your own.

## Simple Sequential

```yaml
name: quick-task
description: Simple linear workflow
steps:
  - name: plan
    type: skill
    ref: superpowers:brainstorming
    transition: prompt

  - name: implement
    type: skill
    ref: superpowers:test-driven-development
    transition: prompt

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
```

---

## Parallel Execution

```yaml
name: parallel-work
description: Run tasks simultaneously
steps:
  - name: setup
    type: bash
    run: echo "Starting..."

  - parallel:
      name: concurrent-tasks
      wait: all
      branches:
        - name: backend
          type: skill
          ref: superpowers:test-driven-development
          args: "backend API"
        - name: frontend
          type: skill
          ref: superpowers:test-driven-development
          args: "frontend UI"
        - name: tests
          type: bash
          run: npm run test:watch

  - name: integrate
    type: bash
    run: npm run build
```

---

## TDD Loop

```yaml
name: tdd-cycle
description: Test-driven development loop
steps:
  - loop:
      name: red-green-refactor
      until: "{{ all_tests_pass }}"
      max_iterations: 10
      steps:
        - name: write-test
          type: skill
          ref: superpowers:test-driven-development
          args: "write failing test"

        - name: run-tests
          type: bash
          run: npm test
          on_error: continue
          outputs:
            - all_tests_pass
            - failed_tests

        - name: fix
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not all_tests_pass }}"
          args: "Fix: {{ failed_tests }}"

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion
```

---

## Conditional Branching

```yaml
name: review-flow
description: Branch based on review result
steps:
  - name: implement
    type: skill
    ref: superpowers:test-driven-development

  - name: request-review
    type: skill
    ref: superpowers:requesting-code-review
    outputs:
      - review_approved

  - name: check-approval
    type: bash
    run: echo "Checking review status..."
    branch:
      if: "{{ review_approved }}"
      then: merge
      else: revise

  - name: revise
    type: skill
    ref: superpowers:receiving-code-review
    branch:
      if: "true"
      then: request-review
      else: request-review

  - name: merge
    type: command
    ref: /commit
```

---

## Full Feature Workflow

```yaml
name: fullstack-feature
description: Complete feature development
default_for:
  - task: feature
    keywords: ["add", "create", "implement", "build"]

defaults:
  on_error: ask
  transition: prompt

steps:
  - name: brainstorm
    type: skill
    ref: superpowers:brainstorming
    description: Explore requirements

  - name: plan
    type: skill
    ref: superpowers:writing-plans

  - parallel:
      name: implementation
      wait: all
      branches:
        - name: backend
          type: skill
          ref: superpowers:test-driven-development
          args: "backend"
        - name: frontend
          type: skill
          ref: superpowers:test-driven-development
          args: "frontend"

  - loop:
      name: quality
      until: "{{ tests_pass }}"
      max_iterations: 5
      steps:
        - name: test
          type: bash
          run: npm test
          outputs: [tests_pass]
        - name: fix
          type: skill
          ref: superpowers:systematic-debugging
          when: "{{ not tests_pass }}"

  - name: verify
    type: skill
    ref: superpowers:verification-before-completion

  - name: review
    type: skill
    ref: superpowers:requesting-code-review

  - name: finish
    type: skill
    ref: superpowers:finishing-a-development-branch
```

---

*These are reference examples. Build your own stack with `/stack build`.*
```

**Step 2: Commit**

```bash
git add references/example-stacks.md
git commit -m "docs: add example stacks reference"
```

---

### Task 11: Create Loop Patterns Reference

**Files:**
- Create: `references/loop-patterns.md`

**Step 1: Create loop-patterns.md**

Create `references/loop-patterns.md`:
```markdown
# Loop Patterns Reference

## Until Loop (Exit When True)

Exit when condition becomes true.

```yaml
- loop:
    name: retry-until-success
    until: "{{ operation_succeeded }}"
    max_iterations: 5
    steps:
      - name: try-operation
        type: bash
        run: ./do-something.sh
        outputs: [operation_succeeded]
```

---

## While Loop (Continue While True)

Continue while condition is true.

```yaml
- loop:
    name: process-while-items
    while: "{{ has_more_items }}"
    steps:
      - name: process-item
        type: bash
        run: ./process-next.sh
        outputs: [has_more_items]
```

---

## Fixed Iterations

Run exactly N times.

```yaml
- loop:
    name: retry-3-times
    times: 3
    steps:
      - name: attempt
        type: bash
        run: ./attempt.sh
```

---

## For-Each Loop

Iterate over a list.

```yaml
- loop:
    name: process-files
    for_each: "{{ changed_files }}"
    as: current_file
    steps:
      - name: lint-file
        type: bash
        run: eslint {{ current_file }}
      - name: test-file
        type: bash
        run: jest {{ current_file }}
```

---

## Safety Limits

Always set `max_iterations` to prevent infinite loops:

```yaml
- loop:
    name: safe-loop
    until: "{{ done }}"
    max_iterations: 20
    on_max_reached: ask  # ask | stop | continue
    steps:
      - ...
```

---

## Nested Loops

Loops can contain other loops (up to 3 levels):

```yaml
- loop:
    name: outer
    times: 3
    steps:
      - loop:
          name: inner
          times: 2
          steps:
            - name: work
              type: bash
              run: echo "Outer $OUTER, Inner $INNER"
```
```

**Step 2: Commit**

```bash
git add references/loop-patterns.md
git commit -m "docs: add loop patterns reference"
```

---

## Phase 5: Validation & Testing

### Task 12: Create Structure Validation Script

**Files:**
- Create: `tests/validate-structure.sh`

**Step 1: Create validation script**

Create `tests/validate-structure.sh`:
```bash
#!/bin/bash

# Skill Stack Plugin Structure Validator
# Run from project root: ./tests/validate-structure.sh

set -e

echo "=== Skill Stack Structure Validation ==="
echo ""

ERRORS=0

check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1"
    else
        echo "✗ $1 (MISSING)"
        ERRORS=$((ERRORS + 1))
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo "✓ $1/"
    else
        echo "✗ $1/ (MISSING)"
        ERRORS=$((ERRORS + 1))
    fi
}

echo "Checking plugin manifest..."
check_file ".claude-plugin/plugin.json"
check_file ".claude-plugin/marketplace.json"

echo ""
echo "Checking command..."
check_dir "commands"
check_file "commands/stack.md"

echo ""
echo "Checking agent..."
check_dir "agents"
check_file "agents/stack.md"

echo ""
echo "Checking skills..."
check_dir "skills"
check_dir "skills/stack-build"
check_file "skills/stack-build/SKILL.md"
check_dir "skills/stack-run"
check_file "skills/stack-run/SKILL.md"
check_dir "skills/stack-validate"
check_file "skills/stack-validate/SKILL.md"

echo ""
echo "Checking references..."
check_dir "references"
check_file "references/yaml-schema.md"
check_file "references/step-types.md"
check_file "references/example-stacks.md"
check_file "references/loop-patterns.md"

echo ""
echo "Checking root files..."
check_file "CLAUDE.md"
check_file "README.md"
check_file "VERSION"

echo ""
echo "=== Validation Complete ==="

if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed!"
    exit 0
else
    echo "❌ Found $ERRORS error(s)"
    exit 1
fi
```

**Step 2: Make executable**

```bash
chmod +x tests/validate-structure.sh
```

**Step 3: Commit**

```bash
git add tests/validate-structure.sh
git commit -m "test: add plugin structure validation script"
```

---

### Task 13: Validate Complete Structure

**Step 1: Run structure validation**

```bash
./tests/validate-structure.sh
```

**Expected output:**
```
=== Skill Stack Structure Validation ===

Checking plugin manifest...
✓ .claude-plugin/plugin.json
✓ .claude-plugin/marketplace.json

Checking command...
✓ commands/
✓ commands/stack.md

Checking agent...
✓ agents/
✓ agents/stack.md

Checking skills...
✓ skills/
✓ skills/stack-build/
✓ skills/stack-build/SKILL.md
✓ skills/stack-run/
✓ skills/stack-run/SKILL.md
✓ skills/stack-validate/
✓ skills/stack-validate/SKILL.md

Checking references...
✓ references/
✓ references/yaml-schema.md
✓ references/step-types.md
✓ references/example-stacks.md
✓ references/loop-patterns.md

Checking root files...
✓ CLAUDE.md
✓ README.md
✓ VERSION

=== Validation Complete ===
✅ All checks passed!
```

**Step 2: Run full test suite**

```bash
./tests/run-tests.sh
```

**Step 3: Final commit**

```bash
git add .
git commit -m "feat: complete skill-stack plugin implementation"
```

---

## Phase 6: Local Testing

### Task 14: Install Plugin Locally

**Step 1: Add local marketplace**

In Claude Code:
```
/plugin marketplace add ./
```

**Step 2: Install plugin**

```
/plugin install skill-stack@skill-stack-marketplace
```

**Step 3: Restart Claude Code**

Close and reopen Claude Code.

**Step 4: Verify installation**

```
/help
```

Expected: `/stack` command appears in help.

---

### Task 15: Test Basic Functionality

**Step 1: Test menu mode**

```
/stack
```

Expected: Shows welcome or menu with options.

**Step 2: Test build mode**

```
/stack build
```

Expected: Starts Socratic questioning flow.

**Step 3: Test list mode**

```
/stack list
```

Expected: Shows "no stacks" or list of stacks.

---

## Summary

**Total Tasks:** 15

**Files Created:**
1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `VERSION`
4. `CLAUDE.md`
5. `README.md`
6. `commands/stack.md`
7. `agents/stack.md`
8. `skills/stack-build/SKILL.md`
9. `skills/stack-run/SKILL.md`
10. `skills/stack-validate/SKILL.md`
11. `references/yaml-schema.md`
12. `references/step-types.md`
13. `references/example-stacks.md`
14. `references/loop-patterns.md`
15. `tests/validate-structure.sh`

**Commits:** 13 (one per logical unit)

**Testing:**
- Structure validation: automated
- Fixture validation: automated
- Functionality: manual scenarios
