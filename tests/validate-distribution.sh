#!/bin/bash

# Skill Stack Distribution Validator
# Checks the invariants that make this repo installable via the `skills` CLI
# (https://github.com/vercel-labs/skills) at a release-please tag.
# Run from project root: ./tests/validate-distribution.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=== Skill Stack Distribution Validation ==="
echo ""

ERRORS=0

pass() { echo "✓ $1"; }
fail() { echo "✗ $1"; ERRORS=$((ERRORS + 1)); }

if ! command -v jq &>/dev/null; then
    echo "✗ jq is required but not installed"
    exit 1
fi
if ! command -v python3 &>/dev/null; then
    echo "✗ python3 is required but not installed"
    exit 1
fi

# Skills that are meaningless without the /stack command and stack agent, which
# the skills CLI does not install. They stay in the Claude Code plugin but are
# hidden from CLI discovery via `metadata.internal`.
INTERNAL_SKILLS="stack-build stack-run stack-validate"

# --- 1. Front matter parses and exposes string name + description ------------
# The skills CLI parses SKILL.md front matter with a real YAML parser and
# silently skips any skill that throws or lacks string name/description.

echo "Checking SKILL.md front matter..."

FM_REPORT="$(python3 "$SCRIPT_DIR/scripts/inspect-frontmatter.py" "$PROJECT_ROOT")"

while IFS= read -r line; do
    [ -z "$line" ] && continue
    dir=$(echo "$line" | jq -r '.dir')
    err=$(echo "$line" | jq -r '.error // ""')
    if [ -n "$err" ]; then
        fail "skills/$dir/SKILL.md — $err"
    else
        pass "skills/$dir/SKILL.md"
    fi
done <<< "$FM_REPORT"

# --- 2. Internal skills are marked so CLI discovery hides them ---------------

echo ""
echo "Checking internal skill markers..."

EXPECTED_INTERNAL=$(printf '%s\n' $INTERNAL_SKILLS | sort)
ACTUAL_INTERNAL=$(echo "$FM_REPORT" | jq -r 'select(.internal == true) | .dir' | sort)

UNMARKED=$(comm -23 <(echo "$EXPECTED_INTERNAL") <(echo "$ACTUAL_INTERNAL"))
UNEXPECTED=$(comm -13 <(echo "$EXPECTED_INTERNAL") <(echo "$ACTUAL_INTERNAL"))

if [ -n "$UNMARKED" ]; then
    fail "missing 'metadata.internal: true' (would be offered by \`npx skills add\`): $(echo $UNMARKED)"
fi
if [ -n "$UNEXPECTED" ]; then
    fail "unexpectedly marked internal (hidden from \`npx skills add\`): $(echo $UNEXPECTED)"
fi
if [ -z "$UNMARKED" ] && [ -z "$UNEXPECTED" ]; then
    pass "internal markers match exactly: $(echo $INTERNAL_SKILLS)"
fi

# --- 3. plugin.json declares exactly the skills that exist on disk -----------

echo ""
echo "Checking plugin.json skill declarations..."

DECLARED=$(jq -r '.skills // [] | .[]' .claude-plugin/plugin.json | sort)
ON_DISK=$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md \
    -exec dirname {} \; | sed 's|^|./|' | sort)

if [ -z "$DECLARED" ]; then
    fail ".claude-plugin/plugin.json has no \"skills\" array (skills CLI cannot group skills under the plugin)"
else
    MISSING=$(comm -13 <(echo "$DECLARED") <(echo "$ON_DISK"))
    EXTRA=$(comm -23 <(echo "$DECLARED") <(echo "$ON_DISK"))
    if [ -n "$MISSING" ]; then
        fail "skill dirs exist but are not declared in plugin.json: $(echo $MISSING)"
    fi
    if [ -n "$EXTRA" ]; then
        fail "plugin.json declares skills that do not exist: $(echo $EXTRA)"
    fi
    if [ -z "$MISSING" ] && [ -z "$EXTRA" ]; then
        pass "plugin.json \"skills\" matches skills/ on disk ($(echo "$ON_DISK" | wc -l | tr -d ' ') skills)"
    fi
fi

# Skill paths must start with './' or the CLI's plugin-manifest reader drops them.
BAD_PATHS=$(jq -r '.skills // [] | .[] | select(startswith("./") | not)' .claude-plugin/plugin.json)
if [ -n "$BAD_PATHS" ]; then
    fail "plugin.json skill paths must start with './': $(echo $BAD_PATHS)"
else
    pass "plugin.json skill paths use the required './' prefix"
fi

# --- 4. Every version field follows the release-please manifest -------------
# release-please owns the version. Any file that states a version and is not
# listed in release-please-config.json will drift.

echo ""
echo "Checking version consistency (release-please is the source of truth)..."

RP_VERSION=$(jq -r '.["."]' .release-please-manifest.json)
FILE_VERSION=$(tr -d '[:space:]' < VERSION)
PLUGIN_VERSION=$(jq -r '.version' .claude-plugin/plugin.json)
MARKET_VERSION=$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)

echo "  release-please manifest: $RP_VERSION"

check_version() {
    if [ "$2" = "$RP_VERSION" ]; then
        pass "$1 = $2"
    else
        fail "$1 = $2 (expected $RP_VERSION from .release-please-manifest.json)"
    fi
}

check_version "VERSION" "$FILE_VERSION"
check_version "plugin.json .version" "$PLUGIN_VERSION"
check_version "marketplace.json .plugins[0].version" "$MARKET_VERSION"

# VERSION only stays in sync if release-please is told to write it. The `simple`
# release-type writes `version-file`, which defaults to version.txt.
CONFIGURED_VERSION_FILE=$(jq -r '.packages["."]["version-file"] // .["version-file"] // ""' release-please-config.json)
if [ "$CONFIGURED_VERSION_FILE" = "VERSION" ]; then
    pass "release-please-config.json sets \"version-file\": \"VERSION\""
else
    fail "release-please-config.json must set \"version-file\": \"VERSION\" or VERSION will never be bumped (found: '${CONFIGURED_VERSION_FILE:-unset}')"
fi

echo ""
echo "=== Distribution Validation Complete ==="

if [ $ERRORS -eq 0 ]; then
    echo "✅ All distribution checks passed!"
    exit 0
else
    echo "❌ Found $ERRORS error(s)"
    exit 1
fi
