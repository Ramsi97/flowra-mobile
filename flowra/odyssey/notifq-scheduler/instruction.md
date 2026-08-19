# Build `notifq`: a notification scheduling engine for scheduled tasks

## Background

Productivity, calendar, and reminder apps all contain the same unglamorous but
surprisingly subtle subsystem: the thing that decides **which notification fires,
and exactly when**, for a set of scheduled tasks. Getting it right means handling
lead-time reminders ("ping me 10 minutes before"), repeating tasks, timezones and
daylight-saving transitions, "do not disturb" quiet hours, de-duplication so the
user isn't buzzed twice at once, and — critically — surviving a process restart
without either re-sending old notifications or dropping ones that came due.

Your job is to implement that engine as a self-contained Python package, `notifq`.

Everything is driven by an **injected clock**: time is passed to you as integer
epoch seconds (UTC). You never read the wall clock. This makes the whole system
deterministic and testable.

## Deliverable

A package importable as `notifq` (start from the stub in `notifq/__init__.py`;
you may split it into multiple modules) exposing exactly these names:

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

### Constraints

- **Python standard library only.** No third-party packages. `zoneinfo` is
  available offline.
- **No wall-clock reads.** Do not call `time.time()`, `datetime.now()`,
  `datetime.today()`, `datetime.utcnow()`, etc. Every time value you need is
  provided as an argument. (Reading the clock makes grading non-deterministic and
  will fail hidden tests.)
- **No network, no threads, no real sleeping.**

## Data model

All absolute instants are **integer epoch seconds, UTC**.

Local times in task definitions are **naive ISO-8601** strings
`"YYYY-MM-DDTHH:MM:SS"` interpreted in the task's IANA `timezone`.

### Task

```python
{
  "id": "t1",                        # unique string id
  "title": "Standup",
  "start_local": "2026-03-08T09:00:00",
  "timezone": "America/New_York",    # IANA tz name
  "reminders": [                     # zero or more; each fires its own notification
      {"id": "r0", "offset_min": 10},   # 10 minutes BEFORE the occurrence
      {"id": "r1", "offset_min": 0}     # at the occurrence
  ],
  "recurrence": null,                # null = one-shot; else see below
  "priority": "normal"               # "normal" | "urgent"
}
```

`offset_min` is a non-negative integer number of minutes **before** the
occurrence. `reminder.id` is unique within a task. `priority` defaults to
`"normal"` if absent.

### Recurrence (optional)

```python
# Daily, every `interval` days:
{"freq": "DAILY", "interval": 1, "count": 10}
{"freq": "DAILY", "interval": 2, "until_local": "2026-06-01T00:00:00"}

# Weekly on given weekdays (0=Mon .. 6=Sun), every `interval` weeks:
{"freq": "WEEKLY", "interval": 1, "byweekday": [0, 2, 4], "count": 12}
```

