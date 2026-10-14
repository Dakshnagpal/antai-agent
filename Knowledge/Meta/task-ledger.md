---
title: Task Ledger — the execution layer
description: The canonical Task Ledger entry schema, how to plan before writing one, status states, and the two drift signals it carries.
code_refs: Tasks/ledger.md
status: stable
last_verified: 2026-10-14
related:
  - okf.md
  - agent-roles.md
  - git.md
---

# Task Ledger — the execution layer

An ordered record of what happened, built so the full execution story can be rebuilt **from the log
alone**.

> Logs written in a better way → Task Ledger

Each entry answers: *what changed, in what order, and why.*

## Entry schema

```
#[Serial]  Task Title (brief)
           Task description (in depth)
                                           [HH:MM – HH:MM]   [Entry Kind]

  why done            → the request or plan item that triggered this
  approach            → the plan: option chosen, alternative rejected, out of scope (2–5 lines)
  input loaded        → the OKF slice this task's context was built from
  artifacts           → everything produced — files, configs, migrations, tests
  user use case       → the user problem this solves, as a user story
  pre-req depended on → #serials this could not start without
  acceptance criteria → minute-level checklist that marks this accepted
  commit              → sha(s) that shipped this, or "n/a — <reason>"
  task status         → see states below
  reconciled status   → true / false
  okf synced          → true / false / n/a
  definition of done  → the gate confirming it is shippable, not merely finished
```

Field labels, the `→` arrow and the status words are exact strings: the hooks count them with grep
(`task status → In Progress`, `reconciled status → false`, `okf synced → false`, `[Inferred]`).
Rewording one silently breaks the counts.

## Field notes

| Field | Note |
|---|---|
| **Serial** | One global sequence. Never restarts, never splits per feature — `pre-req depended on` points across entries, and a per-feature ledger breaks those links. |
| **Entry Kind** | `Task` (from the plan) · `Bug` (a repair) · `Inferred` (found during execution, not in the plan) |
| **why done** | The request or plan item. Not a restatement of the title. |
| **approach** | The output of planning, written before the entry is dispatched: the option chosen, the main alternative rejected and why, and what is out of scope. It is what the reviewer checks the diff against, and what makes the plan survive the session. There is no separate plan file. |
| **input loaded** | Which Knowledge files informed this. Makes it possible to ask later: *was this built on knowledge that was already stale?* |
| **acceptance criteria** | What was built. Minute-level, checkable — the entry is the only contract. An id a test claims (`AC-XXX-NN`) is also listed in the acceptance-criteria catalogue (see [testing](testing.md)). Each must be able to pass or fail: "should be fast" is not a criterion. |
| **definition of done** | Distinct from the above: the quality gate — tests, coverage, review, no downstream breakage. Acceptance criteria say it was built; Definition of Done says it can ship. |
| **reconciled status** | Set by the verification loop only. Never by whoever did the work. |
| **okf synced** | Separate from `reconciled`. A task can be genuinely done *and* leave the OKF behind. |
| **commit** | The sha(s) that shipped it. An entry cannot close without one, or an explicit reason none applies — a doc-only task is a valid reason. This is what makes the trail navigable in reverse: commit → entry. Format in [git.md](git.md). |

## Plan before the entry

No entry is written until the change is planned. A plan is finished when it names:

1. the Knowledge files read (`INDEX.md` first) — becomes `input loaded`
2. the options considered, and the one chosen and why — becomes `approach`
3. the invariants it touches (`.claude/rules/invariants.md`)
4. the open questions it rests on — each one an assumption, stated and flagged
5. acceptance criteria that can each pass or fail — becomes `acceptance criteria`

Depth scales with risk:

| Change | Plan |
|---|---|
| One file, no invariant touched | Three lines, stated, then proceed |
| Several files | All five points, stated before the entry is written |
| Auth, secrets, a migration, an irreversible external write, or anything in `invariants.md` | Plan mode — no edits while planning — and wait for approval before the entry is written |

## Status states

