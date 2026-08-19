#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Sealed verifier for the notifq-notification-scheduler task.
#
# Loads the agent's `notifq` package from /app and grades it against the sealed
# reference (_ref_notifq.py) across many scenarios grouped into weighted
# components. Emits a continuous score in [0, 1].
#
#   score 1.0  -> reference solution (oracle)
#   score 0.0  -> untouched stub (nop)
#
# Grading is fully deterministic: all time is passed explicitly as epoch seconds;
# the verifier never reads the wall clock. Random scenarios use a fixed seed and
# expected values are computed at runtime by the reference, so nothing can be
# hard-coded from the visible environment.

import importlib.util
import json
import os
import random
import sys

THIS = os.path.dirname(os.path.abspath(__file__))
APP = sys.argv[1] if len(sys.argv) > 1 else "/app"
THRESHOLD = 0.70  # binary pass mark (oracle ~1.0, nop 0.0)


def _write_reward(score):
    """Persist the reward the harness reads back after each trial.

    Harbor/Odyssey reads the reward from `/logs/verifier/reward.txt` (a number in
    [0, 1]); the `SCORE:` stdout line is only a human-readable echo. We write there
    first (creating the dir), plus a few fallback locations, tolerating any that are
    not writable. reward.txt is a bare number (matching `echo <n> > reward.txt`);
    reward.json is {"reward": <float>}.
    """
    try:
        score = float(score)
    except Exception:
        score = 0.0
    num = ("%.6f" % score).rstrip("0").rstrip(".") or "0"
    txt = num + "\n"
    js = json.dumps({"reward": score})
    seen = []
    for d in ("/logs/verifier",
              os.path.join(os.getcwd(), "logs", "verifier"),
              THIS, os.getcwd(),
              os.path.join(os.getcwd(), "verifier"), "/verifier"):
        if not d or d in seen:
            continue
        seen.append(d)
        try:
            os.makedirs(d, exist_ok=True)
        except Exception:
            pass
        for fname, data in (("reward.txt", txt), ("reward.json", js)):
            try:
                with open(os.path.join(d, fname), "w") as f:
                    f.write(data)
            except Exception:
                pass


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


ref = _load("notifq_ref", os.path.join(THIS, "_ref_notifq.py"))

sys.path.insert(0, APP)
try:
    import notifq as agent  # noqa: E402
except Exception:
    agent = None

E = ref._local_to_epoch  # convenience: naive-local ISO + tz -> epoch


# ── test doubles handed to both engines ────────────────────────────────────
class MemStore:
    def __init__(self):
        self.d = {}

    def get(self, k):
        return self.d.get(k)

    def set(self, k, v):
        self.d[k] = v

    def delete(self, k):
        self.d.pop(k, None)

    def items(self):
        return list(self.d.items())


class ListSink:
    def __init__(self):
        self.records = []

    def deliver(self, rec):
        self.records.append(rec)


# ── comparison helpers ─────────────────────────────────────────────────────
def _proj(r):
    return tuple(r[k] for k in ref.RECORD_KEYS)


def rec_eq(a, b):
    if len(a) != len(b):
        return False
    for x, y in zip(a, b):
        if _proj(x) != _proj(y):
            return False
    return True


def task(tid, title, start, tz, reminders, recurrence=None, priority="normal"):
    return {
        "id": tid,
        "title": title,
        "start_local": start,
        "timezone": tz,
        "reminders": [{"id": i, "offset_min": o} for i, o in reminders],
        "recurrence": recurrence,
        "priority": priority,
    }


def cmp_build(tasks, cfg, hs, he):
    try:
        a = agent.build_schedule(tasks, cfg, hs, he)
        b = ref.build_schedule(tasks, cfg, hs, he)
        return rec_eq(a, b)
    except Exception:
        return False


