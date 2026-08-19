# -*- coding: utf-8 -*-
# Canonical reference implementation of the `notifq` scheduling engine.
#
# This file is SEALED (part of the verifier). It is the ground truth the grader
# compares the agent's implementation against. The reference solution shipped in
# solution/solve.sh is a byte-for-byte copy of the logic below; if you edit one,
# edit both and re-run the local validation (oracle must score 1.0).
#
# Standard library only. No wall-clock reads (all time is passed in explicitly).

import json
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# The canonical, documented record schema. Extra keys are ignored by the grader;
# missing keys are a mismatch.
RECORD_KEYS = (
    "instant", "task_id", "occ_index", "reminder_id",
    "title", "priority", "deferred", "snoozed",
)


def _z(name):
    return ZoneInfo(name)


def _local_to_epoch(naive_iso, tzname):
    """Convert a naive local ISO datetime string in tz `tzname` to epoch seconds.

    Uses fold=0 semantics: nonexistent (spring-forward) local times resolve via
    the pre-transition offset; ambiguous (fall-back) local times resolve to the
    earlier instant.
    """
    dt = datetime.fromisoformat(naive_iso)
    if dt.tzinfo is not None:
        dt = dt.replace(tzinfo=None)
    return int(dt.replace(tzinfo=_z(tzname), fold=0).timestamp())


def _hhmm(s):
    h, m = s.split(":")
    return int(h) * 60 + int(m)


def _expand_occurrences(task, upper_epoch):
    """Return [(occ_index, occ_iso, occ_epoch), ...] in ascending order.

    occ_index is the global 0-based ordinal within the whole series (independent
    of any window). For unbounded series, generation stops once an occurrence's
    epoch exceeds upper_epoch (callers pad upper_epoch by the max reminder lead).
    """
    tz = task["timezone"]
    start = datetime.fromisoformat(task["start_local"]).replace(microsecond=0)
    rec = task.get("recurrence")
    out = []
    if not rec:
        return [(0, start.isoformat(), _local_to_epoch(start.isoformat(), tz))]

    freq = rec.get("freq")
    interval = int(rec.get("interval", 1) or 1)
    count = rec.get("count", None)
    until = rec.get("until_local", None)
    until_dt = datetime.fromisoformat(until).replace(microsecond=0) if until else None
    CAP = 200000
    idx = 0

    if freq == "DAILY":
        n = 0
        while True:
            occ = start + timedelta(days=interval * n)
            if until_dt is not None and occ > until_dt:
                break
            if count is not None and idx >= int(count):
                break
            iso = occ.isoformat()
            e = _local_to_epoch(iso, tz)
            out.append((idx, iso, e))
            idx += 1
            n += 1
            if count is None and until_dt is None and e > upper_epoch:
                break
            if n > CAP:
                break
        return out

    if freq == "WEEKLY":
        byday = sorted({int(x) for x in rec["byweekday"]})
        monday = start - timedelta(days=start.weekday())
        j = 0
        stop = False
        while not stop:
            base = monday + timedelta(days=7 * j)
            for d in byday:
                occ = base + timedelta(days=d)
                if occ.date() < start.date():
                    continue
                if until_dt is not None and occ > until_dt:
                    stop = True
                    break
                if count is not None and idx >= int(count):
                    stop = True
                    break
                iso = occ.isoformat()
                e = _local_to_epoch(iso, tz)
                out.append((idx, iso, e))
                idx += 1
            if stop:
                break
            if count is None and until_dt is None and out and out[-1][2] > upper_epoch:
                break
            j += interval
            if j > CAP:
                break
        return out

    raise ValueError("unknown recurrence freq: %r" % (freq,))


def _in_quiet(epoch, qh):
    z = _z(qh["tz"])
    lt = datetime.fromtimestamp(epoch, z)
    s = _hhmm(qh["start"])
    e = _hhmm(qh["end"])
    cur = lt.hour * 60 + lt.minute
    if s == e:
        return False
    if s < e:
        return s <= cur < e
    return cur >= s or cur < e  # window wraps past midnight


def _next_end_boundary(epoch, qh):
    """Smallest epoch >= `epoch` whose local time-of-day equals the quiet-hours end."""
    tz = qh["tz"]
    z = _z(tz)
    lt = datetime.fromtimestamp(epoch, z)
    eh, em = qh["end"].split(":")
    base = lt.date()
    for add in range(0, 4):
        cd = base + timedelta(days=add)
        iso = "%04d-%02d-%02dT%02d:%02d:00" % (cd.year, cd.month, cd.day, int(eh), int(em))
        ce = _local_to_epoch(iso, tz)
        if ce >= epoch:
            return ce
    return epoch


def _apply_quiet(raw, task, config):
    """Return (effective_instant, deferred, suppressed)."""
    qh = config.get("quiet_hours")
    if not qh:
        return raw, False, False
    if task.get("priority") == "urgent":
        return raw, False, False
    if not _in_quiet(raw, qh):
        return raw, False, False
    if config.get("quiet_policy", "defer") == "suppress":
        return raw, False, True
    return _next_end_boundary(raw, qh), True, False


