---
title: Testing and traceability
description: How tests are identified, how they map to acceptance criteria, and what "covered" does and does not prove.
code_refs: null
status: stable
last_verified: 2026-10-14
related:
  - task-ledger.md
  - git.md
---

# Testing and traceability

Three identifier families, each stable and never reused:

| Family | Shape | Declared in | Meaning |
|---|---|---|---|
| Acceptance criterion | `AC-XXX-NN` | `tests/acceptance-criteria.md` | A requirement that can pass or fail |
| Test case | `TC-XXX-NNN` | a machine-readable tag on the test | One executable check |
| Ledger entry | `#NNN` | `Tasks/ledger.md` | A unit of work |

`XXX` is a three-letter change code (e.g. `FND` = foundation, `AUT` = auth). A new change picks a new
code; record the codes in `tests/acceptance-criteria.md`.

The catalogue holds one list item per criterion, first line ``**`AC-XXX-NN`** · <statement>``. A ledger
entry that introduces a criterion a test will prove adds it there. Ending the first line with
`[BLOCKED]` reports a criterion waiting on an external gate without counting it as a gap.

## Why tags rather than comments

A coverage claim in a doc comment is prose: nothing can query it, and it rots silently the moment a test
changes what it asserts. A tag the runner understands (a group, tag, marker, or a parseable id in the
test name) makes the claim executable: run exactly the tests for one criterion, list every id declared,
and derive the matrix from code.

Every test carries **two or more** tags: its own `TC-`, plus one `AC-` per criterion it proves. A test
with no `AC-` tag is reported as untraceable — it may still be a good test, but nothing it proves can be
pointed at a requirement.

## The matrix is generated, never written

A traceability command reads the tags and the catalogue and writes the matrix. Both directions:

- **forward** — criterion to the tests covering it, so an uncovered one shows as `none`;
- **backward** — test to the criteria it claims, so an untraceable one shows as `none`.

A hand-maintained matrix is worse than no matrix: it keeps reporting coverage after that coverage has
stopped existing. Deriving it means an uncovered criterion cannot hide, and failing on a gap makes that
a non-zero exit rather than a line someone might read. It also catches the reverse error — a test
claiming an `AC-` id the catalogue does not declare, which usually means a criterion was renumbered and
one reference was missed.

## What "covered" does and does not mean

Coverage here means *a test asserts this criterion*. It does not mean the criterion is satisfied against
real infrastructure. Two honest categories exist alongside it:

- **Blocked** — skipped with the reason, for anything needing a live service this machine does not
  have. A faked version would prove nothing about the real behaviour.
- **Faked** — an external service faked throughout. Those prove the flow's shape and its security
  properties, not interoperability with the real service.

The ledger records both, per criterion, so a `✓` in an entry never overstates what was actually proven.

## A faked test can measure the wrong thing while reporting success

Many fake libraries let a test register a second stub that *appends* rather than replaces. The earlier
stub still answers, but the later one's callback still runs — counters increment, spies fire — so a
guard asserting "the origin was reached" passes while the response under test was never used.

A trap that keeps recurring needs a check (a helper that fails if called twice), and writing it down more
emphatically is not one. When the check covers only some call sites, say so: a partial control described
as a total one stops people looking.

## The suite runs somewhere production is not

A green suite proves the code works **in the test environment**. Where that environment differs from
production, a defect can be invisible by construction — not badly tested, but *untestable* by a
request-level test however carefully written.

The shape to watch for: **anything that behaves differently because it knows it is being tested**
(middleware that short-circuits under test, a flag read from the test env), and **anything the test
database or fake is more permissive about than the real one** (column widths, constraints, encodings).
Both are silent, and neither is caught by writing a better assertion.

Two responses that do work:

1. **Assert the configuration, not the behaviour**, when the behaviour cannot occur under test.
2. **Exercise it against the running application.** When a claim cannot be tested, test it by hand and
   record the result rather than asserting something adjacent and calling it covered.