```
Not Started → In Progress → Incomplete → Incomplete and On Hold → On Hold
                   ↑                                                 │
                   └─────────────────── resumed ─────────────────────┘
                   ↓
      Orchestrator Review Ongoing → Only QA Left → Done → Done and Rechecked ✓
```

| Status | Meaning |
|---|---|
| `Not Started` | Queued, prerequisites not met |
| `In Progress` | Actively being worked |
| `Incomplete` | Started, not finished |
| `On Hold` | Paused — blocked or deprioritised |
| `Incomplete and On Hold` | Partially done and currently blocked |
| `Orchestrator Review Ongoing` | Implementer returned an artifact, verifier is validating |
| `Only QA Left` | Code complete, final quality check pending |
| `Done` | All acceptance criteria met |
| `Done and Rechecked` | Reconciliation loop complete → `reconciled status: true` |

Most entries will move `Not Started → In Progress → Done → Done and Rechecked`. The On Hold branches
exist for when they are needed. Do not invent a tenth state.

## The reconciliation loop

Before an entry closes permanently, a party that did **not** do the work checks:

- every acceptance criterion ticked
- every artifact present and validated
- the Definition of Done gate passed
- no downstream entry broken by this one

Only when all four pass does `reconciled status → true` and the entry become `Done and Rechecked`.
**Self-certification defeats the loop** — the agent that did the work never sets this field. Doc-only
entries may be exempted, but the exemption is stated in the entry, not skipped quietly.

## Two drift signals

What the ledger makes visible:

| Signal | Detects | Meaning |
|---|---|---|
| `Entry Kind → Inferred` | **Plan drift** | Reality required work the plan did not foresee |
| `okf synced → false` | **Knowledge drift** | Code moved, the OKF did not follow |

Neither is a failure. Both are debt, and both have to stay visible. A hook surfaces the counts at
session start — advisory only, it never blocks.

## Write discipline

- **Write the entry at dispatch, not at completion.** A ledger you cannot replay an interrupted run from
  is a log, not a ledger.
- **A failed attempt is its own entry** — `Entry Kind → Bug`, its own serial. Never retry in place.
- **Never silently flip `okf synced` to true.** If code changed and the Knowledge file did not, leave it
  `false` and say so.
- **Rotate.** `Tasks/ledger.md` holds open entries plus the last ~30 closed; older ones move to
  `Tasks/archive/ledger-YYYY-MM.md`. Serials never change.

## File layout

`Tasks/ledger.md` opens with a short header (pointer to this file, the serial/dispatch/rotation rules,
the drift signals), then `---`, then entries in serial order. Each entry sits in its own fenced code
block so the column alignment survives rendering.

## Worked example

```
#004  REST API routes scaffolded — 12 handlers, 3 controllers
      All route handlers defined with request validation, controller delegation,
      and OpenAPI stub comments. No business logic yet — structure only.
                                           [09:31 – 09:44]   [Task]

  why done            → API surface must exist before the UI can integrate
  approach            → one controller per resource, thin handlers delegating to services; rejected a
                        single invokable controller per route (12 classes, no shared validation).
                        Out of scope: business logic, auth policies
  input loaded        → OKF: Backend/Http/routing.md · Backend/Http/validation.md
  artifacts           → src/http/controllers/user-controller.ts
                        src/routes/api.ts · tests/routes/registration.test.ts
  user use case       → As a developer consuming this API, every endpoint is
                        discoverable and behaves predictably
  pre-req depended on → #001 DB schema · #002 Auth middleware · #003 Sanitise util
  acceptance criteria → ✓ 12 handlers registered with correct HTTP verbs
                        ✓ Auth middleware applied to all protected routes
                        ✓ Sanitise util applied to all body params
                        ✓ OpenAPI stub comment on every handler
                        ✓ 404 and 405 fallbacks defined
  commit              → a1b2c3d
  task status         → Done and Rechecked
  reconciled status   → true
  okf synced          → true
  definition of done  → All handlers tested, stubs validated against the OpenAPI
                        schema, no breaking change to dependent modules
```
