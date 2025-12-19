# Skill Stack Test Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Validate that the skill-stack plugin works correctly before publishing

**Architecture:** Test-first approach - create test fixtures and scenarios before implementation, then verify each component works as designed

**Tech Stack:** Claude Code plugin (markdown, YAML), manual testing via Claude Code CLI

---

## Test Strategy

Since this is a Claude Code plugin (not executable code), testing involves:
1. **Structure tests** - Verify plugin files exist and are valid
2. **Fixture tests** - Create test stack YAMLs to validate parsing
3. **Scenario tests** - Manual testing with documented expected behavior
4. **Integration tests** - End-to-end plugin installation and usage

---

## Phase 1: Test Fixtures Setup

### Task 1.1: Create Test Directory Structure

**Files:**
- Create: `tests/fixtures/` directory
- Create: `tests/scenarios/` directory
- Create: `tests/README.md`

**Step 1: Create test directories**

```bash
mkdir -p tests/fixtures tests/scenarios
```

**Step 2: Create test README**

Create `tests/README.md`:
```markdown
# Skill Stack Tests

## Structure
- `fixtures/` - Test YAML files for validation testing
- `scenarios/` - Documented test scenarios for manual testing

## Running Tests

### Structure Validation
```bash
# Verify plugin structure
./tests/validate-structure.sh
```

### Manual Testing
Follow scenarios in `scenarios/` directory, documenting results.
```

**Step 3: Commit**

```bash
git add tests/
git commit -m "test: add test directory structure"
```

---

### Task 1.2: Create Valid Stack Fixtures

**Files:**
- Create: `tests/fixtures/valid-simple.yaml`
- Create: `tests/fixtures/valid-parallel.yaml`
- Create: `tests/fixtures/valid-loop.yaml`
- Create: `tests/fixtures/valid-branch.yaml`
- Create: `tests/fixtures/valid-full.yaml`

**Step 1: Create simple sequential stack fixture**

Create `tests/fixtures/valid-simple.yaml`:
```yaml
_meta:
  version: 1.0
  created_by: test
  created_at: 2025-12-19T00:00:00Z
  modified_at: 2025-12-19T00:00:00Z
  checksum: sha256:test-checksum

name: test-simple
description: Simple sequential stack for testing
scope: personal

defaults:
  on_error: ask
  transition: prompt

steps:
  - name: step-one
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    description: First step

  - name: step-two
    type: bash
    run: echo "Hello World"
    transition: auto

  - name: step-three
    type: command
    ref: /help
    transition: prompt
```

**Step 2: Create parallel stack fixture**

Create `tests/fixtures/valid-parallel.yaml`:
```yaml
_meta:
  version: 1.0
  created_by: test
  created_at: 2025-12-19T00:00:00Z
  modified_at: 2025-12-19T00:00:00Z
  checksum: sha256:test-checksum

name: test-parallel
description: Stack with parallel execution
scope: personal

steps:
  - name: setup
    type: bash
    run: echo "Starting parallel test"
    transition: auto

  - parallel:
      name: parallel-work
      wait: all
      branches:
        - name: branch-a
          type: bash
          run: echo "Branch A"
        - name: branch-b
          type: bash
          run: echo "Branch B"
        - name: branch-c
          type: bash
          run: echo "Branch C"

  - name: complete
    type: bash
    run: echo "All branches complete"
```

**Step 3: Create loop stack fixture**

Create `tests/fixtures/valid-loop.yaml`:
```yaml
_meta:
  version: 1.0
  created_by: test
  created_at: 2025-12-19T00:00:00Z
  modified_at: 2025-12-19T00:00:00Z
  checksum: sha256:test-checksum

name: test-loop
description: Stack with loop execution
scope: personal

steps:
  - name: init
    type: bash
    run: echo "Starting loop test"
    transition: auto

  - loop:
      name: retry-loop
      times: 3
      steps:
        - name: attempt
          type: bash
          run: echo "Attempt iteration"
          transition: auto

  - loop:
      name: until-loop
      until: "{{ success }}"
      max_iterations: 5
      steps:
        - name: try-action
          type: bash
          run: echo "Trying..."
          outputs:
            - success

  - name: done
    type: bash
    run: echo "Loops complete"
```

**Step 4: Create branch stack fixture**

