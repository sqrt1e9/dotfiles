#!/usr/bin/env python3
from __future__ import annotations

import argparse
import calendar
import datetime as dt
import os
import sys

FIRSTWEEKDAY = calendar.MONDAY


def month_grid_row_index(year: int, month: int, target_day: int) -> int | None:
    """
    Return the rofi row index for `target_day` in (year, month), counting:
      - 7 weekday header rows first (indices 0..6)
      - then all cells in monthdatescalendar, including blanks for other months
    """
    cal = calendar.Calendar(firstweekday=FIRSTWEEKDAY)
    weeks = cal.monthdatescalendar(year, month)

    row_index = 7  # after weekday headers
    for week in weeks:
        for day in week:
            if day.month != month:
                row_index += 1
                continue
            if day.day == target_day:
                return row_index
            row_index += 1
    return None


def compute_default_selected_row(y: int, m: int, today: dt.date) -> int:
    """
    If current month: select today's date.
    Else: select the 1st of the month.
    """
    if y == today.year and m == today.month:
        idx = month_grid_row_index(y, m, today.day)
        if idx is not None:
            return idx
    idx = month_grid_row_index(y, m, 1)
    return idx if idx is not None else 0


def main() -> int:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--selected-row", action="store_true")
    parser.add_argument("--ym", default=None)  # expects YYYY-MM
    args, _ = parser.parse_known_args()

    today = dt.date.today()

    # Determine month/year either from args or from ROFI_DATA default.
    if args.ym:
        y, m = map(int, args.ym.split("-"))
    else:
        state = os.environ.get("ROFI_DATA", f"{today.year}-{today.month:02d}")
        y, m = map(int, state.split("-"))

    # Helper mode: print the selected row index and exit.
    if args.selected_row:
        sys.stdout.write(str(compute_default_selected_row(y, m, today)))
        return 0

    # Normal rofi script-mode flow
    retv = os.environ.get("ROFI_RETV", "0")

    # Navigation and selection handling
    if retv == "10":  # Alt+h (Prev Month)
        m -= 1
        if m < 1:
            m = 12
            y -= 1
    elif retv == "11":  # Alt+j (Next Month)
        m += 1
        if m > 12:
            m = 1
            y += 1
    elif retv == "12":  # Alt+k (Prev Year)
        y -= 1
    elif retv == "13":  # Alt+l (Next Year)
        y += 1
    elif retv == "14":  # Alt+t (Today)
        y, m = today.year, today.month
    elif retv == "1":  # Enter
        selection = os.environ.get("ROFI_INFO")
        if selection:
            # wrapper captures stderr as the final selected day
            sys.stderr.write(f"{selection}\n")
        return 0

    # Rofi UI metadata (no special markup/highlight for today)
    print(f"\0data\x1f{y}-{m:02d}")
    print(f"\0prompt\x1f{calendar.month_abbr[m].capitalize()}-{y % 100:02d}")
    print("\0columns\x1f7")
    print("\0markup-rows\x1ffalse")
    print("\0use-hot-keys\x1ftrue")

    cal = calendar.Calendar(firstweekday=FIRSTWEEKDAY)
    weeks = cal.monthdatescalendar(y, m)

    # Weekday header
    names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] if FIRSTWEEKDAY == calendar.MONDAY else \
            ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    for name in names:
        print(f"{name}\0nonselectable\x1ftrue")

    # Day cells (no special formatting for today)
    for week in weeks:
        for day in week:
            if day.month != m:
                print(" \0nonselectable\x1ftrue")
                continue

            iso = day.isoformat()
            label = f"{day.day:>2} "
            print(f"{label}\0info\x1f{iso}")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BrokenPipeError:
        sys.exit(0)
    except Exception:
        sys.exit(1)

