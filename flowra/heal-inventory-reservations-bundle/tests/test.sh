#!/usr/bin/env bash
# Harbor/Odyssey verifier entrypoint — must write /logs/verifier/reward.txt
set -uo pipefail

mkdir -p /logs/verifier

cd /app

echo "=== Running public smoke tests ==="
python -m pytest /app/tests_public -v --tb=short
PUBLIC_EXIT=$?

echo ""
echo "=== Running sealed hidden tests ==="
python -m pytest /tests/hidden -v --tb=short
HIDDEN_EXIT=$?

if [[ $PUBLIC_EXIT -eq 0 && $HIDDEN_EXIT -eq 0 ]]; then
  echo ""
  echo "VERIFICATION PASSED"
  echo 1 > /logs/verifier/reward.txt
  exit 0
fi

echo ""
echo "VERIFICATION FAILED"
echo 0 > /logs/verifier/reward.txt
exit 1