def _run_script(mod, cfg, start_cursor, ops):
    store = MemStore()
    sink = ListSink()
    eng = mod.Engine(store, sink, cfg, start_cursor)
    delivered = []
    for op in ops:
        k = op[0]
        if k == "add":
            eng.add_task(op[1])
        elif k == "update":
            eng.update_task(op[1])
        elif k == "cancel":
            eng.cancel_task(op[1])
        elif k == "complete":
            eng.complete_occurrence(op[1], op[2])
        elif k == "snooze":
            eng.snooze(op[1], op[2], op[3], op[4], op[5])
        elif k == "advance":
            delivered += list(eng.advance_to(op[1]))
        elif k == "restart":
            eng = mod.Engine(store, sink, cfg, start_cursor)
        else:
            raise ValueError("bad op %r" % (k,))
    return delivered, sink.records


def cmp_engine(cfg, start_cursor, ops):
    try:
        da, sa = _run_script(agent, cfg, start_cursor, ops)
        db, sb = _run_script(ref, cfg, start_cursor, ops)
        return rec_eq(da, db) and rec_eq(sa, sb)
    except Exception:
        return False


def _tally(results):
    return sum(1 for r in results if r), len(results)


# ── components ──────────────────────────────────────────────────────────────
def c_basic():
    r = []
    r.append(cmp_build(
        [task("a", "Standup", "2026-01-15T09:00:00", "UTC", [("r10", 10), ("r0", 0)])],
        {}, E("2026-01-01T00:00:00", "UTC"), E("2026-02-01T00:00:00", "UTC")))
    r.append(cmp_build(
        [task("a", "Standup", "2026-01-15T09:00:00", "America/New_York", [("r30", 30), ("r0", 0)])],
        {}, E("2026-01-15T00:00:00", "America/New_York"), E("2026-01-16T00:00:00", "America/New_York")))
    # two tasks at the same instant -> ordered by (instant, task_id, reminder_id)
    r.append(cmp_build(
        [task("b", "B", "2026-01-15T09:05:00", "UTC", [("r0", 0)]),
         task("a", "A", "2026-01-15T09:05:00", "UTC", [("r0", 0)])],
        {}, E("2026-01-15T00:00:00", "UTC"), E("2026-01-16T00:00:00", "UTC")))
    # long lead (a day before) + a reminder that falls before horizon_start
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T09:00:00", "UTC", [("d1", 1440), ("r0", 0)])],
        {}, E("2026-01-14T12:00:00", "UTC"), E("2026-01-16T00:00:00", "UTC")))
    # positive-offset tz, no reminders -> empty
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T09:00:00", "Asia/Kolkata", [])],
        {}, E("2026-01-15T00:00:00", "Asia/Kolkata"), E("2026-01-16T00:00:00", "Asia/Kolkata")))
    return _tally(r)


def c_dst():
    r = []
    # NY spring-forward: daily 09:00 across 2026-03-08 (offset changes -5 -> -4)
    r.append(cmp_build(
        [task("a", "A", "2026-03-06T09:00:00", "America/New_York", [("r0", 0), ("r60", 60)],
              {"freq": "DAILY", "interval": 1, "count": 5})],
        {}, E("2026-03-05T00:00:00", "UTC"), E("2026-03-12T00:00:00", "UTC")))
    # NY nonexistent local time (02:30 on spring-forward day)
    r.append(cmp_build(
        [task("a", "A", "2026-03-08T02:30:00", "America/New_York", [("r0", 0)])],
        {}, E("2026-03-08T00:00:00", "UTC"), E("2026-03-08T12:00:00", "UTC")))
    # NY fall-back ambiguous local time (01:30 on 2026-11-01)
    r.append(cmp_build(
        [task("a", "A", "2026-11-01T01:30:00", "America/New_York", [("r0", 0)])],
        {}, E("2026-11-01T00:00:00", "UTC"), E("2026-11-01T12:00:00", "UTC")))
    # Europe/Berlin spring-forward 2026-03-29 (nonexistent 02:30)
    r.append(cmp_build(
        [task("a", "A", "2026-03-29T02:30:00", "Europe/Berlin", [("r0", 0)])],
        {}, E("2026-03-29T00:00:00", "UTC"), E("2026-03-29T12:00:00", "UTC")))
    # Southern hemisphere: Sydney across its April fall-back, daily
    r.append(cmp_build(
        [task("a", "A", "2026-04-04T08:00:00", "Australia/Sydney", [("r0", 0)],
              {"freq": "DAILY", "interval": 1, "count": 4})],
        {}, E("2026-04-03T00:00:00", "UTC"), E("2026-04-08T00:00:00", "UTC")))
    return _tally(r)


