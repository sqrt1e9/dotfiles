#!/usr/bin/env bash
set -euo pipefail

# ---- CONFIG ----
REPO_DIR="$HOME/Devworx/dotfiles"
WORK_TREE="$HOME"
DOT_GIT=(/usr/bin/git --git-dir="$REPO_DIR" --work-tree="$WORK_TREE")

# Path to your SSH private key (change if needed)
SSH_KEY="$HOME/.ssh/id_ed25519"

# Logging
LOG_FILE="$HOME/.cache/dotfiles-sync.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec >>"$LOG_FILE" 2>&1

echo "--- dotfiles sync start $(date) ---"

# ---- ROFI ASKPASS + SSH AGENT SETUP ----
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found at $SSH_KEY"
    notify-send "Dotfiles" "SSH key not found at $SSH_KEY"
    echo "--- dotfiles sync end (no ssh key) $(date) ---"
    exit 1
fi

# Start a temporary ssh-agent for this script
eval "$(ssh-agent -s)" >/dev/null
AGENT_STARTED=1

# Use rofi for key passphrase
export SSH_ASKPASS="$HOME/.local/bin/askpass.sh"
export GIT_ASKPASS="$HOME/.local/bin/askpass.sh"
export GIT_TERMINAL_PROMPT=0
export DISPLAY="${DISPLAY:-:0}"

# Add key with askpass; setsid + no stdin so SSH_ASKPASS is used
echo "Adding SSH key with ssh-add (via rofi)..."
if ! setsid -w ssh-add "$SSH_KEY" </dev/null; then
    echo "ssh-add failed (wrong passphrase or cancelled)."
    notify-send "Dotfiles" "SSH key add failed (wrong passphrase or cancelled)."
    echo "--- dotfiles sync end (ssh-add failed) $(date) ---"
    ssh-agent -k >/dev/null 2>&1 || true
    exit 1
fi

# ---- GIT COMMIT + PUSH ----
# Commit message: arg1 or default with timestamp
COMMIT_MSG="${1:-"dotfiles: $(date '+%Y-%m-%d %H:%M')"}"

cd "$WORK_TREE"

# Check if there is anything to commit
if ! "${DOT_GIT[@]}" status --short | grep -q .; then
    echo "No changes to commit."
    notify-send "Dotfiles" "No changes to sync."
    echo "--- dotfiles sync end (no changes) $(date) ---"
    ssh-agent -k >/dev/null 2>&1 || true
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
    ssh-agent -k >/dev/null 2>&1 || true
    exit 1
fi

# Push (now uses ssh-agent with the key you just unlocked)
echo "Pushing to origin master..."
if ! "${DOT_GIT[@]}" push origin master; then
    echo "Push failed."
    notify-send "Dotfiles" "Push failed. Check log at $LOG_FILE."
    echo "--- dotfiles sync end (push failed) $(date) ---"
    ssh-agent -k >/dev/null 2>&1 || true
    exit 1
fi

echo "Sync successful."
notify-send "Dotfiles" "Synced to origin master."
echo "--- dotfiles sync end (success) $(date) ---"

# Clean up ssh-agent
ssh-agent -k >/dev/null 2>&1 || true

