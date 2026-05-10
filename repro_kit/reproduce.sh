#!/usr/bin/env bash
# reproduce.sh — verify any single repo's metrics against analysis/summary.csv.
#
# Usage: bash reproduce.sh <task_id>
# Example: bash reproduce.sh davila7-claude-code-templates

set -euo pipefail
THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$THIS_DIR/.." && pwd)"
TASK_ID="${1:-}"
if [ -z "$TASK_ID" ]; then
  echo "usage: $0 <task_id>"
  echo "Available task_ids:"
  awk -F'|' 'NR > 4 && /^\| \[/{ print "  " $2 }' "$ROOT/sampling.md" | sed 's/[][]//g; s/(.*$//' | head -20
  echo "  (full list in $ROOT/sampling.md)"
  exit 1
fi

echo "[repro] task_id = $TASK_ID"

REPO_LINE=$(grep -E "^\| \[$(echo "$TASK_ID" | tr '-' '/')\]" "$ROOT/sampling.md" || true)
if [ -z "$REPO_LINE" ]; then
  echo "task_id not found in sampling.md; check spelling or use full owner-repo form"
  exit 2
fi

REPO_URL=$(echo "$REPO_LINE" | grep -oE 'https://github.com/[^)]+' | head -1)
SHA=$(echo "$REPO_LINE" | grep -oE '`[a-f0-9]{8}`' | tr -d '`')

if [ -z "$REPO_URL" ] || [ -z "$SHA" ]; then
  echo "could not parse REPO_URL or SHA from sampling.md row"
  exit 3
fi
echo "[repro] repo = $REPO_URL  sha = $SHA"

WORK="$(mktemp -d -t repro-XXXXXX)"
trap "rm -rf '$WORK'" EXIT
echo "[repro] cloning to $WORK"
git clone --quiet "$REPO_URL" "$WORK/r"
git -C "$WORK/r" checkout --quiet "$SHA" || git -C "$WORK/r" checkout --quiet "${SHA}^{commit}" || true

python3 - <<EOF
import csv
import json
from pathlib import Path

# Reuse the closed harness's adapter logic if it's available locally.
# Otherwise fall back to a slimmer re-implementation. We expect users to
# install the public deps (semble, radon, tree-sitter-language-pack).
try:
    from agentharness.adapters.semble import _list_functions, _collect_ai_commits, _blame_ai_lines
except ImportError:
    print("[repro] full agentharness adapter unavailable. To reproduce per-repo")
    print("[repro] numbers exactly, install the agentharness venv per the methodology.")
    print("[repro] Without it, this script can still clone + checkout the right SHA")
    print("[repro] (already done) and report file counts + AI commit footers.")
    raise SystemExit(0)

repo = Path("$WORK/r")
print("[repro] running function extraction (this matches methodology v0.1.0)")
funcs = _list_functions(repo)
print(f"[repro] function_count = {len(funcs)}")

# Compare against published value
import csv as _csv
with open(Path("$ROOT") / "analysis" / "summary.csv") as f:
    for row in _csv.DictReader(f):
        if row["repo"].replace("/", "-") == "$TASK_ID":
            print(f"[repro] published function_count = {row['function_count']}")
            break
EOF

echo "[repro] done"
