#!/usr/bin/env bash
# Harbor/Odyssey verifier entrypoint. The harness reads the trial's reward from
# /logs/verifier/reward.txt (a number in [0,1]). grade.py computes the weighted
# score and writes it there (plus reward.json). This wrapper guarantees the file
# exists even if grade.py cannot start, and always exits 0 -- the reward file,
# not the exit code, is the signal.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-/app}"

mkdir -p /logs/verifier
echo 0 > /logs/verifier/reward.txt   # floor; grade.py overwrites with the real score

python3 "$DIR/grade.py" "$APP"

exit 0
