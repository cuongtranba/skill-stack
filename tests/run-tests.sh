#!/bin/bash

# Main test runner for skill-stack plugin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              SKILL-STACK PLUGIN TEST SUITE                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if fixtures are prepared
if [ ! -d "$SCRIPT_DIR/fixtures/generated" ] || [ -z "$(ls -A "$SCRIPT_DIR/fixtures/generated" 2>/dev/null)" ]; then
    echo "⚠️  Fixtures not prepared. Running preparation..."
    "$SCRIPT_DIR/scripts/prepare-fixtures.sh"
    echo ""
fi

# Run structure validation
echo "═══════════════════════════════════════════════════════════════════"
echo "TEST 1: Plugin Structure Validation"
echo "═══════════════════════════════════════════════════════════════════"

if [ -f "$SCRIPT_DIR/validate-structure.sh" ]; then
    "$SCRIPT_DIR/validate-structure.sh" || echo "⚠️  Structure validation failed (plugin not yet implemented)"
else
    echo "⏭️  Skipping (validate-structure.sh not found)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "TEST 2: Fixture Validation"
echo "═══════════════════════════════════════════════════════════════════"

echo "Checking generated fixtures..."
FIXTURE_COUNT=0
FIXTURE_PASS=0

for yaml_file in "$SCRIPT_DIR/fixtures/generated"/*.yaml; do
    if [ -f "$yaml_file" ]; then
        FIXTURE_COUNT=$((FIXTURE_COUNT + 1))
        filename=$(basename "$yaml_file")

        # Validate YAML syntax
        if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
            # Check required fields
            has_name=$(grep -c "^name:" "$yaml_file" || echo "0")
            has_steps=$(grep -c "^steps:" "$yaml_file" || echo "0")

            if [ "$has_name" -gt 0 ] && [ "$has_steps" -gt 0 ]; then
                echo "  ✓ $filename"
                FIXTURE_PASS=$((FIXTURE_PASS + 1))
            else
                echo "  ✗ $filename (missing required fields)"
            fi
        else
            echo "  ✗ $filename (invalid YAML)"
        fi
    fi
done

echo ""
echo "Fixture Results: $FIXTURE_PASS/$FIXTURE_COUNT passed"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "TEST 3: Static Invalid Fixtures"
echo "═══════════════════════════════════════════════════════════════════"

if [ -d "$SCRIPT_DIR/fixtures/static" ]; then
    echo "Checking invalid fixtures are correctly invalid..."
    INVALID_COUNT=0
    INVALID_CORRECT=0

    for yaml_file in "$SCRIPT_DIR/fixtures/static"/invalid-*.yaml; do
        if [ -f "$yaml_file" ]; then
            INVALID_COUNT=$((INVALID_COUNT + 1))
            filename=$(basename "$yaml_file")

            # These should fail validation
            has_name=$(grep -c "^name:" "$yaml_file" 2>/dev/null || echo "0")
            has_steps=$(grep -c "^steps:" "$yaml_file" 2>/dev/null || echo "0")

            if [ "$has_name" -eq 0 ] || [ "$has_steps" -eq 0 ]; then
                echo "  ✓ $filename (correctly invalid)"
                INVALID_CORRECT=$((INVALID_CORRECT + 1))
            else
                echo "  ⚠️ $filename (expected to be invalid)"
            fi
        fi
    done

    if [ "$INVALID_COUNT" -gt 0 ]; then
        echo ""
        echo "Invalid Fixture Results: $INVALID_CORRECT/$INVALID_COUNT correctly invalid"
    else
        echo "  No static invalid fixtures found"
    fi
else
    echo "  No static fixtures directory"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "TEST 4: Mermaid Diagram Generation (Manual)"
echo "═══════════════════════════════════════════════════════════════════"

echo "Mermaid tests require manual verification."
echo "See: tests/scenarios/ for test scenarios"
echo ""
echo "Fixtures with diagrams:"
for yaml_file in "$SCRIPT_DIR/fixtures/generated"/*.yaml; do
    if [ -f "$yaml_file" ]; then
        if grep -q "diagram:" "$yaml_file" 2>/dev/null; then
            echo "  ✓ $(basename "$yaml_file") (has diagram)"
        fi
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "MANUAL TEST SCENARIOS"
echo "═══════════════════════════════════════════════════════════════════"

echo ""
echo "Run these scenarios manually after plugin implementation:"
echo ""
echo "  Scenario files in: tests/scenarios/"
echo ""
ls -1 "$SCRIPT_DIR/scenarios"/*.md 2>/dev/null | while read f; do
    echo "  • $(basename "$f")"
done || echo "  No scenario files found"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "  Fixtures:  $FIXTURE_PASS/$FIXTURE_COUNT passed"
echo "  Structure: (run after implementation)"
echo "  Scenarios: (manual testing required)"
echo ""
echo "Next steps:"
echo "  1. Implement plugin structure"
echo "  2. Run ./tests/validate-structure.sh"
echo "  3. Install plugin locally"
echo "  4. Run manual scenarios in tests/scenarios/"
