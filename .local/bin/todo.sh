#!/usr/bin/env bash
set -euo pipefail

MENU_THEME="$HOME/.config/rofi/todo.rasi"
LIST_THEME="$HOME/.config/rofi/todo_list.rasi"
INPUT_THEME="$HOME/.config/rofi/todo_task.rasi"
MEETING_INPUT_THEME="$HOME/.config/rofi/meeting_task.rasi"

CORE_PY="$HOME/.config/hypr/scripts/todo.py"
DATEPICKER_SH="${DATEPICKER_SH:-$HOME/.local/bin/datepicker.sh}"

core() {
	python3 "$CORE_PY" "$@"
}

rofi_menu() {
	local mesg=""
	if [ "${1:-}" = "--mesg" ]; then
		mesg="${2:-}"
		shift 2
	fi

	if [ -n "$mesg" ]; then
		printf "%s\n" "$@" | rofi -no-config -dmenu -i -theme "$MENU_THEME" -mesg "$mesg"
	else
		printf "%s\n" "$@" | rofi -no-config -dmenu -i -theme "$MENU_THEME"
	fi
}

# IMPORTANT: keep this form. Rofi -dmenu needs at least 1 line on stdin
# so you can type freely. Redirecting stdin breaks input.
rofi_input() {
	printf "\n" | rofi -no-config -dmenu -i -p "$1" -theme "$INPUT_THEME"
}

pick_date() {
	[ -x "$DATEPICKER_SH" ] || return 1
	"$DATEPICKER_SH" 2>/dev/null || true
}

nth_line() {
	local n="$1"
	sed -n "${n}p"
}

# ---------------- MASTER TASKS (Manage Tasks) ----------------

build_master_active_csv() {
	local i=0 line
	local active=()

	while IFS= read -r line; do
		case "$line" in
			*"●"*) active+=("$i") ;;
			*) : ;;
		esac
		i=$((i+1))
	done

	(IFS=,; echo "${active[*]}")
}

rofi_pick_index_master() {
	local active_csv="${1:-}"

	rofi -no-config -dmenu -i -theme "$LIST_THEME" -format i \
		-kb-custom-1 "Alt+n" \
		-kb-custom-2 "Alt+t" \
		-kb-custom-3 "Alt+r"
}

master_screen() {
	while true; do
		local choices display_list raw_list sel_idx rc raw_task action t
		local active_csv

		choices="$(core list-master --choices 2>/dev/null || true)"

		if [ -z "$(echo "${choices:-}" | xargs || true)" ]; then
			t="$(rofi_input "New Master Task")" || true
			t="$(echo "${t:-}" | xargs || true)"
			[ -z "$t" ] && return 0
			core add-master "$t" >/dev/null 2>&1 || true
			continue
		fi

		display_list="$(printf "%s\n" "$choices" | cut -f1)"
		raw_list="$(printf "%s\n" "$choices" | cut -f2- )"

		active_csv="$(printf "%s\n" "$display_list" | build_master_active_csv)"

		set +e
		sel_idx="$(printf "%s\n" "$display_list" | rofi_pick_index_master "$active_csv")"
		rc=$?
		set -e

		[ "$rc" -eq 1 ] && return 0

		if [ "$rc" -eq 10 ]; then
			t="$(rofi_input "New Master Task")" || true
			t="$(echo "${t:-}" | xargs || true)"
			[ -n "$t" ] && core add-master "$t" >/dev/null 2>&1 || true
			continue
		fi

		sel_idx="$(echo "${sel_idx:-}" | xargs || true)"
		[ -z "$sel_idx" ] && return 0

		raw_task="$(
			printf "%s\n" "$raw_list" | nth_line "$((sel_idx + 1))"
		)"
		raw_task="$(echo "${raw_task:-}" | xargs || true)"
		[ -z "$raw_task" ] && return 0

		if [ "$rc" -eq 11 ]; then
			core toggle-master "$raw_task" >/dev/null 2>&1 || true
			continue
		fi

		if [ "$rc" -eq 12 ]; then
			core remove-master "$raw_task" >/dev/null 2>&1 || true
			continue
		fi

		action="$(rofi_menu \
			"Toggle Task" \
			"Remove Task"
		)" || true

		case "$action" in
			"Toggle Task") core toggle-master "$raw_task" >/dev/null 2>&1 || true ;;
			"Remove Task") core remove-master "$raw_task" >/dev/null 2>&1 || true ;;
		esac
	done
}