Create `tests/fixtures/valid-branch.yaml`:
```yaml
_meta:
  version: 1.0
  created_by: test
  created_at: 2025-12-19T00:00:00Z
  modified_at: 2025-12-19T00:00:00Z
  checksum: sha256:test-checksum

name: test-branch
description: Stack with conditional branching
scope: personal

steps:
  - name: check
    type: bash
    run: echo "Checking condition"
    outputs:
      - condition_met

  - name: decide
    type: bash
    run: echo "Decision point"
    branch:
      if: "{{ condition_met }}"
      then: success-path
      else: failure-path

  - name: success-path
    type: bash
    run: echo "Success!"
    branch:
      if: "true"
      then: end
      else: end

  - name: failure-path
    type: bash
    run: echo "Failure path"

  - name: end
    type: bash
    run: echo "Done"
```

**Step 5: Create full-featured stack fixture**

Create `tests/fixtures/valid-full.yaml`:
```yaml
_meta:
  version: 1.0
  created_by: test
  created_at: 2025-12-19T00:00:00Z
  modified_at: 2025-12-19T00:00:00Z
  checksum: sha256:test-checksum

name: test-full
description: Full-featured stack for comprehensive testing
scope: project

default_for:
  - task: test
    keywords: ["test", "validate", "check"]

defaults:
  on_error: ask
  transition: prompt

steps:
  - name: start
    type: skill
    ref: superpowers:brainstorming
    transition: prompt
    description: Initial brainstorming

  - parallel:
      name: parallel-phase
      wait: all
      branches:
        - name: task-a
          type: bash
          run: echo "Task A"
        - name: task-b
          type: bash
          run: echo "Task B"

  - loop:
      name: dev-loop
      until: "{{ tests_pass }}"
      max_iterations: 3
      steps:
        - name: implement
          type: bash
          run: echo "Implementing"
          transition: auto
        - name: test
          type: bash
          run: echo "Testing"
          on_error: continue
          outputs:
            - tests_pass

  - name: review
    type: skill
    ref: superpowers:verification-before-completion
    branch:
      if: "{{ review_passed }}"
      then: complete
      else: dev-loop

  - name: complete
    type: bash
    run: echo "All done!"
```

**Step 6: Commit fixtures**

```bash
git add tests/fixtures/
git commit -m "test: add valid stack YAML fixtures"
```

---

### Task 1.3: Create Invalid Stack Fixtures

**Files:**
- Create: `tests/fixtures/invalid-missing-name.yaml`
- Create: `tests/fixtures/invalid-missing-steps.yaml`
- Create: `tests/fixtures/invalid-unknown-type.yaml`
- Create: `tests/fixtures/invalid-bad-ref.yaml`
- Create: `tests/fixtures/invalid-circular-branch.yaml`
- Create: `tests/fixtures/invalid-loop-no-exit.yaml`

**Step 1: Create missing name fixture**

Create `tests/fixtures/invalid-missing-name.yaml`:
```yaml
_meta:
  version: 1.0
  checksum: sha256:test

# ERROR: missing 'name' field
description: Stack without name
scope: personal

steps:
  - name: step-one
    type: bash
    run: echo "test"
```

**Step 2: Create missing steps fixture**

Create `tests/fixtures/invalid-missing-steps.yaml`:
```yaml
_meta:
  version: 1.0
  checksum: sha256:test

name: no-steps
description: Stack without steps
scope: personal

# ERROR: missing 'steps' field
```

**Step 3: Create unknown type fixture**

Create `tests/fixtures/invalid-unknown-type.yaml`:
```yaml
_meta:
  version: 1.0
  checksum: sha256:test

name: bad-type
description: Stack with unknown step type
scope: personal

steps:
  - name: bad-step
    type: unknown_type  # ERROR: invalid type
    ref: something
```

**Step 4: Create bad reference fixture**

Create `tests/fixtures/invalid-bad-ref.yaml`:
```yaml
_meta:
  version: 1.0
  checksum: sha256:test

name: bad-ref
description: Stack with non-existent skill reference
scope: personal

steps:
  - name: bad-skill
    type: skill
    ref: nonexistent:fake-skill  # ERROR: skill doesn't exist
```

**Step 5: Create circular branch fixture**

Create `tests/fixtures/invalid-circular-branch.yaml`:
```yaml
_meta:
  version: 1.0
  checksum: sha256:test

name: circular
description: Stack with circular branch reference
scope: personal

steps:
  - name: step-a
    type: bash
    run: echo "A"
    branch:
      if: "true"
      then: step-b
      else: step-b

  - name: step-b
    type: bash
    run: echo "B"
    branch:
      if: "true"
      then: step-a  # ERROR: circular reference back to step-a
      else: step-a
```

