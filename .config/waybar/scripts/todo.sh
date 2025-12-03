#!/usr/bin/env bash

TODO_DIR="$HOME/.todo"
TASK_FILE="$TODO_DIR/tasks.json"

mkdir -p "$TODO_DIR"
[ -f "$TASK_FILE" ] || echo "[]" > "$TASK_FILE"

# Counts
total=$(jq 'length' "$TASK_FILE")
done=$(jq '[.[] | select(.completed)] | length' "$TASK_FILE")

# Build task lines
if [ "$total" -eq 0 ]; then
	tasks="(no tasks)"
else
	tasks=$(jq -r '.[] | (if .completed then "[x] " else "[ ] " end) + .task' "$TASK_FILE")
fi

header=$(printf "Tasks: %d total, %d done" "$total" "$done")

# Full tooltip: header + blank line + tasks
tooltip=$(printf "%s\n\n%s\n" "$header" "$tasks" | jq -Rs .)

icon="󰈙"  # paper pad icon

# tooltip is already JSON-escaped by jq -Rs
printf '{"text":"%s","tooltip":%s}\n' "$icon" "$tooltip"

