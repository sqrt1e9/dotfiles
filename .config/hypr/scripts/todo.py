#!/usr/bin/env python3
import argparse
import datetime as dt
import json
import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

BASE_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "todo"
DAYS_DIR = BASE_DIR / "days"
MEETINGS_DIR = BASE_DIR / "meetings"
LEDGER_DIR = BASE_DIR / "ledger"
MASTER_FILE = BASE_DIR / "master.json"
SCORES_FILE = BASE_DIR / "scores.json"

# Legacy verdicts accepted, but FAILED is collapsed into SKIPPED everywhere.
VERDICTS = {"DONE", "FAILED", "SKIPPED"}

# Accountability scoring (no positive points)
# DONE: 0
# FAILED/SKIPPED: -2
# TODO (None): -3
DONE_POINTS = 0
FAIL_POINTS = -2
TODO_POINTS = -3

_TAG_RE = re.compile(r"(?:^|\s)#([A-Za-z0-9_-]+)\b")

TOTAL_W = 92
TITLE_W = 56  # more room since we removed time column

# Sparkline bars (low -> high)
SPARK_BARS = "▁▂▃▄▅▆▇█"


@dataclass
class MasterTask:
	task: str
	active: bool = True
	must: bool = False
	tags: List[str] = field(default_factory=list)


@dataclass
class DayTask:
	task: str
	must: bool = False
	verdict: Optional[str] = None  # None, DONE, SKIPPED
	debt: bool = False
	tags: List[str] = field(default_factory=list)
	deleted: bool = False  # tombstone: removed for this day, prevents sync re-add


@dataclass
class Meeting:
	time: str  # "HH:MM"
	title: str
	code: str = ""  # meet code / url / webex number


def ensure_dirs() -> None:
	BASE_DIR.mkdir(parents=True, exist_ok=True)
	DAYS_DIR.mkdir(parents=True, exist_ok=True)
	MEETINGS_DIR.mkdir(parents=True, exist_ok=True)
	LEDGER_DIR.mkdir(parents=True, exist_ok=True)


def read_json(p: Path, default):
	try:
		if p.exists():
			return json.loads(p.read_text(encoding="utf-8"))
	except Exception:
		pass
	return default


def write_json(p: Path, data) -> None:
	p.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _extract_tags(s: str) -> Tuple[str, List[str]]:
	tags = _TAG_RE.findall(s or "")
	seen = set()
	out_tags: List[str] = []
	for t in tags:
		if t not in seen:
			seen.add(t)
			out_tags.append(t)

	title = re.sub(r"(?:^|\s)#[A-Za-z0-9_-]+\b", "", s or "")
	title = re.sub(r"\s{2,}", " ", title).strip()
	return title, out_tags


def parse_task_input(raw: str) -> Tuple[bool, str, List[str]]:
	"""
	Single textbox format:
		[!]Title #tag1 #tag2
	Examples:
		!DSA/CP: Solve two Recursion Problem #cp #recursion
		Gym #health
	Returns: (must, title, tags)
	"""
	s = (raw or "").strip()
	if not s:
		return (False, "", [])

	must = False
	if s.startswith("!"):
		must = True
		s = s.lstrip("!").strip()

	title, tags = _extract_tags(s)
	return (must, title, tags)


def _norm_verdict(v: Any) -> Optional[str]:
	if v is None:
		return None
	v = str(v).strip().upper()
	if v == "FAILED":
		return "SKIPPED"
	if v in ("DONE", "SKIPPED"):
		return v
	return None


# ---------------- Master / Day IO ----------------

def load_master() -> List[MasterTask]:
	data = read_json(MASTER_FILE, [])
	out: List[MasterTask] = []
	if isinstance(data, list):
		for t in data:
			if isinstance(t, dict) and ("task" in t or "title" in t):
				task = str(t.get("task") if t.get("task") is not None else t.get("title", ""))
				tags = t.get("tags", [])
				if not isinstance(tags, list):
					tags = []
				tags = [str(x) for x in tags if x is not None and str(x).strip()]
				out.append(
					MasterTask(
						task=task,
						active=bool(t.get("active", True)),
						must=bool(t.get("must", False)),
						tags=tags,
					)
				)
	return out


