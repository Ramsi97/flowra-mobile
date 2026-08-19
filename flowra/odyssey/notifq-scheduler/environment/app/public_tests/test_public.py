#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Public self-check tests for notifq.

These are a SUBSET of what the sealed grader checks. Passing every test here is
necessary but NOT sufficient for full marks: the hidden suite adds many more
timezone/DST dates, recurrence shapes, quiet-hours boundaries, coalescing,
staleness, persistence and randomized scenarios.

Run:  python3 public_tests/test_public.py
"""
import os
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import notifq  # noqa: E402


def epoch(iso, tz):
    return int(datetime.fromisoformat(iso).replace(tzinfo=ZoneInfo(tz)).timestamp())


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


def task(tid, title, start, tz, reminders, recurrence=None, priority="normal"):
    return {"id": tid, "title": title, "start_local": start, "timezone": tz,
            "reminders": [{"id": i, "offset_min": o} for i, o in reminders],
            "recurrence": recurrence, "priority": priority}


TESTS = []


def test(fn):
    TESTS.append(fn)
    return fn


@test
def one_shot_utc():
    t = task("a", "Standup", "2026-01-15T09:00:00", "UTC", [("r10", 10), ("r0", 0)])
    got = notifq.build_schedule([t], {}, epoch("2026-01-01T00:00:00", "UTC"),
                                epoch("2026-02-01T00:00:00", "UTC"))
    base = epoch("2026-01-15T09:00:00", "UTC")
    assert [r["instant"] for r in got] == [base - 600, base], got
    assert [r["reminder_id"] for r in got] == ["r10", "r0"], got
    for r in got:
        assert r["task_id"] == "a" and r["title"] == "Standup"
        assert r["priority"] == "normal" and r["deferred"] is False and r["snoozed"] is False


@test
def sorted_by_task_at_same_instant():
    inst = "2026-01-15T09:05:00"
    got = notifq.build_schedule(
        [task("b", "B", inst, "UTC", [("r0", 0)]), task("a", "A", inst, "UTC", [("r0", 0)])],
        {}, epoch("2026-01-15T00:00:00", "UTC"), epoch("2026-01-16T00:00:00", "UTC"))
    assert [r["task_id"] for r in got] == ["a", "b"], got


@test
def daily_count():
    t = task("a", "A", "2026-05-01T09:00:00", "UTC", [("r0", 0)],
             {"freq": "DAILY", "interval": 1, "count": 3})
    got = notifq.build_schedule([t], {}, epoch("2026-05-01T00:00:00", "UTC"),
                                epoch("2026-05-31T00:00:00", "UTC"))
    assert len(got) == 3, got
    assert [r["occ_index"] for r in got] == [0, 1, 2], got
    assert got == sorted(got, key=lambda r: r["instant"])


@test
def quiet_defer_to_morning():
    ny = "America/New_York"
    cfg = {"quiet_hours": {"start": "22:00", "end": "07:00", "tz": ny}, "quiet_policy": "defer"}
    t = task("a", "A", "2026-01-15T23:30:00", ny, [("r0", 0)])
    got = notifq.build_schedule([t], cfg, epoch("2026-01-15T00:00:00", ny),
                                epoch("2026-01-17T00:00:00", ny))
    assert len(got) == 1 and got[0]["deferred"] is True, got
    local = datetime.fromtimestamp(got[0]["instant"], ZoneInfo(ny))
    assert (local.hour, local.minute) == (7, 0), local  # deferred to quiet-hours end


@test
def urgent_bypasses_quiet():
    ny = "America/New_York"
    cfg = {"quiet_hours": {"start": "22:00", "end": "07:00", "tz": ny}, "quiet_policy": "defer"}
    t = task("a", "A", "2026-01-15T23:30:00", ny, [("r0", 0)], None, "urgent")
    got = notifq.build_schedule([t], cfg, epoch("2026-01-15T00:00:00", ny),
                                epoch("2026-01-17T00:00:00", ny))
    assert len(got) == 1 and got[0]["deferred"] is False, got
    assert got[0]["instant"] == epoch("2026-01-15T23:30:00", ny), got


@test
def coalesce_same_instant_one_task():
    t = task("a", "A", "2026-01-15T09:00:00", "UTC", [("b", 10), ("a", 10)])
    got = notifq.build_schedule([t], {}, epoch("2026-01-15T00:00:00", "UTC"),
                                epoch("2026-01-16T00:00:00", "UTC"))
    assert len(got) == 1 and got[0]["reminder_id"] == "a", got


@test
def engine_matches_build_schedule():
    t = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
             {"freq": "DAILY", "interval": 1, "count": 5})
    sc = epoch("2026-02-02T00:00:00", "UTC")
    he = epoch("2026-02-20T00:00:00", "UTC")
    store, sink = MemStore(), ListSink()
    eng = notifq.Engine(store, sink, {}, sc)
    eng.add_task(t)
    delivered = []
    for p in (epoch("2026-02-03T12:00:00", "UTC"), epoch("2026-02-05T00:00:00", "UTC"), he):
        delivered += list(eng.advance_to(p))
    expected = notifq.build_schedule([t], {}, sc + 1, he)
    assert [(r["instant"], r["reminder_id"]) for r in delivered] == \
           [(r["instant"], r["reminder_id"]) for r in expected], (delivered, expected)


@test
def restart_no_double_delivery():
    t = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
             {"freq": "DAILY", "interval": 1, "count": 6})
    sc = epoch("2026-02-02T00:00:00", "UTC")
    store, sink = MemStore(), ListSink()
    eng = notifq.Engine(store, sink, {}, sc)
    eng.add_task(t)
    eng.advance_to(epoch("2026-02-04T12:00:00", "UTC"))
    n_before = len(sink.records)
    eng2 = notifq.Engine(store, sink, {}, sc)          # simulated restart, same store
    assert eng2.advance_to(epoch("2026-02-04T12:00:00", "UTC")) == []  # nothing new
    eng2.advance_to(epoch("2026-02-20T00:00:00", "UTC"))
    keys = [(r["task_id"], r["occ_index"], r["reminder_id"], r["instant"]) for r in sink.records]
    assert len(keys) == len(set(keys)), keys       # no duplicates across restart
    assert len(sink.records) > n_before


@test
def cancel_stops_future():
    t = task("a", "A", "2026-02-02T09:00:00", "UTC", [("r0", 0)],
             {"freq": "DAILY", "interval": 1, "count": 8})
    sc = epoch("2026-02-02T00:00:00", "UTC")
    store, sink = MemStore(), ListSink()
    eng = notifq.Engine(store, sink, {}, sc)
    eng.add_task(t)
    eng.advance_to(epoch("2026-02-04T12:00:00", "UTC"))
    mid = len(sink.records)
    eng.cancel_task("a")
    eng.advance_to(epoch("2026-02-20T00:00:00", "UTC"))
    assert len(sink.records) == mid, sink.records  # no further deliveries


def main():
    passed = 0
    for fn in TESTS:
        try:
            fn()
            print("PASS %s" % fn.__name__)
            passed += 1
        except NotImplementedError:
            print("TODO %s (not implemented yet)" % fn.__name__)
        except AssertionError as e:
            print("FAIL %s: %s" % (fn.__name__, e))
        except Exception as e:
            print("ERROR %s: %r" % (fn.__name__, e))
    print("\n%d/%d public tests passed" % (passed, len(TESTS)))
    sys.exit(0 if passed == len(TESTS) else 1)


if __name__ == "__main__":
    main()
