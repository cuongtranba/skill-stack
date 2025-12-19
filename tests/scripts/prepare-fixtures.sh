#!/bin/bash

# Main script to prepare all test fixtures
# Run this before executing tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           SKILL-STACK TEST FIXTURE PREPARATION                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Discover resources
echo "Step 1/3: Discovering available resources..."
echo "─────────────────────────────────────────────"
"$SCRIPT_DIR/discover-resources.sh"

# Step 2: Generate fixtures (with mock fallback)
echo ""
echo "Step 2/3: Generating test fixtures..."
echo "─────────────────────────────────────────────"
"$SCRIPT_DIR/generate-fixtures.sh"

# Step 3: Validate generated fixtures
echo ""
echo "Step 3/3: Validating generated fixtures..."
echo "─────────────────────────────────────────────"

GENERATED_DIR="$SCRIPT_DIR/../fixtures/generated"
ERRORS=0

for yaml_file in "$GENERATED_DIR"/*.yaml; do
    if [ -f "$yaml_file" ]; then
        filename=$(basename "$yaml_file")

        # Try Python yaml module first, fallback to basic checks
        if command -v python3 &>/dev/null && python3 -c "import yaml" 2>/dev/null; then
            if python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
                echo "  ✓ $filename"
            else
                echo "  ✗ $filename (invalid YAML)"
                ERRORS=$((ERRORS + 1))
            fi
        else
            # Fallback: basic structure check (name and steps fields exist)
            has_name=$(grep -c "^name:" "$yaml_file" 2>/dev/null || echo "0")
            has_steps=$(grep -c "^steps:" "$yaml_file" 2>/dev/null || echo "0")

            if [ "$has_name" -gt 0 ] && [ "$has_steps" -gt 0 ]; then
                echo "  ✓ $filename (basic check)"
            else
                echo "  ✗ $filename (missing required fields)"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    fi
done

echo ""
echo "════════════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ]; then
    echo "✅ All fixtures prepared successfully!"
    echo ""
    echo "Ready to run tests:"
    echo "  ./tests/run-tests.sh"
else
    echo "⚠️  $ERRORS fixture(s) failed validation"
    exit 1
fi
