# Test Fixtures

## Overview

Test fixtures are **dynamically generated** based on discovered skills and commands in the current environment. This ensures tests use real, available resources.

## Fixture Generation Flow

```
┌─────────────────────────────────────────────────────────┐
│                  BEFORE RUNNING TESTS                    │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              1. Run Discovery Script                     │
│                                                          │
│  ./tests/scripts/discover-resources.sh                   │
│                                                          │
│  Scans:                                                  │
│  - ~/.claude/skills/                                     │
│  - ~/.claude/commands/                                   │
│  - ~/.claude/plugins/cache/*/skills/                     │
│  - .claude/skills/ (project)                             │
│  - .claude/commands/ (project)                           │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              2. Generate Discovery JSON                  │
│                                                          │
│  Output: tests/fixtures/discovered-resources.json        │
│                                                          │
│  {                                                       │
│    "skills": [...],                                      │
│    "commands": [...],                                    │
│    "plugins": [...]                                      │
│  }                                                       │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              3. Generate Test Fixtures                   │
│                                                          │
│  ./tests/scripts/generate-fixtures.sh                    │
│                                                          │
│  Creates:                                                │
│  - tests/fixtures/generated/valid-*.yaml                 │
│  - tests/fixtures/generated/invalid-*.yaml               │
│  - tests/fixtures/generated/scenarios/*.yaml             │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              4. Run Tests with Real Resources            │
└─────────────────────────────────────────────────────────┘
```

## Directory Structure

```
tests/fixtures/
├── README.md                      # This file
├── discovered-resources.json      # Generated: available skills/commands
├── templates/                     # Fixture templates (use placeholders)
│   ├── valid-simple.yaml.tmpl
│   ├── valid-parallel.yaml.tmpl
│   ├── valid-loop.yaml.tmpl
│   ├── scenario-fullstack.yaml.tmpl
│   └── ...
├── generated/                     # Generated fixtures (git-ignored)
│   ├── valid-simple.yaml
│   ├── valid-parallel.yaml
│   └── ...
└── static/                        # Static fixtures (no skill refs)
    ├── invalid-missing-name.yaml
    ├── invalid-missing-steps.yaml
    └── ...
```

## Usage

```bash
# Full preparation
./tests/scripts/prepare-fixtures.sh

# Or step by step:
./tests/scripts/discover-resources.sh
./tests/scripts/generate-fixtures.sh

# Then run tests
./tests/run-tests.sh
```
