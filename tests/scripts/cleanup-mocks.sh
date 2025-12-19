#!/bin/bash

# Remove mock skills and commands from ~/.claude

set -e

echo "🧹 Cleaning up mock resources..."
echo ""

# Remove mock skills
echo "Removing mock skills..."
for skill_dir in "$HOME/.claude/skills"/mock-skill-*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        rm -rf "$skill_dir"
        echo "  ✓ Removed $skill_name"
    fi
done

# Remove mock commands
echo ""
echo "Removing mock commands..."
for cmd_file in "$HOME/.claude/commands"/mock-command-*.md; do
    if [ -f "$cmd_file" ]; then
        cmd_name=$(basename "$cmd_file")
        rm "$cmd_file"
        echo "  ✓ Removed $cmd_name"
    fi
done

echo ""
echo "✅ Mock cleanup complete!"
