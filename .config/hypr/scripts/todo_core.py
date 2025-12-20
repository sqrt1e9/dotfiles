#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# ---------------- Paths ----------------
def xdg_config_home() -> Path:
	return Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))

BASE_DIR = xdg_config_home() / "todo"
DAYS_DIR = BASE_DIR / "days"
LEDGER_DIR = BASE_DIR / "ledger"
MASTER_FILE = BASE_DIR / "master.json"
SCORES_FILE = BASE_DIR / "scores.json"

# ---------------- Model ----------------
Verdict = Optional[str]  # "DONE" | "FAILED" | "SKIPPED" | None

@dataclass(frozen=True)
class MasterTask:
	task: str
	active: bool = True
	must: bool = False

@dataclass(frozen=True)
class DayTask:
	task: str
	must: bool = False
	verdict: Verdict = None
	debt: bool = False

DONE_POINTS = 0
FAILED_POINTS = -1
SKIPPED_POINTS = -3

# ---------------- Utilities ----------------
def ensure_dirs() -> None:
	BASE_DIR.mkdir(parents=True, exist_ok=True)
	DAYS_DIR.mkdir(parents=True, exist_ok=True)
	LEDGER_DIR.mkdir(parents=True, exist_ok=True)

def iso_today() -> str:
	return dt.date.today().isoformat()

def iso_yesterday() -> str:
	return (dt.date.today() - dt.timedelta(days=1)).isoformat()

def parse_iso_date(s: str) -> dt.date:
	return dt.date.fromisoformat(s)

def iso_add_days(day: str, n: int) -> str:
	return (parse_iso_date(day) + dt.timedelta(days=n)).isoformat()

def day_file(day: str) -> Path:
	return DAYS_DIR / f"{day}.json"

def read_json(path: Path, default: Any) -> Any:
	if not path.exists():
		return default
	try:
		return json.loads(path.read_text(encoding="utf-8"))
	except Exception:
		return default

def write_json(path: Path, data: Any) -> None:
	tmp = path.with_suffix(path.suffix + ".tmp")
	tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
	tmp.replace(path)

def trim(s: str) -> str:
	return s.strip()

def parse_must_prefix(raw: str) -> Tuple[bool, str]:
	raw = trim(raw)
	if not raw:
		return False, ""
	if raw.startswith("!"):
		return True, trim(raw[1:])
	return False, raw

# ---------------- Normalization (self-healing) ----------------
def normalize_master(data: Any) -> List[MasterTask]:
	tasks: List[MasterTask] = []
	if isinstance(data, list):
		for it in data:
			if not isinstance(it, dict):
				continue
			t = it.get("task")
			if not isinstance(t, str) or not t.strip():
				continue
			active = it.get("active", True)
			must = it.get("must", False)
			tasks.append(MasterTask(task=t.strip(), active=bool(active), must=bool(must)))
	seen = set()
	out: List[MasterTask] = []
	for mt in tasks:
		if mt.task in seen:
			continue
		seen.add(mt.task)
		out.append(mt)
	return out

def normalize_day(data: Any) -> List[DayTask]:
	tasks: List[DayTask] = []
	if isinstance(data, list):
		for it in data:
			if not isinstance(it, dict):
				continue
			t = it.get("task")
			if not isinstance(t, str) or not t.strip():
				continue
			must = bool(it.get("must", False))
			debt = bool(it.get("debt", False))
			v = it.get("verdict", None)
			if v not in (None, "DONE", "FAILED", "SKIPPED"):
				v = None
			tasks.append(DayTask(task=t.strip(), must=must, verdict=v, debt=debt))
	seen = set()
	out: List[DayTask] = []
	for dtask in tasks:
		if dtask.task in seen:
			continue
		seen.add(dtask.task)
		out.append(dtask)
	return out