def save_master(tasks: List[MasterTask]) -> None:
	write_json(MASTER_FILE, [t.__dict__ for t in tasks])


def load_day(day: str) -> List[DayTask]:
	p = DAYS_DIR / f"{day}.json"
	data = read_json(p, [])
	out: List[DayTask] = []
	if isinstance(data, list):
		for t in data:
			if isinstance(t, dict) and ("task" in t or "title" in t):
				task = str(t.get("task") if t.get("task") is not None else t.get("title", ""))

				verdict = _norm_verdict(t.get("verdict", None))
				tags = t.get("tags", [])
				if not isinstance(tags, list):
					tags = []
				tags = [str(x) for x in tags if x is not None and str(x).strip()]

				out.append(
					DayTask(
						task=task,
						must=bool(t.get("must", False)),
						verdict=verdict,
						debt=bool(t.get("debt", False)),
						tags=tags,
						deleted=bool(t.get("deleted", False)),
					)
				)
	return out


def save_day(day: str, tasks: List[DayTask]) -> None:
	p = DAYS_DIR / f"{day}.json"
	write_json(p, [t.__dict__ for t in tasks])


def _iso_add_days(day: str, n: int) -> str:
	return (dt.date.fromisoformat(day) + dt.timedelta(days=n)).isoformat()


# ---------------- Scores ----------------

def load_scores() -> Dict[str, Any]:
	data = read_json(SCORES_FILE, {})
	return data if isinstance(data, dict) else {}


def save_scores(scores: Dict[str, Any]) -> None:
	write_json(SCORES_FILE, scores)


def is_day_closed(day: str) -> bool:
	return day in load_scores()


# ---------------- Meetings (PER-DAY FILES) ----------------

def _meetings_file(day: str) -> Path:
	return MEETINGS_DIR / f"{day}.json"


def load_meetings_day(day: str) -> List[Meeting]:
	data = read_json(_meetings_file(day), [])
	out: List[Meeting] = []
	if isinstance(data, list):
		for it in data:
			if not isinstance(it, dict):
				continue
			tm = str(it.get("time", "") or "").strip()
			title = str(it.get("title", "") or "").strip()
			code = str(it.get("code", "") or "").strip()
			if tm and title:
				out.append(Meeting(time=tm, title=title, code=code))
	return out


def save_meetings_day(day: str, meetings: List[Meeting]) -> None:
	write_json(_meetings_file(day), [m.__dict__ for m in meetings])


def _fmt_meeting_row(m: Meeting) -> str:
	tm = m.time[:5].ljust(5)
	title = m.title[:44].ljust(44)
	code = (m.code or "").strip()
	return f"{tm}  {title}  {code}".rstrip()


def cmd_list_meetings(day: str, choices: bool) -> None:
	items = load_meetings_day(day)
	items.sort(key=lambda x: x.time)

	for i, m in enumerate(items):
		label = _fmt_meeting_row(m)
		raw = str(i)  # index
		if choices:
			print(f"{label}\t{raw}")
		else:
			print(label)


def cmd_add_meeting(day: str, time: str, title: str, code: str) -> None:
	time = (time or "").strip()
	title = (title or "").strip()
	code = (code or "").strip()
	if not time or not title:
		return

	items = load_meetings_day(day)
	items.append(Meeting(time=time, title=title, code=code))
	items.sort(key=lambda x: x.time)
	save_meetings_day(day, items)


def cmd_remove_meeting(day: str, index: int) -> None:
	items = load_meetings_day(day)
	if index < 0 or index >= len(items):
		return
	items.pop(index)
	save_meetings_day(day, items)


# ---------------- Day assembly / sync ----------------

