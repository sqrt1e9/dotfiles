#!/usr/bin/env bash
set -euo pipefail

# Bare repo config
REPO_DIR="$HOME/Devworx/dotfiles"
WORK_TREE="$HOME"
DOT_GIT=(/usr/bin/git --git-dir="$REPO_DIR" --work-tree="$WORK_TREE")

# Logging
LOG_FILE="$HOME/.cache/dotfiles-sync.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >>"$LOG_FILE" 2>&1

echo "--- dotfiles sync start $(date) ---"

# Use rofi for passwords (Git/SSH)
export GIT_ASKPASS="$HOME/bin/rofi-askpass.sh"
export SSH_ASKPASS="$HOME/bin/rofi-askpass.sh"
export GIT_TERMINAL_PROMPT=0
export DISPLAY="${DISPLAY:-:0}"

# Commit message: arg1 or default with timestamp
COMMIT_MSG="${1:-"dotfiles: $(date '+%Y-%m-%d %H:%M')"}"

cd "$WORK_TREE"

# Check if there is anything to commit
if ! "${DOT_GIT[@]}" status --short | grep -q .; then
    echo "No changes to commit."
    notify-send "Dotfiles" "No changes to sync."
    echo "--- dotfiles sync end (no changes) $(date) ---"
    exit 0
fi

# Stage everything
echo "Adding all changes..."
"${DOT_GIT[@]}" add -A

# Commit
echo "Committing with message: $COMMIT_MSG"
if ! "${DOT_GIT[@]}" commit -m "$COMMIT_MSG"; then
    echo "Commit failed."
    notify-send "Dotfiles" "Commit failed. Check log at $LOG_FILE."
    echo "--- dotfiles sync end (commit failed) $(date) ---"
    exit 1
fi

# Push
echo "Pushing to origin master..."
if ! "${DOT_GIT[@]}" push origin master; then
    echo "Push failed."
    notify-send "Dotfiles" "Push failed. Check log at $LOG_FILE."
    echo "--- dotfiles sync end (push failed) $(date) ---"
    exit 1
fi

echo "Sync successful."
notify-send "Dotfiles" "Synced to origin master."
echo "--- dotfiles sync end (success) $(date) ---"

