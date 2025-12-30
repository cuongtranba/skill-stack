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
  timeout: number                 # Optional: max seconds for bash steps (default: 120)
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
