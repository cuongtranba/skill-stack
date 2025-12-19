#!/bin/bash

# Skill Stack Plugin Structure Validator
# Run from project root: ./tests/validate-structure.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

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