**Step 6: Create loop without exit fixture**

Create `tests/fixtures/invalid-loop-no-exit.yaml`:
```yaml
_meta:
  version: 1.0
  checksum: sha256:test

name: infinite-loop
description: Stack with loop that has no exit condition
scope: personal

steps:
  - loop:
      name: bad-loop
      # ERROR: no until, while, times, or for_each
      steps:
        - name: forever
          type: bash
          run: echo "infinite"
```

**Step 7: Commit invalid fixtures**

```bash
git add tests/fixtures/invalid-*.yaml
git commit -m "test: add invalid stack YAML fixtures for validation testing"
```

---

## Phase 2: Structure Validation Script

### Task 2.1: Create Plugin Structure Validator

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

# Check required files
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
    echo "All checks passed!"
    exit 0
else
    echo "Found $ERRORS error(s)"
    exit 1
fi
```

**Step 2: Make executable and commit**

```bash
chmod +x tests/validate-structure.sh
git add tests/validate-structure.sh
git commit -m "test: add plugin structure validation script"
```

---

## Phase 3: Test Scenarios

### Task 3.1: Installation Test Scenario

**Files:**
- Create: `tests/scenarios/01-installation.md`

**Step 1: Create installation test scenario**

Create `tests/scenarios/01-installation.md`:
```markdown
# Test Scenario 01: Plugin Installation

## Objective
Verify the plugin can be installed from local marketplace.

## Prerequisites
- Claude Code CLI installed
- Plugin structure complete (run `./tests/validate-structure.sh` first)

## Steps

### Step 1: Add Local Marketplace
```bash
/plugin marketplace add ./
```

**Expected:** Marketplace added successfully

### Step 2: Install Plugin
```bash
/plugin install skill-stack@skill-stack-marketplace
```

**Expected:** Plugin installed, prompt to restart Claude Code

### Step 3: Restart and Verify
Restart Claude Code, then:
```bash
/help
```

**Expected:** `/stack` command appears in help output

### Step 4: Test Command Exists
```bash
/stack
```

**Expected:** Shows menu or welcome message

## Results

| Step | Status | Notes |
|------|--------|-------|
| 1. Add marketplace | | |
| 2. Install plugin | | |
| 3. Verify in help | | |
| 4. Test command | | |

## Tester
- Name:
- Date:
```

**Step 2: Commit**

```bash
git add tests/scenarios/01-installation.md
git commit -m "test: add installation test scenario"
```

---

### Task 3.2: Command Routing Test Scenario

**Files:**
- Create: `tests/scenarios/02-command-routing.md`

**Step 1: Create command routing test scenario**

Create `tests/scenarios/02-command-routing.md`:
```markdown
# Test Scenario 02: Command Routing

## Objective
Verify `/stack` command routes correctly to different modes.

## Prerequisites
- Plugin installed (Scenario 01 passed)

## Steps

### Step 1: Menu Mode (no args)
```bash
/stack
```

**Expected:** Shows menu with options:
- Run a stack
- Build new stack
- Edit existing stack
- List stacks

### Step 2: Build Mode
```bash
/stack build
```

**Expected:** Starts Socratic builder flow, asks first question

### Step 3: List Mode
```bash
/stack list
```

**Expected:** Shows available stacks (or "no stacks" message)

### Step 4: Run Mode (non-existent)
```bash
/stack nonexistent-stack
```

**Expected:** Error message "Stack 'nonexistent-stack' not found"

### Step 5: Edit Mode (non-existent)
```bash
/stack edit nonexistent-stack
```

**Expected:** Error message or offer to create new stack

## Results

| Step | Status | Notes |
|------|--------|-------|
| 1. Menu mode | | |
| 2. Build mode | | |
| 3. List mode | | |
| 4. Run (missing) | | |
| 5. Edit (missing) | | |

## Tester
- Name:
- Date:
```

**Step 2: Commit**

```bash
git add tests/scenarios/02-command-routing.md
git commit -m "test: add command routing test scenario"
```

---

### Task 3.3: Stack Build Test Scenario

**Files:**
- Create: `tests/scenarios/03-stack-build.md`

**Step 1: Create stack build test scenario**

Create `tests/scenarios/03-stack-build.md`:
```markdown
# Test Scenario 03: Stack Build (Socratic Flow)

## Objective
Verify the Socratic builder creates valid stack YAML.

## Prerequisites
- Plugin installed (Scenario 01 passed)

