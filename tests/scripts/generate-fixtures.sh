#!/bin/bash

# Generate test fixtures from discovered resources with mock fallback
# Requires: discovered-resources.json (run discover-resources.sh first)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_DIR="$PROJECT_ROOT/tests/fixtures"
TEMPLATES_DIR="$FIXTURES_DIR/templates"
GENERATED_DIR="$FIXTURES_DIR/generated"
MOCKS_DIR="$FIXTURES_DIR/mocks"
DISCOVERY_FILE="$FIXTURES_DIR/discovered-resources.json"

# Minimum required resources
MIN_SKILLS=5
MIN_COMMANDS=2

echo "🔧 Generating test fixtures..."
echo ""

# Check if discovery was run
if [ ! -f "$DISCOVERY_FILE" ]; then
    echo "⚠️  Discovery file not found. Running discovery first..."
    "$SCRIPT_DIR/discover-resources.sh"
fi

# Parse discovery results
DISCOVERED_SKILLS=$(cat "$DISCOVERY_FILE" | grep -o '"total_skills": [0-9]*' | grep -o '[0-9]*')
DISCOVERED_COMMANDS=$(cat "$DISCOVERY_FILE" | grep -o '"total_commands": [0-9]*' | grep -o '[0-9]*')

echo "📊 Discovered resources:"
echo "   Skills: $DISCOVERED_SKILLS (need $MIN_SKILLS)"
echo "   Commands: $DISCOVERED_COMMANDS (need $MIN_COMMANDS)"
echo ""

# Check if we need mocks
NEED_MOCK_SKILLS=false
NEED_MOCK_COMMANDS=false

if [ "$DISCOVERED_SKILLS" -lt "$MIN_SKILLS" ]; then
    NEED_MOCK_SKILLS=true
    echo "⚠️  Not enough skills discovered. Will use mocks."
fi

if [ "$DISCOVERED_COMMANDS" -lt "$MIN_COMMANDS" ]; then
    NEED_MOCK_COMMANDS=true
    echo "⚠️  Not enough commands discovered. Will use mocks."
fi

# Install mocks if needed
if [ "$NEED_MOCK_SKILLS" = true ] || [ "$NEED_MOCK_COMMANDS" = true ]; then
    echo ""
    echo "📦 Installing mock resources..."
    "$SCRIPT_DIR/install-mocks.sh"

    # Re-run discovery to include mocks
    echo ""
    echo "🔄 Re-running discovery with mocks..."
    "$SCRIPT_DIR/discover-resources.sh"
fi

# Clear generated directory
rm -rf "$GENERATED_DIR"
mkdir -p "$GENERATED_DIR"

echo ""
echo "📝 Generating fixture files..."

