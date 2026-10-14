---
paths:
  - "Tasks/*.md"
  - "Tasks/**/*.md"
---

# Writing in Tasks/ (Task Ledger)

Normative reference: `Knowledge/Meta/task-ledger.md` — full schema, all status states, planning
depth, worked example. Read it before your first ledger write this session.

## Non-negotiable

- **One global serial.** `#001`, `#002`, … never restart, never split per feature. `pre-req depended on`
  points across entries by serial, so a per-feature ledger breaks those references.
- **Plan first; the plan goes in `approach`.** No entry before the change is planned
  (`Knowledge/Meta/task-ledger.md`, "Plan before the entry"). `approach` carries the option chosen, the
  alternative rejected, and what is out of scope. There is no separate plan file.
- **Write the entry at dispatch, not at completion.** A ledger the run cannot be replayed from is a log,
  not a ledger. An interrupted run must be recoverable from the file alone.
- **`reconciled status` is not yours to set if you did the work.** It records that the reconciliation
  loop ran — acceptance criteria checked, artifacts validated, Definition of Done passed, no downstream
  entry broken. Self-certification is a defect.
- **`okf synced` is a separate field from `reconciled status`.** `reconciled` = the task is truly done.
  `okf synced` = `Knowledge/` has caught up with it. A task can be reconciled and still unsynced.
- **A failed attempt is its own entry.** Never retry in place. `Entry Kind → Bug`, its own serial.
- **Every entry carries a `commit` field** — the sha that shipped it, or `n/a — <reason>` for a
  doc-only task. Format in `Knowledge/Meta/git.md`. Without it the trail cannot be walked
  backwards from a commit to the entry that justified it.
- **Emergent work is `Entry Kind → Inferred`.** Work not in the plan is first-class, not hidden. A rising
  `Inferred` count is the signal that reality keeps outrunning the plan.

## Two drift signals this file carries

| Signal | Means |
|---|---|
| `Entry Kind → Inferred` | Plan drift — reality needed work the plan did not foresee |
| `okf synced → false` | Knowledge drift — code moved, docs did not |

Neither is a failure. Both are debt that has to stay visible.

## Rotation

`Tasks/ledger.md` holds open entries plus the last ~30 closed. Older entries move to
`Tasks/archive/ledger-YYYY-MM.md`. Serials never change on rotation.