# ---------------- DAY TASKS (Today / any date) ----------------

build_day_state_csvs() {
	local i=0 line
	local active=() urgent=()

	while IFS= read -r line; do
		case "$line" in
			*"✔"*) : ;;               # DONE
			*"✘"*) urgent+=("$i") ;;  # SKIPPED
			*)      active+=("$i") ;; # TODO
		esac
		i=$((i+1))
	done

	(IFS=,; echo "${active[*]}")
	(IFS=,; echo "${urgent[*]}")
}

rofi_pick_index_day() {
	local active_csv="${1:-}"
	local urgent_csv="${2:-}"

	rofi -no-config -dmenu -i -theme "$LIST_THEME" -format i \
		-kb-custom-1 "Alt+n" \
		-kb-custom-2 "Alt+d" \
		-kb-custom-3 "Alt+s" \
		-kb-custom-4 "Alt+r"
}

day_screen() {
	local day="$1"

	core sync-day "$day" >/dev/null 2>&1 || true

	while true; do
		local choices display_list raw_list sel_idx rc raw_task action verdict t
		local active_csv urgent_csv
		local -a csvs

		choices="$(core list-day "$day" --choices 2>/dev/null || true)"

		if [ -z "$(echo "${choices:-}" | xargs || true)" ]; then
			t="$(rofi_input "New Task for $day (! for MUST)")" || true
			t="$(echo "${t:-}" | xargs || true)"
			[ -z "$t" ] && return 0
			core add-day "$day" "$t" >/dev/null 2>&1 || true
			core sync-day "$day" >/dev/null 2>&1 || true
			continue
		fi

		display_list="$(printf "%s\n" "$choices" | cut -f1)"
		raw_list="$(printf "%s\n" "$choices" | cut -f2- )"

		mapfile -t csvs < <(printf "%s\n" "$display_list" | build_day_state_csvs)
		active_csv="${csvs[0]:-}"
		urgent_csv="${csvs[1]:-}"

		set +e
		sel_idx="$(printf "%s\n" "$display_list" | rofi_pick_index_day "$active_csv" "$urgent_csv")"
		rc=$?
		set -e

		[ "$rc" -eq 1 ] && return 0

		if [ "$rc" -eq 10 ]; then
			t="$(rofi_input "New Task for $day (! for MUST)")" || true
			t="$(echo "${t:-}" | xargs || true)"
			[ -n "$t" ] && core add-day "$day" "$t" >/dev/null 2>&1 || true
			core sync-day "$day" >/dev/null 2>&1 || true
			continue
		fi

		sel_idx="$(echo "${sel_idx:-}" | xargs || true)"
		[ -z "$sel_idx" ] && return 0

		raw_task="$(
			printf "%s\n" "$raw_list" | nth_line "$((sel_idx + 1))"
		)"
		raw_task="$(echo "${raw_task:-}" | xargs || true)"
		[ -z "$raw_task" ] && return 0

		if [ "$rc" -eq 11 ]; then
			core set-verdict "$day" "$raw_task" "DONE" >/dev/null 2>&1 || true
			continue
		fi

		if [ "$rc" -eq 12 ]; then
			core set-verdict "$day" "$raw_task" "SKIPPED" >/dev/null 2>&1 || true
			continue
		fi

		if [ "$rc" -eq 13 ]; then
			core remove-day "$day" "$raw_task" >/dev/null 2>&1 || true
			continue
		fi

		action="$(rofi_menu \
			"Set Verdict" \
			"Remove Task"
		)" || true

		case "$action" in
			"Set Verdict")
				verdict="$(rofi_menu \
					"DONE" \
					"FAILED / SKIPPED"
				)" || true
				case "$verdict" in
					"DONE") core set-verdict "$day" "$raw_task" "DONE" >/dev/null 2>&1 || true ;;
					"FAILED / SKIPPED") core set-verdict "$day" "$raw_task" "SKIPPED" >/dev/null 2>&1 || true ;;
				esac
				;;
			"Remove Task")
				core remove-day "$day" "$raw_task" >/dev/null 2>&1 || true
				;;
		esac
	done
}

# ---------------- MEETINGS (per-day files) ----------------

MEET_PAST_ICON="󰥔"
MEET_UPCOMING_ICON="󰥗"
MEET_PAST_COLOR="#999999"

