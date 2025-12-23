#!/usr/bin/env python3
from __future__ import annotations

import calendar
import datetime as dt
import os
import sys

FIRSTWEEKDAY = calendar.MONDAY


def main() -> int:
    # 1) Capture selection state and today's date
    retv = os.environ.get("ROFI_RETV", "0")
    today = dt.date.today()

    # 2) Persisted state across key presses
    # Use YYYY-MM (zero-padded) so parsing is stable.
    state = os.environ.get("ROFI_DATA", f"{today.year}-{today.month:02d}")
    y, m = map(int, state.split("-"))

    # 3) Navigation and selection handling
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
            # The wrapper script captures stderr and treats it as the final selected day.
            sys.stderr.write(f"{selection}\n")
        return 0

    # 4) Rofi UI metadata
    # Persist state for the next run; keep it zero-padded.
    print(f"\0data\x1f{y}-{m:02d}")

    # Show month/year in the prompt (your theme renders prompt inside the inputbar)
    print(f"\0prompt\x1f{calendar.month_abbr[m].capitalize()}-{y % 100:02d}")

    print("\0columns\x1f7")
    print("\0markup-rows\x1ftrue")
    print("\0use-hot-keys\x1ftrue")

    # 5) Calendar generation
    cal = calendar.Calendar(firstweekday=FIRSTWEEKDAY)
    weeks = cal.monthdatescalendar(y, m)

    # Weekday header
    if FIRSTWEEKDAY == calendar.MONDAY:
        names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    else:
        names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    for name in names:
        print(f"<b>{name}</b>\0nonselectable\x1ftrue")

    # Day cells
    for week in weeks:
        for day in week:
            if day.month != m:
                print(" \0nonselectable\x1ftrue")
                continue

            iso = day.isoformat()
            if day == today:
                # e.g. "15*"
                label = f"<b><u>{day.day:>2}*</u></b>"
            else:
                # e.g. "15 "
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

