---
title: OKF — the knowledge layer
description: What the Knowledge/ bundle is, why it exists, and how to write a file in it correctly.
code_refs: null
status: stable
last_verified: 2026-10-14
related:
  - task-ledger.md
  - agent-roles.md
  - git.md
---

# OKF — the knowledge layer

`Knowledge/` is the source of truth about this system. Its claim is specific:

> An agent should be able to answer "how does X work here" by reading `Knowledge/`, without reading code.

If an agent has to grep the source tree to answer that, the OKF has a hole. Recording the hole is the
correct response — not reading code and quietly moving on.

## Why it exists

An agent working across many sessions starts each one blind. Two common fixes each fail alone:

- **A wiki alone** goes stale. Nothing forces it to update when code changes.
- **A work log alone** has no present tense. It records what changed, not what the system now is, and
  the next session has to replay it to find out.

The OKF is the durable half. The Task Ledger is the change half. The `okf synced` flag bridges them by
making the gap between the two *visible* — see [task-ledger](task-ledger.md).

## Always load the map, never the territory

`Knowledge/INDEX.md` is a generated table of every file's title, description, status and
`last_verified`. It is small, and it is the only file read unconditionally each session. An agent reads
the index, then opens the two or three files that matter.

Loading the whole tree would defeat the purpose — the OKF exists to make context cheap, not to fill it.

## The two conventions that matter

**One concept per file.** Not one file per source file. If one auth service handles both the
authorization-code exchange and the refresh cycle, that is two Knowledge files:

```
Knowledge/Backend/Services/Auth/authorization-code-exchange.md
Knowledge/Backend/Services/Auth/token-refresh.md
```

Never one `AuthService.md` covering both. The reason is retrieval: an agent looking for refresh
semantics should open a file that is *only* about refresh semantics, and pay for nothing else.

**Name for the concept, not the file.** The directory path mirrors the code tree so things can be
found. The filename says what it explains.

## Frontmatter

Six fields, every file, no exceptions:

```yaml
---
title:         # the concept
description:   # one line — what another agent reads in INDEX.md to decide whether to open this
code_refs:     # path(s) + symbol name(s) documented here
status:        # draft | stable | stale | deprecated
last_verified: # YYYY-MM-DD
related:       # relative links to sibling concepts
---
```

`description` is the highest-leverage field in the whole bundle. It is the only thing most agents will
ever read about a file. Write it as the question the file answers.

`code_refs` uses **real paths, plus symbol names, never line numbers.** A line anchor is wrong the moment
anything above it is edited, and nothing tells you. Comma-separated; `null` for a process or
root-truth file that documents no code.

Two rules that exist because breaking them makes the staleness hook useless rather than merely imprecise:

- **The path must resolve, extension included.** `src/models/token` does not; `src/models/token.ts`
  does. A ref that does not resolve is silently never matched.
- **Name files, not trees.** A map-level file that declares `src/` gets flagged on every edit anywhere
  under `src/`. A signal that fires on everything trains you to ignore it, which is worse than no signal.
  A directory ref (trailing `/`) is for a concept that genuinely owns a whole directory.

`status` has four values, and two of them are commonly confused:

| Value | Means |
|---|---|
| `draft` | Describes something not built yet. Do not trust as current reality. |
| `stable` | Checked against the code at `last_verified`. Trust it. |
| `stale` | The code moved and this file did not. Fix before relying on it. |
| `deprecated` | The thing this described no longer exists. |

`stale` is a doc problem. `deprecated` is a code fact. Collapsing them loses the distinction that makes
drift findable.

`last_verified` moves only when the **whole** file was re-checked against the code. Correcting one
number does not move it; say what was re-checked in `log.md` instead.

## Layout

```
Knowledge/
  INDEX.md            generated map — the only always-read file
  Architecture.md     what the system is, at the top level
  Decisions.md        ADR log — why things are the way they are
  Glossary.md         domain vocabulary
  Open_Questions.md   the single home for unresolved questions
  log.md              what changed in the OKF, when, and which task caused it
  Meta/               this directory — how the process itself works
  <mirrors the code tree>
```

Root is **project truth**. `Meta/` is **process truth**. Nothing is written in both.

### Root-file formats

| File | Entry format |
|---|---|
| `Decisions.md` | `## ADR-### — <title>` · `**YYYY-MM-DD · <status>**` · **Context.** · **Decision.** · **Consequences.** — statuses `accepted` · `superseded by ADR-###` · `reversed`. Newest last. |
| `Open_Questions.md` | `**OQ-### — <the question?>**` · `Status: open \| answered \| dropped` · what it gates. Answered → becomes an ADR, link it here. |
| `log.md` | `- YYYY-MM-DD · <file(s)> · <what changed> · #<ledger serial>` — append only, newest last. |
| `Glossary.md` | `**Term** — definition`, grouped under `##` headings by domain. |

Ids (`ADR-###`, `OQ-###`) are serial and never reused, same as ledger serials.

## Rules of maintenance

- Update **after** the change lands, not before. The interval in between is exactly what
  `okf synced → false` on a ledger entry records.
- Describe reality. Anything not yet built is `draft` and says so in its first line.
- Every write appends one line to [log.md](../log.md) naming the ledger serial that caused it.
- An answered open question moves out of `Open_Questions.md` into `Decisions.md` as an ADR.
- A new question gets one entry in `Open_Questions.md`. An open question **never halts work**: proceed
  under a stated assumption, log it as an `Inferred` ledger entry, flag it.
- `INDEX.md` is generated by `.claude/hooks/okf-index.sh`. Never hand-edit it.
