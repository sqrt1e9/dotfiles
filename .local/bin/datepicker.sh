#!/usr/bin/env bash
set -euo pipefail

PICKER="${PICKER:-$HOME/.config/hypr/scripts/datepicker.py}"
THEME="${THEME:-$HOME/.config/rofi/datepicker.rasi}"

rofi_msg() {
	local title="$1"
	local text="${2:-}"
	[ -z "$text" ] && text="(none)"
	rofi -e "$(printf "%s\n\n%s" "$title" "$text")" -theme "$THEME" >/dev/null 2>&1 || true
}

# Capture the selection once.
day="$(
	rofi -show daypicker \
		-modi "daypicker:python3 $PICKER" \
		-theme "$THEME" \
		-kb-custom-1 "Alt+h" \
		-kb-custom-2 "Alt+j" \
		-kb-custom-3 "Alt+k" \
		-kb-custom-4 "Alt+l" \
		-kb-custom-5 "Alt+t" \
		2>&1 >/dev/null
)"

# Cancel/Escape
[[ -z "${day}" ]] && exit 0

# Validate and display
if [[ "${day}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
	rofi_msg "Selected date" "${day}"
fi

exit 0

