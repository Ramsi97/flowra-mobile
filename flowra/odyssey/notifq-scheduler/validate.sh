#!/usr/bin/env bash
# Local validation for the notifq-scheduler bundle.
#
# Confirms the grader's contract WITHOUT building the Docker image:
#   * untouched stub          -> SCORE 0.000000  (nop floors at 0)
#   * sealed reference         -> SCORE 1.000000  (ground truth)
#   * oracle (solve.sh) app    -> SCORE 1.000000  (oracle reaches full reward)
#   * public self-check tests  -> all pass against the reference
#
# It also does a comment/blank-insensitive diff of the oracle's embedded engine
# against the sealed reference: the two must be behaviourally identical (they
# differ only in docstrings/comments by design).
#
# Usage:  bash odyssey/notifq-scheduler/validate.sh
set -uo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "workspace: $TMP"
python3 --version

# Three candidate /app trees.
cp -r "$BASE/environment/app" "$TMP/stub"      # untouched stub
cp -r "$BASE/environment/app" "$TMP/ref"       # reference == ground truth
cp -r "$BASE/environment/app" "$TMP/solve"     # oracle's installed engine
cp "$BASE/tests/_ref_notifq.py" "$TMP/ref/notifq/__init__.py"
awk '/cat > \/app\/notifq\/__init__.py/ {f=1; next} f && $0=="PYEOF" {f=0; next} f {print}' \
    "$BASE/solution/solve.sh" > "$TMP/solve/notifq/__init__.py"

echo
echo "== oracle-vs-reference (AST compare; ignores comments & docstrings) =="
norm_py='
import ast, sys
def norm(p):
    t = ast.parse(open(p).read())
    for n in ast.walk(t):
        b = getattr(n, "body", None)
        if isinstance(n, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)) and b \
           and isinstance(b[0], ast.Expr) and isinstance(getattr(b[0], "value", None), ast.Constant) \
           and isinstance(b[0].value.value, str):
            n.body = b[1:] or [ast.Pass()]
    return ast.unparse(ast.fix_missing_locations(t))
sys.exit(0 if norm(sys.argv[1]) == norm(sys.argv[2]) else 1)
'
if python3 -c "$norm_py" "$TMP/solve/notifq/__init__.py" "$BASE/tests/_ref_notifq.py"; then
  echo "   OK: oracle engine is behaviourally identical to the sealed reference"
else
  echo "   WARNING: oracle engine differs from reference in EXECUTABLE code"
fi

echo
rc=0
for app in stub ref solve; do
  echo "== grade: $app =="
  python3 "$BASE/tests/grade.py" "$TMP/$app" 2>&1 | grep -E '^(SCORE|RESULT):' || true
done

echo
echo "== public self-check tests (against reference) =="
( cd "$TMP/ref" && python3 public_tests/test_public.py 2>&1 | tail -2 )

echo
echo "Expected: stub SCORE 0.000000 | ref & solve SCORE 1.000000 | 9/9 public tests passed"