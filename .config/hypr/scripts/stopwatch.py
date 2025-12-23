#!/usr/bin/env python3
import json
import os
import sys
import time

STATE = os.path.expanduser("~/.cache/stopwatch_state")

def load():
	if not os.path.exists(STATE):
		return {"mode": "idle", "start": 0, "accum": 0}  # accum = seconds elapsed while not running
	with open(STATE, "r", encoding="utf-8") as f:
		try:
			s = json.load(f)
		except Exception:
			return {"mode": "idle", "start": 0, "accum": 0}
	# self-heal
	mode = s.get("mode", "idle")
	start = int(s.get("start", 0) or 0)
	accum = int(s.get("accum", 0) or 0)
	if mode not in ("idle", "running", "paused"):
		mode = "idle"
		start = 0
		accum = 0
	return {"mode": mode, "start": start, "accum": accum}

def save(s):
	os.makedirs(os.path.dirname(STATE), exist_ok=True)
	with open(STATE, "w", encoding="utf-8") as f:
		json.dump(s, f)

def format_time(total_sec: int) -> str:
	if total_sec < 0:
		total_sec = 0
	h = total_sec // 3600
	m = (total_sec % 3600) // 60
	s = total_sec % 60
	if h > 0:
		return f"{h:02d}:{m:02d}:{s:02d}"
	return f"{m:02d}:{s:02d}"

def tooltip_for(mode: str, elapsed_str: str | None = None) -> str:
	lines = ["Stopwatch", f"Status: {mode.capitalize()}"]
	if elapsed_str is not None:
		lines.append(f"Elapsed: {elapsed_str}")
	return "\n".join(lines)

def output(text: str, class_name: str = "", tooltip: str | None = None):
	out = {"text": text, "class": class_name}
	if tooltip:
		out["tooltip"] = tooltip
	print(json.dumps(out))
	sys.exit(0)

def elapsed_seconds(state, now: int) -> int:
	mode = state["mode"]
	accum = int(state.get("accum", 0) or 0)
	start = int(state.get("start", 0) or 0)
	if mode == "running":
		return accum + max(0, now - start)
	return accum

# -------- STATUS MODE for expand-center-ext (NO tooltip here) --------
if len(sys.argv) == 2 and sys.argv[1] == "status":
	s = load()
	mode = s.get("mode", "idle")
	print(json.dumps({
		"text": "<span size='x-large'>›</span>",
		"class": mode
	}))
	sys.exit(0)

state = load()
now = int(time.time())

if len(sys.argv) == 2:
	cmd = sys.argv[1]

	if cmd == "toggle":
		# idle -> running
		# running -> paused (freeze time into accum)
		# paused -> running (resume from accum)
		if state["mode"] == "idle":
			state["mode"] = "running"
			state["start"] = now
			state["accum"] = 0
		elif state["mode"] == "running":
			# freeze elapsed into accum
			state["accum"] = elapsed_seconds(state, now)
			state["mode"] = "paused"
			state["start"] = 0
		elif state["mode"] == "paused":
			state["mode"] = "running"
			state["start"] = now
		save(state)
		sys.exit(0)

	if cmd == "reset":
		state = {"mode": "idle", "start": 0, "accum": 0}
		save(state)
		sys.exit(0)

# -------- Visual Output --------
mode = state["mode"]
elapsed = elapsed_seconds(state, now)
elapsed_str = format_time(elapsed)

if mode == "idle":
	output("󱫑  00:00", "idle", tooltip_for("idle", "00:00"))

if mode == "paused":
	output("  " + elapsed_str, "paused", tooltip_for("paused", elapsed_str))

if mode == "running":
	output("󱎫  " + elapsed_str, "running", tooltip_for("running", elapsed_str))

# fallback
output("  00:00", "idle", tooltip_for("idle", "00:00"))

