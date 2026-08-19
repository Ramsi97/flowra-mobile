# Odyssey submission draft — `notifq-notification-scheduler`

Everything you need to (a) fill in the Odyssey draft form and (b) build the
upload ZIP. This task tests whether an agent can build a **notification system
for scheduled tasks**: the scheduling/dispatch core, graded deterministically
and fully offline.

> Design note: it is implemented as a standalone **Python** engine rather than in
> Flutter/Dart. Odyssey requires offline, deterministic, sealed grading, and the
> gradable essence of a "notification system" is the scheduling/dispatch logic
> (lead-time reminders, recurrence, timezone/DST, quiet hours, idempotent delivery
> across restarts) — none of which can be graded through a phone's OS push stack.
> All time is injected as integers so the verifier never touches a wall clock.

---

## Draft form fields

**Title:** notifq — notification scheduling engine for scheduled tasks

**Collection family:** Library clone
*(You hand the agent a precise API spec for a self-contained scheduler/notifier
module and grade to spec. If the platform pushes toward it, "Product clone" is a
defensible alternative — it's a working slice of a reminders/calendar backend.)*

**Task family:** feature_development

**Verifier family:** programmatic

**One-line summary:**
Implement a deterministic notification-scheduling engine: lead-time reminders,
daily/weekly recurrence, timezone/DST-correct firing, quiet-hours defer/suppress,
coalescing, and idempotent delivery that survives process restarts.

**Objective (long):**
Build a Python package `notifq` that computes and dispatches notifications for a
set of scheduled tasks. It must expose a pure `build_schedule(...)` that returns
the deterministic delivery schedule over a time window, and a stateful `Engine`
driven by an injected clock (`advance_to(now)`), sink, and persistent store. The
engine must handle multiple lead-time reminders per task, DAILY/WEEKLY recurrence
(interval, count, until, byweekday), DST-correct local→UTC conversion (recurrence
expanded in local wall time; fold=0 semantics), quiet-hours suppression or
deferral with an urgent bypass, coalescing of same-instant reminders within a
task, staleness dropping via a catch-up grace, cancel/complete/update mutations,
snooze, and — critically — idempotent delivery that survives a restart (a new
Engine over the same store neither re-sends past notifications nor drops due
ones). Standard library only; no wall-clock reads; fully offline.

**Verification strategy:**
A sealed programmatic verifier (`tests/test.sh` → `tests/grade.py`) imports the
agent's `notifq` and grades it against an independent reference implementation
(`tests/_ref_notifq.py`, sealed) across weighted components, with partial credit:

| Component | Weight | Checks |
|---|---|---|
| basic | 0.10 | one-shot + multi-reminder ordering, tz, empty reminders |
| dst | 0.12 | spring-forward/fall-back, nonexistent/ambiguous local times, recurrence across DST, southern hemisphere |
| recurrence_daily | 0.08 | interval, count, until, window subset |
| recurrence_weekly | 0.12 | byweekday, interval, start-not-in-byday, occ_index ordering |
| quiet_hours | 0.12 | defer/suppress/urgent, wrap-midnight vs same-day windows, boundary |
| coalesce | 0.08 | same-instant dedup + tiebreak; different tasks not coalesced |
| engine_order_stale | 0.10 | cross-task ordering, staleness grace, no-op backward advance |
| restart_idempotent | 0.10 | persistence across a simulated restart, no double-send, tasks survive |
| cancel_complete_update | 0.08 | future pruning; past deliveries preserved |
| snooze | 0.04 | reschedule once; no-op after delivery |
| randomized | 0.06 | seeded-random tasks/configs; agent vs reference on build + engine drive |

Multi-channel by construction: results are checked both via the pure
`build_schedule` and via the stateful `Engine`, and the two must agree
(consistency), plus persistence/idempotency and mutation semantics are exercised
independently. The verifier emits `SCORE: <float 0..1>` (and `ODYSSEY_SCORE=`),
writes `report.json`, and exits 0 whenever it produced a score (pass or fail);
the harness derives pass/fail by comparing the parsed SCORE to `pass_threshold`
(0.70). A non-zero exit (2) is reserved for a genuine grader crash.
Reference solution → 1.0; untouched stub → 0.0.

**Visible vs hidden split:**
Visible (`/app/public_tests/test_public.py`): ~9 checks covering the easy path
plus invariants (build↔engine consistency, restart idempotency, cancel). They
compute only atomic/definitional expected values and never implement recurrence,
quiet-hours, coalescing, or engine logic — so they cannot be copied to pass the
graded suite. Hidden (in `tests/`): the full weighted suite above, including
many more DST dates, recurrence shapes, quiet-hours boundaries, and seeded-random
scenarios whose expected outputs are computed at grade time by the reference.

**Anticipated exploits / how they're defeated:**
- *Hard-coding public outputs* — hidden suite uses different fixed cases plus
  seeded-random scenarios; expected values computed at runtime by a sealed
  reference, not stored.
- *Reading the answer* — the reference and all hidden scenarios live only in
  sealed `tests/`, never in `/app`.
- *Fixed UTC offset instead of real tz math* — DST component (recurrence across
  spring-forward/fall-back, nonexistent/ambiguous times) diverges immediately.
- *Expanding recurrence in absolute time* — daily/weekly-across-DST cases catch
  the drift (occurrences must keep local wall-clock time).
- *Skipping coalescing / mis-tiebreak* — dedicated component with exact tiebreak.
- *Re-sending after restart or dropping due items* — persistence/idempotency
  component with a simulated restart over the same store.
- *Gaming a proxy metric* — grading is exact field-for-field record match + order;
  there is no proxy to game.
- *Wall-clock / nondeterminism* — all time is injected; the verifier never reads
  the clock, so runs are reproducible.

**Difficulty justification (hard, but reference-solvable):**
A single frontier attempt tends to miss at least one of: fold=0 semantics for
nonexistent/ambiguous local times; expanding recurrence in local (not absolute)
time so 09:00-local holds across DST; subtracting reminder leads in absolute time;
the weekly Monday-anchored byweekday alignment and global `occ_index`; deferring
to the *next local end boundary* (itself DST-aware); the coalescing tiebreak;
"stale ⇒ consume but don't deliver"; and idempotent persistence so a restart
neither double-sends nor drops. The reference is ~230 lines of standard library,
so it is clearly solvable; the difficulty is in the interacting edge cases.

**Novelty / realism:** This is the notification core of any reminders/calendar/
productivity backend (Google Calendar alerts, Todoist reminders, etc.) — realistic,
and not a standard published kata.

---

## Resource / runtime settings (task.toml)

- Environment build network: `open` (build installs tzdata; nothing needed at
  run time). Agent network: `none`. Verifier network: `none`.
- CPU 2000 millis (2 cores), memory 4096 MB, storage 8192 MB, GPUs 0 (all within
  the 8 CPU / 65536 MB / 40960 MB sandbox budget).
- Agent timeout: 14400 s (4h, matches the expert estimate). Verifier timeout: 1200 s
  (the verifier actually runs in well under a second).

---

## Bundle layout (what gets zipped)

```
notifq-scheduler/
├── task.toml
├── instruction.md
├── environment/
│   ├── Dockerfile
│   └── app/                      # copied to /app in the image
│       ├── notifq/__init__.py    # stub the agent fills in (nop = score 0)
│       ├── public_tests/test_public.py
│       └── README.md
├── tests/                        # SEALED verifier
│   ├── test.sh                   # entrypoint
│   ├── grade.py                  # weighted grader
│   └── _ref_notifq.py            # independent reference (ground truth)
└── solution/
    └── solve.sh                  # oracle: installs the reference into /app
```

## Build the ZIP

From `odyssey/notifq-scheduler/`:

```bash
cd odyssey/notifq-scheduler
zip -r ../notifq-scheduler.zip . -x '*/__pycache__/*' '*.pyc'
```

Upload `notifq-scheduler.zip` as the quarantined bundle after creating the draft.

## Validate locally before uploading

```bash
BASE="$(pwd)"; TMP=$(mktemp -d)
cp -r "$BASE/environment/app" "$TMP/stub"      # untouched stub
cp -r "$BASE/environment/app" "$TMP/ref"
cp "$BASE/tests/_ref_notifq.py" "$TMP/ref/notifq/__init__.py"
python3 tests/grade.py "$TMP/stub"   # expect SCORE: 0.000000
python3 tests/grade.py "$TMP/ref"    # expect SCORE: 1.000000
( cd "$TMP/ref" && python3 public_tests/test_public.py )   # all public tests pass
```

To reproduce Odyssey's **"Oracle & nop"** stage exactly (build the real image, then
check BOTH the score and the verifier's exit code):

```bash
bash odyssey/notifq-scheduler/validate_docker.sh
# BUILD ok | ORACLE SCORE ~1.0 PASS exit 0 | NOP SCORE ~0.0 FAIL exit 0
```

Verifier output contract (what the harness actually consumes): every trial must
leave a **reward file at `/logs/verifier/reward.txt`** (a bare number in `[0,1]`).
`tests/test.sh` does `mkdir -p /logs/verifier` and writes a `0` floor, then `grade.py`
overwrites `/logs/verifier/reward.txt` with the real weighted score (and also writes
`/logs/verifier/reward.json` = `{"reward": <float>}`, plus a few fallback locations).
The `SCORE:` stdout line is only a human-readable echo, and the exit code is secondary
(always 0). This path — confirmed against a peer's passing bundle whose `test.sh` states
*"must write /logs/verifier/reward.txt"* — is the fix for attempt 2's
*"verifier completed without writing a reward file."* (Attempt 1 was chasing the exit
code, which turned out not to be the signal.)

---

## Submission form — every field, 1:1

**Title:** notifq — notification scheduling engine for scheduled tasks

**Working slug:** `notifq-scheduler`

**Collection family:** Library clone
**Task family:** feature development
**Verifier family:** programmatic
**Expert time estimate (hours):** 4

**Objective:** *(see the Objective block above)*

**Motivation:**
Every calendar, reminder, and productivity backend contains the same unglamorous
core: the component that decides *which* notification fires and *exactly when*. It
looks trivial but concentrates a cluster of correctness hazards that are famously
easy to get subtly wrong — daylight-saving transitions, recurrence that must be
expanded in local wall-clock time, quiet-hours / do-not-disturb handling,
de-duplication so a user isn't buzzed twice at once, staleness after the device was
off, and — above all — crash/restart idempotency so a process restart never
re-sends old alerts or drops due ones. These bugs are hard to catch by eye and
rarely covered by casual tests, which is exactly why this is a good probe of a
frontier coding agent: doing well requires holding many interacting edge cases in
mind at once and implementing precise, spec-faithful behavior rather than
plausible-looking code. The domain is realistic (it mirrors Google Calendar alerts,
Todoist/Things reminders, cron-like schedulers) yet small and pure enough to grade
deterministically and fully offline.

**Environment summary:**
A single Docker image built `FROM python:3.11-bookworm`. Python **standard library
only** — no third-party packages, no network, no background services, no database.
`tzdata` is installed at build time so `zoneinfo` has a complete IANA timezone
database offline (essential for the DST cases). The agent works in `/app`,
implementing the `notifq` package by editing `notifq/__init__.py` (it may split into
multiple modules as long as the public names stay importable). A non-exhaustive
`public_tests/test_public.py` self-check and a `README.md` orient the agent. All time
enters as injected integer epoch seconds (UTC); the solution must never read the wall
clock, sleep, spawn threads, or touch the network. The sealed verifier runs the same
interpreter, imports the agent's `notifq`, and grades it against a hidden reference.
Because everything used is stdlib (`datetime`, `zoneinfo`, `json`), behavior is
identical whether the host runs Python 3.11 or 3.12.

**Difficulty explanation:**
Correctness lives entirely in the interaction of edge cases, and a single frontier
attempt typically misses at least one:
- **fold=0 timezone semantics** — nonexistent local times (spring-forward gap)
  resolve via the pre-transition offset; ambiguous local times (fall-back overlap)
  resolve to the earlier instant.
- **Recurrence in local wall time** — a "daily 09:00 local" series keeps firing at
  09:00 *local* across a DST change, so its absolute epoch shifts by an hour;
  expanding in absolute time is subtly wrong.
- **Weekly anchoring** — occurrences are anchored on the Monday of the start week,
  iterate `byweekday` ascending, drop candidates before the start date, and get a
  single global ascending `occ_index`.
- **Reminder leads** are subtracted in absolute time, then **quiet hours** may defer
  them to the *next local end boundary* (itself DST-aware) or suppress them, with an
  urgent bypass.
- **Coalescing** keeps exactly one notification per (task, effective-instant) with a
  precise tiebreak.
- **Engine semantics** — deliver exactly once within `(cursor, now]` in a defined
  order; items older than the catch-up grace are consumed but *not* delivered; and
  state must persist so a brand-new `Engine` over the same store neither re-sends nor
  drops (idempotency across restart).
It is clearly solvable — the reference is ~230 lines of pure standard library — but
only if the agent reads the spec carefully and reasons through each transition.

**Oracle strategy:**
The reference (installed into `/app/notifq` by `solution/solve.sh`) is ~230 lines of
standard library. `_local_to_epoch` converts a naive local ISO string to epoch via
`datetime.replace(tzinfo=ZoneInfo(tz), fold=0).timestamp()`, giving the pre-transition
offset for nonexistent times and the earlier instant for ambiguous ones.
`_expand_occurrences` generates occurrences in local wall-clock time (one-shot; DAILY
by adding `interval*n` days; WEEKLY anchored on the Monday of the start week, iterating
`byweekday` and dropping candidates before the start date), assigns a global ascending
`occ_index`, and terminates on `count` / `until_local` / horizon. For each
occurrence × reminder it subtracts `offset_min*60` in absolute time for the raw instant,
applies quiet hours (urgent bypass; suppress drops; defer moves to the next local end
boundary), then coalesces same-instant reminders within a task keeping the smallest
`(offset, reminder_id, occ_index)`. `build_schedule` filters to the window and sorts by
`(instant, task_id, reminder_id)`. `Engine` persists `{tasks, cursor, dispatched,
completed, snoozes}` as JSON in the store; `advance_to(now)` recomputes candidates in
`(cursor, now]`, removes completed/snoozed/cancelled/already-dispatched, sorts, marks
each dispatched (idempotency), drops those older than the catch-up grace as
stale-but-consumed, delivers the rest via the sink, and advances the cursor. A fresh
`Engine` over the same store reloads this state, so restarts neither re-send nor drop.

**Verification strategy:** *(see the Verification-strategy block + component table above)*

**Binary success condition:**
The verifier prints `SCORE: <float in [0,1]>` and the harness compares it to
`pass_threshold`: **pass = SCORE ≥ 0.70.** The verifier exits 0 whenever it
successfully computes a score (pass or fail — including the nop's 0.0), so a low
score is reported cleanly rather than looking like a crashed verifier; a non-zero
exit (2) is reserved for a genuine grader error. The score is the weighted fraction
of component checks whose output records match the sealed reference exactly (the 8
canonical record keys, compared field-for-field and in order). The untouched stub
scores `0.000000` (fail); the reference/oracle scores `1.000000` (pass). The 0.70
bar means an agent must get the timezone/DST core plus most of recurrence,
quiet-hours, and engine/restart behavior right — not merely the one-shot happy path.

**Partial score strategy:**
Grading is split into 11 weighted components whose weights sum to 1.00: basic 0.10,
dst 0.12, recurrence_daily 0.08, recurrence_weekly 0.12, quiet_hours 0.12, coalesce
0.08, engine_order_stale 0.10, restart_idempotent 0.10, cancel_complete_update 0.08,
snooze 0.04, randomized 0.06. Each component runs several scenarios; its credit is
`(scenarios passed / total) × weight`, and the final score is the sum. A scenario
passes only if the agent's records equal the reference's field-for-field and in order.
Credit therefore degrades gracefully with how much of the spec is correct: an agent
that nails scheduling but botches DST still earns substantial partial credit, and
vice-versa — there is no single all-or-nothing gate below the 0.70 pass line.

**Anticipated exploits:** *(see the Anticipated-exploits block above)*

**Resource request:** CPU 2000 millis (2 cores) · Memory 4096 MB · Storage 8192 MB ·
GPU 0 · Agent timeout 14400 s · Verifier timeout 1200 s. All comfortably within the
8 CPU / 65536 MB / 40960 MB budget; the workload is tiny (stdlib Python; the verifier
finishes in well under a second), so these are deliberately generous headroom.

**Network — Mode:** none
**Network — Justification:** None required. The task is pure computation over injected
data using only the Python standard library, and `zoneinfo`'s tzdata is baked into the
image at build time. Running the agent and verifier with no network guarantees
determinism and removes any channel for fetching or exfiltrating grading data.