def get_ready_day(day: str) -> List[DayTask]:
	master = load_master()
	current = load_day(day)

	day_map: Dict[str, DayTask] = {}
	for t in current:
		if t.task:
			day_map[t.task] = t

	out: List[DayTask] = []

	for m in master:
		if not m.active:
			continue
		ext = day_map.get(m.task)
		if ext and ext.deleted:
			continue

		out.append(
			DayTask(
				task=m.task,
				must=m.must,
				verdict=(ext.verdict if ext else None),
				debt=(ext.debt if ext else False),
				tags=(ext.tags if (ext and ext.tags) else m.tags),
				deleted=False,
			)
		)

	master_names = {m.task for m in master}
	for t in current:
		if not t.task or t.task in master_names:
			continue
		if t.deleted:
			continue
		out.append(t)

	return out


def cmd_sync_day(day: str) -> None:
	if is_day_closed(day):
		return

	master = load_master()
	current = load_day(day)

	by_name: Dict[str, DayTask] = {}
	order: List[str] = []

	for t in current:
		if not t.task:
			continue
		by_name[t.task] = t
		if t.task not in order:
			order.append(t.task)

	for m in master:
		if not m.active or not m.task:
			continue

		existing = by_name.get(m.task)
		if existing is not None:
			if existing.deleted:
				continue
			if (not existing.tags) and m.tags:
				existing.tags = list(m.tags)
			if not existing.must and m.must:
				existing.must = True
		else:
			by_name[m.task] = DayTask(
				task=m.task,
				must=m.must,
				verdict=None,
				debt=False,
				tags=list(m.tags),
				deleted=False,
			)
			order.append(m.task)

	out: List[DayTask] = []
	for name in order:
		t = by_name.get(name)
		if t is not None:
			out.append(t)

	save_day(day, out)


# ---------------- Rendering ----------------

def _status_day(verdict: Optional[str]) -> str:
	if verdict == "DONE":
		return "✔"
	if verdict in ("FAILED", "SKIPPED"):
		return "✘"
	return "■"


def _status_master(active: bool) -> str:
	return "■" if active else "□"


def _fmt_tags(tags: List[str]) -> str:
	if not tags:
		return ""
	return " ".join(f"#{t}" for t in tags)


def _fmt_row(status: str, title: str, must: bool, tags: List[str]) -> str:
	ttl = ("!" if must else "") + (title or "")
	ttl = ttl[:TITLE_W].ljust(TITLE_W)
	left = f"{status} {ttl}"
	tag_str = _fmt_tags(tags)
	space = max(1, TOTAL_W - len(left) - len(tag_str))
	return f"{left}{' ' * space}{tag_str}".rstrip()


# ---------------- Commands: list/add/set/remove ----------------

def cmd_list_day(day: str, choices: bool) -> None:
	tasks = get_ready_day(day)

	def grp(t: DayTask) -> int:
		if t.verdict is None:
			return 0
		if t.verdict in ("FAILED", "SKIPPED"):
			return 1
		return 2  # DONE

	tasks.sort(key=lambda t: (grp(t), t.task.lower()))

	for t in tasks:
		status = _status_day(t.verdict)
		label = _fmt_row(status, t.task, t.must, t.tags)
		raw = t.task
		if choices:
			print(f"{label}\t{raw}")
		else:
			print(label)


def cmd_list_master(choices: bool) -> None:
	tasks = load_master()
	tasks.sort(key=lambda t: (0 if t.active else 1, t.task.lower()))

	for t in tasks:
		status = _status_master(t.active)
		label = _fmt_row(status, t.task, t.must, t.tags)
		raw = t.task
		if choices:
			print(f"{label}\t{raw}")
		else:
			print(label)


def cmd_add_day(day: str, raw: str) -> None:
	if is_day_closed(day):
		return

	must, title, tags = parse_task_input(raw)
	if not title:
		return
	tasks = load_day(day)

	for t in tasks:
		if t.task == title:
			t.deleted = False
			if must and not t.must:
				t.must = True
			if tags:
				t.tags = list(tags)
			save_day(day, tasks)
			return

	tasks.append(DayTask(task=title, must=must, tags=tags, deleted=False))
	save_day(day, tasks)


def cmd_add_master(raw: str) -> None:
	must, title, tags = parse_task_input(raw)
	if not title:
		return
	m = load_master()
	m.append(MasterTask(task=title, must=must, active=True, tags=tags))
	save_master(m)


