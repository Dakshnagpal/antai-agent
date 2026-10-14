---
# Adjust to this project's source directories. A rule file loads only when a matching path is touched.
paths:
  - "src/**"
  - "app/**"
  - "lib/**"
---

# Invariants — violating one is a defect, not a style issue

**Template — no invariants recorded yet.**

This file holds the small set of load-bearing rules for the code itself: security properties and
irreversible defaults, not design preferences. Everything else in the build reference is a reference
you may diverge from with a logged reason (an `Inferred` ledger entry). **This file is not.** Each rule
closes a specific threat or failure; a violation is a defect, not a trade-off.

## How to write a rule

- One bold sentence stating the rule, then why — the threat or failure it closes.
- Cite the source: build-reference section, threat id, or the ADR in `Knowledge/Decisions.md`.
- Say how it is enforced: a test id, a lint/CI rule, or `none — gap`. A convention that is only
  written down is a convention that drifts.
- Amending a rule is a commit that says so, linked to a ledger entry. Replace, never silently drop:
  keep the old wording quoted under an **Amended by `#NNN`** line.

## <Area>

- **<Rule.>** <Why — what breaks without it.> [<threat/ref id>] Enforced by: <test id | lint rule | none — gap>.
