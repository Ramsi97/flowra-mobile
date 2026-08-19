#!/usr/bin/env bash
# Reproduce Odyssey's "Oracle & nop" validation stage LOCALLY, in Docker.
#
# This is the one stage local validate.sh CANNOT cover, because it builds the
# real image and checks BOTH the score AND the reward file the same way the
# harness does:
#
#   BUILD  : docker build with context = environment/ (harness convention)
#   ORACLE : run solution/solve.sh in the container, then the sealed verifier
#            -> want SCORE ~1.0, RESULT PASS, /logs/verifier/reward.txt = 1
#   NOP    : untouched image (/app = the shipped stub), sealed verifier
#            -> want SCORE ~0.0, RESULT FAIL, /logs/verifier/reward.txt = 0
#
# The reward FILE at /logs/verifier/reward.txt is what the harness consumes on
# every trial (confirmed against a passing bundle). The earlier "Oracle & nop"
# failures were the verifier not writing that file; the SCORE stdout line and the
# exit code are secondary. This script fails loudly if the reward file is missing.
#
# Usage:  ! bash odyssey/notifq-scheduler/validate_docker.sh
set -uo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="notifq-verify:local"
FAIL=0

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Skip this script and use the no-Docker exit-code check instead."
  exit 127
fi

echo "== BUILD: docker build (context = environment/) =="
if ! docker build -t "$IMG" "$BASE/environment"; then
  echo "RESULT: BUILD FAILED  <-- this alone would fail 'Oracle & nop'"
  exit 1
fi
echo "  build OK"

grade_in () {   # $1 = container id ; runs the sealed verifier exactly as the harness would
  docker cp "$BASE/tests/." "$1:/verifier/" >/dev/null || { echo "cp tests failed"; return 99; }
  docker exec "$1" bash /verifier/test.sh /app
}

check_reward () {   # $1 = container id ; $2 = expected reward (1 or 0)
  local r
  r="$(docker exec "$1" cat /logs/verifier/reward.txt 2>/dev/null)"
  if [ -z "$r" ]; then
    echo "  !! NO reward file at /logs/verifier/reward.txt -- this was the failure"
    FAIL=1
  else
    echo "  /logs/verifier/reward.txt = $r   (want ~$2)"
  fi
}

echo
echo "== ORACLE: solution/solve.sh + sealed verifier =="
oc="$(docker run -d "$IMG" sleep 3600)"
docker cp "$BASE/solution/solve.sh" "$oc:/tmp/solve.sh" >/dev/null
docker exec "$oc" bash /tmp/solve.sh >/dev/null 2>&1
out="$(grade_in "$oc" 2>&1)"; rc=$?
echo "$out" | grep -E '^(SCORE|RESULT):' || echo "  (no SCORE/RESULT line!)"
echo "  verifier exit_code=$rc   (want: SCORE ~1.0, RESULT PASS, exit 0)"
[ "$rc" = "0" ] || { echo "  !! oracle verifier exit != 0"; FAIL=1; }
echo "$out" | grep -q 'RESULT: PASS' || { echo "  !! oracle did not PASS"; FAIL=1; }
check_reward "$oc" 1
docker rm -f "$oc" >/dev/null

echo
echo "== NOP: untouched image (stub notifq) + sealed verifier =="
nc="$(docker run -d "$IMG" sleep 3600)"
out="$(grade_in "$nc" 2>&1)"; rc=$?
echo "$out" | grep -E '^(SCORE|RESULT):' || echo "  (no SCORE/RESULT line!)"
echo "  verifier exit_code=$rc   (want: SCORE ~0.0, RESULT FAIL, exit 0)"
[ "$rc" = "0" ] || { echo "  !! nop verifier exit != 0  (this was the bug)"; FAIL=1; }
echo "$out" | grep -q 'RESULT: FAIL' || { echo "  !! nop did not FAIL as expected"; FAIL=1; }
check_reward "$nc" 0
docker rm -f "$nc" >/dev/null

echo
if [ "$FAIL" = "0" ]; then
  echo "ALL GOOD: oracle PASS/exit 0, nop FAIL/exit 0 -> matches Odyssey's 'Oracle & nop' stage."
else
  echo "PROBLEM: see the flagged lines above."
fi
exit "$FAIL"
