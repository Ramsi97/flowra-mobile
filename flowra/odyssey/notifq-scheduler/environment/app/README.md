# notifq — notification scheduling engine (task workspace)

Implement the `notifq` package in this directory so it satisfies the task
specification (see the task instructions / `instruction.md`).

## What you deliver

A Python package importable as `notifq`, exposing:

```python
build_schedule(tasks, config, horizon_start, horizon_end) -> list[dict]

class Engine:
    def __init__(self, store, sink, config, start_cursor=0): ...
    def add_task(self, task): ...
    def update_task(self, task): ...
    def cancel_task(self, task_id): ...
    def complete_occurrence(self, task_id, occ_index): ...
    def snooze(self, task_id, occ_index, reminder_id, delta_min, now): ...
    def advance_to(self, now) -> list[dict]: ...
```

A starting stub is in `notifq/__init__.py`. You may split the package into
several modules as long as those names remain importable from `notifq`.

## Rules

- **Standard library only.** No third-party packages, no network.
- **Never read the wall clock.** All time enters through arguments as integer
  epoch seconds (UTC). Do not call `time.time()`, `datetime.now()`, etc.
- `zoneinfo` is available offline (tzdata is installed in the image).

## Self-check

```bash
python3 public_tests/test_public.py
```

These public tests are a small subset of the automated grader. Passing them all
is necessary but not sufficient — the hidden suite covers many more timezone/DST
dates, recurrence shapes, quiet-hours boundaries, coalescing, staleness,
persistence/restart, and randomized scenarios.
