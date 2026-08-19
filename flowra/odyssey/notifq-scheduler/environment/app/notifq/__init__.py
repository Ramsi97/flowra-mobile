"""notifq — a notification scheduling engine for scheduled tasks.

Implement the API described in /app/README.md and the task instructions:

  - build_schedule(tasks, config, horizon_start, horizon_end) -> list[dict]
  - class Engine(store, sink, config, start_cursor=0) with:
        add_task(task), update_task(task), cancel_task(task_id),
        complete_occurrence(task_id, occ_index),
        snooze(task_id, occ_index, reminder_id, delta_min, now),
        advance_to(now) -> list[dict]

Standard library only. Do not read the wall clock: all time enters through
function/method arguments (epoch seconds, UTC).

Replace the NotImplementedError bodies below with your implementation. You may
split the package into multiple modules as long as the names above remain
importable from `notifq`.
"""


def build_schedule(tasks, config, horizon_start, horizon_end):
    raise NotImplementedError("implement build_schedule")


class Engine:
    def __init__(self, store, sink, config, start_cursor=0):
        raise NotImplementedError("implement Engine.__init__")

    def add_task(self, task):
        raise NotImplementedError("implement Engine.add_task")

    def update_task(self, task):
        raise NotImplementedError("implement Engine.update_task")

    def cancel_task(self, task_id):
        raise NotImplementedError("implement Engine.cancel_task")

    def complete_occurrence(self, task_id, occ_index):
        raise NotImplementedError("implement Engine.complete_occurrence")

    def snooze(self, task_id, occ_index, reminder_id, delta_min, now):
        raise NotImplementedError("implement Engine.snooze")

    def advance_to(self, now):
        raise NotImplementedError("implement Engine.advance_to")
