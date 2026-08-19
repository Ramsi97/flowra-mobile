#!/usr/bin/env bash
# Build the Odyssey upload bundle: exactly the 5 required entries, nothing else.
# (Excludes local helpers like validate*.sh / make_zip.sh by only adding the 5
#  named paths, and strips caches / grader artifacts.)
#
# Usage:  bash heal-inventory-reservations-bundle/make_zip.sh
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE"
OUT="$BASE/../heal-inventory-reservations-bundle.zip"

rm -f "$OUT"
zip -rq "$OUT" task.toml instruction.md environment tests solution \
    -x '*/__pycache__/*' '*.pyc' '*/report.json' \
       '*reward.txt' '*reward.json' '*/logs/*'

echo "wrote: $OUT"
echo "contents:"
unzip -l "$OUT" 2>/dev/null || zip -sf "$OUT"