def normalize_scores(data: Any) -> List[Dict[str, Any]]:
	out: List[Dict[str, Any]] = []
	if isinstance(data, list):
		for it in data:
			if not isinstance(it, dict):
				continue
			day = it.get("day")
			if not isinstance(day, str) or not day.strip():
				continue

			def to_int(v: Any, default: int = 0) -> int:
				if isinstance(v, int):
					return v
				if isinstance(v, float):
					return int(v)
				return default

			out.append({
				"day": day.strip(),
				"score": to_int(it.get("score", 0), 0),
				"total": to_int(it.get("total", 0), 0),
				"done": to_int(it.get("done", 0), 0),
				"failed": to_int(it.get("failed", 0), 0),
				"skipped": to_int(it.get("skipped", 0), 0),
				"must_missed": to_int(it.get("must_missed", 0), 0),
			})

	# dedupe by day (stable), then sort by day
	seen = set()
	dedup: List[Dict[str, Any]] = []
	for r in out:
		if r["day"] in seen:
			continue
		seen.add(r["day"])
		dedup.append(r)
	dedup.sort(key=lambda x: x["day"])
	return dedup

def load_master() -> List[MasterTask]:
	ensure_dirs()
	data = read_json(MASTER_FILE, [])
	master = normalize_master(data)
	write_json(MASTER_FILE, [mt.__dict__ for mt in master])
	return master

def load_scores() -> List[Dict[str, Any]]:
	ensure_dirs()
	data = read_json(SCORES_FILE, [])
	scores = normalize_scores(data)
	write_json(SCORES_FILE, scores)
	return scores

def load_day(day: str) -> List[DayTask]:
	ensure_dirs()
	p = day_file(day)
	data = read_json(p, [])
	day_tasks = normalize_day(data)
	write_json(p, [t.__dict__ for t in day_tasks])
	return day_tasks

def save_day(day: str, tasks: List[DayTask]) -> None:
	# normalize again to guarantee schema + dedupe
	write_json(day_file(day), [t.__dict__ for t in normalize_day([t.__dict__ for t in tasks])])

# ---------------- Core behaviors ----------------
def ensure_day_ready(day: str) -> List[DayTask]:
	master = load_master()
	day_tasks = load_day(day)

	dmap: Dict[str, DayTask] = {t.task: t for t in day_tasks}

	out: List[DayTask] = []
	active_names: List[str] = []

	# active master tasks included (preserve verdict/debt if exists)
	for mt in master:
		if not mt.active:
			continue
		active_names.append(mt.task)
		ex = dmap.get(mt.task)
		if ex is not None:
			out.append(DayTask(task=mt.task, must=mt.must, verdict=ex.verdict, debt=ex.debt))
		else:
			out.append(DayTask(task=mt.task, must=mt.must, verdict=None, debt=False))

	# extras preserved (day-only tasks)
	active_set = set(active_names)
	for t in day_tasks:
		if t.task not in active_set:
			out.append(t)

	# stable dedupe
	seen = set()
	final: List[DayTask] = []
	for t in out:
		if t.task in seen:
			continue
		seen.add(t.task)
		final.append(t)

	save_day(day, final)
	return final

def is_day_closed(day: str) -> bool:
	scores = load_scores()
	return any(r["day"] == day for r in scores)

def score_day(tasks: List[DayTask]) -> Dict[str, int]:
	done = sum(1 for t in tasks if t.verdict == "DONE")
	failed = sum(1 for t in tasks if t.verdict == "FAILED")
	skipped = sum(1 for t in tasks if t.verdict in ("SKIPPED", None))
	must_missed = sum(1 for t in tasks if t.must and t.verdict != "DONE")
	total = len(tasks)
	score = done * DONE_POINTS + failed * FAILED_POINTS + skipped * SKIPPED_POINTS
	return {
		"score": score,
		"total": total,
		"done": done,
		"failed": failed,
		"skipped": skipped,
		"must_missed": must_missed,
	}

