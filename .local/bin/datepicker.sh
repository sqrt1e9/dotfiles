#!/usr/bin/env bash
set -euo pipefail

PICKER="${PICKER:-$HOME/.config/hypr/scripts/datepicker.py}"
THEME="${THEME:-$HOME/.config/rofi/datepicker.rasi}"
LOG_FILE="${LOG_FILE:-$HOME/.config/todo/datepicker.pick.log}"

mkdir -p "$(dirname "$LOG_FILE")"

day="$(
	rofi -no-config -show daypicker \
		-modi "daypicker:python3 $PICKER" \
		-theme "$THEME" \
		-kb-custom-1 "Alt+h" \
		-kb-custom-2 "Alt+j" \
		-kb-custom-3 "Alt+k" \
		-kb-custom-4 "Alt+l" \
		-kb-custom-5 "Alt+t" \
		2>&1 1>/dev/null
)"

day="$(echo "${day:-}" | tr -d '\r' | xargs || true)"
printf '%s picked="%s"\n' "$(date -Is)" "$day" >>"$LOG_FILE"

[[ -z "${day}" ]] && exit 0

if [[ "${day}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
	printf '%s\n' "${day}"
	exit 0
fi

exit 1

