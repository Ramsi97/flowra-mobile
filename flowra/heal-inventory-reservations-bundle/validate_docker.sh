#!/usr/bin/env bash
# Reproduce Odyssey's "Oracle & nop" validation stage LOCALLY, in Docker.
#
#   BUILD  : docker build with context = environment/ (harness convention)
#   ORACLE : run solution/solve.sh in the container, then the sealed verifier
#            -> want RESULT PASS, /logs/verifier/reward.txt = 1, exit 0
#   NOP    : untouched image (shipped buggy service.py), sealed verifier
#            -> want RESULT FAIL, /logs/verifier/reward.txt = 0
#
# This bundle's tests/test.sh hardcodes /app/tests_public and /tests/hidden and
# writes /logs/verifier/reward.txt, so we copy tests/. -> /tests and run
# `bash /tests/test.sh` (it ignores argv).
#
# Usage:  ! bash heal-inventory-reservations-bundle/validate_docker.sh
set -uo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMG="heal-inventory-verify:local"
FAIL=0

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install it or run the no-Docker venv check instead."
  exit 127
fi

echo "== BUILD: docker build (context = environment/) =="
if ! docker build -t "$IMG" "$BASE/environment"; then
  echo "RESULT: BUILD FAILED  <-- this alone would fail 'Oracle & nop'"
  exit 1
fi
echo "  build OK"

grade_in () {   # $1 = container id ; runs the sealed verifier exactly as the harness would
  docker cp "$BASE/tests/." "$1:/tests/" >/dev/null || { echo "cp tests failed"; return 99; }
  docker exec "$1" bash /tests/test.sh
}

check_reward () {   # $1 = container id ; $2 = expected reward (1 or 0)
  local r
  r="$(docker exec "$1" cat /logs/verifier/reward.txt 2>/dev/null)"
  if [ -z "$r" ]; then
    echo "  !! NO reward file at /logs/verifier/reward.txt"
    FAIL=1
  else
    echo "  /logs/verifier/reward.txt = $r   (want $2)"
    [ "$r" = "$2" ] || { echo "  !! reward != $2"; FAIL=1; }
  fi
}

echo
echo "== ORACLE: solution/solve.sh + sealed verifier =="
oc="$(docker run -d "$IMG" sleep 3600)"
docker cp "$BASE/solution/." "$oc:/tmp/solution/" >/dev/null
docker exec "$oc" bash /tmp/solution/solve.sh
out="$(grade_in "$oc" 2>&1)"; rc=$?
echo "$out" | grep -E 'PASSED|FAILED|VERIFICATION' | tail -5
echo "  verifier exit_code=$rc   (want: RESULT PASS, exit 0)"
[ "$rc" = "0" ] || { echo "  !! oracle verifier exit != 0"; FAIL=1; }
echo "$out" | grep -q 'VERIFICATION PASSED' || { echo "  !! oracle did not PASS"; FAIL=1; }
check_reward "$oc" 1
docker rm -f "$oc" >/dev/null

echo
echo "== NOP: untouched image (shipped buggy service.py) + sealed verifier =="
nc="$(docker run -d "$IMG" sleep 3600)"
out="$(grade_in "$nc" 2>&1)"; rc=$?
echo "$out" | grep -E 'PASSED|FAILED|VERIFICATION' | tail -5
echo "  verifier exit_code=$rc   (want: RESULT FAIL, exit 1)"
echo "$out" | grep -q 'VERIFICATION FAILED' || { echo "  !! nop did not FAIL as expected"; FAIL=1; }
check_reward "$nc" 0
docker rm -f "$nc" >/dev/null

echo
if [ "$FAIL" = "0" ]; then
  echo "ALL GOOD: oracle PASS/reward 1, nop FAIL/reward 0 -> matches Odyssey's 'Oracle & nop' stage."
else
  echo "PROBLEM: see the flagged lines above."
fi
exit "$FAIL"
