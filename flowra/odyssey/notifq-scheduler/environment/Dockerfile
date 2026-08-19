# Builds the task environment at /app. Fully offline at agent/verify time:
# tzdata is baked in at build so `zoneinfo` resolves IANA zones without a network.
#
# Debian-based python images ship the OS tzdata package (/usr/share/zoneinfo);
# we additionally install the pip `tzdata` first-party package as a belt-and-suspenders
# fallback so zoneinfo works even on slimmed bases. The build-time smoke check fails
# loudly if no timezone database is reachable.
FROM python:3.11-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Timezone data (build-time network only; none required afterwards).
RUN pip install --no-cache-dir "tzdata==2024.1" || true

WORKDIR /app
COPY app/ /app/

# Fail the build if the timezone database or DST handling is unavailable.
RUN python3 - <<'PY'
from zoneinfo import ZoneInfo
from datetime import datetime
# A known spring-forward instant in America/New_York (2026-03-08 02:00 -> 03:00).
before = int(datetime(2026, 3, 8, 1, 30, tzinfo=ZoneInfo("America/New_York")).timestamp())
after = int(datetime(2026, 3, 8, 3, 30, tzinfo=ZoneInfo("America/New_York")).timestamp())
assert after - before == 3600, (before, after)  # only 1 real hour elapsed
print("tzdata OK")
PY

CMD ["python3", "-c", "import notifq; print('notifq import OK')"]
