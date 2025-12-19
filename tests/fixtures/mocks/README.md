# Mock Skills and Commands

These mock resources are used when the environment doesn't have enough real skills/commands for testing.

## When Mocks Are Used

1. Discovery finds < 3 skills → Use mock skills
2. Discovery finds < 2 commands → Use mock commands
3. Specific skill type needed but not available → Use mock

## Mock Resources

### Skills
- `mock-skill-alpha` - General purpose mock skill
- `mock-skill-beta` - Secondary mock skill
- `mock-skill-gamma` - Third mock skill
- `mock-skill-debug` - Debugging mock skill
- `mock-skill-verify` - Verification mock skill

### Commands
- `mock-command-one` - General purpose mock command
- `mock-command-two` - Secondary mock command

## Installation

Mocks are auto-installed to `~/.claude/skills/` when running fixture generation if needed.

```bash
./tests/scripts/install-mocks.sh
```

## Cleanup

```bash
./tests/scripts/cleanup-mocks.sh
```
