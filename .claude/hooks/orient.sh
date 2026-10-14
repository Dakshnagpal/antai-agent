#!/usr/bin/env bash
# SessionStart: print open ledger entries and drift counts. Plain stdout enters context.
# Advisory only. Always exits 0.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
L=Tasks/ledger.md
[ -f "$L" ] || exit 0
# shellcheck source=/dev/null
. .claude/hooks/_count.sh 2>/dev/null || exit 0

OPEN=$(cnt '^[[:space:]]*task status[[:space:]]*→[[:space:]]*(Not Started|In Progress|Incomplete|On Hold|Incomplete and On Hold|Orchestrator Review Ongoing|Only QA Left)[[:space:]]*$' "$L")
UNREC=$(cnt '^[[:space:]]*reconciled status[[:space:]]*→[[:space:]]*false[[:space:]]*$' "$L")
UNSYNC=$(cnt '^[[:space:]]*okf synced[[:space:]]*→[[:space:]]*false[[:space:]]*$' "$L")
INFER=$(cnt '\[Inferred\]' "$L")
STALE=0
[ -d Knowledge ] && STALE=$(cnt_files '^status:[[:space:]]*stale[[:space:]]*$' Knowledge)

echo "Ledger: ${OPEN} open · ${UNREC} unreconciled · ${UNSYNC} awaiting OKF sync · ${INFER} inferred (plan drift) · ${STALE} stale Knowledge files."
if [ "$OPEN" -gt 0 ]; then
  echo "Open entries:"
  grep -oE '^#[0-9]{3}[[:space:]]+.*' "$L" 2>/dev/null | tail -8 | cut -c1-100 | sed 's/^/  /'
fi
echo "Read Knowledge/INDEX.md before touching code."
exit 0
