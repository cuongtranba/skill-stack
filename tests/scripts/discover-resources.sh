#!/bin/bash

# Discover all available skills and commands in the environment
# Output: tests/fixtures/discovered-resources.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$PROJECT_ROOT/tests/fixtures/discovered-resources.json"

echo "🔍 Discovering available skills and commands..."
echo ""

# Initialize arrays
SKILLS=()
COMMANDS=()
PLUGINS=()

# Function to extract skill info from SKILL.md
extract_skill_info() {
    local skill_path="$1"
    local skill_dir="$(dirname "$skill_path")"
    local skill_name="$(basename "$skill_dir")"
    local source="$2"

    # Extract description from frontmatter
    local description=""
    if [ -f "$skill_path" ]; then
        description=$(grep -A1 "^description:" "$skill_path" 2>/dev/null | tail -1 | sed 's/^[- ]*//' | head -c 100)
    fi

    echo "{\"name\": \"$skill_name\", \"source\": \"$source\", \"path\": \"$skill_path\", \"description\": \"$description\"}"
}

# Function to extract command info from .md file
extract_command_info() {
    local cmd_path="$1"
    local cmd_name="$(basename "$cmd_path" .md)"
    local source="$2"

    # Extract description from frontmatter
    local description=""
    if [ -f "$cmd_path" ]; then
        description=$(grep -A1 "^description:" "$cmd_path" 2>/dev/null | tail -1 | sed 's/^[- ]*//' | head -c 100)
    fi

    echo "{\"name\": \"$cmd_name\", \"source\": \"$source\", \"path\": \"$cmd_path\", \"description\": \"$description\"}"
}

echo "📁 Scanning skill locations..."

# 1. Personal skills (~/.claude/skills/)
if [ -d "$HOME/.claude/skills" ]; then
    echo "  → ~/.claude/skills/"
    for skill_dir in "$HOME/.claude/skills"/*/; do
        if [ -f "${skill_dir}SKILL.md" ]; then
            info=$(extract_skill_info "${skill_dir}SKILL.md" "personal")
            SKILLS+=("$info")
            echo "    ✓ $(basename "$skill_dir")"
        fi
    done
fi

# 2. Project skills (.claude/skills/)
if [ -d ".claude/skills" ]; then
    echo "  → .claude/skills/"
    for skill_dir in .claude/skills/*/; do
        if [ -f "${skill_dir}SKILL.md" ]; then
            info=$(extract_skill_info "${skill_dir}SKILL.md" "project")
            SKILLS+=("$info")
            echo "    ✓ $(basename "$skill_dir")"
        fi
    done
fi

# 3. Plugin skills (~/.claude/plugins/cache/*/skills/)
if [ -d "$HOME/.claude/plugins/cache" ]; then
    echo "  → Plugin cache..."
    for plugin_dir in "$HOME/.claude/plugins/cache"/*/*/; do
        plugin_name="$(basename "$(dirname "$plugin_dir")")"

        # Get latest version only
        if [ -d "${plugin_dir}skills" ]; then
            PLUGINS+=("$plugin_name")
            for skill_dir in "${plugin_dir}skills"/*/; do
                if [ -f "${skill_dir}SKILL.md" ]; then
                    skill_name="$(basename "$skill_dir")"
                    info=$(extract_skill_info "${skill_dir}SKILL.md" "plugin:$plugin_name")
                    SKILLS+=("$info")
                    echo "    ✓ $plugin_name:$skill_name"
                fi
            done
        fi
    done
fi

echo ""
echo "📁 Scanning command locations..."

# 4. Personal commands (~/.claude/commands/)
if [ -d "$HOME/.claude/commands" ]; then
    echo "  → ~/.claude/commands/"
    for cmd_file in "$HOME/.claude/commands"/*.md; do
        if [ -f "$cmd_file" ]; then
            info=$(extract_command_info "$cmd_file" "personal")
            COMMANDS+=("$info")
            echo "    ✓ $(basename "$cmd_file" .md)"
        fi
    done
fi

# 5. Project commands (.claude/commands/)
if [ -d ".claude/commands" ]; then
    echo "  → .claude/commands/"
    for cmd_file in .claude/commands/*.md; do
        if [ -f "$cmd_file" ]; then
            info=$(extract_command_info "$cmd_file" "project")
            COMMANDS+=("$info")
            echo "    ✓ $(basename "$cmd_file" .md)"
        fi
    done
fi

# 6. Plugin commands
if [ -d "$HOME/.claude/plugins/cache" ]; then
    echo "  → Plugin commands..."
    for plugin_dir in "$HOME/.claude/plugins/cache"/*/*/; do
        plugin_name="$(basename "$(dirname "$plugin_dir")")"

        if [ -d "${plugin_dir}commands" ]; then
            for cmd_file in "${plugin_dir}commands"/*.md; do
                if [ -f "$cmd_file" ]; then
                    info=$(extract_command_info "$cmd_file" "plugin:$plugin_name")
                    COMMANDS+=("$info")
                    echo "    ✓ $plugin_name:$(basename "$cmd_file" .md)"
                fi
            done
        fi
    done
fi

echo ""
echo "📝 Generating discovered-resources.json..."

# Build JSON output
{
    echo "{"
    echo "  \"generated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
    echo "  \"environment\": {"
    echo "    \"home\": \"$HOME\","
    echo "    \"project\": \"$(pwd)\""
    echo "  },"

    # Skills array
    echo "  \"skills\": ["
    first=true
    for skill in "${SKILLS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo -n "    $skill"
    done
    echo ""
    echo "  ],"

    # Commands array
    echo "  \"commands\": ["
    first=true
    for cmd in "${COMMANDS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo -n "    $cmd"
    done
    echo ""
    echo "  ],"

    # Plugins array
    echo "  \"plugins\": ["
    first=true
    for plugin in "${PLUGINS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo -n "    \"$plugin\""
    done
    echo ""
    echo "  ],"

    # Summary
    echo "  \"summary\": {"
    echo "    \"total_skills\": ${#SKILLS[@]},"
    echo "    \"total_commands\": ${#COMMANDS[@]},"
    echo "    \"total_plugins\": ${#PLUGINS[@]}"
    echo "  }"
    echo "}"
} > "$OUTPUT_FILE"

echo ""
echo "✅ Discovery complete!"
echo ""
echo "Summary:"
echo "  Skills:   ${#SKILLS[@]}"
echo "  Commands: ${#COMMANDS[@]}"
echo "  Plugins:  ${#PLUGINS[@]}"
echo ""
echo "Output: $OUTPUT_FILE"