def write_witness(day: str, tasks: List[DayTask], stats: Dict[str, int]) -> None:
	ensure_dirs()
	out = LEDGER_DIR / f"{day}.txt"
	if out.exists():
		return

	# FAILED + SKIPPED only, dedupe by task
	filtered: List[DayTask] = []
	seen = set()
	for t in tasks:
		if t.verdict not in ("FAILED", "SKIPPED"):
			continue
		if t.task in seen:
			continue
		seen.add(t.task)
		filtered.append(t)

	# sort: debt first, then must, then verdict, then task
	def sort_key(t: DayTask) -> Tuple[int, int, str, str]:
		return (0 if t.debt else 1, 0 if t.must else 1, t.verdict or "", t.task)

	filtered.sort(key=sort_key)

	def line(t: DayTask) -> str:
		icon = "[x] " if t.verdict == "FAILED" else "[-] "
		prefix = "!!" if t.debt else ("!" if t.must else "")
		return f"{icon}{prefix}{t.task}"

	body = "\n".join(line(t) for t in filtered) if filtered else "(none)"

	text = (
		f"DAY: {day}\n"
		f"SCORE: {stats['score']}\n"
		f"TOTAL: {stats['total']}\n"
		f"DONE: {stats['done']}\n"
		f"FAILED: {stats['failed']}\n"
		f"SKIPPED: {stats['skipped']}\n"
		f"MUST_MISSED: {stats['must_missed']}\n"
		f"\nFAILED/SKIPPED:\n{body}\n"
	)
	out.write_text(text, encoding="utf-8")

	hook = os.environ.get("TODO_WITNESS_CMD", "").strip()
	if hook:
		try:
			subprocess.run([hook, str(out)], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
		except Exception:
			pass

def carry_forward_failures(day: str, closed_tasks: List[DayTask]) -> None:
	next_day = iso_add_days(day, 1)
	next_tasks = ensure_day_ready(next_day)

	nmap: Dict[str, DayTask] = {t.task: t for t in next_tasks}

	for t in closed_tasks:
		if t.verdict not in ("FAILED", "SKIPPED"):
			continue
		ex = nmap.get(t.task)
		if ex is not None:
			nmap[t.task] = DayTask(task=ex.task, must=True, verdict=ex.verdict, debt=True)
		else:
			nmap[t.task] = DayTask(task=t.task, must=True, verdict=None, debt=True)

	# preserve existing order + append new
	ordered: List[DayTask] = []
	seen = set()
	for t in next_tasks:
		if t.task in nmap and t.task not in seen:
			ordered.append(nmap[t.task])
			seen.add(t.task)
	for k, v in nmap.items():
		if k not in seen:
			ordered.append(v)
			seen.add(k)

	save_day(next_day, ordered)

def close_day(day: str, silent: bool) -> Dict[str, Any]:
	if is_day_closed(day):
		return {"already_closed": True}

	tasks = ensure_day_ready(day)

	# unset verdict -> SKIPPED
	closed: List[DayTask] = []
	for t in tasks:
		closed.append(DayTask(task=t.task, must=t.must, verdict=(t.verdict or "SKIPPED"), debt=t.debt))
	save_day(day, closed)

	stats = score_day(closed)

	scores = load_scores()
	scores.append({"day": day, **stats})
	scores = normalize_scores(scores)
	write_json(SCORES_FILE, scores)

	write_witness(day, closed, stats)
	carry_forward_failures(day, closed)

	return {"already_closed": False, **stats}

def force_close_day_as_skipped(day: str) -> None:
	if is_day_closed(day):
		return
	tasks = ensure_day_ready(day)
	skipped = [DayTask(task=t.task, must=t.must, verdict="SKIPPED", debt=t.debt) for t in tasks]
	save_day(day, skipped)
	close_day(day, silent=True)

def auto_reckon_unclosed_past_days() -> None:
	# close every missing day up to yesterday, silently as SKIPPED
	scores = load_scores()
	today = iso_today()
	yest = iso_yesterday()

	last_closed = max((r["day"] for r in scores), default="")

	start = iso_add_days(last_closed, 1) if last_closed else yest
	if start > yest:
		return

	d = start
	while d < today:
		if not is_day_closed(d):
			force_close_day_as_skipped(d)
		d = iso_add_days(d, 1)

# ---------------- Formatting (for rofi display) ----------------
def fmt_master(mt: MasterTask) -> str:
	chk = "[✓] " if mt.active else "[ ] "
	prefix = "!" if mt.must else ""
	return f"{chk}{prefix}{mt.task}"

def fmt_day(t: DayTask) -> str:
	v = t.verdict
	if v == "DONE":
		icon = "[✓] "
	elif v == "FAILED":
		icon = "[x] "
	elif v == "SKIPPED":
		icon = "[-] "
	else:
		icon = "[ ] "
	prefix = "!!" if t.debt else ("!" if t.must else "")
	return f"{icon}{prefix}{t.task}"

def list_day_lines(day: str, choices: bool) -> List[str]:
	tasks = ensure_day_ready(day)
	if choices:
		return [f"{fmt_day(t)}\t{t.task}" for t in tasks]
	return [fmt_day(t) for t in tasks]

def list_master_lines(choices: bool) -> List[str]:
	master = load_master()
	if choices:
		return [f"{fmt_master(t)}\t{t.task}" for t in master]
	return [fmt_master(t) for t in master]

# ---------------- Commands ----------------
def cmd_auto_reckon(_: argparse.Namespace) -> int:
	auto_reckon_unclosed_past_days()
	return 0

def cmd_ensure_day(ns: argparse.Namespace) -> int:
	ensure_day_ready(ns.day)
	return 0

def cmd_list_day(ns: argparse.Namespace) -> int:
	lines = list_day_lines(ns.day, ns.choices)
	sys.stdout.write("\n".join(lines) + ("\n" if lines else ""))
	return 0

def cmd_add_day(ns: argparse.Namespace) -> int:
	if is_day_closed(ns.day):
		sys.stdout.write("ERROR: Day closed\n")
		return 2
	must, task = parse_must_prefix(ns.raw)
	if not task:
		return 0
	tasks = ensure_day_ready(ns.day)
	if any(t.task == task for t in tasks):
		return 0
	tasks.append(DayTask(task=task, must=must, verdict=None, debt=False))
	save_day(ns.day, tasks)
	return 0

def cmd_remove_day(ns: argparse.Namespace) -> int:
	if is_day_closed(ns.day):
		sys.stdout.write("ERROR: Day closed\n")
		return 2
	task = trim(ns.task)
	if not task:
		return 0
	tasks = ensure_day_ready(ns.day)
	save_day(ns.day, [t for t in tasks if t.task != task])
	return 0

def cmd_set_verdict(ns: argparse.Namespace) -> int:
	if is_day_closed(ns.day):
		sys.stdout.write("ERROR: Day closed\n")
		return 2
	task = trim(ns.task)
	v = trim(ns.verdict)
	if v not in ("DONE", "FAILED", "SKIPPED"):
		sys.stdout.write("ERROR: Invalid verdict\n")
		return 2
	tasks = ensure_day_ready(ns.day)
	out: List[DayTask] = []
	for t in tasks:
		if t.task == task:
			out.append(DayTask(task=t.task, must=t.must, verdict=v, debt=t.debt))
		else:
			out.append(t)
	save_day(ns.day, out)
	return 0

def cmd_list_master(ns: argparse.Namespace) -> int:
	lines = list_master_lines(ns.choices)
	sys.stdout.write("\n".join(lines) + ("\n" if lines else ""))
	return 0

def cmd_add_master(ns: argparse.Namespace) -> int:
	must, task = parse_must_prefix(ns.raw)
	if not task:
		return 0
	master = load_master()
	if any(t.task == task for t in master):
		return 0
	master.append(MasterTask(task=task, active=True, must=must))
	write_json(MASTER_FILE, [t.__dict__ for t in master])
	return 0

def cmd_remove_master(ns: argparse.Namespace) -> int:
	task = trim(ns.task)
	if not task:
		return 0
	master = load_master()
	write_json(MASTER_FILE, [t.__dict__ for t in master if t.task != task])
	return 0

def cmd_toggle_master(ns: argparse.Namespace) -> int:
	task = trim(ns.task)
	if not task:
		return 0
	master = load_master()
	out: List[MasterTask] = []
	for t in master:
		if t.task == task:
			out.append(MasterTask(task=t.task, active=not t.active, must=t.must))
		else:
			out.append(t)
	write_json(MASTER_FILE, [t.__dict__ for t in out])
	return 0

def cmd_stats(_: argparse.Namespace) -> int:
	scores = load_scores()
	if not scores:
		sys.stdout.write("No data\n")
		return 0
	days = len(scores)
	score_sum = sum(r.get("score", 0) for r in scores)
	done_sum = sum(r.get("done", 0) for r in scores)
	failed_sum = sum(r.get("failed", 0) for r in scores)
	skipped_sum = sum(r.get("skipped", 0) for r in scores)
	must_missed_sum = sum(r.get("must_missed", 0) for r in scores)

	txt = (
		f"Days: {days}\n"
		f"Score sum: {score_sum}\n"
		f"DONE: {done_sum}\n"
		f"FAILED: {failed_sum}\n"
		f"SKIPPED: {skipped_sum}\n"
		f"MUST Missed: {must_missed_sum}\n"
	)
	sys.stdout.write(txt)
	return 0

def cmd_close(ns: argparse.Namespace) -> int:
	res = close_day(ns.day, silent=ns.silent)
	if res.get("already_closed") is True:
		sys.stdout.write("ALREADY_CLOSED\n")
		return 0
	sys.stdout.write(json.dumps(res) + "\n")
	return 0

def build_arg_parser() -> argparse.ArgumentParser:
	p = argparse.ArgumentParser(prog="todo_core.py")
	sub = p.add_subparsers(dest="cmd", required=True)

	sp = sub.add_parser("auto-reckon")
	sp.set_defaults(func=cmd_auto_reckon)

	sp = sub.add_parser("ensure-day")
	sp.add_argument("day")
	sp.set_defaults(func=cmd_ensure_day)

	sp = sub.add_parser("list-day")
	sp.add_argument("day")
	sp.add_argument("--choices", action="store_true")
	sp.set_defaults(func=cmd_list_day)

	sp = sub.add_parser("add-day")
	sp.add_argument("day")
	sp.add_argument("raw")
	sp.set_defaults(func=cmd_add_day)

	sp = sub.add_parser("remove-day")
	sp.add_argument("day")
	sp.add_argument("task")
	sp.set_defaults(func=cmd_remove_day)

	sp = sub.add_parser("set-verdict")
	sp.add_argument("day")
	sp.add_argument("task")
	sp.add_argument("verdict", choices=["DONE", "FAILED", "SKIPPED"])
	sp.set_defaults(func=cmd_set_verdict)

	sp = sub.add_parser("list-master")
	sp.add_argument("--choices", action="store_true")
	sp.set_defaults(func=cmd_list_master)

	sp = sub.add_parser("add-master")
	sp.add_argument("raw")
	sp.set_defaults(func=cmd_add_master)

	sp = sub.add_parser("remove-master")
	sp.add_argument("task")
	sp.set_defaults(func=cmd_remove_master)

	sp = sub.add_parser("toggle-master")
	sp.add_argument("task")
	sp.set_defaults(func=cmd_toggle_master)

	sp = sub.add_parser("stats")
	sp.set_defaults(func=cmd_stats)

	sp = sub.add_parser("close")
	sp.add_argument("day")
	sp.add_argument("--silent", action="store_true")
	sp.set_defaults(func=cmd_close)

	return p

def main() -> int:
	ensure_dirs()
	args = build_arg_parser().parse_args()
	try:
		return int(args.func(args))
	except KeyboardInterrupt:
		return 130

if __name__ == "__main__":
	raise SystemExit(main())

