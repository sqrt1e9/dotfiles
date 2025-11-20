#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
REPO_DIR="$HOME/Devworx/dotfiles"
WORK_TREE="$HOME"
DOT_GIT=(/usr/bin/git --git-dir="$REPO_DIR" --work-tree="$WORK_TREE")

LOG_FILE="$HOME/.cache/dotfiles-sync.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >>"$LOG_FILE" 2>&1

echo "--- dotfiles sync start $(date) ---"

# --- INLINE ROFI PASSWORD PROMPT ---
askpass() {
    local prompt="${1:-Password:}"
    rofi -dmenu -config ~/.config/rofi/password.rasi -password -p "$prompt" 
}

# Tell Git/SSH to use this inline askpass
export GIT_ASKPASS="/bin/sh"
export SSH_ASKPASS="/bin/sh"
export GIT_TERMINAL_PROMPT=0

# Custom askpass backend through environment trick:
export DISPLAY="${DISPLAY:-:0}"

# Whenever Git/SSH call $GIT_ASKPASS, they execute: /bin/sh -c "$SSH_ASKPASS"
# So we embed the rofi prompt in SSH_ASKPASS itself:
export SSH_ASKPASS="askpass"

# --- COMMIT MESSAGE ---
COMMIT_MSG="${1:-"dotfiles: $(date '+%Y-%m-%d %H:%M')"}"

cd "$WORK_TREE"

# Check if anything changed
if ! "${DOT_GIT[@]}" status --short | grep -q .; then
    echo "No changes to commit."
    notify-send "Dotfiles" "No changes to sync."
    echo "--- dotfiles sync end (no changes) $(date) ---"
    exit 0
fi

# Add all changes
echo "Adding changes..."
"${DOT_GIT[@]}" add -A

# Commit
echo "Committing: $COMMIT_MSG"
if ! "${DOT_GIT[@]}" commit -m "$COMMIT_MSG"; then
    echo "Commit failed."
    notify-send "Dotfiles" "Commit failed!"
    exit 1
fi

# Push
echo "Pushing..."
if ! "${DOT_GIT[@]}" push origin master; then
    echo "Push failed."
    notify-send "Dotfiles" "Push failed!"
    exit 1
fi

notify-send "Dotfiles" "Synced to origin master."
echo "--- dotfiles sync end (success) $(date) ---"

