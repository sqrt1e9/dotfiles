#!/usr/bin/env bash

# rofi-based askpass helper for Git/SSH

PROMPT="${1:-Password:}"

PASS="$(rofi -dmenu -config ~/.config/rofi/password.rasi -password -p "$PROMPT")" || exit 1

printf '%s\n' "$PASS"

