#!/usr/bin/env bash
set -euo pipefail

# Oracle entrypoint: install the known-good service implementation.
TARGET="/app/inventory/service.py"
SOURCE="$(dirname "$0")/service.py"

if [[ ! -f "$SOURCE" ]]; then
  echo "Reference service.py missing beside solve.sh" >&2
  exit 1
fi

cp "$SOURCE" "$TARGET"
echo "Installed reference service.py"
