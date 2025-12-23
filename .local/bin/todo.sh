#!/usr/bin/env bash
set -euo pipefail

command -v rofi >/dev/null 2>&1 || { echo "Install 'rofi' first."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Install 'python3' first."; exit 1; }

ROFI_THEME="$HOME/.config/rofi/todo.rasi"
PASSWORD_THEME="$HOME/.config/rofi/todo_task.rasi"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TODO_DIR="$XDG_CONFIG_HOME/todo"
CORE_PY="$HOME/.config/hypr/scripts/todo.py"

# --- Datepicker integration ---
DATEPICKER_SH="${DATEPICKER_SH:-$HOME/.local/bin/todo-datepicker.sh}"

rofi_menu() {
	local prompt="$1"; shift
	printf "%s\n" "$@" | rofi -dmenu -i -p "$prompt" -theme "$ROFI_THEME" || true
}

rofi_input() {
	local prompt="$1"
	printf "\n" | rofi -dmenu -i -p "$prompt" -theme "$ROFI_THEME" || true
}

rofi_msg() {
	local title="$1"
	local text="${2:-}"
	[ -z "$text" ] && text="(none)"
	rofi -e "$(printf "%s\n\n%s" "$title" "$text")" -theme "$ROFI_THEME" || true
}

core() {
	python3 "$CORE_PY" "$@"
}

select_from_choices() {
	local lines=()
	local line

	while IFS= read -r line; do
		[ -n "$line" ] && lines+=("$line")
	done

	[ "${#lines[@]}" -eq 0 ] && return 1

	local idx
	idx="$(
		printf "%s\n" "${lines[@]%%$'\t'*}" \
		| rofi -dmenu -i -p "Select" -theme "$ROFI_THEME" -format 'i'
	)" || true

	[ -z "${idx:-}" ] && return 1
	[[ "$idx" =~ ^[0-9]+$ ]] || return 1
	[ "$idx" -ge 0 ] && [ "$idx" -lt "${#lines[@]}" ] || return 1

	local sel="${lines[$idx]}"
	local raw="${sel#*$'\t'}"
	[ "$raw" = "$sel" ] && raw="$sel"
	printf "%s\n" "$raw"
}

pick_date() {
	if [ ! -x "$DATEPICKER_SH" ]; then
		rofi_msg "Error" "Missing datepicker: $DATEPICKER_SH"
		return 1
	fi

	# todo-datepicker.sh prints YYYY-MM-DD on stdout
	local d
	d="$("$DATEPICKER_SH" 2>/dev/null || true)"
	d="$(echo "${d:-}" | xargs || true)"
	[[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo "$d" || return 1
}

day_view() {
	local day="$1"
	local lines
	lines="$(core list-day "$day" 2>/dev/null || true)"
	rofi_msg "Tasks ($day)" "$lines"
}

master_view() {
	local lines
	lines="$(core list-master 2>/dev/null || true)"
	rofi_msg "Master List" "$lines"
}

day_menu() {
	local day="$1"
	core ensure-day "$day" >/dev/null 2>&1 || true

	while true; do
		local c
		c="$(rofi_menu "Tasks ($day)" \
			"  View Tasks" \
			"  Add Task" \
			"󰄬  Set Verdict" \
			"  Remove Task" \
			"󰌍  Back")"

		case "$c" in
			"  View Tasks")
				day_view "$day"
				;;
			"  Add Task")
				local OLD_THEME="$ROFI_THEME"
				ROFI_THEME="$PASSWORD_THEME"

				local raw
				raw="$(rofi_input "New Task for $day (! for MUST)")"
				raw="$(echo "${raw:-}" | xargs || true)"
				ROFI_THEME="$OLD_THEME"

				[ -z "$raw" ] && continue
				core add-day "$day" "$raw" >/dev/null 2>&1 \
					|| rofi_msg "Error" "Could not add task (day may be closed)."
				;;
			"󰄬  Set Verdict")
				local task v
				task="$(core list-day "$day" --choices | select_from_choices)" || continue
				v="$(rofi_menu "Verdict" "DONE" "FAILED" "SKIPPED")"
				[ -z "$v" ] && continue
				core set-verdict "$day" "$task" "$v" >/dev/null 2>&1 \
					|| rofi_msg "Error" "Could not set verdict."
				;;
			"  Remove Task")
				local task
				task="$(core list-day "$day" --choices | select_from_choices)" || continue
				core remove-day "$day" "$task" >/dev/null 2>&1 \
					|| rofi_msg "Error" "Could not remove task."
				;;
			*)
				return
				;;
		esac
	done
}

master_menu() {
	while true; do
		local c
		c="$(rofi_menu "Manage Tasks" \
			"󰄬  Toggle Task" \
			"  Add Task" \
			"  Remove Task" \
			"  View Tasks" \
			"󰌍  Back")"

		case "$c" in
			"󰄬  Toggle Task")
				local t
				t="$(core list-master --choices | select_from_choices)" || continue
				core toggle-master "$t" >/dev/null 2>&1 || rofi_msg "Error" "Toggle failed."
				;;
			"  Add Task")
				local OLD_THEME="$ROFI_THEME"
				ROFI_THEME="$PASSWORD_THEME"

				local raw
				raw="$(rofi_input "New Master Task (! for MUST)")"
				raw="$(echo "${raw:-}" | xargs || true)"
				ROFI_THEME="$OLD_THEME"

				[ -z "$raw" ] && continue
				core add-master "$raw" >/dev/null 2>&1 || rofi_msg "Error" "Add failed."
				;;
			"  Remove Task")
				local t
				t="$(core list-master --choices | select_from_choices)" || continue
				core remove-master "$t" >/dev/null 2>&1 || rofi_msg "Error" "Remove failed."
				;;
			"  View Tasks")
				master_view
				;;
			*)
				return
				;;
		esac
	done
}

# ---------------- Start ----------------
mkdir -p "$TODO_DIR"

[ ! -f "$CORE_PY" ] && { rofi_msg "Error" "Missing core: $CORE_PY"; exit 1; }

core auto-reckon >/dev/null 2>&1 || true

while true; do
	local_today="$(date +%F)"
	choice="$(rofi_menu "Todo Menu ($local_today)" \
		"  Today" \
		"󰈙  Past / Future Day" \
		"󱌣  Manage Tasks" \
		"  View Stats" \
		"  Close Today" \
		"  Exit")"

	case "$choice" in
		"  Today") day_menu "$local_today" ;;
		"󰈙  Past / Future Day") d="$(pick_date)" && day_menu "$d" ;;
		"󱌣  Manage Tasks") master_menu ;;
		"  View Stats")
			rofi_msg "Stats" "$(core stats 2>/dev/null || true)"
			;;
		"  Close Today")
			out="$(core close "$local_today" 2>/dev/null || true)"
			if echo "$out" | grep -q "ALREADY_CLOSED"; then
				rofi_msg "Error" "Already closed."
			elif [ -n "$out" ]; then
				score="$(echo "$out" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("score",""))')"
				rofi_msg "Closed" "Day finalized. Score: $score"
			else
				rofi_msg "Closed" "Day finalized."
			fi
			;;
		*) exit 0 ;;
	esac
done

