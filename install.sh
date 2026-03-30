#!/bin/bash
# Install Ariadne into a project.
#
# Usage:
#   ./install.sh                  # Install into current directory
#   ./install.sh /path/to/project # Install into specific project
#
# Supports: OpenCode, KiloCode, Claude Code, Gemini CLI
# Platforms: macOS, Linux, Windows WSL
# Idempotent — safe to re-run. Existing files are not overwritten.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"

# Determine project directory
if [ $# -ge 1 ]; then
    PROJECT_DIR="$(cd "$1" && pwd)"
else
    PROJECT_DIR="$(pwd)"
fi

echo "Installing Ariadne into: $PROJECT_DIR"
echo ""

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

# Detect installed agents
detect_agents() {
    agents=()

    if command -v opencode &>/dev/null; then
        agents+=("opencode")
    fi

    if command -v kilo &>/dev/null || command -v kilocode &>/dev/null; then
        agents+=("kilocode")
    fi

    if command -v claude &>/dev/null; then
        agents+=("claude")
    fi

    if command -v gemini &>/dev/null; then
        agents+=("gemini")
    fi

    if [ ${#agents[@]} -eq 0 ]; then
        echo "Warning: No known AI agents detected (opencode, kilo, claude, gemini)."
        echo "Install files anyway? The skills will work once you install an agent."
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
        agents=("opencode")
    fi
}

# Detect project name from git remote or directory
detect_project_name() {
    local name=""
    if [ -d "$PROJECT_DIR/.git" ]; then
        name=$(cd "$PROJECT_DIR" && basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || true)
    fi
    if [ -z "$name" ]; then
        name=$(basename "$PROJECT_DIR")
    fi
    echo "$name"
}

# Check if Ogham MCP is configured
check_ogham() {
    local mcp_file="$PROJECT_DIR/.mcp.json"
    if [ -f "$mcp_file" ] && grep -q '"ogham"' "$mcp_file" 2>/dev/null; then
        echo "yes"
    else
        echo "no"
    fi
}

# Cross-platform patch function using Python (works on macOS, Linux, WSL)
# Usage: patch_context_file <target_file> <marker_name> <patch_file>
patch_context_file() {
    local target="$1"
    local marker="$2"
    local patch="$3"

    python3 - "$target" "$marker" "$patch" << 'PYEOF'
import sys
import os

target = sys.argv[1]
marker = sys.argv[2]
patch_file = sys.argv[3]

start_marker = f"<!-- {marker}:start -->"
end_marker = f"<!-- {marker}:end -->"

with open(patch_file, "r") as f:
    patch_content = f.read().rstrip("\n")

if os.path.exists(target):
    with open(target, "r") as f:
        content = f.read()

    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)

    if start_idx != -1 and end_idx != -1:
        end_idx += len(end_marker)
        new_content = content[:start_idx] + patch_content + "\n" + content[end_idx:]
        with open(target, "w") as f:
            f.write(new_content)
        print(f"  Updated markers in {os.path.basename(target)}")
    else:
        with open(target, "a") as f:
            f.write("\n" + patch_content + "\n")
        print(f"  Appended to {os.path.basename(target)}")
else:
    os.makedirs(os.path.dirname(target) or ".", exist_ok=True)
    with open(target, "w") as f:
        f.write(patch_content + "\n")
    print(f"  Created {os.path.basename(target)}")
PYEOF
}

# Helper: copy file only if destination doesn't exist
copy_if_missing() {
    local src="$1"
    local dst="$2"
    if [ -f "$dst" ]; then
        skipped+=("$dst")
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        installed+=("$dst")
    fi
}

# Track what we installed
installed=()
skipped=()

OS="$(detect_os)"
echo "Detected OS: $OS"

detect_agents
echo "Detected agents: ${agents[*]}"
echo ""

PROJECT_NAME=$(detect_project_name)
echo "Project name: $PROJECT_NAME"

OGHAM_STATUS=$(check_ogham)
echo "Ogham MCP: $OGHAM_STATUS"
echo ""

# Install for each detected agent
for agent in "${agents[@]}"; do
    echo "Installing for $agent..."

    case "$agent" in
        opencode|kilocode)
            copy_if_missing "$SRC_DIR/skills/session-bootstrap/SKILL.md" "$PROJECT_DIR/.opencode/skills/session-bootstrap/SKILL.md"
            copy_if_missing "$SRC_DIR/skills/session-checkpoint/SKILL.md" "$PROJECT_DIR/.opencode/skills/session-checkpoint/SKILL.md"
            copy_if_missing "$SRC_DIR/commands/session-bootstrap.md" "$PROJECT_DIR/.opencode/command/session-bootstrap.md"
            copy_if_missing "$SRC_DIR/commands/checkpoint.md" "$PROJECT_DIR/.opencode/command/checkpoint.md"
            copy_if_missing "$SRC_DIR/plugins/project-memory.js" "$PROJECT_DIR/.opencode/plugins/project-memory.js"
            patch_context_file "$PROJECT_DIR/AGENTS.md" "ariadne" "$SRC_DIR/patches/agents-section.md"
            ;;
        claude)
            copy_if_missing "$SRC_DIR/claude/skills/session-bootstrap/SKILL.md" "$PROJECT_DIR/.claude/skills/session-bootstrap/SKILL.md"
            copy_if_missing "$SRC_DIR/claude/skills/session-checkpoint/SKILL.md" "$PROJECT_DIR/.claude/skills/session-checkpoint/SKILL.md"
            patch_context_file "$PROJECT_DIR/AGENTS.md" "ariadne" "$SRC_DIR/patches/agents-section.md"
            ;;
        gemini)
            copy_if_missing "$SRC_DIR/gemini/skills/session-bootstrap/SKILL.md" "$PROJECT_DIR/.gemini/skills/session-bootstrap/SKILL.md"
            copy_if_missing "$SRC_DIR/gemini/skills/session-checkpoint/SKILL.md" "$PROJECT_DIR/.gemini/skills/session-checkpoint/SKILL.md"
            patch_context_file "$PROJECT_DIR/GEMINI.md" "ariadne" "$SRC_DIR/gemini/patches/gemini-section.md"
            ;;
    esac