# Helper function to get skill ref by index from discovery
get_skill_ref() {
    local index=$1
    # Extract skill name and source, format as "source:name" or just "name"
    local skill=$(cat "$DISCOVERY_FILE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
skills = data.get('skills', [])
if $index < len(skills):
    s = skills[$index]
    source = s.get('source', '')
    name = s.get('name', '')
    if source.startswith('plugin:'):
        print(f\"{source.replace('plugin:', '')}:{name}\")
    else:
        print(name)
else:
    print('mock-skill-alpha')
" 2>/dev/null || echo "mock-skill-alpha")
    echo "$skill"
}

get_command_ref() {
    local index=$1
    local cmd=$(cat "$DISCOVERY_FILE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
commands = data.get('commands', [])
if $index < len(commands):
    print(commands[$index].get('name', 'mock-command-one'))
else:
    print('mock-command-one')
" 2>/dev/null || echo "mock-command-one")
    echo "$cmd"
}

# Get timestamp
GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get skill/command refs
SKILL_1=$(get_skill_ref 0)
SKILL_2=$(get_skill_ref 1)
SKILL_3=$(get_skill_ref 2)
SKILL_DEBUG=$(get_skill_ref 3)
SKILL_VERIFY=$(get_skill_ref 4)
COMMAND_1=$(get_command_ref 0)
COMMAND_2=$(get_command_ref 1)

echo "   Using skills: $SKILL_1, $SKILL_2, $SKILL_3"
echo "   Using commands: $COMMAND_1, $COMMAND_2"
echo ""

# Generate valid-simple.yaml
cat > "$GENERATED_DIR/valid-simple.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: test-simple
description: Simple sequential stack using discovered resources
scope: personal

defaults:
  on_error: ask
  transition: prompt

steps:
  - name: first-skill
    type: skill
    ref: $SKILL_1
    transition: prompt
    description: First step using discovered skill

  - name: bash-step
    type: bash
    run: echo "Test step executed"
    transition: auto

  - name: second-skill
    type: skill
    ref: $SKILL_2
    transition: prompt
    description: Second step using discovered skill
EOF
echo "   ✓ valid-simple.yaml"

# Generate valid-parallel.yaml
cat > "$GENERATED_DIR/valid-parallel.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: test-parallel
description: Stack with parallel execution using discovered resources
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
          type: skill
          ref: $SKILL_1
        - name: branch-b
          type: skill
          ref: $SKILL_2
        - name: branch-c
          type: bash
          run: echo "Branch C executing"

  - name: complete
    type: skill
    ref: $SKILL_VERIFY
    transition: prompt
EOF
echo "   ✓ valid-parallel.yaml"

# Generate valid-loop.yaml
cat > "$GENERATED_DIR/valid-loop.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: test-loop
description: Stack with loop execution using discovered resources
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
          run: echo "Loop iteration"
          transition: auto

  - loop:
      name: until-loop
      until: "{{ success }}"
      max_iterations: 5
      steps:
        - name: try-action
          type: bash
          run: echo "Trying action..."
          outputs:
            - success
        - name: fix-if-needed
          type: skill
          ref: $SKILL_DEBUG
          when: "{{ not success }}"

  - name: done
    type: skill
    ref: $SKILL_VERIFY
    transition: prompt
EOF
echo "   ✓ valid-loop.yaml"

# Generate valid-branch.yaml
cat > "$GENERATED_DIR/valid-branch.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

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
    type: skill
    ref: $SKILL_1
    branch:
      if: "true"
      then: end
      else: end

  - name: failure-path
    type: skill
    ref: $SKILL_DEBUG

  - name: end
    type: skill
    ref: $SKILL_VERIFY
EOF
echo "   ✓ valid-branch.yaml"

# Generate valid-full.yaml (complex combined)
cat > "$GENERATED_DIR/valid-full.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

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
    ref: $SKILL_1
    transition: prompt
    description: Initial step

  - parallel:
      name: parallel-phase
      wait: all
      branches:
        - name: task-a
          type: skill
          ref: $SKILL_2
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
        - name: fix
          type: skill
          ref: $SKILL_DEBUG
          when: "{{ not tests_pass }}"

  - name: review
    type: skill
    ref: $SKILL_3
    branch:
      if: "{{ review_passed }}"
      then: complete
      else: dev-loop

  - name: complete
    type: skill
    ref: $SKILL_VERIFY
EOF
echo "   ✓ valid-full.yaml"

# Generate scenario fixtures for each role
echo ""
echo "📝 Generating role-based scenario fixtures..."

# Fullstack developer scenario
cat > "$GENERATED_DIR/scenario-fullstack.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated
  diagram: |
    flowchart TD
      brainstorm[brainstorm] --> plan[plan]
      subgraph parallel[Parallel: implementation]
        backend[backend]
        frontend[frontend]
      end
      plan --> parallel
      subgraph loop[Loop: quality]
        test[test] -->|fail| fix[fix]
        fix --> test
      end
      parallel --> loop
      loop -->|pass| verify[verify] --> review[review] --> finish[finish]

name: scenario-fullstack
description: Fullstack developer feature workflow
scope: personal

default_for:
  - task: feature
    keywords: ["add", "create", "implement", "build"]

steps:
  - name: brainstorm
    type: skill
    ref: $SKILL_1
    transition: prompt
    description: Explore requirements

  - name: plan
    type: skill
    ref: $SKILL_2
    transition: prompt
    description: Create plan

  - parallel:
      name: implementation
      wait: all
      branches:
        - name: backend
          type: skill
          ref: $SKILL_3
          args: "backend"
        - name: frontend
          type: skill
          ref: $SKILL_3
          args: "frontend"

  - loop:
      name: quality-loop
      until: "{{ all_tests_pass }}"
      max_iterations: 5
      steps:
        - name: run-tests
          type: bash
          run: npm test 2>/dev/null || echo "tests simulated"
          outputs:
            - all_tests_pass
        - name: fix-issues
          type: skill
          ref: $SKILL_DEBUG
          when: "{{ not all_tests_pass }}"

  - name: verify
    type: skill
    ref: $SKILL_VERIFY
    transition: prompt

  - name: review
    type: skill
    ref: $SKILL_1
    transition: prompt

  - name: finish
    type: bash
    run: echo "Feature complete!"
EOF
echo "   ✓ scenario-fullstack.yaml"

# Backend developer scenario
cat > "$GENERATED_DIR/scenario-backend.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: scenario-backend
description: Backend API development workflow
scope: personal

default_for:
  - task: api
    keywords: ["api", "endpoint", "rest", "graphql"]

steps:
  - name: design-api
    type: skill
    ref: $SKILL_1
    transition: prompt
    args: "API contract design"

  - name: implement
    type: skill
    ref: $SKILL_2
    transition: prompt

  - name: generate-docs
    type: bash
    run: echo "Generating API docs..."
    transition: auto

  - parallel:
      name: quality-gates
      wait: all
      branches:
        - name: security
          type: bash
          run: echo "Security scan..."
        - name: performance
          type: bash
          run: echo "Load test..."
        - name: integration
          type: bash
          run: echo "Integration test..."

  - loop:
      name: security-fix
      until: "{{ security_pass }}"
      max_iterations: 3
      steps:
        - name: audit
          type: bash
          run: echo "Security audit..."
          outputs:
            - security_pass
        - name: fix-security
          type: skill
          ref: $SKILL_DEBUG
          when: "{{ not security_pass }}"

  - name: verify
    type: skill
    ref: $SKILL_VERIFY
    transition: prompt

  - name: deploy
    type: bash
    run: echo "Deploying to staging..."
    transition: prompt
EOF
echo "   ✓ scenario-backend.yaml"

# Frontend developer scenario
cat > "$GENERATED_DIR/scenario-frontend.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: scenario-frontend
description: Frontend component development workflow
scope: personal

default_for:
  - task: component
    keywords: ["component", "ui", "button", "form"]

steps:
  - name: design
    type: skill
    ref: $SKILL_1
    transition: prompt
    description: Design component

  - name: implement
    type: skill
    ref: $SKILL_2
    transition: prompt
    args: "React component"

  - parallel:
      name: quality-checks
      wait: all
      branches:
        - name: visual-test
          type: bash
          run: echo "Visual regression test..."
        - name: a11y-check
          type: bash
          run: echo "Accessibility check..."
        - name: unit-test
          type: bash
          run: echo "Unit tests..."

  - name: document
    type: bash
    run: echo "Building Storybook..."
    transition: auto

  - name: verify
    type: skill
    ref: $SKILL_VERIFY
    transition: prompt
EOF
echo "   ✓ scenario-frontend.yaml"

# PM scenario
cat > "$GENERATED_DIR/scenario-pm.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: scenario-pm
description: Project manager feature planning workflow
scope: personal

default_for:
  - task: planning
    keywords: ["plan", "feature", "requirement", "spec"]

steps:
  - name: gather-requirements
    type: skill
    ref: $SKILL_1
    transition: prompt
    args: "Gather feature requirements"

  - name: impact-analysis
    type: skill
    ref: $SKILL_2
    transition: prompt
    args: "Analyze impact and risks"

  - name: create-spec
    type: bash
    run: echo "Creating specification..."
    transition: prompt

  - name: stakeholder-review
    type: skill
    ref: $SKILL_1
    transition: prompt
    args: "Review with stakeholders"

  - loop:
      name: revision-loop
      until: "{{ approved }}"
      max_iterations: 3
      steps:
        - name: check-approval
          type: bash
          run: echo "Checking approval status..."
          outputs:
            - approved
        - name: revise
          type: skill
          ref: $SKILL_2
          when: "{{ not approved }}"
          args: "Address feedback"

  - name: create-tickets
    type: bash
    run: echo "Creating dev tickets..."
    transition: prompt

  - name: handoff
    type: bash
    run: echo "Handoff to development team"
EOF
echo "   ✓ scenario-pm.yaml"

# DevOps scenario
cat > "$GENERATED_DIR/scenario-devops.yaml" << EOF
_meta:
  version: 1.0
  created_by: test-generator
  created_at: $GENERATED_AT
  modified_at: $GENERATED_AT
  checksum: sha256:auto-generated

name: scenario-devops
description: DevOps deployment pipeline workflow
scope: personal

default_for:
  - task: deploy
    keywords: ["deploy", "release", "production"]

steps:
  - name: pre-deploy
    type: skill
    ref: $SKILL_VERIFY
    transition: prompt
    args: "Pre-deployment checks"

  - parallel:
      name: safety-gates
      wait: all
      branches:
        - name: tests
          type: bash
          run: echo "Running all tests..."
        - name: security
          type: bash
          run: echo "Security scan..."
        - name: staging
          type: bash
          run: echo "Staging verification..."

  - name: backup
    type: bash
    run: echo "Creating rollback point..."
    transition: auto

  - name: deploy
    type: bash
    run: echo "Deploying to production..."
    transition: prompt
    on_error: ask

  - loop:
      name: health-check
      until: "{{ healthy }}"
      max_iterations: 10
      steps:
        - name: wait
          type: bash
          run: sleep 2
        - name: check
          type: bash
          run: echo "Health check..."
          outputs:
            - healthy

  - name: verify-metrics
    type: bash
    run: echo "Checking metrics..."
    transition: prompt

  - name: complete
    type: bash
    run: echo "Deployment complete!"
EOF
echo "   ✓ scenario-devops.yaml"

echo ""
echo "✅ Fixture generation complete!"
echo ""
echo "Generated files:"
ls -la "$GENERATED_DIR"
echo ""
echo "Summary:"
echo "  Valid fixtures: 5"
echo "  Scenario fixtures: 5"
echo "  Total: 10"
