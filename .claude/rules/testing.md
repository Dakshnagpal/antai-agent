---
paths:
  - "tests/**"
  - "**/*.test.*"
  - "**/*.spec.*"
---

# Writing tests here

Normative reference: `Knowledge/Meta/testing.md`. Read it before your first test this session.

## Non-negotiable

- **Every test carries two machine-readable tags**: its own `TC-XXX-NNN` identifier, and one
  `AC-XXX-NN` per acceptance criterion it proves. Use the runner's native mechanism (a group, tag,
  marker, or a parseable token in the test name) — never a comment alone. Without the tags the test is
  untraceable: nothing can answer "what covers this requirement".
- **IDs are stable and never reused.** A deleted test's number is retired, not recycled. Reuse makes the
  ledger and the matrix lie about history.
- **The traceability check must report zero uncovered criteria** before a change ships.
- **A blocked criterion is skipped with the reason**, never a passing test against a fake that proves
  nothing. A green suite that has not earned it is worse than a red one.
- **No test may mutate process-wide state another test depends on.** If a suite's result depends on
  file or execution order, it is not measuring the code.
- **Assert the thing, not its shadow.** Read the raw stored value rather than trusting a transform;
  advance time rather than trusting a TTL argument; send the request shape that actually breaks rather
  than the convenient one.

## Fakes

One fake registration per outbound dependency per test. Many fake libraries *append* a second
registration while the first still answers, so a later stub's side effects fire (counters, spies) while
the response under test comes from the earlier one — a guard passes while measuring nothing.

A trap that recurs after being written down needs a check (a helper that fails when called twice), not
a louder note. State the check's scope honestly: a guard that covers some call sites is not a control
over all of them.