def cmd_set_verdict(day: str, task: str, verdict: str) -> None:
	if is_day_closed(day):
		return

	verdict = _norm_verdict(verdict)
	task = (task or "").strip()
	if not task or verdict not in ("DONE", "SKIPPED"):
		return

	tasks = load_day(day)
	found = False
	for t in tasks:
		if t.task == task:
			t.verdict = verdict
			t.deleted = False
			found = True

	if not found:
		master = load_master()
		m = next((x for x in master if x.task == task), None)
		tasks.append(
			DayTask(
				task=task,
				must=(m.must if m else False),
				tags=(list(m.tags) if (m and m.tags) else []),
				verdict=verdict,
				deleted=False,
			)
		)

	save_day(day, tasks)


def cmd_remove_day(day: str, task: str) -> None:
	if is_day_closed(day):
		return

	task = (task or "").strip()
	if not task:
		return

	tasks = load_day(day)
	found = False
	for t in tasks:
		if t.task == task:
			t.deleted = True
			found = True

	if not found:
		master = load_master()
		m = next((x for x in master if x.task == task), None)
		tasks.append(
			DayTask(
				task=task,
				must=(m.must if m else False),
				tags=(list(m.tags) if (m and m.tags) else []),
				verdict=None,
				debt=False,
				deleted=True,
			)
		)

	save_day(day, tasks)


def cmd_toggle_master(task: str) -> None:
	task = (task or "").strip()
	if not task:
		return
	m = load_master()
	for t in m:
		if t.task == task:
			t.active = not t.active
	save_master(m)


def cmd_remove_master(task: str) -> None:
	task = (task or "").strip()
	if not task:
		return
	m = [t for t in load_master() if t.task != task]
	save_master(m)


# ---------------- Streak / stats / bars ----------------

def compute_clean_streak() -> int:
	scores = load_scores()
	if not scores:
		return 0

	days = sorted(scores.keys(), reverse=True)
	streak = 0
	for d in days:
		s = scores.get(d, {})
		if int(s.get("failed_skipped", 0) or 0) == 0:
			streak += 1
		else:
			break
	return streak


def compute_day_stats(day: str) -> Dict[str, int]:
	tasks = get_ready_day(day)

	done = sum(1 for t in tasks if (not t.deleted) and t.verdict == "DONE")
	fail = sum(1 for t in tasks if (not t.deleted) and t.verdict in ("SKIPPED", "FAILED"))
	todo = sum(1 for t in tasks if (not t.deleted) and t.verdict is None)

	must_missed = sum(1 for t in tasks if (not t.deleted) and t.must and t.verdict != "DONE")
	total = sum(1 for t in tasks if not t.deleted)

	score = done * DONE_POINTS + fail * FAIL_POINTS + todo * TODO_POINTS

	return {
		"total": total,
		"done": done,
		"failed_skipped": fail,
		"todo": todo,
		"must_missed": must_missed,
		"score": score,
	}


def _spark_for_ratio(ratio: float) -> str:
	if ratio <= 0:
		return SPARK_BARS[0]
	if ratio >= 1:
		return SPARK_BARS[-1]
	idx = int(round(ratio * (len(SPARK_BARS) - 1)))
	idx = max(0, min(idx, len(SPARK_BARS) - 1))
	return SPARK_BARS[idx]


def cmd_week_bars(days: int = 7, gap: str = "\u2009") -> None:
	scores = load_scores()
	if not scores:
		print("")
		return

	keys = sorted(scores.keys())
	keys = keys[-max(1, int(days)):]  # last N closed days

	bars: List[str] = []
	for d in keys:
		s = scores.get(d, {})
		done = int(s.get("done", 0) or 0)
		total = int(s.get("total", 0) or 0)

		# If nothing was done, skip this day entirely
		if total <= 0 or done == 0:
			continue

		bars.append(_spark_for_ratio(done / total))

	# If no bars at all → show nothing
	if not bars:
		print("")
		return

	spark = gap.join(bars)
	streak = compute_clean_streak()

	if streak > 0:
		print(f"{spark}   🔥{streak}")
	else:
		print(spark)


# ---------------- Close / auto-reckon (MUST RULE) ----------------

