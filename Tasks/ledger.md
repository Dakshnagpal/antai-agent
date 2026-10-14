# Task Ledger

Schema, status states and rules: `Knowledge/Meta/task-ledger.md`.
One global serial. Entry written **at dispatch**, not at completion. Rotate closed entries older than
the last ~30 into `Tasks/archive/ledger-YYYY-MM.md`.

**Drift signals** — `Entry Kind → Inferred` is plan drift; `okf synced → false` is knowledge drift.

---

```
#001  Remove Stop drift-nudge hook
      Drop the Stop hook that printed outstanding ledger/OKF drift counts at the
      end of every turn. Session-start orient hook keeps surfacing the same counts.
                                           [19:24 – 19:24]   [Task]

  why done            → user request: remove the drift-nudge (Stop) hook
  approach            → delete the Stop block from .claude/settings.json and remove
                        .claude/hooks/drift-nudge.sh (no other caller). Keep _count.sh —
                        orient.sh still sources it. Rejected: leaving the script unwired
                        (dead file). Out of scope: other hooks, caveman plugin
  input loaded        → OKF: Meta/task-ledger.md (Two drift signals)
  artifacts           → .claude/settings.json · .claude/hooks/drift-nudge.sh (deleted)
                        Knowledge/Meta/task-ledger.md · Knowledge/log.md
  user use case       → As a user, turns end without an extra drift-count message
  pre-req depended on → none
  acceptance criteria → ✓ settings.json has no Stop key and is valid JSON
                        ✓ drift-nudge.sh removed; no remaining references in repo
                        ✓ _count.sh kept; orient.sh still runs cleanly
                        ✓ task-ledger.md no longer claims counts show at turn end
  commit              → fd0165b
  task status         → Done
  reconciled status   → false
  okf synced          → true
  definition of done  → hooks config valid, orient hook output unchanged, docs match
```