def c_daily():
    r = []
    r.append(cmp_build(
        [task("a", "A", "2026-05-01T09:00:00", "UTC", [("r0", 0)],
              {"freq": "DAILY", "interval": 1, "count": 5})],
        {}, E("2026-05-01T00:00:00", "UTC"), E("2026-05-20T00:00:00", "UTC")))
    r.append(cmp_build(
        [task("a", "A", "2026-05-01T09:00:00", "UTC", [("r0", 0)],
              {"freq": "DAILY", "interval": 3, "count": 4})],
        {}, E("2026-05-01T00:00:00", "UTC"), E("2026-05-31T00:00:00", "UTC")))
    r.append(cmp_build(
        [task("a", "A", "2026-05-01T09:00:00", "UTC", [("r0", 0)],
              {"freq": "DAILY", "interval": 1, "until_local": "2026-05-06T00:00:00"})],
        {}, E("2026-05-01T00:00:00", "UTC"), E("2026-05-31T00:00:00", "UTC")))
    # window narrower than series -> only occurrences inside the window
    r.append(cmp_build(
        [task("a", "A", "2026-05-01T09:00:00", "UTC", [("r0", 0)],
              {"freq": "DAILY", "interval": 1, "count": 30})],
        {}, E("2026-05-10T00:00:00", "UTC"), E("2026-05-13T00:00:00", "UTC")))
    return _tally(r)


def c_weekly():
    r = []
    # Mon/Wed/Fri, count 10 (2026-06-01 is a Monday)
    r.append(cmp_build(
        [task("a", "A", "2026-06-01T09:00:00", "UTC", [("r0", 0)],
              {"freq": "WEEKLY", "interval": 1, "byweekday": [0, 2, 4], "count": 10})],
        {}, E("2026-06-01T00:00:00", "UTC"), E("2026-08-01T00:00:00", "UTC")))
    # every 2 weeks, Tue/Thu
    r.append(cmp_build(
        [task("a", "A", "2026-06-02T18:30:00", "UTC", [("r0", 0)],
              {"freq": "WEEKLY", "interval": 2, "byweekday": [1, 3], "count": 8})],
        {}, E("2026-06-01T00:00:00", "UTC"), E("2026-09-01T00:00:00", "UTC")))
    # start weekday NOT in byweekday: first occurrence is the next listed day
    r.append(cmp_build(
        [task("a", "A", "2026-06-03T07:00:00", "UTC", [("r0", 0)],  # Wed start
              {"freq": "WEEKLY", "interval": 1, "byweekday": [0, 4], "count": 6})],  # Mon/Fri
        {}, E("2026-06-01T00:00:00", "UTC"), E("2026-07-15T00:00:00", "UTC")))
    # weekly with tz + DST + until
    r.append(cmp_build(
        [task("a", "A", "2026-10-05T09:00:00", "America/New_York", [("r30", 30)],
              {"freq": "WEEKLY", "interval": 1, "byweekday": [0], "until_local": "2026-11-30T00:00:00"})],
        {}, E("2026-10-01T00:00:00", "UTC"), E("2026-12-01T00:00:00", "UTC")))
    return _tally(r)