def _must_failed_or_missed(tasks: List[DayTask]) -> bool:
	for t in tasks:
		if t.deleted:
			continue
		if t.must and t.verdict != "DONE":
			return True
	return False


def write_witness(day: str, tasks: List[DayTask], stats: Dict[str, int]) -> None:
	out = LEDGER_DIR / f"{day}.txt"
	if out.exists():
		return

	lines: List[str] = []
	seen = set()
	for t in tasks:
		if not t.task or t.task in seen or t.deleted:
			continue
		seen.add(t.task)
		if t.verdict != "SKIPPED":
			continue

		prefix = "!!" if t.debt else ("!" if t.must else "")
		lines.append(f"[-] {prefix}{t.task}")

	body = "\n".join(lines) if lines else "(none)"

	text = (
		f"DAY: {day}\n"
		f"SCORE: {stats['score']}\n"
		f"TOTAL: {stats['total']}\n"
		f"DONE: {stats['done']}\n"
		f"FAILED/SKIPPED: {stats['failed_skipped']}\n"
		f"TODO: {stats['todo']}\n"
		f"MUST_MISSED: {stats['must_missed']}\n"
		f"\nFAILED/SKIPPED:\n{body}\n"
	)
	out.write_text(text, encoding="utf-8")


def carry_forward_failures(day: str, closed_tasks: List[DayTask]) -> None:
	next_day = _iso_add_days(day, 1)

	cmd_sync_day(next_day)
	next_tasks = load_day(next_day)
	nmap: Dict[str, DayTask] = {t.task: t for t in next_tasks if t.task}

	for t in closed_tasks:
		if t.deleted:
			continue
		if t.verdict != "SKIPPED":
			continue

		ex = nmap.get(t.task)
		if ex is not None:
			if ex.deleted:
				continue
			ex.debt = True
			ex.must = True
		else:
			nmap[t.task] = DayTask(
				task=t.task,
				must=True,
				verdict=None,
				debt=True,
				tags=list(t.tags),
				deleted=False,
			)

	ordered: List[DayTask] = []
	seen = set()
	for t0 in next_tasks:
		if t0.task in nmap and t0.task not in seen:
			ordered.append(nmap[t0.task])
			seen.add(t0.task)
	for k, v in nmap.items():
		if k not in seen:
			ordered.append(v)
			seen.add(k)

	save_day(next_day, ordered)


def cmd_close(day: str) -> None:
	scores = load_scores()
	if day in scores:
		print("ALREADY_CLOSED")
		return

	cmd_sync_day(day)
	tasks = load_day(day)

	# If ANY must task is not DONE, the whole day becomes SKIPPED for all non-deleted tasks.
	must_failed = _must_failed_or_missed(tasks)

	closed: List[DayTask] = []
	for t in tasks:
		if t.deleted:
			closed.append(t)
			continue

		if must_failed:
			v = "SKIPPED"
		else:
			v = "DONE" if t.verdict == "DONE" else "SKIPPED"

		closed.append(
			DayTask(
				task=t.task,
				must=t.must,
				verdict=v,
				debt=t.debt,
				tags=list(t.tags),
				deleted=False,
			)
		)

	save_day(day, closed)
	stats = compute_day_stats(day)

	scores[day] = {
		"closed_at": dt.datetime.now().isoformat(timespec="seconds"),
		**stats,
	}
	save_scores(scores)

	write_witness(day, closed, stats)
	carry_forward_failures(day, closed)

	print(f"CLOSED {day}")
	print(f"TOTAL: {stats['total']}")
	print(f"DONE: {stats['done']}")
	print(f"FAILED/SKIPPED: {stats['failed_skipped']}")
	print(f"TODO: {stats['todo']}")
	print(f"MUST_MISSED: {stats['must_missed']}")
	print(f"SCORE: {stats['score']}")