done

# Create PROJECT-STATE.md if missing
echo ""
if [ -f "$PROJECT_DIR/PROJECT-STATE.md" ]; then
    skipped+=("PROJECT-STATE.md (already exists)")
else
    TODAY=$(date +%Y-%m-%d)
    sed -e "s/{project-name}/$PROJECT_NAME/g" \
        -e "s/{date}/$TODAY/g" \
        -e "s/{your stack here}/[fill in]/g" \
        -e "s/{development stage}/[fill in]/g" \
        "$SRC_DIR/../templates/PROJECT-STATE.md" > "$PROJECT_DIR/PROJECT-STATE.md"
    installed+=("PROJECT-STATE.md")
fi

# Summary
echo ""
echo "=========================================="
echo "  Installation complete"
echo "=========================================="
echo ""

if [ ${#installed[@]} -gt 0 ]; then
    echo "Installed (${#installed[@]}):"
    for f in "${installed[@]}"; do
        echo "  + $f"
    done
    echo ""
fi

if [ ${#skipped[@]} -gt 0 ]; then
    echo "Skipped (already exist, ${#skipped[@]}):"
    for f in "${skipped[@]}"; do
        echo "  ~ $f"
    done
    echo ""
fi

echo "Agents configured: ${agents[*]}"
echo "Ogham MCP: $OGHAM_STATUS"
echo ""
echo "=========================================="
echo "  Initialize PROJECT-STATE.md"
echo "=========================================="
echo ""
echo "Paste this prompt into your AI agent to fill in PROJECT-STATE.md:"
echo ""
echo '  "Read PROJECT-STATE.md and fill it in based on the codebase.'
echo '   Detect the stack from package.json, composer.json, Cargo.toml,'
echo '   go.mod, or similar. Identify the current development stage.'
echo '   List the top 3-5 active tasks from open issues, recent commits,'
echo '   or TODO comments. Add any known gotchas you find in the code.'
echo '   Keep each section concise — 1-liners for decisions,'
echo '   short descriptions for gotchas."'
echo ""
echo "Then restart your AI agent to pick up the new skills."
echo ""
echo "After that:"
echo "  - Run 'session-bootstrap' at the start of each session"
echo "  - Run '/checkpoint' after completing significant work"
echo ""

if [ "$OGHAM_STATUS" = "no" ]; then
    echo "Tip: Install Ogham MCP for richer memory (semantic search, decision history)."
    echo "  See: https://github.com/nickthecook/ogham"
    echo ""
fi
  echo ""
fi
