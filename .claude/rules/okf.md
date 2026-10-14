---
paths:
  - "Knowledge/*.md"
  - "Knowledge/**/*.md"
---

# Writing in Knowledge/ (OKF)

Normative reference: `Knowledge/Meta/okf.md`. Read it before your first write this session.

## Non-negotiable

- **One concept per file.** Two concepts in one file is a defect. Split them, even when the code puts
  both in one module. `token-refresh.md` and `token-storage.md`, never `AuthService.md`.
- **Name for the concept, not the source file.** The directory path tracks the code tree so things can
  be found; the filename says what it explains.
- **Frontmatter on every file**, all six fields:

```yaml
---
title:         # the concept
description:   # one line — this is what an agent reads to decide whether to open the file
code_refs:     # path(s) + symbol name(s) this documents. Never line numbers — they rot silently.
status:        # draft | stable | stale | deprecated
last_verified: # YYYY-MM-DD — when this was last checked against the code
related:       # relative links to other Knowledge files
---
```

- `stale` means the doc fell behind the code. `deprecated` means the thing it described is gone.
  They are different; do not collapse them.
- **Describe reality, not intent.** Anything not yet built is `status: draft` and says so in its first
  line. Plans belong in `Tasks/ledger.md`, questions in `Knowledge/Open_Questions.md`.

## After writing

1. Append one line to `Knowledge/log.md`: date · file · what changed · the ledger entry `#id` that caused it.
2. Set `okf synced → true` on that ledger entry.
3. `Knowledge/INDEX.md` is generated. Do not hand-edit it.
