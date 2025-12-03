#!/usr/bin/env bash

STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar_stopwatch"

load_state() {
	if [ -f "$STATE_FILE" ]; then
		# state;accumulated;start
		IFS=';' read -r state accumulated start < "$STATE_FILE"
	else
		state=0
		accumulated=0
		start=0
	fi
}

save_state() {
	printf '%s;%s;%s\n' "$state" "$accumulated" "$start" > "$STATE_FILE"
}

toggle() {
	now=$(date +%s)
	load_state

	if [ "$state" -eq 0 ]; then
		# start
		state=1
		start=$now
	else
		# stop
		elapsed=$(( now - start ))
		accumulated=$(( accumulated + elapsed ))
		state=0
		start=$now
	fi

	save_state
}

reset() {
	load_state
	state=0
	accumulated=0
	start=$(date +%s)
	save_state
}

format_time() {
	total="$1"
	hours=$(( total / 3600 ))
	mins=$(( (total % 3600) / 60 ))
	secs=$(( total % 60 ))

	if [ "$hours" -gt 0 ]; then
		printf "%02d:%02d:%02d" "$hours" "$mins" "$secs"
	else
		printf "%02d:%02d" "$mins" "$secs"
	fi
}

print_state() {
	now=$(date +%s)
	load_state

	if [ "$state" -eq 1 ]; then
		# running
		elapsed=$(( accumulated + (now - start) ))
		icon="⏱"
	else
		# stopped
		elapsed=$accumulated
		icon="⏸"
	fi

	formatted=$(format_time "$elapsed")

	tooltip="Stopwatch\nState: $( [ "$state" -eq 1 ] && echo "running" || echo "stopped" )\nTime: $formatted\n\nLeft-click: start/stop\nRight-click: reset"

	# Single-line, compact JSON, no tabs/newlines formatting
	printf '{"text":"%s","tooltip":"%s"}\n' "$icon $formatted" "$tooltip"
}

case "$1" in
	--toggle) toggle ;;
	--reset) reset ;;
esac

print_state

