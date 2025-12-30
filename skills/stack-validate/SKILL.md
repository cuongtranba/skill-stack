---
name: stack-validate
description: Use when validating stack YAML files - checks schema, references, and offers conversational fixes
---

# Stack Validate Skill

## Overview

Validate stack YAML files and help fix issues conversationally.

**Announce:** "I'm validating the stack configuration..."

## Validation Checks

### 0. Syntax Validation (First Step)

Before any other validation, verify the YAML parses correctly:

```bash
# Check YAML syntax using Python (widely available)
python3 -c "import yaml, sys; yaml.safe_load(open(sys.argv[1]))" "$STACK_FILE" 2>&1
```

**If syntax error:**
```
Stack '[name]' has invalid YAML syntax:

  Line [N]: [error message from parser]

  Example: "mapping values are not allowed here"

Fix the YAML syntax before validation can continue.
Common issues:
- Missing quotes around strings with special characters
- Incorrect indentation (use 2 spaces, no tabs)
- Missing colons after keys
```

**Only proceed to schema validation if syntax check passes.**

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

```bash
# Set base path
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
```

**Check skill refs exist:**
```bash
# For each skill ref in stack
ref="superpowers:brainstorming"
plugin=$(echo "$ref" | cut -d: -f1)
skill=$(echo "$ref" | cut -d: -f2)

# Check plugin skills
ls "$CLAUDE_HOME/plugins/cache/$plugin"/*/skills/"$skill"/SKILL.md 2>/dev/null

# Check personal skills
ls "$CLAUDE_HOME/skills/$skill/SKILL.md" 2>/dev/null
```

**Check command refs exist:**
```bash
# For each command ref
ls "$CLAUDE_HOME/commands/$ref.md" 2>/dev/null
```

**Check stack refs exist (for nested/extends):**
```bash
ls "$CLAUDE_HOME/stacks/$ref.yaml" .claude/stacks/"$ref.yaml" 2>/dev/null
```

### 3. Logic Validation

**No circular references:**
- Stack A extends B, B extends A -> ERROR
- Stack A includes B, B includes A -> ERROR

**Loops have exit conditions:**
- Every loop must have: `until`, `while`, `times`, or `for_each`

**Branch targets exist:**
- `then` and `else` must reference valid step names

**No orphan steps:**
- Steps after unconditional branch are unreachable

### 4. Safety Validation

**Limits:**
- `max_iterations` <= 20 (or warning)
- Parallel branches <= 5 (or warning)
- Nested stack depth <= 3

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
Stack '[name]' is valid.

Schema: OK
References: OK (N skills, M commands)
Logic: OK
Checksum: OK
```

**If errors found:**
```
Stack '[name]' has errors:

1. [Line N] Missing required field: steps
2. [Line M] Unknown skill ref: 'superpowers:brianstorm'
   Did you mean: 'superpowers:brainstorming'?
3. [Line P] Loop 'dev-cycle' has no exit condition
   Add 'until:', 'while:', or 'times:'

Would you like me to fix these?
```

**If warnings found:**
```
Stack '[name]' has warnings:

1. max_iterations (25) exceeds recommended limit (20)
2. 6 parallel branches may impact performance

Proceed anyway?
```

## Conversational Fixes

When user agrees to fix:

**Typo in skill ref:**
```
Fixing 'superpowers:brianstorm' -> 'superpowers:brainstorming'
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
This stack was modified outside the builder.

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
1. Typo in skill ref (brianstorm -> brainstorming)
2. Missing checksum

Apply automatic fixes?
```

## Guidelines

- Be helpful, not blocking
- Suggest fixes, don't just report errors
- Fuzzy match for typos
- Allow override for warnings
- Always explain why something is invalid
