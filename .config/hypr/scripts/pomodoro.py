#!/usr/bin/env python3
import json, os, time, sys

STATE = os.path.expanduser("~/.cache/pomodoro_state")

# Durations (minutes)
WORK = 25
BREAK = 5

def load():
    if not os.path.exists(STATE):
        return {"mode": "idle", "start": 0, "duration": WORK * 60}
    with open(STATE) as f:
        return json.load(f)

def save(s):
    with open(STATE, "w") as f:
        json.dump(s, f)

def format_time(sec):
    m = sec // 60
    s = sec % 60
    return f"{m:02d}:{s:02d}"

def tooltip_for(mode, remaining_str=None):
    lines = ["Pomodoro Timer", f"Status: {mode.capitalize()}"]
    if remaining_str:
        lines.append(f"Remaining: {remaining_str}")
    return "\n".join(lines)

def output(text, class_name="", tooltip=None):
    out = {"text": text, "class": class_name}
    if tooltip:
        out["tooltip"] = tooltip
    print(json.dumps(out))
    sys.exit(0)

# -------- STATUS MODE for expand-center-ext (NO tooltip here) --------
if len(sys.argv) == 2 and sys.argv[1] == "status":
    s = load()
    mode = s.get("mode", "idle")
    print(json.dumps({
        "text": "<span size='x-large'>›</span>",
        "class": mode
    }))
    sys.exit(0)

# -------- MAIN CLOCK MODULE (THIS WILL HAVE TOOLTIP) --------
state = load()
now = int(time.time())

if len(sys.argv) == 2:
    cmd = sys.argv[1]

    if cmd == "toggle":
        if state["mode"] == "idle":
            state["mode"] = "work"
            state["start"] = now
            state["duration"] = WORK * 60
        elif state["mode"] in ("work", "break"):
            remaining = state["duration"] - (now - state["start"])
            state["duration"] = remaining
            state["mode"] = "paused"
        elif state["mode"] == "paused":
            state["start"] = now
            state["mode"] = "work"
        save(state)
        sys.exit(0)

    if cmd == "reset":
        state = {"mode": "idle", "start": 0, "duration": WORK * 60}
        save(state)
        sys.exit(0)

# Compute timer
mode = state["mode"]
elapsed = now - state["start"]
remaining = state["duration"] - elapsed

# Determine remaining string (for tooltip)
remaining_str = None
if mode in ("work", "break"):
    remaining_str = format_time(max(0, remaining))
elif mode == "paused":
    remaining_str = format_time(max(0, state["duration"]))

# -------- Visual Output --------
if mode == "idle":
    output("  25:00", "idle", tooltip_for("idle"))

if mode == "paused":
    output("  " + remaining_str, "paused", tooltip_for("paused", remaining_str))

if remaining <= 0:
    if mode == "work":
        state["mode"] = "break"
        state["start"] = now
        state["duration"] = BREAK * 60
    else:
        state["mode"] = "idle"
        state["duration"] = WORK * 60
        state["start"] = 0
    save(state)
    output("  Done", "done", tooltip_for("done"))

if mode == "work":
    output("  " + remaining_str, "work", tooltip_for("work", remaining_str))

if mode == "break":
    output("  " + remaining_str, "break", tooltip_for("break", remaining_str))

