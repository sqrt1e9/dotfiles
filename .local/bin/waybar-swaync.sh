#!/usr/bin/env bash

# Get notification count from swaync-client.
# If swaync-client isn't ready or fails, treat count as 0.

# Raw output from swaync-client (first line only)
raw="$(swaync-client -c 2>/dev/null | awk 'NR==1 {print $1}')"

# Fallback if empty or non-numeric
if ! printf '%s\n' "$raw" | grep -qE '^[0-9]+$'; then
    raw=0
fi

c="$raw"

alt="default"
text=""

# If new notifications appear
if [ "$c" -gt 0 ] 2>/dev/null; then
    alt="new"
    text=" $c"
fi

# Always output valid JSON
printf '{"text":"%s","alt":"%s","class":["%s"]}\n' "$text" "$alt" "$alt"

exit 0

