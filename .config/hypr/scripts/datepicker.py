#!/usr/bin/env python3
from __future__ import annotations

import argparse
import calendar
import datetime as dt
import os
import sys

TODAY_COLOR = "#9aa0a6"
FIRSTWEEKDAY = calendar.MONDAY


def month_grid_row_index(year: int, month: int, target_day: int) -> int | None:
	cal = calendar.Calendar(firstweekday=FIRSTWEEKDAY)
	weeks = cal.monthdatescalendar(year, month)

	idx = 7  # weekday headers are 0..6
	for week in weeks:
		for d in week:
			# Count ALL cells (we print out-of-month blanks too)
			if d.month == month and d.day == target_day:
				return idx
			idx += 1
	return None


def compute_default_selected_row(y: int, m: int, today: dt.date) -> int:
	if y == today.year and m == today.month:
		i = month_grid_row_index(y, m, today.day)
		if i is not None:
			return i
	i = month_grid_row_index(y, m, 1)
	return i if i is not None else 0


def main() -> int:
	parser = argparse.ArgumentParser(add_help=False)
	parser.add_argument("--selected-row", action="store_true")
	parser.add_argument("--ym", default=None)  # YYYY-MM (optional)
	args, _ = parser.parse_known_args()

	today = dt.date.today()

	if args.ym:
		y, m = map(int, args.ym.split("-"))
	else:
		state = os.environ.get("ROFI_DATA", f"{today.year}-{today.month:02d}")
		y, m = map(int, state.split("-"))

	if args.selected_row:
		sys.stdout.write(str(compute_default_selected_row(y, m, today)))
		return 0

	retv = os.environ.get("ROFI_RETV", "0")

	# IMPORTANT: On Enter, write selection to STDERR and exit (no stdout).
	if retv == "1":
		selection = (os.environ.get("ROFI_INFO") or "").strip()
		if selection:
			sys.stderr.write(selection + "\n")
		return 0

	# Navigation
	if retv == "10":  # prev month
		m -= 1
		if m < 1:
			m = 12
			y -= 1
	elif retv == "11":  # next month
		m += 1
		if m > 12:
			m = 1
			y += 1
	elif retv == "12":  # prev year
		y -= 1
	elif retv == "13":  # next year
		y += 1
	elif retv == "14":  # today
		y, m = today.year, today.month

	mon_abbr = calendar.month_abbr[m].capitalize()
	mmm_yy = f"{mon_abbr}-{y % 100:02d}"

	print(f"\0data\x1f{y}-{m:02d}")
	print(f"\0prompt\x1f{mmm_yy}")
	print(f"\0message\x1f{mmm_yy}")
	print("\0columns\x1f7")
	print("\0markup-rows\x1ftrue")
	print("\0use-hot-keys\x1ftrue")
	print(f"\0selected-row\x1f{compute_default_selected_row(y, m, today)}")

	cal = calendar.Calendar(firstweekday=FIRSTWEEKDAY)
	weeks = cal.monthdatescalendar(y, m)

	names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
	for name in names:
		print(f"{name}\0nonselectable\x1ftrue")

	for week in weeks:
		for d in week:
			if d.month != m:
				print(" \0nonselectable\x1ftrue")
				continue

			label = f"{d.day:>2} "
			if d == today:
				label = f"<span color=\"{TODAY_COLOR}\">{label}</span>"

			# info is the ISO date; returned via stderr on Enter
			print(f"{label}\0info\x1f{d.isoformat()}")

	return 0


if __name__ == "__main__":
	try:
		raise SystemExit(main())
	except BrokenPipeError:
		sys.exit(0)
	except Exception:
		sys.exit(1)