## Steps

### Step 1: Start Builder
```bash
/stack build
```

**Expected:** Asks role/context question (multiple choice)

### Step 2: Answer Role Question
Select an option (e.g., "Fullstack developer")

**Expected:** Asks about task type or pain points

### Step 3: Answer Task Question
Select or describe task type

**Expected:** Asks about workflow steps

### Step 4: Build Workflow
Follow prompts to add 2-3 steps:
- Add a skill step
- Add a bash step
- Add transitions

**Expected:** Shows current stack, asks for more steps or confirmation

### Step 5: Choose Scope
When asked, select "personal" scope

**Expected:** Asks for stack name

### Step 6: Name Stack
Enter: `test-build-scenario`

**Expected:**
- Shows final stack YAML
- Saves to `~/.claude/stacks/test-build-scenario.yaml`
- Shows success message

### Step 7: Verify File Created
```bash
cat ~/.claude/stacks/test-build-scenario.yaml
```

**Expected:** Valid YAML with:
- `_meta` block with checksum
- `name: test-build-scenario`
- `steps` array with defined steps

## Cleanup
```bash
rm ~/.claude/stacks/test-build-scenario.yaml
```

## Results

| Step | Status | Notes |
|------|--------|-------|
| 1. Start builder | | |
| 2. Role question | | |
| 3. Task question | | |
| 4. Build workflow | | |
| 5. Choose scope | | |
| 6. Name stack | | |
| 7. Verify file | | |

## Tester
- Name:
- Date:
```

**Step 2: Commit**

```bash
git add tests/scenarios/03-stack-build.md
git commit -m "test: add stack build Socratic flow test scenario"
```

---

### Task 3.4: Stack Run Test Scenario

**Files:**
- Create: `tests/scenarios/04-stack-run.md`

**Step 1: Create stack run test scenario**

Create `tests/scenarios/04-stack-run.md`:
```markdown
# Test Scenario 04: Stack Run (Execution)

## Objective
Verify stack runner executes different step types correctly.

## Prerequisites
- Plugin installed (Scenario 01 passed)
- Test fixtures available

## Setup
Copy test fixture to stacks directory:
```bash
mkdir -p ~/.claude/stacks
cp tests/fixtures/valid-simple.yaml ~/.claude/stacks/test-simple.yaml
```

## Steps

### Step 1: Run Simple Stack
```bash
/stack test-simple
```

**Expected:**
- Shows execution plan
- Asks to confirm start
- Executes step-one (skill)
- Executes step-two (bash) - shows "Hello World"
- Executes step-three (command)
- Shows completion message

### Step 2: Test Transition Prompt
During execution, at `transition: prompt` steps:

**Expected:** Asks "Ready for next step?" before proceeding

### Step 3: Test Transition Auto
At `transition: auto` steps:

**Expected:** Proceeds automatically without asking

## Parallel Execution Test

### Setup
```bash
cp tests/fixtures/valid-parallel.yaml ~/.claude/stacks/test-parallel.yaml
```

### Step 4: Run Parallel Stack
```bash
/stack test-parallel
```

**Expected:**
- Shows setup step
- Shows "Starting parallel branches..."
- Spawns subagents for branch-a, branch-b, branch-c
- Shows "Waiting for all branches..."
- Shows completion when all done

## Loop Execution Test

### Setup
```bash
cp tests/fixtures/valid-loop.yaml ~/.claude/stacks/test-loop.yaml
```

### Step 5: Run Loop Stack
```bash
/stack test-loop
```

**Expected:**
- Executes retry-loop exactly 3 times
- Executes until-loop until condition or max (5)
- Shows iteration count for each loop

## Cleanup
```bash
rm ~/.claude/stacks/test-*.yaml
```

## Results

| Step | Status | Notes |
|------|--------|-------|
| 1. Run simple | | |
| 2. Transition prompt | | |
| 3. Transition auto | | |
| 4. Run parallel | | |
| 5. Run loop | | |

## Tester
- Name:
- Date:
```

**Step 2: Commit**

```bash
git add tests/scenarios/04-stack-run.md
git commit -m "test: add stack run execution test scenario"
```

---

### Task 3.5: Stack Validate Test Scenario

**Files:**
- Create: `tests/scenarios/05-stack-validate.md`

**Step 1: Create stack validate test scenario**

Create `tests/scenarios/05-stack-validate.md`:
```markdown
# Test Scenario 05: Stack Validation

## Objective
Verify validator catches errors and offers fixes.

