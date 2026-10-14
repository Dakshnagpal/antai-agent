# Task Ledger

Schema, status states and rules: `Knowledge/Meta/task-ledger.md`.
One global serial. Entry written **at dispatch**, not at completion. Rotate closed entries older than
the last ~30 into `Tasks/archive/ledger-YYYY-MM.md`.

**Drift signals** — `Entry Kind → Inferred` is plan drift; `okf synced → false` is knowledge drift.

---
