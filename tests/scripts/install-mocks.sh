#!/bin/bash

# Install mock skills and commands to ~/.claude for testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MOCKS_DIR="$PROJECT_ROOT/tests/fixtures/mocks"

echo "📦 Installing mock resources for testing..."
echo ""

# Create directories if needed
mkdir -p "$HOME/.claude/skills"
mkdir -p "$HOME/.claude/commands"

# Install mock skills
echo "Installing mock skills..."
for skill_dir in "$MOCKS_DIR/skills"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        target_dir="$HOME/.claude/skills/$skill_name"

        if [ -d "$target_dir" ]; then
            echo "  ⏭️  $skill_name (already exists)"
        else
            cp -r "$skill_dir" "$target_dir"
            echo "  ✓ $skill_name"
        fi
    fi
done

# Install mock commands
echo ""
echo "Installing mock commands..."
for cmd_file in "$MOCKS_DIR/commands"/*.md; do
    if [ -f "$cmd_file" ]; then
        cmd_name=$(basename "$cmd_file")
        target_file="$HOME/.claude/commands/$cmd_name"

        if [ -f "$target_file" ]; then
            echo "  ⏭️  $cmd_name (already exists)"
        else
            cp "$cmd_file" "$target_file"
            echo "  ✓ $cmd_name"
        fi
    fi
done

echo ""
echo "✅ Mock installation complete!"
echo ""
echo "Installed to:"
echo "  Skills: ~/.claude/skills/mock-skill-*"
echo "  Commands: ~/.claude/commands/mock-command-*"