meetings_choices_with_icons_markup() {
	local day="$1"
	local now_hm
	now_hm="$(date +%H:%M)"

	core list-meetings "$day" --choices 2>/dev/null | awk -v now="$now_hm" -v pastc="$MEET_PAST_COLOR" -F'\t' '
	BEGIN { OFS="\t" }
	NF>=2 {
		label=$1; raw=$2;
		tm=substr(label,1,5);
		icon = (tm < now) ? "'"$MEET_PAST_ICON"'" : "'"$MEET_UPCOMING_ICON"'";
		if (tm < now) {
			print "<span color=\"" pastc "\">" icon "  " label "</span>", raw
		} else {
			print icon "  " label, raw
		}
	}'
}

rofi_pick_index_meetings() {
	rofi -no-config -dmenu -i -theme "$LIST_THEME" -format i -markup-rows \
		-kb-custom-1 "Alt+m" \
		-kb-custom-2 "Alt+r"
}

rofi_input_meeting() {
	printf "\n" | rofi -no-config -dmenu -i -p "$1" -theme "$MEETING_INPUT_THEME"
}

meetings_add_flow() {
	local day="$1"
	local raw time title code

	raw="$(rofi_input_meeting "HH:MM | Title | Link (optional)")" || return 1
	raw="$(echo "${raw:-}" | xargs || true)"
	[ -z "$raw" ] && return 1

	IFS='|' read -r time title code <<< "$raw"
	time="$(echo "${time:-}" | xargs || true)"
	title="$(echo "${title:-}" | xargs || true)"
	code="$(echo "${code:-}" | xargs || true)"

	if [[ "$time" =~ ^[0-9]{1}:[0-9]{2}$ ]]; then
		time="0$time"
	fi
	[[ "$time" =~ ^[0-9]{2}:[0-9]{2}$ ]] || return 1
	[ -n "$title" ] || return 1

	core add-meeting "$day" "$time" "$title" "${code:-}" >/dev/null 2>&1 || return 1
	return 0
}

meetings_screen() {
	local day="$1"

	while true; do
		local choices display_list raw_list sel_idx rc raw_idx action

		choices="$(meetings_choices_with_icons_markup "$day" || true)"

		if [ -z "$(echo "${choices:-}" | xargs || true)" ]; then
			meetings_add_flow "$day" || return 0
			continue
		fi

		display_list="$(printf "%s\n" "$choices" | cut -f1)"
		raw_list="$(printf "%s\n" "$choices" | cut -f2-)"

		set +e
		sel_idx="$(printf "%s\n" "$display_list" | rofi_pick_index_meetings)"
		rc=$?
		set -e

		[ "$rc" -eq 1 ] && return 0

		if [ "$rc" -eq 10 ]; then
			meetings_add_flow "$day" || true
			continue
		fi

		sel_idx="$(echo "${sel_idx:-}" | xargs || true)"
		[ -z "$sel_idx" ] && return 0

		raw_idx="$(printf "%s\n" "$raw_list" | nth_line "$((sel_idx + 1))")"
		raw_idx="$(echo "${raw_idx:-}" | xargs || true)"
		[ -z "$raw_idx" ] && return 0

		if [ "$rc" -eq 11 ]; then
			core remove-meeting "$day" "$raw_idx" >/dev/null 2>&1 || true
			continue
		fi

		action="$(rofi_menu "Remove Meeting")" || true
		case "$action" in
			"Remove Meeting") core remove-meeting "$day" "$raw_idx" >/dev/null 2>&1 || true ;;
		esac
	done
}

# ---------------- MAIN MENU ----------------
while true; do
	python3 "$CORE_PY" auto-reckon >/dev/null 2>&1 || true
	today="$(date +%F)"

	sparkline="$(core week-bars --days 14 2>/dev/null | tr -d '\n' || true)"
	if [ "${sparkline:-}" = "·" ]; then
		sparkline=""
	fi

	choice="$(rofi_menu --mesg "$sparkline" \
		" Today" \
		"󰈙 Past / Future Day" \
		"󱌣 Manage Tasks" \
		"󰗽 Manage Meetings" \
		" Close Today" \
		"⌧ Exit"
	)" || true

	case "$choice" in
		" Today")
			day_screen "$today"
			;;
		"󰈙 Past / Future Day")
			d="$(pick_date)"
			[ -n "${d:-}" ] && day_screen "$d"
			;;
		"󱌣 Manage Tasks")
			master_screen
			;;
		"󰗽 Manage Meetings")
			meetings_screen "$today"
			;;
		" Close Today")
			core close "$today" >/dev/null 2>&1 || true
			;;
		*)
			exit 0
			;;
	esac
done

