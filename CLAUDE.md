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
