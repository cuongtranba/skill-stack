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

## Skills

| Skill | Description |
|-------|-------------|
| `stack-build` | Socratic builder for creating stacks through guided questions |
| `stack-run` | Execution engine for running stack workflows |
| `stack-validate` | Validates stack YAML and offers conversational fixes |
| `wcag-verify` | Strict WCAG 2.1 A/AA accessibility reviewer for frontend files |

## Documentation

- [Design Document](docs/plans/2025-12-19-skill-stack-design.md)
- [YAML Schema](references/yaml-schema.md)
- [Step Types](references/step-types.md)
- [Examples](references/example-stacks.md)

## License

MIT