def cmd_auto_reckon() -> None:
	"""
	Close past days that exist as day files but are not in scores.json.
	Uses the same MUST rule as cmd_close.
	"""
	ensure_dirs()

	if not MASTER_FILE.exists():
		write_json(MASTER_FILE, [])
	if not SCORES_FILE.exists():
		write_json(SCORES_FILE, {})

	scores = load_scores()
	today = dt.date.today().isoformat()

	for p in sorted(DAYS_DIR.glob("*.json")):
		day = p.stem
		if day >= today:
			continue
		if day in scores:
			continue

		tasks = load_day(day)
		must_failed = _must_failed_or_missed(tasks)

		closed: List[DayTask] = []
		for t in tasks:
			if t.deleted:
				closed.append(t)
				continue
			v = "SKIPPED" if must_failed else ("DONE" if t.verdict == "DONE" else "SKIPPED")
			closed.append(
				DayTask(
					task=t.task,
					must=t.must,
					verdict=v,
					debt=t.debt,
					tags=list(t.tags),
					deleted=False,
				)
			)

		save_day(day, closed)
		stats = compute_day_stats(day)
		scores[day] = {"closed_at": dt.datetime.now().isoformat(timespec="seconds"), **stats}

	save_scores(scores)


# ---------------- CLI ----------------

def main() -> int:
	ensure_dirs()

	p = argparse.ArgumentParser()
	sub = p.add_subparsers(dest="cmd", required=True)

	ld = sub.add_parser("list-day")
	ld.add_argument("day")
	ld.add_argument("--choices", action="store_true")

	lm = sub.add_parser("list-master")
	lm.add_argument("--choices", action="store_true")

	ad = sub.add_parser("add-day")
	ad.add_argument("day")
	ad.add_argument("raw")

	am = sub.add_parser("add-master")
	am.add_argument("raw")

	sd = sub.add_parser("sync-day")
	sd.add_argument("day")

	sv = sub.add_parser("set-verdict")
	sv.add_argument("day")
	sv.add_argument("task")
	sv.add_argument("verdict", choices=["DONE", "SKIPPED", "FAILED"])  # FAILED accepted, collapsed

	rd = sub.add_parser("remove-day")
	rd.add_argument("day")
	rd.add_argument("task")

	tm = sub.add_parser("toggle-master")
	tm.add_argument("task")

	rm = sub.add_parser("remove-master")
	rm.add_argument("task")

	cl = sub.add_parser("close")
	cl.add_argument("day")

	wb = sub.add_parser("week-bars")
	wb.add_argument("--days", type=int, default=7)

	# Meetings (per-day files)
	lmt = sub.add_parser("list-meetings")
	lmt.add_argument("day")
	lmt.add_argument("--choices", action="store_true")

	amt = sub.add_parser("add-meeting")
	amt.add_argument("day")
	amt.add_argument("time")
	amt.add_argument("title")
	amt.add_argument("code", nargs="?", default="")

	rmt = sub.add_parser("remove-meeting")
	rmt.add_argument("day")
	rmt.add_argument("index", type=int)

	sub.add_parser("auto-reckon")

	args = p.parse_args()

	if args.cmd == "list-day":
		cmd_list_day(args.day, args.choices)
	elif args.cmd == "list-master":
		cmd_list_master(args.choices)
	elif args.cmd == "add-day":
		cmd_add_day(args.day, args.raw)
	elif args.cmd == "add-master":
		cmd_add_master(args.raw)
	elif args.cmd == "sync-day":
		cmd_sync_day(args.day)
	elif args.cmd == "set-verdict":
		cmd_set_verdict(args.day, args.task, args.verdict)
	elif args.cmd == "remove-day":
		cmd_remove_day(args.day, args.task)
	elif args.cmd == "toggle-master":
		cmd_toggle_master(args.task)
	elif args.cmd == "remove-master":
		cmd_remove_master(args.task)
	elif args.cmd == "close":
		cmd_close(args.day)
	elif args.cmd == "week-bars":
		cmd_week_bars(args.days)
	elif args.cmd == "list-meetings":
		cmd_list_meetings(args.day, args.choices)
	elif args.cmd == "add-meeting":
		cmd_add_meeting(args.day, args.time, args.title, args.code)
	elif args.cmd == "remove-meeting":
		cmd_remove_meeting(args.day, args.index)
	elif args.cmd == "auto-reckon":
		cmd_auto_reckon()

	return 0


if __name__ == "__main__":
	raise SystemExit(main())

