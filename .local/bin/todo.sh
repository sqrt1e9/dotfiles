#!/usr/bin/env bash
set -euo pipefail

command -v rofi >/dev/null 2>&1 || { echo "Install 'rofi' first."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Install 'python3' first."; exit 1; }

ROFI_THEME="$HOME/.config/rofi/todo.rasi"
TASKLIST_THEME="${TASKLIST_THEME:-$HOME/.config/rofi/todo_list.rasi}"
PASSWORD_THEME="$HOME/.config/rofi/todo_task.rasi"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TODO_DIR="$XDG_CONFIG_HOME/todo"
CORE_PY="$HOME/.config/hypr/scripts/todo.py"

DATEPICKER_SH="${DATEPICKER_SH:-$HOME/.local/bin/datepicker.sh}"

rofi_menu() {
	local prompt="$1"; shift
	printf "%s\n" "$@" | rofi -dmenu -i -p "$prompt" -theme "$ROFI_THEME" || true
}

# Allow specifying a theme explicitly (so Add Task can use PASSWORD_THEME reliably)
rofi_input() {
	local prompt="$1"
	local theme="${2:-$ROFI_THEME}"
	printf "\n" | rofi -dmenu -i -p "$prompt" -theme "$theme" || true
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
	[ -x "$DATEPICKER_SH" ] || return 1
	local d
	d="$("$DATEPICKER_SH" 2>/dev/null || true)"
	d="$(echo "${d:-}" | xargs || true)"
	[[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo "$d"
}

add_task_for_day() {
	local day="$1"

	local raw
	raw="$(rofi_input "New Task for $day (! for MUST)" "$PASSWORD_THEME")"
	raw="$(echo "${raw:-}" | xargs || true)"

	[ -z "$raw" ] && return 0
	core add-day "$day" "$raw" >/dev/null 2>&1
}

task_actions_menu() {
	local day="$1"
	local task="$2"

	while true; do
		local c
		c="$(rofi_menu "Task ($day)" \
			"󰄬  Set Verdict" \
			"  Remove Task")"

		case "$c" in
			"󰄬  Set Verdict")
				local v
				v="$(rofi_menu "Verdict" "DONE" "FAILED" "SKIPPED")"
				[ -n "$v" ] && core set-verdict "$day" "$task" "$v" >/dev/null 2>&1
				;;
			"  Remove Task")
				core remove-day "$day" "$task" >/dev/null 2>&1
				return
				;;
			*)
				return
				;;
		esac
	done
}

day_screen() {
	local day="$1"
	core ensure-day "$day" >/dev/null 2>&1 || true

	while true; do
		local labels=()
		local raws=()
		local line label raw

		while IFS= read -r line; do
			[ -z "$line" ] && continue
			label="${line%%$'\t'*}"
			raw="${line#*$'\t'}"
			[ "$raw" = "$line" ] && raw="$line"
			labels+=("$label")
			raws+=("$raw")
		done < <(core list-day "$day" --choices 2>/dev/null || true)

		# 👉 NEW: no tasks → directly add task
		if [ "${#labels[@]}" -eq 0 ]; then
			add_task_for_day "$day"
			return
		fi

		local idx rc
		set +e
		idx="$(
			printf "%s\n" "${labels[@]}" \
			| rofi -dmenu -i -p "Tasks ($day)" -theme "$TASKLIST_THEME" -format 'i' \
				-kb-custom-1 "Alt+n"
		)"
		rc=$?
		set -e

		[ "$rc" -eq 1 ] && return

		if [ "$rc" -eq 10 ]; then
			add_task_for_day "$day"
			continue
		fi

		[[ "${idx:-}" =~ ^[0-9]+$ ]] || continue
		[ "$idx" -ge 0 ] && [ "$idx" -lt "${#raws[@]}" ] || continue

		task_actions_menu "$day" "${raws[$idx]}"
	done
}

# -------- Master screen (same UX as day_screen) --------
add_master_task() {
	local raw
	raw="$(rofi_input "New Master Task (! for MUST)" "$PASSWORD_THEME")"
	raw="$(echo "${raw:-}" | xargs || true)"
	[ -z "$raw" ] && return 0
	core add-master "$raw" >/dev/null 2>&1
}

master_actions_menu() {
	local task="$1"

	while true; do
		local c
		c="$(rofi_menu "Master Task" \
			"󰄬  Toggle Task" \
			"  Remove Task")"

		case "$c" in
			"󰄬  Toggle Task")
				core toggle-master "$task" >/dev/null 2>&1
				;;
			"  Remove Task")
				core remove-master "$task" >/dev/null 2>&1
				return
				;;
			*)
				return
				;;
		esac
	done
}

master_screen() {
	while true; do
		local labels=()
		local raws=()
		local line label raw

		while IFS= read -r line; do
			[ -z "$line" ] && continue
			label="${line%%$'\t'*}"
			raw="${line#*$'\t'}"
			[ "$raw" = "$line" ] && raw="$line"
			labels+=("$label")
			raws+=("$raw")
		done < <(core list-master --choices 2>/dev/null || true)

		# 👉 NEW: no master tasks → add one
		if [ "${#labels[@]}" -eq 0 ]; then
			add_master_task
			return
		fi

		local idx rc
		set +e
		idx="$(
			printf "%s\n" "${labels[@]}" \
			| rofi -dmenu -i -p "Master Tasks" -theme "$TASKLIST_THEME" -format 'i' \
				-kb-custom-1 "Alt+n"
		)"
		rc=$?
		set -e

		[ "$rc" -eq 1 ] && return

		if [ "$rc" -eq 10 ]; then
			add_master_task
			continue
		fi

		[[ "${idx:-}" =~ ^[0-9]+$ ]] || continue
		[ "$idx" -ge 0 ] && [ "$idx" -lt "${#raws[@]}" ] || continue

		master_actions_menu "${raws[$idx]}"
	done
}

mkdir -p "$TODO_DIR"
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
		"  Today")
			day_screen "$local_today"
			;;
		"󰈙  Past / Future Day")
			d="$(pick_date)" && day_screen "$d"
			;;
		"󱌣  Manage Tasks")
			master_screen
			;;
		"  View Stats")
			rofi_msg "Stats" "$(core stats 2>/dev/null || true)"
			;;
		"  Close Today")
			out="$(core close "$local_today" 2>/dev/null || true)"
			echo "$out" | grep -q "ALREADY_CLOSED" && rofi_msg "Error" "Already closed."
			;;
		*)
			exit 0
			;;
	esac
done

