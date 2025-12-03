#!/usr/bin/env bash

# Simple TODO app using rofi + jq
# Features: view tasks, add, complete, remove

command -v rofi >/dev/null 2>&1 || { echo "Install 'rofi' first."; exit 1; }
command -v jq   >/dev/null 2>&1 || { echo "Install 'jq' first."; exit 1; }

TODO_DIR="$HOME/.todo"
mkdir -p "$TODO_DIR"

TASK_FILE="$TODO_DIR/tasks.json"
[ -f "$TASK_FILE" ] || echo "[]" > "$TASK_FILE"

# ---------- Helpers ----------

rofi_prompt() {
    local prompt="$1"
    shift
    printf "%s\n" "$@" | rofi -dmenu -i -p "$prompt"
}

rofi_input() {
    local prompt="$1"
    printf "" | rofi -dmenu -i -p "$prompt"
}

# ---------- Task operations ----------

view_tasks() {
    local total completed lines header
    total=$(jq 'length' "$TASK_FILE")
    completed=$(jq '[.[] | select(.completed)] | length' "$TASK_FILE")

    lines=$(jq -r '.[] | if .completed then "[x] " + .task else "[ ] " + .task end' "$TASK_FILE")
    [ -z "$lines" ] && lines=""

    header="$(printf "Tasks: %d total, %d done" "$total" "$completed")"

    rofi -e "$(printf "%s\n\n%s\n" "$header" "$lines")"
}

add_task() {
    local task
    task=$(rofi_input "New task")
    [ -z "$task" ] && return

    task=$(echo "$task" | xargs)
    [ -z "$task" ] && return

    jq --arg task "$task" '. + [{"task": $task, "completed": false}]' \
        "$TASK_FILE" > "$TASK_FILE.tmp" && mv "$TASK_FILE.tmp" "$TASK_FILE"
}

select_task_index() {
    # $1 = filter: "all" | "incomplete"
    local filter="$1"
    local jq_filter

    case "$filter" in
        all)        jq_filter='to_entries[] | "\(.key) \(.value.task) [\(.value.completed)]"' ;;
        incomplete) jq_filter='to_entries[] | select(.value.completed == false) | "\(.key) \(.value.task)"' ;;
    esac

    mapfile -t entries < <(jq -r "$jq_filter" "$TASK_FILE")
    [ "${#entries[@]}" -eq 0 ] && { rofi -e "No matching tasks."; return 1; }

    local display_list=()
    local original_indices=()
    local idx task

    for entry in "${entries[@]}"; do
        idx=${entry%% *}
        task=${entry#* }
        display_list+=("$((${#display_list[@]} + 1)). $task")
        original_indices+=("$idx")
    done

    local selected
    selected=$(printf '%s\n' "${display_list[@]}" | rofi -dmenu -i -p "Select task")
    [ -z "$selected" ] && return 1

    local display_num
    display_num=${selected%%.*}
    local task_index=${original_indices[$((display_num - 1))]}
    echo "$task_index"
    return 0
}

complete_task() {
    local idx
    if ! idx=$(select_task_index "incomplete"); then
        return
    fi

    jq --argjson idx "$idx" '.[$idx].completed = true' \
        "$TASK_FILE" > "$TASK_FILE.tmp" && mv "$TASK_FILE.tmp" "$TASK_FILE"
}

remove_task() {
    local idx
    if ! idx=$(select_task_index "all"); then
        return
    fi

    jq --argjson idx "$idx" 'del(.[$idx])' \
        "$TASK_FILE" > "$TASK_FILE.tmp" && mv "$TASK_FILE.tmp" "$TASK_FILE"
}

# ---------- Main menu ----------

main_menu() {
    while true; do
        local choice
        choice=$(rofi_prompt "Tasks" \
            "  View tasks" \
            "  Add task" \
            "  Complete task" \
            "  Remove task" \
            "  Exit")

        [ -z "$choice" ] && exit 0

        case "$choice" in
            "  View tasks")    view_tasks ;;
            "  Add task")      add_task ;;
            "  Complete task") complete_task ;;
            "  Remove task")   remove_task ;;
            "  Exit")          exit 0 ;;
        esac
    done
}

main_menu