## Prerequisites
- Plugin installed (Scenario 01 passed)
- Test fixtures available

## Valid Stack Tests

### Step 1: Validate Valid Simple Stack
```bash
# Copy fixture
cp tests/fixtures/valid-simple.yaml ~/.claude/stacks/test-valid.yaml

# Try to run (triggers validation)
/stack test-valid
```

**Expected:** Validation passes, execution starts

### Step 2: Validate Valid Full Stack
```bash
cp tests/fixtures/valid-full.yaml ~/.claude/stacks/test-full.yaml
/stack test-full
```

**Expected:** Validation passes for complex stack

## Invalid Stack Tests

### Step 3: Missing Name
```bash
cp tests/fixtures/invalid-missing-name.yaml ~/.claude/stacks/test-invalid.yaml
/stack test-invalid
```

**Expected:**
- Validation fails
- Error: "Missing required field: name"
- Offers to open in builder

### Step 4: Missing Steps
```bash
cp tests/fixtures/invalid-missing-steps.yaml ~/.claude/stacks/test-invalid.yaml
/stack test-invalid
```

**Expected:**
- Validation fails
- Error: "Missing required field: steps"

### Step 5: Unknown Type
```bash
cp tests/fixtures/invalid-unknown-type.yaml ~/.claude/stacks/test-invalid.yaml
/stack test-invalid
```

**Expected:**
- Validation fails
- Error: "Unknown step type: unknown_type"
- Suggests valid types

### Step 6: Bad Reference
```bash
cp tests/fixtures/invalid-bad-ref.yaml ~/.claude/stacks/test-invalid.yaml
/stack test-invalid
```

**Expected:**
- Validation fails
- Error: "Skill not found: nonexistent:fake-skill"
- Suggests similar skills if any

### Step 7: Loop Without Exit
```bash
cp tests/fixtures/invalid-loop-no-exit.yaml ~/.claude/stacks/test-invalid.yaml
/stack test-invalid
```

**Expected:**
- Validation fails
- Error: "Loop 'bad-loop' has no exit condition"

## Manual Edit Detection Test

### Step 8: Checksum Mismatch
```bash
# Copy valid stack
cp tests/fixtures/valid-simple.yaml ~/.claude/stacks/test-checksum.yaml

# Manually edit (change description)
sed -i '' 's/Simple sequential/MODIFIED/' ~/.claude/stacks/test-checksum.yaml

# Run stack
/stack test-checksum
```

**Expected:**
- Detects checksum mismatch
- Message: "This stack was modified outside the builder"
- Offers options: validate, open in builder, run anyway

## Cleanup
```bash
rm ~/.claude/stacks/test-*.yaml
```

## Results

| Step | Status | Notes |
|------|--------|-------|
| 1. Valid simple | | |
| 2. Valid full | | |
| 3. Missing name | | |
| 4. Missing steps | | |
| 5. Unknown type | | |
| 6. Bad reference | | |
| 7. Loop no exit | | |
| 8. Checksum mismatch | | |

## Tester
- Name:
- Date:
```

**Step 2: Commit**

```bash
git add tests/scenarios/05-stack-validate.md
git commit -m "test: add stack validation test scenario"
```

---

### Task 3.6: Integration Test Scenario

**Files:**
- Create: `tests/scenarios/06-integration.md`

**Step 1: Create integration test scenario**

Create `tests/scenarios/06-integration.md`:
```markdown
# Test Scenario 06: End-to-End Integration

## Objective
Complete workflow: build a stack, run it, edit it, validate it.

## Prerequisites
- Plugin installed (Scenario 01 passed)
- All previous scenarios passed

## Steps

### Step 1: Build a New Stack
```bash
/stack build
```

Build a stack named `integration-test` with:
- 2 bash steps
- 1 loop with 2 iterations

**Expected:** Stack saved to `~/.claude/stacks/integration-test.yaml`

### Step 2: List Stacks
```bash
/stack list
```

**Expected:** Shows `integration-test` in list

### Step 3: Run the Stack
```bash
/stack integration-test
```

**Expected:**
- All steps execute
- Loop runs 2 times
- Completes successfully

### Step 4: Edit the Stack
```bash
/stack edit integration-test
```

Add one more bash step at the end.

**Expected:**
- Shows current stack
- Guides through adding step
- Updates checksum
- Saves file

### Step 5: Run Edited Stack
```bash
/stack integration-test
```

**Expected:** Runs with new step included