def c_quiet():
    ny = "America/New_York"
    defer = {"quiet_hours": {"start": "22:00", "end": "07:00", "tz": ny}, "quiet_policy": "defer"}
    supp = {"quiet_hours": {"start": "22:00", "end": "07:00", "tz": ny}, "quiet_policy": "suppress"}
    r = []
    # 23:30 reminder deferred to 07:00 next morning
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T23:30:00", ny, [("r0", 0)])],
        defer, E("2026-01-15T00:00:00", ny), E("2026-01-17T00:00:00", ny)))
    # urgent bypasses quiet hours
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T23:30:00", ny, [("r0", 0)], None, "urgent")],
        defer, E("2026-01-15T00:00:00", ny), E("2026-01-17T00:00:00", ny)))
    # suppress policy drops the nighttime reminder entirely
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T23:30:00", ny, [("r0", 0)])],
        supp, E("2026-01-15T00:00:00", ny), E("2026-01-17T00:00:00", ny)))
    # daytime reminder untouched
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T09:00:00", ny, [("r0", 0)])],
        defer, E("2026-01-15T00:00:00", ny), E("2026-01-16T00:00:00", ny)))
    # non-wrapping quiet window 13:00-14:00
    midday = {"quiet_hours": {"start": "13:00", "end": "14:00", "tz": ny}, "quiet_policy": "defer"}
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T13:30:00", ny, [("r0", 0)])],
        midday, E("2026-01-15T00:00:00", ny), E("2026-01-16T00:00:00", ny)))
    # early-morning (05:00) inside wrap window -> deferred to 07:00 same day
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T05:00:00", ny, [("r0", 0)])],
        defer, E("2026-01-14T00:00:00", ny), E("2026-01-16T00:00:00", ny)))
    return _tally(r)


def c_coalesce():
    ny = "America/New_York"
    defer = {"quiet_hours": {"start": "22:00", "end": "07:00", "tz": ny}, "quiet_policy": "defer"}
    r = []
    # two reminders at the same offset -> one notification (smallest reminder_id)
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T09:00:00", "UTC", [("b", 10), ("a", 10)])],
        {}, E("2026-01-15T00:00:00", "UTC"), E("2026-01-16T00:00:00", "UTC")))
    # two different-offset reminders both deferred to the same 07:00 boundary -> coalesce
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T23:30:00", ny, [("x", 0), ("y", 30)])],
        defer, E("2026-01-15T00:00:00", ny), E("2026-01-17T00:00:00", ny)))
    # two different tasks at the same instant do NOT coalesce
    r.append(cmp_build(
        [task("a", "A", "2026-01-15T09:00:00", "UTC", [("r0", 0)]),
         task("b", "B", "2026-01-15T09:00:00", "UTC", [("r0", 0)])],
        {}, E("2026-01-15T00:00:00", "UTC"), E("2026-01-16T00:00:00", "UTC")))
    return _tally(r)


