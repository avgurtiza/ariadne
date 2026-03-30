#!/bin/bash
# Uninstall Ariadne from a project.
#
# Usage:
#   ./uninstall.sh                  # Uninstall from current directory
#   ./uninstall.sh /path/to/project # Uninstall from specific project
#
# Removes skills, config files, and patches.
# Does NOT remove PROJECT-STATE.md (user may want to keep it).

set -euo pipefail

# Determine project directory
if [ $# -ge 1 ]; then
    PROJECT_DIR="$(cd "$1" && pwd)"
else
    PROJECT_DIR="$(pwd)"
fi

echo "Uninstalling Ariadne from: $PROJECT_DIR"
echo ""

# Track what was removed
removed=()

# Helper: remove file if it exists
remove_file() {
    if [ -f "$1" ]; then
        rm "$1"
        removed+=("$1")
    fi
}

# Helper: remove directory if it exists and is empty
remove_dir_if_empty() {
    if [ -d "$1" ] && [ -z "$(ls -A "$1")" ]; then
        rmdir "$1"
        removed+=("$1/")
    fi
}

# Remove skills from all agent directories
for skills_dir in \
    "$PROJECT_DIR/.opencode/skills" \
    "$PROJECT_DIR/.claude/skills" \
    "$PROJECT_DIR/.gemini/skills"
do
    remove_file "$skills_dir/session-bootstrap/SKILL.md"
    remove_file "$skills_dir/session-checkpoint/SKILL.md"
    remove_dir_if_empty "$skills_dir/session-bootstrap"
    remove_dir_if_empty "$skills_dir/session-checkpoint"
done

# Remove command files (OpenCode/KiloCode)
remove_file "$PROJECT_DIR/.opencode/command/session-bootstrap.md"
remove_file "$PROJECT_DIR/.opencode/command/checkpoint.md"

# Remove plugin (OpenCode/KiloCode)
remove_file "$PROJECT_DIR/.opencode/plugins/project-memory.js"

# Remove markers from context files (cross-platform via Python)
remove_markers() {
    local file="$1"
    local start_marker="<!-- ariadne:start -->"
    local end_marker="<!-- ariadne:end -->"

    if [ ! -f "$file" ]; then
        return
    fi

    if ! grep -q "$start_marker" "$file" 2>/dev/null; then
        return
    fi

    python3 - "$file" "$start_marker" "$end_marker" << 'PYEOF'
import sys

filepath = sys.argv[1]
start = sys.argv[2]
end = sys.argv[3]

with open(filepath, "r") as f:
    lines = f.readlines()

result = []
skip = False
for line in lines:
    if start in line:
        skip = True
        continue
    if skip and end in line:
        skip = False
        continue
    if not skip:
        result.append(line)

# Clean up consecutive blank lines at the end
while len(result) > 1 and result[-1].strip() == "" and result[-2].strip() == "":
    result.pop()

with open(filepath, "w") as f:
    f.writelines(result)
PYEOF

    removed+=("Markers removed from $(basename "$file")")
}

remove_markers "$PROJECT_DIR/AGENTS.md"
remove_markers "$PROJECT_DIR/GEMINI.md"

# Summary
echo ""
echo "=========================================="
echo "  Uninstall complete"
echo "=========================================="
echo ""

if [ ${#removed[@]} -gt 0 ]; then
    echo "Removed (${#removed[@]}):"
    for f in "${removed[@]}"; do
        echo "  - $f"
    done
else
    echo "Nothing to remove."
fi

echo ""
echo "Kept PROJECT-STATE.md (delete manually if unwanted)."
echo ""
