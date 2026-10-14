#!/usr/bin/env bash
# Stop: surface outstanding drift as an advisory message. NEVER exits 2 — cannot block a turn.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
L=Tasks/ledger.md
[ -f "$L" ] || exit 0
# shellcheck source=/dev/null
. .claude/hooks/_count.sh 2>/dev/null || exit 0

UNREC=$(cnt '^[[:space:]]*reconciled status[[:space:]]*→[[:space:]]*false[[:space:]]*$' "$L")
UNSYNC=$(cnt '^[[:space:]]*okf synced[[:space:]]*→[[:space:]]*false[[:space:]]*$' "$L")
STALE=0
[ -d Knowledge ] && STALE=$(cnt_files '^status:[[:space:]]*stale[[:space:]]*$' Knowledge)

[ "$UNREC" = "0" ] && [ "$UNSYNC" = "0" ] && [ "$STALE" = "0" ] && exit 0

printf '{"systemMessage":"Outstanding debt: %s unreconciled ledger entries, %s awaiting OKF sync, %s stale Knowledge files. Advisory only."}\n' "$UNREC" "$UNSYNC" "$STALE"
exit 0