def c_engine():
    r = []
    tA = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
              {"freq": "DAILY", "interval": 1, "count": 4})
    tB = task("b", "B", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
              {"freq": "DAILY", "interval": 1, "count": 4})
    sc = E("2026-02-02T00:00:00", "UTC")
    # deliver over several chunks; ordering across same-instant tasks must be stable
    ops = [("add", tA), ("add", tB),
           ("advance", E("2026-02-03T00:00:00", "UTC")),
           ("advance", E("2026-02-05T00:00:00", "UTC")),
           ("advance", E("2026-02-10T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops))
    # staleness: single big jump with a grace window drops old occurrences
    grace = {"catchup_grace_min": 60}
    ops2 = [("add", tA), ("advance", E("2026-02-05T09:30:00", "UTC"))]
    r.append(cmp_engine(grace, sc, ops2))
    # advancing backwards / to the same instant delivers nothing
    ops3 = [("add", tA),
            ("advance", E("2026-02-10T00:00:00", "UTC")),
            ("advance", E("2026-02-04T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops3))
    return _tally(r)


def c_restart():
    r = []
    t = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
             {"freq": "DAILY", "interval": 1, "count": 6})
    sc = E("2026-02-02T00:00:00", "UTC")
    ops = [("add", t),
           ("advance", E("2026-02-04T12:00:00", "UTC")),
           ("restart",),
           ("advance", E("2026-02-04T12:00:00", "UTC")),  # same instant -> nothing new
           ("advance", E("2026-02-10T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops))
    # add another task after restart; both known state and new task deliver
    t2 = task("b", "B", "2026-02-06T09:00:00", "UTC", [("r0", 0)])
    ops2 = [("add", t),
            ("advance", E("2026-02-03T12:00:00", "UTC")),
            ("restart",),
            ("add", t2),
            ("advance", E("2026-02-10T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops2))
    return _tally(r)


def c_mutate():
    r = []
    daily = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
                 {"freq": "DAILY", "interval": 1, "count": 8})
    sc = E("2026-02-02T00:00:00", "UTC")
    # cancel stops future deliveries but keeps already-delivered ones
    ops = [("add", daily),
           ("advance", E("2026-02-04T12:00:00", "UTC")),
           ("cancel", "a"),
           ("advance", E("2026-02-20T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops))
    # complete_occurrence removes only that occurrence's not-yet-fired reminders
    lead = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r", 60)],
                {"freq": "DAILY", "interval": 1, "count": 6})
    ops2 = [("add", lead),
            ("advance", E("2026-02-03T12:00:00", "UTC")),
            ("complete", "a", 3),
            ("advance", E("2026-02-20T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops2))
    # update_task changes the future; already-dispatched keys don't re-fire
    updated = task("a", "A2", "2026-02-02T15:00:00", "UTC", [("r0", 0)],
                   {"freq": "DAILY", "interval": 1, "count": 8})
    ops3 = [("add", daily),
            ("advance", E("2026-02-04T12:00:00", "UTC")),
            ("update", updated),
            ("advance", E("2026-02-20T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops3))
    return _tally(r)


def c_snooze():
    r = []
    one = task("a", "A", "2026-02-05T09:00:00", "UTC", [("r", 0)])
    sc = E("2026-02-02T00:00:00", "UTC")
    # snooze before it fires -> delivered later, once, snoozed=True
    ops = [("add", one),
           ("advance", E("2026-02-04T00:00:00", "UTC")),
           ("snooze", "a", 0, "r", 120, E("2026-02-04T00:00:00", "UTC")),
           ("advance", E("2026-02-06T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops))
    # snooze after it already fired -> no-op
    ops2 = [("add", one),
            ("advance", E("2026-02-06T00:00:00", "UTC")),
            ("snooze", "a", 0, "r", 120, E("2026-02-06T00:00:00", "UTC")),
            ("advance", E("2026-02-08T00:00:00", "UTC"))]
    r.append(cmp_engine({}, sc, ops2))
    return _tally(r)


def _rand_task(rng, i):
    tz = rng.choice(["UTC", "America/New_York", "Europe/Berlin", "Australia/Sydney", "Asia/Kolkata"])
    month = rng.choice([1, 3, 4, 7, 10, 11])
    day = rng.randint(1, 27)
    hh = rng.randint(0, 23)
    mm = rng.choice([0, 15, 30, 45])
    start = "2026-%02d-%02dT%02d:%02d:00" % (month, day, hh, mm)
    reminders = [("r%d" % j, rng.choice([0, 5, 10, 15, 30, 60, 120, 1440]))
                 for j in range(rng.randint(1, 3))]
    kind = rng.choice(["none", "daily", "weekly"])
    rec = None
    if kind == "daily":
        rec = {"freq": "DAILY", "interval": rng.choice([1, 2, 3]), "count": rng.randint(2, 8)}
    elif kind == "weekly":
        bd = sorted(rng.sample([0, 1, 2, 3, 4, 5, 6], rng.randint(1, 3)))
        rec = {"freq": "WEEKLY", "interval": rng.choice([1, 2]), "byweekday": bd, "count": rng.randint(2, 10)}
    prio = rng.choice(["normal", "normal", "urgent"])
    return task("t%d" % i, "T%d" % i, start, tz, reminders, rec, prio)


def _rand_cfg(rng):
    cfg = {}
    if rng.random() < 0.6:
        cfg["quiet_hours"] = {
            "start": rng.choice(["22:00", "23:00", "21:30"]),
            "end": rng.choice(["06:00", "07:00", "08:00"]),
            "tz": rng.choice(["America/New_York", "UTC", "Europe/Berlin"]),
        }
        cfg["quiet_policy"] = rng.choice(["defer", "suppress"])
    if rng.random() < 0.4:
        cfg["catchup_grace_min"] = rng.choice([60, 120, 240])
    return cfg


def c_random():
    rng = random.Random(20260815)
    hs = E("2026-01-01T00:00:00", "UTC")
    he = E("2026-12-31T00:00:00", "UTC")
    r = []
    # build_schedule agreement on random scenarios
    for _ in range(10):
        tasks = [_rand_task(rng, i) for i in range(rng.randint(1, 4))]
        cfg = _rand_cfg(rng)
        r.append(cmp_build(tasks, cfg, hs, he))
    # engine drive agreement on random scenarios
    for _ in range(5):
        tasks = [_rand_task(rng, i) for i in range(rng.randint(1, 3))]
        cfg = _rand_cfg(rng)
        pts = sorted(rng.sample(range(hs, he, 3600 * 6), rng.randint(3, 6)))
        ops = [("add", t) for t in tasks] + [("advance", p) for p in pts]
        r.append(cmp_engine(cfg, hs, ops))
    return _tally(r)


COMPONENTS = [
    ("basic", 0.10, c_basic),
    ("dst", 0.12, c_dst),
    ("recurrence_daily", 0.08, c_daily),
    ("recurrence_weekly", 0.12, c_weekly),
    ("quiet_hours", 0.12, c_quiet),
    ("coalesce", 0.08, c_coalesce),
    ("engine_order_stale", 0.10, c_engine),
    ("restart_idempotent", 0.10, c_restart),
    ("cancel_complete_update", 0.08, c_mutate),
    ("snooze", 0.04, c_snooze),
    ("randomized", 0.06, c_random),
]


def main():
    report = {}
    score = 0.0
    for name, weight, fn in COMPONENTS:
        try:
            passed, total = fn()
        except Exception:
            passed, total = 0, 1
        frac = (passed / total) if total else 0.0
        contrib = frac * weight
        score += contrib
        report[name] = {
            "passed": passed,
            "total": total,
            "weight": weight,
            "score": round(contrib, 6),
        }
    score = round(score, 6)

    print(json.dumps(report, indent=2))
    print("SCORE: %.6f" % score)
    print("ODYSSEY_SCORE=%.6f" % score)
    print("RESULT: %s" % ("PASS" if score >= THRESHOLD else "FAIL"))

    payload = {"score": score, "threshold": THRESHOLD, "components": report}
    for path in (os.path.join(THIS, "report.json"), os.path.join(APP, "report.json")):
        try:
            with open(path, "w") as f:
                json.dump(payload, f, indent=2)
        except Exception:
            pass

    # Odyssey reads the reward back from a file the verifier must write on EVERY
    # trial (reward.txt / reward.json). This is the required output; the SCORE line
    # above is only a human-readable echo.
    _write_reward(score)

    # A successfully-computed score -- even 0.0 for the nop / empty solution -- means
    # the verifier RAN CORRECTLY, so exit 0. A low score is a valid result, never a
    # non-zero exit; non-zero is reserved for a genuine grader crash (see the wrapper).
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        import traceback
        traceback.print_exc()
        # Even on an unexpected grader error, still leave a reward file (0.0) so the
        # trial produces one, and exit cleanly -- the 0.0 reward IS the fail signal.
        _write_reward(0.0)
        print("SCORE: 0.0")
        print("ODYSSEY_SCORE=0.000000")
        sys.exit(0)
