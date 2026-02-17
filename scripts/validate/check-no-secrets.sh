#! bash
set -euo pipefail

echo "[check] scanning for common secret patterns..."
PATTERNS=(
  "BEGIN PRIVATE KEY"
  "AKIA"
  "SECRET_KEY"
  "PASSWORD="
  "DATABASE_URL="
)

FAILED=0
for p in "${PATTERNS[@]}"; do
  if git grep -n "$p" -- . ':!**/.env.example' ':!**/secrets.example.md' >/dev/null 2>&1; then
    echo "[fail] found pattern: $p"
    git grep -n "$p" -- . ':!**/.env.example' ':!**/secrets.example.md' || true
    FAILED=1
  fi
done

if [ "$FAILED" -eq 1 ]; then
  echo "Secret-like patterns found. Please remove or move to example files."
  exit 1
fi

echo "[ok] no obvious secrets found."