- `interval` defaults to 1.
- Termination is by `count` (max number of occurrences in the whole series),
  or `until_local` (inclusive upper bound on the occurrence's local datetime),
  or neither (unbounded — only meaningful because callers always bound by a
  finite horizon / `now`).

### Config

```python
{
  "quiet_hours": {"start": "22:00", "end": "07:00", "tz": "America/New_York"},  # optional
  "quiet_policy": "defer",       # "defer" (default) | "suppress"
  "catchup_grace_min": 120       # optional; omitted => no staleness dropping
}
```

Unknown keys are ignored. Any field may be absent.

### Notification record (output)

Every notification — from `build_schedule` and from `Engine.advance_to` — is a
dict with **exactly** these keys:

```python
{
  "instant": 1772985000,   # int epoch seconds (UTC) it fires at
  "task_id": "t1",
  "occ_index": 0,          # which occurrence of the series (0-based, global)
  "reminder_id": "r0",
  "title": "Standup",
  "priority": "normal",
  "deferred": false,       # true iff moved by quiet-hours deferral
  "snoozed": false         # true iff produced by snooze(); always false from build_schedule
}
```

## Semantics — the precise rules

### 1. Local → UTC conversion (timezone & DST)

Convert a naive local datetime to epoch seconds using `zoneinfo` with **fold=0**
semantics (i.e. `datetime.replace(tzinfo=ZoneInfo(tz), fold=0).timestamp()`):

- **Nonexistent** local times (spring-forward gap) resolve using the offset in
  effect *before* the transition.
- **Ambiguous** local times (fall-back overlap) resolve to the *earlier* instant.

Worked examples (America/New_York; EST = UTC−5, EDT = UTC−4):

- `2026-01-15T09:00:00` (winter, EST) → `14:00:00Z`.
- `2026-07-15T09:00:00` (summer, EDT) → `13:00:00Z`.
- Spring forward is `2026-03-08` (02:00→03:00). The nonexistent `02:30`
  resolves via EST → `07:30:00Z`.
- Fall back is `2026-11-01` (02:00→01:00). The ambiguous `01:30` resolves to the
  earlier (EDT) instant → `05:30:00Z`.

**Recurrence is expanded in local wall-clock time**, so a "daily 09:00 local"
reminder keeps firing at 09:00 *local* across a DST change — meaning its absolute
epoch shifts by an hour. Do not compute one fixed UTC offset and reuse it.

### 2. Occurrences and `occ_index`

- One-shot (`recurrence` null): a single occurrence at `start_local`, `occ_index = 0`.
- `DAILY`: occurrences at `start_local + n*interval` days (n = 0, 1, 2, …), same
  wall-clock time each day. `occ_index = n`.
- `WEEKLY`: let `M` = the Monday of `start_local`'s week. For week blocks
  `j = 0, interval, 2*interval, …`, and each weekday `d` in `byweekday` (ascending),
  the occurrence date is `M + 7*j days + d days` at `start_local`'s time-of-day.
  Drop any candidate whose **date is earlier than `start_local`'s date** (so the
  first partial week starts at the task's start). `occ_index` is assigned in
  ascending occurrence order across the whole series (0, 1, 2, …).

Occurrences are terminated by `count` / `until_local` as defined above.

### 3. Reminder fire instants

For an occurrence at epoch `occ_epoch` and a reminder with `offset_min = m`, the
**raw** fire instant is `occ_epoch - m*60` (subtract in absolute time).

### 4. Quiet hours

`quiet_hours` defines a daily window `[start, end)` in local time `tz`:

- `start < end`: the window is that same-day interval.
- `start > end`: the window **wraps midnight** (e.g. 22:00–07:00 covers evening
  and early morning).
- `start == end`: empty (no quiet hours).

An instant is "in quiet hours" if its local time-of-day in `tz` lies in the
window. For a reminder whose raw instant is in quiet hours:

- **`priority == "urgent"`** → never affected (fires at the raw instant,
  `deferred=false`).
- **`quiet_policy == "suppress"`** → the notification is dropped entirely.
- **`quiet_policy == "defer"`** (default) → the effective instant becomes the
  next time the local clock reaches `end` at or after the raw instant, and the
  record's `deferred` is `true`.

Reminders not in quiet hours keep their raw instant with `deferred=false`.

### 5. Coalescing (de-duplication)

After computing effective instants, **within a single task** at most one
notification may exist per distinct effective instant. If several of a task's
reminders resolve to the *same* effective instant, keep exactly one — the one
with the smallest `offset_min`, ties broken by smallest `reminder_id`
(lexicographic), then smallest `occ_index` — and drop the rest.

Notifications from **different tasks** at the same instant are **not** coalesced.

### 6. `build_schedule(tasks, config, horizon_start, horizon_end)`

Return every surviving notification whose effective `instant` is in the inclusive
window `[horizon_start, horizon_end]`, sorted by `(instant, task_id, reminder_id)`.
`snoozed` is always `false` here. This is a pure function of its inputs (no clock,
no persistence).

### 7. `Engine` — delivery over time

The engine drives delivery against an injected `store`, `sink`, and clock.

**`store`** is a persistence handle with methods:

```python
store.get(key) -> str | None
store.set(key, value)      # value is a str
store.delete(key)
store.items() -> iterable[(key, value)]
```

You choose what/how to serialize; the grader only checks *behavior*. The engine
must persist enough that a **new `Engine` constructed over the same store**
resumes correctly (known tasks, delivery cursor, and which notifications were
already sent).

**`sink`** has `sink.deliver(record)` — call it once per delivered notification,
in order.

**`start_cursor`** is the initial "already processed up to" instant, used only
when the store has no saved state.

**`advance_to(now)`** processes time forward to `now` (epoch seconds) and returns
the list of records delivered by this call (also pushed to `sink`, in the same
order):

1. If `now <= cursor`, do nothing and return `[]`.
2. Consider every notification (per rules 1–5, for all current tasks) whose
   effective instant is in `(cursor, now]`, plus any pending snoozes (rule 9).
3. Skip any whose `(task_id, occ_index, reminder_id)` was already delivered
   (idempotency) and any occurrence removed by cancel/complete (rule 8).
4. Process in ascending `(instant, task_id, reminder_id)` order. For each, if
   `catchup_grace_min` is set and the instant is older than `now - grace`, the
   notification is **stale**: mark it consumed (so it never fires later) but do
   **not** deliver it. Otherwise deliver it.
5. Set `cursor = now`, persist, and return the delivered records.

A notification is delivered **at most once** over the engine's lifetime, across
restarts.

### 8. Mutations

- `add_task(task)` / `update_task(task)`: register (or replace, by `id`) a task
  and persist. Already-delivered notifications never re-fire; future ones follow
  the new definition.
- `cancel_task(task_id)`: the task's not-yet-delivered notifications never fire.
  Already-delivered ones are unaffected.
- `complete_occurrence(task_id, occ_index)`: the not-yet-delivered reminders of
  *that occurrence only* never fire. Other occurrences are unaffected.

### 9. Snooze

`snooze(task_id, occ_index, reminder_id, delta_min, now)`:

- If that notification key was already delivered, it's a **no-op**.
- Otherwise the original (task_id, occ_index, reminder_id) notification is
  replaced by a single delivery at `now + delta_min*60`. Quiet hours do **not**
  apply to a snoozed delivery (`deferred=false`); its record has `snoozed=true`.
  It fires once, on the `advance_to` that reaches its new instant, and is subject
  to the same idempotency guarantee.

## How you're graded

An automated verifier imports your `notifq` and scores it across weighted
components: basic scheduling, DST correctness, daily & weekly recurrence,
quiet-hours (defer/suppress/urgent), coalescing, engine ordering & staleness,
restart/persistence idempotency, cancel/complete/update, snooze, and a batch of
randomized scenarios. Partial credit is awarded per component. The visible tests
in `public_tests/` are a small, non-exhaustive subset — the graded suite adds
many more timezone/DST dates, recurrence shapes, boundary conditions, and
seeded-random cases.

Aim for exact, spec-faithful behavior: records are compared field-for-field and
in order.