def _notifs_for_task(task, config, reminder_upper):
    """All (coalesced) notifications for a task with effective instant <= reminder_upper.

    reminder_upper bounds *reminder* instants; occurrences are expanded slightly
    beyond it to cover leads. Deferral only moves instants later, so raw > upper
    can never yield an effective instant <= upper.
    """
    task_maxoff = 0
    for r in task.get("reminders", []):
        task_maxoff = max(task_maxoff, int(r["offset_min"]) * 60)
    occs = _expand_occurrences(task, reminder_upper + task_maxoff)
    items = []
    for (occ_index, _occ_iso, occ_epoch) in occs:
        for r in task.get("reminders", []):
            off = int(r["offset_min"])
            raw = occ_epoch - off * 60
            eff, deferred, supp = _apply_quiet(raw, task, config)
            if supp:
                continue
            items.append({
                "instant": eff,
                "task_id": task["id"],
                "occ_index": occ_index,
                "reminder_id": r["id"],
                "title": task["title"],
                "priority": task.get("priority", "normal"),
                "deferred": deferred,
                "snoozed": False,
                "_off": off,
            })
    # Coalesce: at most one notification per (task_id, effective_instant).
    groups = {}
    for it in items:
        groups.setdefault((it["task_id"], it["instant"]), []).append(it)
    result = []
    for _, g in groups.items():
        g.sort(key=lambda x: (x["_off"], x["reminder_id"], x["occ_index"]))
        w = dict(g[0])
        w.pop("_off", None)
        result.append(w)
    return result


def build_schedule(tasks, config, horizon_start, horizon_end):
    """Deterministic ideal delivery schedule within [horizon_start, horizon_end]."""
    hs = int(horizon_start)
    he = int(horizon_end)
    alln = []
    for t in tasks:
        alln += _notifs_for_task(t, config, he)
    alln = [n for n in alln if hs <= n["instant"] <= he]
    alln.sort(key=lambda x: (x["instant"], x["task_id"], x["reminder_id"]))
    return alln


class Engine:
    """Stateful delivery driver over an injected clock, sink, and persistent store."""

    def __init__(self, store, sink, config, start_cursor=0):
        self.store = store
        self.sink = sink
        self.config = config
        raw = store.get("state") if store is not None else None
        if raw:
            s = json.loads(raw)
            self.tasks = s["tasks"]
            self.cursor = int(s["cursor"])
            self.dispatched = set(tuple(k) for k in s["dispatched"])
            self.completed = set(tuple(k) for k in s["completed"])
            self.snoozes = {tuple(k): int(v) for k, v in s["snoozes"]}
        else:
            self.tasks = []
            self.cursor = int(start_cursor)
            self.dispatched = set()
            self.completed = set()
            self.snoozes = {}

    def _persist(self):
        if self.store is None:
            return
        self.store.set("state", json.dumps({
            "tasks": self.tasks,
            "cursor": self.cursor,
            "dispatched": [list(k) for k in self.dispatched],
            "completed": [list(k) for k in self.completed],
            "snoozes": [[list(k), v] for k, v in self.snoozes.items()],
        }))

    def add_task(self, task):
        self.tasks = [t for t in self.tasks if t["id"] != task["id"]] + [task]
        self._persist()

    def update_task(self, task):
        self.add_task(task)

    def cancel_task(self, task_id):
        self.tasks = [t for t in self.tasks if t["id"] != task_id]
        self._persist()

    def complete_occurrence(self, task_id, occ_index):
        self.completed.add((task_id, int(occ_index)))
        self._persist()

    def snooze(self, task_id, occ_index, reminder_id, delta_min, now):
        key = (task_id, int(occ_index), reminder_id)
        if key in self.dispatched:
            return
        self.snoozes[key] = int(now) + int(delta_min) * 60
        self._persist()

    def advance_to(self, now):
        now = int(now)
        if now <= self.cursor:
            return []
        cand = []
        for t in self.tasks:
            for n in _notifs_for_task(t, self.config, now):
                key = (n["task_id"], n["occ_index"], n["reminder_id"])
                if (n["task_id"], n["occ_index"]) in self.completed:
                    continue
                if key in self.snoozes:
                    continue  # original delivery replaced by its snooze
                cand.append((n["instant"], n["task_id"], n["reminder_id"], 0, n, key))
        for key, inst in self.snoozes.items():
            tid, occ, rid = key
            task = next((t for t in self.tasks if t["id"] == tid), None)
            rec = {
                "instant": int(inst),
                "task_id": tid,
                "occ_index": occ,
                "reminder_id": rid,
                "title": task["title"] if task else "",
                "priority": task.get("priority", "normal") if task else "normal",
                "deferred": False,
                "snoozed": True,
            }
            cand.append((int(inst), tid, rid, 1, rec, key))

        cand = [c for c in cand if self.cursor < c[0] <= now and c[5] not in self.dispatched]
        cand.sort(key=lambda c: (c[0], c[1], c[2], c[3]))

        grace = self.config.get("catchup_grace_min", None)
        grace_sec = int(grace) * 60 if grace is not None else None

        fired = []
        for c in cand:
            inst = c[0]
            rec = c[4]
            key = c[5]
            self.dispatched.add(key)  # consumed even if dropped as stale
            if grace_sec is not None and inst < now - grace_sec:
                continue
            self.sink.deliver(rec)
            fired.append(rec)

        self.cursor = now
        self._persist()
        return fired
