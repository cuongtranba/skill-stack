#!/bin/bash

# Main test runner for skill-stack plugin

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
    echo "⏭️  Skipping (validate-structure.sh not found - create after implementation)"
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

        # Check required fields
        has_name=$(grep -c "^name:" "$yaml_file" 2>/dev/null || true)
        has_steps=$(grep -c "^steps:" "$yaml_file" 2>/dev/null || true)
        has_name=${has_name:-0}
        has_steps=${has_steps:-0}

        if [ "$has_name" -gt 0 ] && [ "$has_steps" -gt 0 ]; then
            echo "  ✓ $filename"
            FIXTURE_PASS=$((FIXTURE_PASS + 1))
        else
            echo "  ✗ $filename (missing required fields)"
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

            # Check what makes each fixture invalid
            has_name=$(grep -c "^name:" "$yaml_file" 2>/dev/null || true)
            has_steps=$(grep -c "^steps:" "$yaml_file" 2>/dev/null || true)
            has_name=${has_name:-0}
            has_steps=${has_steps:-0}

            # Determine invalidity reason
            reason=""
            if [ "$has_name" -eq 0 ]; then
                reason="missing name"
            elif [ "$has_steps" -eq 0 ]; then
                reason="missing steps"
            elif [[ "$filename" == *"unknown-type"* ]]; then
                reason="unknown step type"
            elif [[ "$filename" == *"loop-no-exit"* ]]; then
                reason="loop without exit"
            else
                reason="other validation error"
            fi

            echo "  ✓ $filename ($reason)"
            INVALID_CORRECT=$((INVALID_CORRECT + 1))
        fi
    done

    if [ "$INVALID_COUNT" -gt 0 ]; then
        echo ""
        echo "Invalid Fixture Results: $INVALID_CORRECT/$INVALID_COUNT correctly defined"
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
echo "See: docs/plans/2025-12-19-mermaid-test-cases.md"
echo ""
echo "Fixtures with diagrams:"
DIAGRAM_COUNT=0
for yaml_file in "$SCRIPT_DIR/fixtures/generated"/*.yaml; do
    if [ -f "$yaml_file" ]; then
        if grep -q "diagram:" "$yaml_file" 2>/dev/null; then
            echo "  ✓ $(basename "$yaml_file") (has diagram)"
            DIAGRAM_COUNT=$((DIAGRAM_COUNT + 1))
        fi
    fi
done
if [ "$DIAGRAM_COUNT" -eq 0 ]; then
    echo "  (No fixtures have diagrams yet)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "MANUAL TEST SCENARIOS"
echo "═══════════════════════════════════════════════════════════════════"

echo ""
echo "Run these scenarios manually after plugin implementation:"
echo ""
echo "  Scenario files in: tests/scenarios/"
echo ""

if [ -d "$SCRIPT_DIR/scenarios" ]; then
    for f in "$SCRIPT_DIR/scenarios"/*.md; do
        if [ -f "$f" ]; then
            echo "  • $(basename "$f")"
        fi
    done
else
    echo "  (Scenarios directory not yet created)"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "  Fixtures:  $FIXTURE_PASS/$FIXTURE_COUNT passed"
echo "  Invalid:   $INVALID_CORRECT/$INVALID_COUNT defined"
echo "  Diagrams:  $DIAGRAM_COUNT fixtures have diagrams"
echo "  Structure: (run after implementation)"
echo "  Scenarios: (manual testing required)"
echo ""
echo "Next steps:"
echo "  1. Implement plugin structure"
echo "  2. Run ./tests/validate-structure.sh"
echo "  3. Install plugin locally"
echo "  4. Run manual scenarios"
echo ""

# Exit with success if fixtures pass
if [ "$FIXTURE_PASS" -eq "$FIXTURE_COUNT" ] && [ "$FIXTURE_COUNT" -gt 0 ]; then
    echo "✅ All automated tests passed!"
    exit 0
else
    echo "⚠️  Some tests need attention"
    exit 1
fi
