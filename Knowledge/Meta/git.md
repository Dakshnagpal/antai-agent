---
title: Git conventions
description: Commit message format, types per layer, branch naming, and how a commit is traced back to a ledger entry.
code_refs: null
status: stable
last_verified: 2026-10-14
related:
  - task-ledger.md
  - agent-roles.md
---

# Git conventions

A commit is the second place a unit of work is recorded, after the ledger entry. The two have to point
at each other, or the trace breaks.

## Commit message format

```
<type>(<scope>): <subject>

<body — why, not what. Wrap at 72.>

Ledger: #001, #002
OKF: synced | stale: Knowledge/path.md
```

- **Subject**: imperative mood, lower case after the colon, no trailing period, ≤ 60 chars.
  "add token refresh lock", not "Added token refresh lock." or "adds…".
- **Body**: why this change, what was considered, what it costs. Skip it only for genuinely trivial
  commits. The diff already says what changed.
- **Trailers**: `Ledger:` is required on any commit that implements a task. `OKF:` states whether the
  knowledge layer is caught up — the same fact as the `okf synced` field, restated where a reviewer
  reading `git log` will see it.

## Types — one per layer of the architecture

| Type | For | Touches |
|---|---|---|
| `feat` | New capability | source code |
| `fix` | Bug repair. Pairs with an `Entry Kind: Bug` ledger entry | source code |
| `refactor` | Behaviour-preserving restructure | code |
| `perf` | Behaviour-preserving speed change | code |
| `test` | Tests only | tests |
| `build` | Dependencies, package manifests, CI, tooling | manifests, CI |
| `chore` | Housekeeping with no product effect | anything |
| `okf` | Knowledge layer — a doc written, split, or marked stale | `Knowledge/` |
| `ledger` | Execution layer — ledger entries and rotation | `Tasks/` |
| `meta` | The agentic architecture itself — agents, rules, hooks, `CLAUDE.md` | `.claude/`, `CLAUDE.md` |
| `docs` | The build reference and everything under `docs/` | `docs/` |

The last four exist because this repo has layers beside the code, and a commit touching the knowledge
layer is not the same event as one touching the code. `git log --oneline --grep '^okf'` shows the
history of the OKF alone.

## Scope

The module or layer, lower case: `auth`, `cache`, `api`, `okf`, `ledger`, `agents`, `hooks`, `rules`.
Omit the parentheses entirely if a change genuinely spans everything.

## Examples

```
feat(auth): add single-flight lock around token refresh

Two concurrent requests could both observe an expired access token and
both call the provider. Guarded with a lock carrying an explicit TTL —
without one, a crashed owner holds it forever. The handler is idempotent
too, since the lock has no fencing token.

Ledger: #014
OKF: stale: Knowledge/Backend/Services/Auth/token-refresh.md
```

```
okf(auth): document token refresh and single-flight guard

Split the old combined auth note into token-refresh.md and
token-storage.md — one concept per file.

Ledger: #014
OKF: synced
```

## Branches

- `main` — always deployable. Direct commits are fine while this is a single-developer repo.
- `change/<slug>` — a multi-entry change; the slug names the feature the entries share.
- `fix/<short-slug>` — for an `Entry Kind: Bug` entry.

## Rules

- **Never commit a secret.** `.env` is ignored; `.env.example` is the tracked template and carries keys
  with empty values only.
- **One logical change per commit.** If the message needs the word "and", it is probably two commits.
- **A commit implementing a task records its serial.** An entry cannot close without a commit ref, or an
  explicit reason none applies — a doc-only task is a valid reason.
- **Push is outward-facing.** Confirm before the first push of a session unless the user has said to
  proceed without asking. Never force-push `main`.
- **Record the commit on the entry.** The `commit` field on a ledger entry is what makes the log
  navigable in reverse: from a shipped commit back to the entry that justified it.