### Step 6: Manually Break Stack
```bash
# Add invalid step type manually
echo "  - name: broken
    type: invalid" >> ~/.claude/stacks/integration-test.yaml
```

### Step 7: Validation Catches Error
```bash
/stack integration-test
```

**Expected:**
- Detects manual edit (checksum)
- Runs validation
- Reports error about invalid type
- Offers to fix

### Step 8: Fix via Builder
Choose option to open in builder, remove the broken step.

**Expected:** Stack fixed, checksum updated

### Step 9: Final Run
```bash
/stack integration-test
```

**Expected:** Runs successfully

## Cleanup
```bash
rm ~/.claude/stacks/integration-test.yaml
```

## Results

| Step | Status | Notes |
|------|--------|-------|
| 1. Build stack | | |
| 2. List stacks | | |
| 3. Run stack | | |
| 4. Edit stack | | |
| 5. Run edited | | |
| 6. Break stack | | |
| 7. Catch error | | |
| 8. Fix via builder | | |
| 9. Final run | | |

## Tester
- Name:
- Date:
```

**Step 2: Commit**

```bash
git add tests/scenarios/06-integration.md
git commit -m "test: add end-to-end integration test scenario"
```

---

## Phase 4: Test Summary Document

### Task 4.1: Create Test Summary

**Files:**
- Create: `tests/TEST-SUMMARY.md`

**Step 1: Create test summary**

Create `tests/TEST-SUMMARY.md`:
```markdown
# Skill Stack Test Summary

## Test Coverage

| Component | Test Type | Location |
|-----------|-----------|----------|
| Plugin structure | Automated | `validate-structure.sh` |
| YAML parsing | Fixtures | `fixtures/valid-*.yaml` |
| Validation errors | Fixtures | `fixtures/invalid-*.yaml` |
| Installation | Manual | `scenarios/01-installation.md` |
| Command routing | Manual | `scenarios/02-command-routing.md` |
| Stack build | Manual | `scenarios/03-stack-build.md` |
| Stack run | Manual | `scenarios/04-stack-run.md` |
| Stack validate | Manual | `scenarios/05-stack-validate.md` |
| Integration | Manual | `scenarios/06-integration.md` |

## Running Tests

### 1. Structure Validation (Automated)
```bash
./tests/validate-structure.sh
```

### 2. Manual Scenarios
Run each scenario in `tests/scenarios/` in order:
1. 01-installation.md
2. 02-command-routing.md
3. 03-stack-build.md
4. 04-stack-run.md
5. 05-stack-validate.md
6. 06-integration.md

Document results in each scenario file.

## Test Results Template

| Scenario | Date | Tester | Status | Notes |
|----------|------|--------|--------|-------|
| 01-installation | | | | |
| 02-command-routing | | | | |
| 03-stack-build | | | | |
| 04-stack-run | | | | |
| 05-stack-validate | | | | |
| 06-integration | | | | |

## Pre-Release Checklist

- [ ] Structure validation passes
- [ ] All fixtures parse correctly
- [ ] All 6 scenarios pass
- [ ] README documentation complete
- [ ] VERSION file updated
```

**Step 2: Commit**

```bash
git add tests/TEST-SUMMARY.md
git commit -m "test: add test summary document"
```

---

## Summary

**Total Tasks:** 11

**Files Created:**
- `tests/README.md`
- `tests/validate-structure.sh`
- `tests/fixtures/valid-simple.yaml`
- `tests/fixtures/valid-parallel.yaml`
- `tests/fixtures/valid-loop.yaml`
- `tests/fixtures/valid-branch.yaml`
- `tests/fixtures/valid-full.yaml`
- `tests/fixtures/invalid-missing-name.yaml`
- `tests/fixtures/invalid-missing-steps.yaml`
- `tests/fixtures/invalid-unknown-type.yaml`
- `tests/fixtures/invalid-bad-ref.yaml`
- `tests/fixtures/invalid-circular-branch.yaml`
- `tests/fixtures/invalid-loop-no-exit.yaml`
- `tests/scenarios/01-installation.md`
- `tests/scenarios/02-command-routing.md`
- `tests/scenarios/03-stack-build.md`
- `tests/scenarios/04-stack-run.md`
- `tests/scenarios/05-stack-validate.md`
- `tests/scenarios/06-integration.md`
- `tests/TEST-SUMMARY.md`

**Test Strategy:**
1. Run structure validation first (automated)
2. Use fixtures to test YAML parsing
3. Run manual scenarios in order
4. Document all results
