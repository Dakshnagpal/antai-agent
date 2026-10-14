---
title: Glossary
description: Project and domain vocabulary used across this codebase and its docs. Read when a term elsewhere is unfamiliar.
code_refs: null
status: stable
last_verified: 2026-10-14
related:
  - Architecture.md
  - Meta/okf.md
---

# Glossary

Format: `**Term** — definition`, grouped under `##` headings by domain.

## Process

**OKF** — the knowledge layer, `Knowledge/`. What the system *is*, right now. See `Meta/okf.md`.

**Task Ledger** — the execution layer, `Tasks/ledger.md`. What changed, in what order, and why. See
`Meta/task-ledger.md`.

**Reconciled** — a ledger entry verified by a party other than the one that did the work.

**OKF synced** — `Knowledge/` has caught up with a ledger entry's change. Separate from reconciled.

**Inferred entry** — work found during execution that the plan did not foresee. The plan-drift signal.

**Stale** — a Knowledge file whose code moved while the file did not. Not the same as **deprecated**,
which means the thing described no longer exists.

## Project
