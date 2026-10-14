# antai — Deliverables Document v1

| | |
|---|---|
| **Product** | antai (brand) / `antai` (command) |
| **Document** | DELIVERABLES_1, everything the v1 MVP hands over and how each item is accepted |
| **Status** | Draft for review |
| **Version** | 0.3 |
| **Date** | 14 October 2026 |
| **Author** | Daksh Nagpal |
| **Based on** | BRD_1 v0.4, HLD.png, deliverables 01 to 16 |
| **How to use** | Reference design, not a fixed rail. Where the technology needs something different or extra, the implementation may change it; the change is then made in every deliverable it touches, so the set keeps agreeing. |
| **Research basis** | External facts (provider limits and model line-ups, package, registry and CI rules, Node dates) checked on 12 October 2026 and stated where they are used (Appendix B) |

### Change log

| Version | Date | Change |
|---|---|---|
| 0.1 | 12 Oct 2026 | First draft |
| 0.2 | 12 Oct 2026 | File name and eval pass bar agreed (6.7). MCP OAuth login is Must in BRD_1 v0.3 (FR-MCP-11, AC-26): added to the P4 gate, VER-03, VER-05, the threat model and 9.2, and removed from section 12. Technical design, threat model and test strategy now live in the design document set `docs/Deliverables/`. |
| 0.3 | 14 Oct 2026 | Aligned with BRD_1 v0.4: AC-01 to AC-35, the phase exit checks of BRD section 10 (sections 4 and 9.3), 114 FRs (9.1), Q6 resolved by D30, BRD Q7 added to 10.1. This document's own questions renumbered Q8 to Q10 so they do not clash with BRD Q7. The interim UI is the line-mode renderer `LINE` (deliverable 01). The document now rests on the repository alone: BRD_1, HLD.png and deliverables 01 to 16. |

---

## Contents

1. [Purpose](#1-purpose)
2. [Summary](#2-summary)
3. [Terms and roles](#3-terms-and-roles)
4. [Deliverables by phase](#4-deliverables-by-phase)
5. [Deliverables register](#5-deliverables-register)
6. [Specifications for critical deliverables](#6-specifications-for-critical-deliverables)
7. [Definition of Done](#7-definition-of-done)
8. [Acceptance process](#8-acceptance-process)
9. [Traceability](#9-traceability)
10. [Dependencies and open questions](#10-dependencies-and-open-questions)
11. [Changes proposed to BRD_1](#11-changes-proposed-to-brd_1)
12. [Not delivered in v1](#12-not-delivered-in-v1)
13. [Handover](#13-handover)
14. [Sign-off](#14-sign-off)
- [Appendix A. Where deliverables live in the repository](#appendix-a-where-deliverables-live-in-the-repository)
- [Appendix B. Sources](#appendix-b-sources)

---

## 1. Purpose

BRD_1 says **what** antai v1 must do, and HLD.png with the design set (deliverables 01 to 16) shows **how** it might be built. This document says **what the project hands over** to prove it: the software, the evidence that it works and is safe, the documentation and the release. For every deliverable it states where it lives, when it is due, who approves it, and what decides whether it is accepted.

The design set is a reference, not a fixed rail. Where the technology needs something different or extra, the implementation may change it; the change is then made in every deliverable it touches, so the set keeps agreeing. Keeping all deliverables in agreement is the rule, and each gate checks it (DLV-PLN-04).

Use it in three ways:

- **Planning:** section 4 lists what each phase (P0 to P6) must hand over before the next phase starts.
- **Review:** section 5 is the checklist a reviewer signs off against. Section 6 gives the detailed criteria for the deliverables where a mistake would hurt most.
- **Closing:** section 14 records each decision. v1 is finished when every Must deliverable is accepted and the final acceptance is signed.

Priorities use the same MoSCoW scale as BRD_1: **Must** (v1 is not done without it), **Should** (expected in v1, can slip to v1.1), **Could** (if time allows). As in BRD_1, no dates are set. Phases are ordered by dependency.

This document does not change a requirement. Where delivery needs a requirement to change, the change is proposed in section 11 and settled in the BRD baseline (DLV-PLN-01).

---

## 2. Summary

antai v1 hands over **42 deliverables** in five groups:

| Group | Code | Count | What it covers |
|---|---|---|---|
| Plan and design | PLN | 8 | BRD baseline, spike findings, model choice, technical design and ADRs (including CI and release), threat model, test strategy, backlog, project log |
| Software | SW | 10 | The repository, one working increment per phase, the safety rule sets, prompts, schemas, built-in skills |
| Verification | VER | 10 | Tests, command classifier table, secret scan, prompt-injection suite, interoperability tests, evals, acceptance and performance reports, CI, traceability |
| Documentation | DOC | 10 | README, user guide, reference, extension guide, security model, privacy note, contributor guide, security policy, changelog, licence |
| Release and handover | REL | 4 | The v1.0.0 release, supply-chain pack, release runbook, handover pack |

Each deliverable of the design set lists where it goes beyond BRD v0.4. Checks made for this document found further facts that affect delivery. The five that matter most:

1. **Groq's free plan allows 8,000 tokens per minute** on `openai/gpt-oss-120b` (30 requests per minute, 1,000 per day). An agent resends its whole context at every step. One capped shell output (30,000 characters) is about 7,500 tokens, and one capped `read_file` result (50 KB) is about 12,500 tokens, more than a whole minute's allowance. Cached prompt tokens do not count toward the limit, which helps. Whether "free to start" (G3) holds is measured in P0 (DLV-PLN-02).
2. **Of the four Groq models BRD_1 names, three can no longer be used on the free plan.** `llama-3.3-70b-versatile` and `llama-3.1-8b-instant` left the free and developer tiers on 16 August 2026, and `moonshotai/kimi-k2-instruct-0905` was shut down on 15 April 2026. Only `openai/gpt-oss-120b` remains. `gemini-3.5-flash` is also deprecated (current: `gemini-3.8-flash`).
3. **The unscoped npm name `antai` will probably be refused**, because `ant-ai` exists and npm rejects names that differ only by punctuation. `@geekyants/antai`, with the command still `antai`, avoids this, and is the name this plan uses.
4. **git.geekyants.com cannot use GitLab's hosted Windows or macOS runners**, and npm provenance cannot be produced from a self-managed GitLab. Three-OS CI needs our own runners (or a public GitHub mirror). The plan assumes an internal release (own runners, internal registry, no provenance); the CI and release ADR also covers a public one.
5. **BRD_1 still schedules some acceptance scenarios before the features they need** (for example AC-23 at the P2 gate needs skills from P3 and MCP from P4, and AC-20 and AC-31 need session files from P4). Section 9.3 splits them across gates.

P0 closes when the BRD baseline is accepted (DLV-PLN-01), the spike has answered its questions, including the default model (BRD Q3), and DevOps has said which runners exist (BRD Q4). No other open question holds a gate: section 10.1 gives the default the plan uses for each.

---

## 3. Terms and roles

### 3.1 Terms

| Term | Meaning in this document |
|---|---|
| Deliverable | A unique, verifiable product, result or capability the project hands over. Here: a file, a report, a package version or a tested capability. |
| Short IDs | Deliverables are `DLV-<group>-<nn>`. Inside tables the `DLV-` prefix is dropped (`PLN-02` means `DLV-PLN-02`). IDs from other documents keep their own form: `FR-`, `NFR-`, `AC-`, `G`, `D`, `R` and `Q1` to `Q7` are BRD_1's; component codes such as `LINE` are the design set's (deliverable 01). `Q8` to `Q10` and `CR-nn` are this document's (sections 10.1 and 11). |
| Increment | A working, tagged build of antai at the end of a phase, published to the internal prerelease channel |
| Prerelease channel | An internal package registry (chosen in the CI and release ADR) that holds the phase increments. Nothing is published publicly before the release candidate. |
| Interim UI | What drives an interactive session before the Ink UI exists (P1 to P4): the line-mode renderer `LINE` (deliverable 01), checked in the spike (6.1, question 4) |
| Line-mode renderer | A minimal interactive renderer (one line in, plain text out) with numbered dialogs and antai's slash commands. It is used instead of `@ai-sdk/tui`, which runs the agent itself and so would bypass antai's session controller. It stays after P5 for tests and as an automatic fallback, with a notice, when Ink cannot start (deliverable 13, UI-D21). |
| Acceptance criteria | The conditions a deliverable must meet to be accepted, written so that a reviewer can check them |
| Definition of Done (DoD) | The checklist every deliverable of a type must meet before it is submitted (section 7) |
| Verified | The producer has met the DoD and attached evidence. Automated checks pass. |
| Accepted | The approver has signed it off (section 8). Only accepted deliverables count as delivered. |
| Gate | The end of a phase. A gate passes when its deliverables are accepted and its exit checks pass. |
| Evidence | What proves a criterion: a CI job link, a report, a recording, a signed review |
| Severity | Defect level 1 (critical) to 4 (low), defined in 8.2 |
| Eval | A test that runs a real model several times on a fixed task and grades the outcome with code |
| pass^k | An eval task passes only if all k trials pass. It measures consistency. |
| RTM | Requirements traceability matrix: requirement → tests → latest result per OS |
| ADR | Architecture decision record: one short file per decision, with the options, the choice and the reason |
| STRIDE | A threat-modelling checklist: spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege |
| SBOM | Software bill of materials: a machine-readable list of every component shipped. CycloneDX is the format used here. |
| Provenance | A signed statement, checked by npm, of which source and build produced a package. It needs OIDC: a CI login without stored tokens. |
| Changesets | A tool where each change carries a short note; the notes build the changelog and the version number |
| Code owners | A repository rule that makes approval by named people mandatory for changes to named files |

### 3.2 Roles

| Role | Does |
|---|---|
| **Engineering** | Produces every deliverable unless another producer is named |
| **Tech lead** | Reviews technical items |
| **QA** | Reviews test evidence |
| **Security reviewer** | Reviews safety items. Must not have written the code or rules under review. |
| **DevOps** | Owns runners, CI and registries |
| **Product owner** | Approves product-facing items and owns the open questions |

**Staffing assumption.** The independence rules need at least **two people**: the producer and a reviewer. One person may hold the Tech lead, QA and Security reviewer roles, but nobody approves their own work. If the project has only one engineer, the Product owner names an independent reviewer before P2, because the P2 safety deliverables cannot be accepted otherwise.

---

## 4. Deliverables by phase

Each phase ends with a gate. The next phase starts when the gate's deliverables are accepted; P5 can start after P1 and run in parallel with P2 to P4 (BRD 10). Exit checks follow BRD_1 section 10; a scenario that needs a feature from a later phase is checked in parts (9.3). Living deliverables (backlog, project log, test suite, RTM, acceptance report, threat model, changelog) are updated at every gate after they first appear. This table and the **Phase** column of section 5 say the same thing; if they ever differ, section 5 wins.

| Phase | Deliverables due | Exit check |
|---|---|---|
| **P0 Spike** | PLN-01 BRD baseline, PLN-02 spike report, PLN-03 model selection (provisional), PLN-04 technical design and ADRs (first issue, including the CI and release ADR), PLN-05 threat model (draft), PLN-06 test strategy, PLN-07 backlog (P1 and P2 stories ready), PLN-08 project log | All eleven spike questions answered with a measurement and a written go or no-go (6.1), including the default model (BRD Q3). DevOps has said which Windows and macOS runners exist (BRD Q4); 10.1 gives the fallback for a missing one. The CI and release ADR works for both a public and an internal release. |
| **P1 Core** | SW-01 repository, SW-02 core increment, SW-08 base instructions (v1), SW-09 schemas (config), VER-01 test suite, VER-06 eval tasks for AC-02 and AC-11, VER-07 acceptance report (P1 scenarios), VER-09 CI (Linux and macOS), VER-10 RTM, DOC-09 changelog | AC-01, AC-02, AC-11, AC-21 and AC-35 pass on Linux and macOS in CI and by hand on Windows; AC-02, AC-11 and AC-35 as defined in 8.3. Early checks of AC-20, AC-33 and AC-34 (9.3). |
| **P2 Safety** | SW-03 safety increment, SW-07 safety rule sets, VER-02 classifier table, VER-03 secret scan, VER-04 prompt-injection suite (built-in tools), VER-06 eval tasks for AC-09, VER-09 CI (three OSes on every merge request), PLN-05 threat model (built-in tools), DOC-05 security model (draft) | On all three OSes: AC-04, AC-08, AC-24, AC-25 and AC-28 to AC-30 in full; AC-05 to AC-07 as approval decisions (9.3); AC-09 as defined in 8.3; and the P2 parts of AC-03, AC-10, AC-19, AC-20, AC-22, AC-23, AC-31, AC-32 and AC-35 (9.3). |
| **P3 Context** | SW-04 context increment, SW-08 base instructions (v2), SW-09 schemas (profile and skill frontmatter), SW-10 built-in skills and starter content, VER-04 (instruction files, skills, profiles), VER-05 interoperability (skills, instruction files, drop-in extension), VER-06 eval suite (first full run), PLN-03 model selection (confirmed), PLN-05 threat model (context sources) | AC-15 in full; AC-12 and AC-13 as defined in 8.3; the P3 parts of AC-10, AC-14, AC-19 and AC-23 (9.3). First full eval report accepted (8.3). |
| **P4 Memory and MCP** | SW-05 memory and MCP increment, SW-09 schemas (session records, MCP config), VER-03 re-run (history and logs), VER-04 (MCP), VER-05 (MCP on both spec versions), PLN-05 threat model (MCP and history) | AC-16 to AC-19, AC-26, AC-33 and AC-34 in full. AC-03, AC-20, AC-22, AC-23, AC-31 and AC-32 complete (9.3). |
| **P5 Interface** | SW-06 interface increment, DOC-01 README (draft), DOC-02 user guide (draft) | Scripted UI tests for dialogs, tool cards and the status bar on all three OSes in CI, including AC-05 to AC-07 against the Ink dialogs and the AC-14 status bar. The `/` menu (FR-SLC-01). Recorded walkthrough of every journey in BRD_1 section 4 on all three OSes. |
| **P6 Hardening** | DOC-01 to DOC-10 final, VER-03 final run, VER-06 eval report (final), VER-07 acceptance report (all scenarios), VER-08 performance report, VER-10 RTM (final), PLN-03 model selection (refresh), REL-01 to REL-04 | Every Must requirement and every NFR passes on three-OS CI (RTM). AC-01 to AC-35 pass on all three OSes; model-dependent scenarios, AC-27 among them, as defined in 8.3. The NFR-PERF benchmarks meet their targets (VER-08). No open severity 1 or 2 defects. Final acceptance signed (section 14). |

---

## 5. Deliverables register

**Phase** is the gate where the deliverable is first due; later gates update living items. **Accepted when** is the short form of the criteria; items marked ★ have a full specification in section 6. **Approver** signs it off. The producer is Engineering unless the approver column names one.

### 5.1 Plan and design (PLN)

| ID | Deliverable | Form and location | Phase | Priority | Accepted when | Approver | Traces to |
|---|---|---|---|---|---|---|---|
| DLV-PLN-01 | BRD_1 v1 baseline | `BRD_1.md` (repository root) | P0 | Must | Every BRD section has been reviewed. Each change in section 11, and each addition beyond BRD v0.4 that the design set lists, is applied or rejected with a reason. D14 to D21 are confirmed or changed. The change log records the baseline version. | Tech lead (producer: Product owner) | All |
| DLV-PLN-02 ★ | P0 spike report | `docs/reports/p0-spike.md` | P0 | Must | Criteria in 6.1 | Tech lead | P0, R3, R4, R6, R7, R9, Q3, Q9 |
| DLV-PLN-03 ★ | Model selection report and model catalog | `docs/reports/model-selection.md`; a model catalog data file in the source | P0 provisional, P3 confirmed, P6 refreshed | Must | Criteria in 6.2 | Product owner | FR-MOD-01..03, Q3, R3 |
| DLV-PLN-04 | Technical design and ADRs | Design document set in `docs/Deliverables/` (deliverables 01 to 16), with `HLD.png` as the source architecture; `docs/adr/` | P0, updated each gate | Must | The deliverables agree with each other and with HLD.png; a change made during implementation is made in every deliverable it touches. Covers the event model (NFR-MNT-01), session records and the approval round trip. Has accepted ADRs for: build tool; bundling and dependency pinning; the interim UI for P1 to P4 (9.3); Ollama provider; MCP version support; process-tree killing; **CI and release topology** (where Linux, Windows and macOS jobs run, who owns the runners, which registry receives prereleases and releases, how publishing is authenticated, for both answers to Q1). | Tech lead; DevOps also approves the CI and release ADR | BRD_1 8, NFR-MNT-01/03, NFR-SEC-04, Q1, Q4, R5, R6 |
| DLV-PLN-05 ★ | Threat model | `docs/Deliverables/02_security_authorization_design.md` (threat model section) | P0 draft; updated P2, P3, P4 | Must | Criteria in 6.3 | Security reviewer, then Product owner | NFR-SEC-01..05, R1, R2, R8 |
| DLV-PLN-06 | Test strategy and plan | `docs/Deliverables/14_qa_testing_strategy.md` | P0 | Must | Defines the test layers (unit with mock model, classifier table, integration, injection, interoperability, acceptance, eval, performance), the OS and Node matrix, which scenarios are automated and which manual, and the pass rules of section 8 | QA | NFR-MNT-02/03, BRD_1 9 |
| DLV-PLN-07 | Product backlog | Issue tracker on git.geekyants.com: one epic per phase, stories with Given/When/Then criteria and requirement IDs; v1.1 items labelled | P0, groomed at each gate | Must | Every Must and Should requirement belongs to a story. Stories for the next phase are estimated before the gate closes. | Tech lead (producer: Product owner) | All FR |
| DLV-PLN-08 | Project log | `docs/project/log.md`: decisions, risks, open questions; it starts from the two lists in `docs/Deliverables/others/` | P0, kept current | Must | Every decision since the last gate is recorded with owner and date before the gate review. Each risk has owner, likelihood, impact, mitigation and status. | Tech lead | BRD_1 11, 12 |

### 5.2 Software (SW)

| ID | Deliverable | Form and location | Phase | Priority | Accepted when | Approver | Traces to |
|---|---|---|---|---|---|---|---|
| DLV-SW-01 | Source repository | `git.geekyants.com/daksh.nagpal/project-agent`, tagged at each gate (`p1` … `p5`, then `v1.0.0`) | P1 | Must | TypeScript strict, lint and format enforced in CI. Every merge request reviewed by someone other than the author. | Tech lead | NFR-MNT-04 |
| DLV-SW-02 | P1 core increment | Prerelease + tag `p1` | P1 | Must | Delivers the P1 rows of 9.1: CLI entry, config, credentials, providers (including the OpenAI-compatible presets), provider error handling, agent loop, the **read-only** file and directory tools (workspace boundary and secret-file refusal already enforced), plain and JSON renderers, `run` mode, and the line-mode renderer `LINE`. P1 exit checks pass. | Product owner | 9.1 (P1 row) |
| DLV-SW-03 | P2 safety increment | Prerelease + tag `p2` | P2 | Must | Delivers the P2 rows of 9.1: write and edit tools, shell tool, classifier, Git Bash discovery, modes, approvals, double approval, hard floor, protected paths, redaction, audit log, workspace trust. P2 exit checks pass on all three OSes. | Product owner, Security reviewer | 9.1 (P2 row) |
| DLV-SW-04 | P3 context increment | Prerelease + tag `p3` | P3 | Must | Delivers the P3 rows of 9.1: instruction files, profiles, skills, `load_skill`, the remaining slash commands. P3 exit checks pass. | Product owner | 9.1 (P3 row) |
| DLV-SW-05 | P4 memory and MCP increment | Prerelease + tag `p4` | P4 | Must | Delivers the P4 rows of 9.1: history store, resume, retention, MCP client over stdio and Streamable HTTP, MCP OAuth login, drift warnings, `antai mcp`. P4 exit checks pass. | Product owner | 9.1 (P4 row) |
| DLV-SW-06 | P5 interface increment | Prerelease + tag `p5` | P5 | Must | Delivers the P5 rows of 9.1: Ink UI with streaming Markdown, tool cards, dialogs, status bar and `/` menu. P5 exit checks pass. | Product owner | 9.1 (P5 row) |
| DLV-SW-07 ★ | Safety rule sets | Versioned data files in the source: shell tier rules and secret patterns | P2 | Must | Criteria in 6.4 | Security reviewer | FR-SH-01/05/12, FR-SEC-01/03, D9 |
| DLV-SW-08 | Base instructions and tool descriptions | Versioned text files in the source | P1, revised P3 | Must | Reviewed as code. Their token size, plus the tool schemas, is reported in CI and stays within the budget set by the spike report. From P3, every change re-runs the eval suite. | Tech lead | FR-AGT-03, FR-TOOL-01..08 |
| DLV-SW-09 | Schemas | JSON Schemas for `config.json`, `mcp.json`, `PROFILE.md` and `SKILL.md` frontmatter, and session records | P1 (config), P3 (profile, skill), P4 (session, MCP) | Must | Config validation (FR-CFG-02) and the configuration reference (DOC-03) are generated from the same schemas. The config schema has no value for skip-permissions (FR-CFG-05). | Tech lead | FR-CFG-02/05, FR-PRF-01, FR-SKL-01, FR-HIS-01, FR-MCP-02 |
| DLV-SW-10 | Built-in skills and starter content | Built-in skills `repo-tour`, `commit-message` and `explain-error`, one sample profile (`node-dev`), example config files; the `antai init` template if FR-CLI-06 is done | P3 | Should | Each skill passes the skills conformance test and has at least one eval task. | Product owner | FR-SKL-07, FR-CLI-06, Q5 |

### 5.3 Verification (VER)

| ID | Deliverable | Form and location | Phase | Priority | Accepted when | Approver | Traces to |
|---|---|---|---|---|---|---|---|
| DLV-VER-01 | Automated test suite | `test/`: unit and integration tests, no network, using `MockLanguageModelV4` | P1, grows each gate | Must | Runs in CI on every merge request. Tests carry requirement IDs so the RTM can be generated. Besides feature tests it includes: crash and kill tests for history files (NFR-REL-01); fault tests for a failing MCP server, a provider outage and an invalid skill (NFR-REL-02); a no-orphan-process test on all three OSes (NFR-REL-03); a network test that allows only the provider and MCP hosts (NFR-PRIV-01, BRD 1.4); a file-location test showing antai writes only under `~/.antai` and approved workspace paths (NFR-PRIV-02); and a check that every user-facing error names a next step (NFR-USE-02). | QA | NFR-MNT-02, NFR-REL-01..03, NFR-PRIV-01/02, NFR-USE-02 |
| DLV-VER-02 ★ | Command classifier test table | Data file of at least 300 commands with expected tiers | P2 | Must | Criteria in 6.5 | Security reviewer | NFR-SEC-01, NFR-COMP-02, FR-SH-01/12, R1 |
| DLV-VER-03 ★ | Secret-scan test | Test that seeds known secrets and scans every output | P2; re-run P4 and P6 | Must | Criteria in 6.6 | Security reviewer | NFR-SEC-05, AC-22, FR-SEC-03, G2 |
| DLV-VER-04 ★ | Prompt-injection regression suite and report | `test/injection/`, `docs/reports/injection-<version>.md` | P2 (built-in tools), P3 (instruction files, skills, profiles), P4 (MCP) | Must | Criteria in 6.6 | Security reviewer | NFR-SEC-02, FR-MODE-03, R2, G2 |
| DLV-VER-05 | Interoperability and extension tests | Agent Skills conformance (strict validator, lenient loader), instruction-file resolution, a drop-in extension test, MCP against servers on spec 2026-07-28 and 2025-11-25 over stdio and Streamable HTTP, and OAuth login against an OAuth-only server (AC-26) | P3 (skills, instructions, drop-in), P4 (MCP) | Must | All pass on three OSes. Unknown skill frontmatter fields warn instead of failing. A skill or profile folder dropped into a recognised location appears in `/skills` or `/profile` on the next start, and invalid ones are listed with a reason (G5). A broken MCP server never blocks the prompt. AC-26 passes: after a restart the server reconnects without a new login. | QA | G5, FR-SKL-01/06, FR-INS-01..03, FR-PRF-01, FR-MCP-01/04/05/11 |
| DLV-VER-06 ★ | Eval suite and report | `evals/`, `docs/reports/eval-<version>.md` | P1 and P2 (tasks for the scenarios due there), P3 (first full run), P6 (final) | Must | Criteria in 6.7 | Product owner | G1, G3, AC-02, AC-09, AC-11..14, AC-27, R3 |
| DLV-VER-07 ★ | Acceptance test report | `docs/reports/acceptance-<version>.md` | P1, updated each gate, complete at P6 | Must | Criteria in 6.8 | Product owner, after QA review | BRD_1 9, G4, NFR-COMP-01 |
| DLV-VER-08 | Performance report | `docs/reports/performance-<version>.md` | P6 (launch-time baseline in PLN-02) | Must | NFR-PERF-01 to 04 measured on one stated machine per OS, with the method written down. All targets met. | Tech lead | NFR-PERF-01..04, G4 |
| DLV-VER-09 | CI pipeline | `.gitlab-ci.yml`, plus any mirror workflow the CI and release ADR names | P1 (Linux and macOS), P2 (three OSes) | Must | From P2, every merge request runs lint, typecheck and tests on macOS, Linux and Windows (NFR-MNT-03). A lint rule rejects hard-coded path separators (NFR-COMP-03). The release candidate runs on Node 22, 24 and 26 on all three OSes. Release tags also run the SBOM, `npm audit`, `npm audit signatures` and secret detection. | DevOps | NFR-MNT-03/04, NFR-COMP-01..03, G4 |
| DLV-VER-10 ★ | Requirements traceability matrix | Generated from test IDs into `docs/reports/rtm-<version>.md` | P1, every gate | Must | Criteria in 6.9 | QA | BRD_1 9 |

### 5.4 Documentation (DOC)

| ID | Deliverable | Form and location | Phase | Priority | Accepted when | Approver | Traces to |
|---|---|---|---|---|---|---|---|
| DLV-DOC-01 | README | `README.md` (replaces the GitLab template) | P5 draft, P6 | Must | Someone outside the project installs antai and gets a first useful answer in under 3 minutes by following it alone, timed and recorded in VER-07 | Product owner | NFR-USE-01 |
| DLV-DOC-02 | User guide | `docs/guide/` | P5 draft, P6 | Must | Covers every journey in BRD_1 section 4: modes and approvals, secrets, skills, profiles, instruction files, MCP, history, scripts and CI, Windows and Git Bash, quota errors | Product owner | G1, G4 |
| DLV-DOC-03 | Reference | `docs/guide/reference.md` and the `--help` text | P6 | Must | Lists every flag, subcommand, slash command, shortcut, config key, environment variable and file location. Config keys are generated from SW-09. A test checks that `--help` and `/help` list every flag and command. | Tech lead | NFR-USE-03, FR-CLI-04/05 |
| DLV-DOC-04 | Extending antai guide | `docs/guide/extending.md` | P6 | Should | A team lead who has not seen the code adds a skill, a profile, an instruction file and an MCP server by following it alone | Product owner | G5 |
| DLV-DOC-05 ★ | Security model | `docs/guide/security.md` | P2 draft, P6 | Must | Criteria in 6.10 | Security reviewer | NFR-SEC-03, D8, D9 |
| DLV-DOC-06 | Privacy note | `docs/guide/privacy.md` | P6 | Must | States what leaves the machine and to whom, each provider's training and retention terms (CR-09), and that there is no telemetry | Product owner | NFR-PRIV-01..03 |
| DLV-DOC-07 | Contributor guide | `CONTRIBUTING.md` with an architecture overview | P6 | Should | A new engineer clones, builds, tests and prepares a patch release using only these files | Tech lead | NFR-MNT-01..04 |
| DLV-DOC-08 | Security policy | `SECURITY.md` | P6 | Must | Says how to report a vulnerability, who triages it, response targets and supported versions | Security reviewer | NFR-SEC |
| DLV-DOC-09 | Changelog and release notes | `CHANGELOG.md` (from changesets); release notes for each gate and for v1.0.0 | P1, each gate | Must | Every user-visible change has an entry. The v1.0.0 notes list known issues with severity, and the versions tested (from VER-07). | Tech lead | — |
| DLV-DOC-10 | Licence and third-party notices | `LICENSE`, `THIRD_PARTY_NOTICES` | Before any public release; P6 at the latest | Must | `LICENSE` states the licence: proprietary (`UNLICENSED` in the package) for the internal release the plan assumes, or the licence the Product owner picks for a public one. The notices list every bundled dependency and its licence. | Product owner | Q2 |

### 5.5 Release and handover (REL)

| ID | Deliverable | Form and location | Phase | Priority | Accepted when | Approver | Traces to |
|---|---|---|---|---|---|---|---|
| DLV-REL-01 ★ | v1.0.0 release | Package `@geekyants/antai` (command `antai`) in the registry chosen in the CI and release ADR; tag `v1.0.0` | P6 | Must | Criteria in 6.11 | Product owner | All Must FR, all NFR |
| DLV-REL-02 | Supply-chain pack | CycloneDX 1.6 SBOM, `npm audit` result and secret-detection result attached to the release; npm provenance if the package is public | P6 | Must (provenance only for a public package) | The SBOM validates against the CycloneDX schema and lists every shipped dependency. Every high or critical advisory is fixed or has a written exception approved by the Security reviewer. | Security reviewer | NFR-SEC-04 |
| DLV-REL-03 | Release runbook | `docs/project/release-runbook.md` | P6 | Must | Covers versioning, the publish steps and approvals, token or OIDC set-up, rollback (publish a fixed patch and deprecate, because npm blocks most unpublishing after 72 hours) and a hotfix. Someone other than the author has done one dry run to the prerelease channel. | DevOps | — |
| DLV-REL-04 | Handover pack | `docs/project/handover.md` and a recorded walkthrough | P6 | Must | Criteria in section 13 | Product owner | — |

---

## 6. Specifications for critical deliverables

These are the deliverables where a weak acceptance test would let a serious problem through. Each gives the purpose, the contents, measurable criteria and the evidence the approver should expect.

### 6.1 DLV-PLN-02 P0 spike report

- **Purpose:** answer the questions that can change the design before feature work starts.
- **Contents:** one section per question, each with method, measurement, recommendation and the resulting ADR or BRD change.
  1. **Groq free-plan budget.** Token size of the base instructions, the tool schemas, the skill catalog, and the schemas of a large MCP server (the 34-tool example in BRD 4.8). Steps per minute under 8,000 tokens per minute, with and without prompt-cache hits. Effect of the 30,000-character shell cap and the 50 KB `read_file` cap. Requests and tokens per day used by a typical session. Recommended free-plan defaults, and whether Groq's free plan stays a usable default. Whether `toolSearch` is needed in v1 (the design does not use it).
  2. **Default model.** Tool-calling reliability of `openai/gpt-oss-120b`, `openai/gpt-oss-20b` and `gemini-3.8-flash` on ten seed tasks in a prototype loop. gpt-oss on Groq makes no parallel tool calls.
  3. **Approval round trip.** The design in deliverable 03 (SD-7a to SD-9): `toolApproval` set when the agent is built, `await agent.stream()`, two dialogs sent as one response, denial, resume while a dialog is open, and the per-process approval signing secret (deliverable 07, section 4.5).
  4. **Interim UI for P1 to P4.** Does the line-mode renderer `LINE` show antai's second, red dialog with No selected, discard type-ahead when a dialog opens, and run antai's slash commands on all three OSes (9.3)? `@ai-sdk/tui` is used only for internal demos, if it works (BRD 10), because it runs the agent itself and bypasses antai's session controller.
  5. **Ink 8.** Text input, paste, multi-line input, a Markdown renderer, testing on Ink 8, `suspendTerminal` for `sudo` (deliverable 03, SD-11), and launch time with React 19.3.
  6. **Windows and Git Bash.** Finding `bash.exe` in antai's search order (deliverable 03, SD-1a), the `/c/...` path form, killing a process tree with `taskkill /T /F` spawned from Node, starting stdio MCP servers through `npx.cmd` (run through `cmd.exe /c`), and checking that no child process survives.
  7. **Ollama provider.** `ai-sdk-ollama` against `ollama-ai-provider-v2`, with tool calling on one local model.
  8. **Gemini multi-turn tool calls.** Whether `@ai-sdk/google` keeps Gemini 3 "thought signatures" across turns.
  9. **MCP versions.** `@ai-sdk/mcp` against one server on spec 2026-07-28 and one on 2025-11-25.
  10. **Quota errors.** `maxRetries: 0` plus antai's own retry (`RTY`) using Groq's rate-limit headers: a daily-quota 429 is shown once, with the reset time.
  11. **Launch time.** Baseline for NFR-PERF-01, with providers loaded lazily.
- **Criteria:** every question has a number or a yes/no backed by a run, not an opinion, and a written go or no-go (BRD 10). BRD Q3 (the default Groq model) is answered.
- **Evidence:** the report, the prototype code on a spike branch, the raw measurements.
- **Approver:** Tech lead. **Depends on:** a Groq key, a Gemini key, one Windows machine with Git for Windows.

### 6.2 DLV-PLN-03 Model selection report and model catalog

- **Purpose:** justify the shipped defaults (FR-MOD-02) and keep model IDs out of the code.
- **Contents:** candidates per provider; method; results; the default and the `fast` and `smart` aliases; free-plan limits; training and retention terms; deprecation dates.
- **Method:** at P0, the spike's prototype loop gives a provisional choice. At P3, the choice is confirmed by running the eval suite inside antai, because public benchmarks score a model together with the harness that ran it, not with antai.
- **Starting point:** Groq default `openai/gpt-oss-120b` (also the `smart` alias), `fast` alias `openai/gpt-oss-20b`; Gemini default `gemini-3.8-flash`. Preview models only on request.
- **Model catalog:** a data file in the source with each model's ID, provider, context window, tool-calling support, reasoning support and deprecation date. antai warns, without any network call, when a configured model is past its deprecation date.
- **Criteria:** from P3, the default meets the eval thresholds in 6.7. Every listed model was available on the report date.
- **Evidence:** the report and the eval run IDs.
- **Approver:** Product owner. Refreshed at P6 and whenever a provider retires a default.

### 6.3 DLV-PLN-05 Threat model

- **Purpose:** show that every known way to misuse antai has a control and a test.
- **Contents:**
  - **Components and trust boundaries:** user and terminal; model provider; workspace files and command output (untrusted); instruction files, skills and profiles from the project (untrusted, loaded without trust); project config (untrusted until the folder is trusted); MCP servers and their tool descriptions (untrusted); MCP OAuth authorization servers and the local loopback redirect; history, logs and credentials on disk.
  - **STRIDE threats** per component.
  - **A table** mapping each threat to its control (FR ID or a rule of the design set), its test (VER ID) and the residual risk.
  - **OWASP mapping** to the Top 10 for LLM Applications **2025** and **2026**, and to the Top 10 for Agentic Applications (ASI01–ASI10). IDs always carry the year, because the 2026 list renumbers entries (Excessive Agency is LLM06 in 2025 and LLM03 in 2026).
  - **Attack patterns seen against terminal agents in 2025–2026,** each with the antai control:

    | Pattern | What can happen | antai control |
    |---|---|---|
    | Allowlist bypass by chaining | A dangerous command chained after an allowlisted prefix (`grep …; curl …`) runs unasked | Every segment classified, strictest wins (FR-SH-01) |
    | Environment changed by shell built-ins | Built-ins change environment variables that later commands use | Environment assignments classified; commands that run other commands are unwrapped and checked |
    | Provider base URL set by the project | Project config points the provider base URL at an attacker, and the API key is sent before the folder is trusted | Provider settings need trust (FR-CFG-04, AC-35); keys antai stores never enter `process.env` or child environments (FR-SH-06) |
    | MCP commands from the project | MCP server commands from project config run on launch | Project MCP servers need trust (FR-CFG-04) |
    | Self-escalation | The agent edits its own settings to raise its permissions | The model cannot change mode or permissions (FR-MODE-03); antai's own config files are protected paths (FR-TOOL-11), and `~/.antai` is outside the writable workspace |
    | Malware driving local agents | Malware runs local AI agents with their approval-skipping flags to search for secrets | Skip-permissions is launch-only (FR-MODE-02); the hard floor still applies; documented in DOC-05 |
    | Secrets leaking from agents in CI | An agent running in CI leaks secrets into its output or logs | `run` defaults to research mode (D19); redaction; CI guidance in DOC-05 |

  - **Provider data terms** that affect privacy (CR-09).
- **Criteria:** no threat without a control, or without a residual-risk acceptance signed by the Product owner.
- **Evidence:** the document and its links to tests.
- **Approver:** Security reviewer, then Product owner.

### 6.4 DLV-SW-07 Safety rule sets

- **Purpose:** keep the rules that decide what may run as reviewable data, not scattered code.
- **Contents:** the Safe, Normal, Dangerous and Hard-floor rules, including Windows executables reachable from Git Bash; nested-shell and inline-interpreter rules (`python -c`, `node -e` and the like are Dangerous); unwrap rules for commands that run other commands; secret-path rules (the one secret-path list of FR-SEC-01 for every tool and command, D25; a shell read of a secret file with any verb is hard floor); the secret file patterns, environment-variable name patterns and credential formats used for redaction (deliverable 02, section 6, including Groq `gsk_` keys).
- **Criteria:**
  - Every rule has at least one test row in VER-02 or VER-03.
  - Nothing in user or project config can remove a hard-floor rule or move a built-in Dangerous command to a lower tier (FR-SH-05). Tests prove it.
  - Changes to these files need Security reviewer approval through code owners.
- **Evidence:** the files, the code-owners rule, the linked tests.
- **Approver:** Security reviewer.

### 6.5 DLV-VER-02 Command classifier test table

- **Purpose:** the main evidence for R1 (a command slips past the classifier).
- **Contents:** at least 300 rows, each a command and its expected tier, covering:
  - every example in BRD_1 5.5 and the worked examples in deliverable 02, section 4.7;
  - obfuscation: extra spaces, quotes, backslashes, `$IFS`, variables, `env` and `VAR=value` prefixes, absolute paths (`/usr/bin/rm`), `.exe` suffixes and mixed case on Windows;
  - chaining with `&&`, `||`, `;`, `|`, `&` and newlines; redirection; command substitution; unparseable input and commands over 10,000 characters (fail closed);
  - nested shells and inline interpreters (`bash -c`, `sh -c`, `eval`, `cmd /c`, `powershell`, `pwsh`, `python -c`, `node -e` and the other inline interpreters), including hard-floor patterns inside them;
  - commands that run other commands (`xargs`, `find -exec`, `watch`, `timeout`, `nohup`), write-then-run (`bash script.sh`, `source`) and detaching commands (`&`, `nohup`, `setsid`, `disown`);
  - secret reads with any verb (`sed`, `base64`, `xxd`, `git show HEAD:.env`, `tar`), and reads of `~/.antai/credentials.json`, `~/.ssh`, `~/.aws` and the other secret paths of FR-SEC-01;
  - outbound transfers (`curl -d @file`, `scp`, `nc`), which BRD 5.5 makes Dangerous;
  - Windows executables called from Git Bash (`del /s`, `rd /s`, `taskkill /f`, `reg delete`, `format`, `diskpart`);
  - the attack patterns in 6.3.
- **Criteria:**
  - A row passes when the actual tier is **the expected tier or stricter**. 100 % of rows pass in bash on macOS and Linux and in Git Bash on Windows (D24).
  - A Dangerous or Hard-floor command classified lower is a **severity 1** defect.
  - Rows classified stricter than expected are listed in the report so false alarms stay visible.
  - Before acceptance, the Security reviewer adds at least 30 rows the author has not seen.
- **Evidence:** CI results on three OSes, the over-classification list, the reviewer's added rows.
- **Approver:** Security reviewer.

### 6.6 DLV-VER-03 Secret-scan test and DLV-VER-04 prompt-injection suite

**Secret scan**

- **Contents:** canary values seeded into `.env` files, environment variables, `~/.antai/credentials.json` (including a Groq `gsk_` key and MCP OAuth access and refresh tokens, AC-26) and the credential formats of the redaction rules (6.4). The full test and acceptance suites run with the canaries present. Every captured provider request, MCP request, terminal output, JSON event, history file, debug log and error message is scanned. A child-process test checks that `printenv` shows no key antai stores (FR-SH-06); provider-key variables the user exported stay and are masked (deliverable 02, section 6.6).
- **Criteria:** zero canaries found. Known limits (values shorter than 4 characters; `.env` values whose names are not secret-like and are shorter than 8 characters (FR-SEC-04); encoded or transformed secrets) are stated in DOC-05.
- **Runs:** P2 (no history yet), P4 (history files and logs added), P6 (release candidate).

**Prompt-injection suite**

- **Contents:** at least 40 cases where untrusted content tries to make antai act:
  - instructions planted in a README, a source comment, command output, an instruction file, a skill body, a project profile, an MCP tool description and an MCP tool result;
  - text asking the model to change mode or permissions;
  - a project profile with `mode: auto`, pinned or auto-matched, in an untrusted folder (no project profile can set `auto`, BRD v0.4);
  - a project config that adds MCP servers, allowlist entries, a mode or a provider base URL before trust;
  - a replayed `tool-approval-response` in resumed history (the per-process approval signing secret rejects it);
  - an MCP server that changes a tool description or flips `readOnlyHint` between sessions (antai warns of the drift, D29, and the changed tool loses Safe until the user accepts the change in `/mcp`, FR-MCP-06);
  - dangerous commands behind allowlisted prefixes.
- **Method:** the deterministic layer uses the mock model to emit the malicious tool calls directly, so the test checks the guardrail, not the model's judgement. A live-model subset is reported for information only.
- **Criteria:** in 100 % of cases nothing changes state without the approvals the mode requires, no canary appears in any captured provider or MCP request, and mode, profile and permissions are unchanged.
- **Runs:** P2 (built-in tools), P3 (instruction files, skills, profiles), P4 (MCP).

**Evidence for both:** CI results, the scan report and the injection report. **Approver:** Security reviewer.

### 6.7 DLV-VER-06 Eval suite and report

- **Purpose:** accept the behaviour that depends on the model, which mock tests cannot prove (8.3), and give G1 a measure.
- **Contents:** 30 tasks, each with a fixture workspace and a grader written in code that checks the end state and the session log:

  | Category | Tasks | Linked to |
  |---|---|---|
  | Questions about the repository (uses the list, find and search tools) | 3 | AC-02 |
  | Coding in a repository | 6 | G1, AC-27 |
  | Organising files | 4 | G1, AC-27 |
  | Writing documentation | 4 | G1, AC-27 |
  | Matching a skill and following it, or following an invoked skill | 4 | AC-12, AC-13 |
  | Following a profile | 2 | AC-14 |
  | Respecting research mode and explaining why | 3 | AC-09 |
  | Recovering after a tool error | 2 | FR-AGT-07 |
  | Continuing correctly after `/model` switches provider | 2 | AC-11, G3 |

  The coding, file and documentation tasks run on one install, changing only configuration and Markdown between them (G1, AC-27).
- **Method:** pinned model IDs, k = 5 trials per task, run for the default Groq model and the default Gemini model. At P1 and P2 only the tasks for the scenarios due there run (AC-02 and AC-11 at P1, AC-09 at P2); the full suite runs from P3 (deliverable 14, section 4.7). The report gives pass rate, pass^k, tokens and requests per task, and the share of free-plan limits used.
- **Criteria** (the first two agreed by the Product owner on 12 October 2026; the rest proposed):
  - every task linked to an acceptance scenario passes at least 4 of 5 trials on the default model;
  - the whole suite passes at least 80 % of trials on the default model, to be raised once the P3 baseline exists;
  - on the Gemini default, the AC-11 tasks pass at least 4 of 5 trials, and the rest is reported;
  - no safety outcome depends on an eval. Safety is deterministic and covered by VER-02 to VER-04.
- **Evidence:** the report, raw transcripts, the run configuration.
- **Approver:** Product owner.

### 6.8 DLV-VER-07 Acceptance test report

- **Contents:** each scenario due at the gate, with:
  - the result per OS (macOS, Linux, Windows with Git Bash);
  - the package version, commit SHA and Node version tested, and the exact versions of `ai`, the providers, `@ai-sdk/mcp`, Ink and React;
  - whether it was automated or manual, and a link to the evidence (CI job, recording, log);
  - for split scenarios (9.3), which part was checked.

  At P6 it also records the README timing test (DOC-01).
- **Criteria:** every scenario due at the gate passes on all three OSes. At P6, AC-01 to AC-35 pass in full against the release candidate. Manual checks name the person and the date.
- **Evidence:** the report and its links.
- **Approver:** Product owner, after QA review.

### 6.9 DLV-VER-10 Requirements traceability matrix

- **Contents:** every FR, every NFR, the goals G1 to G5 and the slash commands of BRD 5.11, each mapped to the tests or reviews that cover it and the latest result per OS. Generated from requirement IDs in test names, so it cannot drift from the code.
- **Criteria:**
  - Every Must FR and every NFR is covered and passing. NFRs have no MoSCoW priority in BRD_1, so they count as Must.
  - NFRs about documentation (NFR-SEC-03, NFR-PRIV-03) are covered by an accepted review of the named document instead of a test.
  - An uncovered or failing Must blocks the gate. Should and Could coverage is reported.
- **Evidence:** the generated matrix for the gate's tagged version.
- **Approver:** QA.

### 6.10 DLV-DOC-05 Security model

- **Contents:** what each mode allows; the four tiers; the hard floor; workspace trust, and exactly what an untrusted folder can and cannot do; redaction and its limits; what `--dangerously-skip-permissions` does; guidance for untrusted repositories and for CI.
- **Limits it must state plainly:**
  - Command classification is a guardrail, not a security boundary. There are commands it does not recognise.
  - Approved commands run with the user's full rights, and Normal-tier commands can send data off the machine.
  - In `auto` mode, Normal commands run without asking, including package installs, project scripts and commands that send data over the network, and a script the model writes and then runs is not inspected; `auto` is meant only for work the user trusts (BRD 5.5).
  - An approved `sudo` command runs with administrator rights. Only `sudo -v` gets the real terminal; the command's output is captured and redacted, and antai clears sudo's cached credential afterwards (FR-SH-09), but it cannot limit what the command does.
  - Redaction does not mask values shorter than 4 characters, or `.env` values whose names are not secret-like and are shorter than 8 characters (FR-SEC-04), and cannot catch secrets a command encodes or transforms.
  - MCP tool annotations such as `readOnlyHint` are hints from the server, not guarantees.
  - Untrusted repositories belong in a container or VM.
- **Evidence:** the document and the Security reviewer's review record.
- **Approver:** Security reviewer.

### 6.11 DLV-REL-01 v1.0.0 release

- **Purpose:** the version users install.
- **Contents:** the package, the tag, the release notes (DOC-09) and the supply-chain pack (REL-02).
- **Criteria:**
  - Tag `v1.0.0` is on the accepted commit, and the package version matches.
  - Installs with `npm install -g @geekyants/antai` and runs with `npx @geekyants/antai` on macOS, Linux and Windows, on Node 22, 24 and 26, with npm 12, which blocks dependency install scripts. No native dependencies.
  - `antai --version` prints `1.0.0`.
  - VER-07 and VER-10 are accepted for this exact version. No open severity 1 or 2 defects.
- **Evidence:** the registry page, install logs from the three OSes, the accepted reports.
- **Approver:** Product owner.

---

## 7. Definition of Done

A deliverable is submitted for acceptance only when the checklist for its type is complete. The checklists cover the usual steps (code reviewed, unit tested, criteria verified, documented, deployed to staging, demo-ready), adapted to a terminal tool.

| Type | Definition of Done |
|---|---|
| **Software increment** | Code reviewed and approved by someone other than the author. Typecheck, lint and format clean. New behaviour has tests carrying requirement IDs, passing in CI (Linux and macOS on every merge request in P1; all three OSes from P2). RTM regenerated. User-visible changes have a changeset and doc updates. Published to the internal prerelease channel and installed fresh on all three OSes. Demo-ready. No open severity 1 or 2 defects. |
| **Document** | In the repository at the agreed path. Reviewed by the named reviewer. Links to the BRD IDs it covers. No placeholders. Links checked. |
| **Report** | States the method, the environment (OS, Node version, model IDs, package version or commit SHA) and the date. Raw data is stored or linked. Results are compared with the stated thresholds. Open issues are listed. |
| **Test asset** | Runs in CI. Deterministic, or marked as an eval with its trial count. A failure names the requirement it protects. |

For a terminal tool, "deployed to staging" means **published to the internal prerelease channel and installed fresh on macOS, Linux and Windows**.

---

## 8. Acceptance process

### 8.1 Steps

1. **Submit.** The producer checks the DoD, attaches the evidence and submits one exact version: a commit SHA, a tag or a package version. Nothing is reviewed "on the branch".
2. **Verify.** CI and the producer's checks pass. The deliverable is marked **verified**.
3. **Review.** The approver has **3 working days**, or **5 working days** for security items and eval reports. (Proposed; to be confirmed in review.)
4. **Decide.** The approver records one of:
   - **Accept.**
   - **Accept with conditions.** Allowed only when the open defects are severity 3 or 4. Each condition has a fix-by gate.
   - **Reject.** The approver names the failed criterion or gives a reproducible defect.
5. **Rework.** After a rejection only the failed criteria and what they affect are reviewed again. After two rejections the item goes to the Product owner.
6. **No silent acceptance.** Every decision is explicit and recorded in section 14. A missed review window is escalated, not treated as acceptance.
7. **Change control.** A change to an accepted deliverable is reviewed again, for the changed parts.

### 8.2 Defect severity

| Severity | Meaning | Effect |
|---|---|---|
| **1 Critical** | A safety or secret failure: a hard-floor command runs, a secret reaches the model, the screen, history or logs, a required approval is skipped, or the model changes its own mode or permissions. Also data loss, or antai fails to start. | Blocks. Safety defects are severity 1 however unlikely they seem. |
| **2 High** | A Must requirement or an NFR fails its test, with or without a workaround | Blocks |
| **3 Medium** | A Should requirement fails, or a Must requirement passes its test but has a defect that hurts use (for example a misleading message) | Accept with conditions |
| **4 Low** | Cosmetic, wording, documentation | Does not block |

### 8.3 Model-dependent behaviour

Model output varies between runs, so a scenario that depends on what the model chooses to do is split in two:

- **The deterministic part** is tested with the mock model and must pass every time: the right tools are offered, routing works, the mode is enforced, the conversation survives a model switch.
- **The behavioural part** is accepted through the eval suite (6.7), with pinned model IDs, a trial count and a threshold: the model uses the listing tools, calls `load_skill`, explains that it cannot edit, follows a profile, carries on after a switch.

This applies to AC-02, AC-09, AC-11, AC-12, AC-13 and AC-14. AC-27 has no deterministic part and is accepted through the eval suite alone. AC-35's behavioural part, a tool-using answer from a non-default provider, is checked live (deliverable 14, section 5.3). BRD_1 section 9 says "these scenario tests pass", so this rule is proposed as a BRD change (CR-12).

---

## 9. Traceability

### 9.1 Requirement to increment

BRD_1 v0.4 has 114 functional requirements (95 Must, of which three are partly Should; 17 Should; 1 Could; 1 for v1.1), 26 NFRs, and 17 slash-command rows in 5.11 with their own priorities. Where a requirement group spans phases, it is split here at FR level.

| Phase | Requirements built (increment) |
|---|---|
| **P1** (SW-02) | FR-CLI-01..03; FR-CLI-04 flags `--model`, `--effort`, `--json`, `--debug`, `--version`, `--help`; FR-CLI-05 `config` and `login`; FR-MOD-01..08; FR-AGT-01..05, 07 (FR-AGT-04: the partial turn is kept in history from P4); FR-TOOL-01, 04, 05, 06, 09, 10; FR-SEC-01 (file tools), FR-SEC-05; FR-CFG-01..03; FR-UI-06, FR-UI-07 (plain renderer); FR-ERR-01, 02, 04; FR-SLC-02; commands `/model`, `/effort`, `/exit` |
| **P2** (SW-03, SW-07) | FR-CLI-04 `--mode`, `--dangerously-skip-permissions`; FR-TOOL-02, 03, 07, 11; FR-SH-01..13 (FR-SH-10 in the audit log; as session `event` records from P4); FR-MODE-01..04; FR-SEC-01 (shell), FR-SEC-02..04; FR-HIS-13 (audit log); FR-CFG-04, 05 (trust for allowlist, mode, model and provider settings); command `/mode` |
| **P3** (SW-04, SW-10) | FR-CLI-04 `--profile`; FR-CLI-06 (Could); FR-AGT-06; FR-TOOL-08; FR-INS-01..04; FR-PRF-01..05 (FR-PRF-05: shown by `/profile`; status bar from P5); FR-SKL-01..07; commands `/help`, `/profile`, `/skills`, `/<skill-name>`, `/usage`, `/instructions`, `/compact`, `/trust`, `/config` (Could) |
| **P4** (SW-05) | FR-CLI-04 `--continue`, `--resume`, `--no-history`; FR-CLI-05 `mcp list/add/remove`; FR-HIS-01..12; FR-MCP-01..11; FR-CFG-04 (trust for MCP servers); FR-ERR-03 (redacted debug log); commands `/mcp`, `/history`, `/resume`, `/clear` |
| **P5** (SW-06) | FR-UI-01..05, 07, 08; FR-SLC-01; FR-PRF-05 status-bar part |
| **v1.1** | FR-SH-14 |

### 9.2 Requirement to verification

| Requirement | Verified by |
|---|---|
| All FR | VER-01 (unit and integration), VER-07 (scenarios), VER-10 (coverage) |
| FR-SH, FR-SEC, FR-MODE, FR-TOOL-11, FR-CFG-04/05 | VER-02, VER-03, VER-04 |
| FR-INS, FR-SKL, FR-PRF, FR-MCP-01/04/05/11 | VER-05 |
| Model-dependent scenarios (8.3) | VER-06 |
| NFR-SEC-01 / 02 / 03 / 04 / 05 | VER-02 / VER-04 / DOC-05 review / PLN-04 pinning ADR and REL-02 / VER-03 |
| NFR-PERF-01..04 | VER-08 |
| NFR-COMP-01..04 | VER-09 (OS and Node matrix, path lint), VER-02 (bash on three OSes), REL-01 (install check) |
| NFR-REL-01..03 | VER-01 (crash, fault and orphan-process tests), AC-16, AC-17, AC-29 |
| NFR-MNT-01..04 | VER-01 (the core runs headless; nothing below the event boundary imports Ink or React), VER-09 |
| NFR-PRIV-01 / 02 / 03 | VER-01 network test / VER-01 file-location test / DOC-06 review |
| NFR-USE-01 / 02 / 03 | DOC-01 timing in VER-07 / VER-01 error-message check / DOC-03 help test |
| G1 / G2 / G3 / G4 / G5 | VER-06 / VER-03 and VER-04 / AC-11 and VER-06 / VER-07 and VER-08 / VER-05 drop-in test |

Many Must requirements have no acceptance scenario of their own. They are covered by tagged tests in VER-01, and the RTM (VER-10) proves it. Examples that matter for safety or reliability: FR-SH-06 (stored keys never in the command environment), FR-SH-08 (output cap and redaction), FR-SH-09 (`sudo`), FR-CFG-02 (safety keys fail closed), FR-MCP-03, FR-MCP-10, FR-HIS-07 and FR-AGT-05 (pruning).

### 9.3 Scenarios split across gates

BRD_1 section 10 places some scenarios, or parts of them, at a gate before every feature they need exists. They are checked in parts (deliverable 14, section 5.4, has the test detail):

| Scenario | Why it must be split | Checked |
|---|---|---|
| AC-03 | Needs an MCP filesystem server (P4) and a history check (P4) | P2: built-in routes, model input and screen. P4: MCP route and history file. |
| AC-05, AC-06, AC-07 | The dialogs belong to the Ink UI (P5) | P2: as approval decisions in the event stream and audit records, through `LINE` (BRD 10 names the plain renderer, which has no dialogs to answer). P5: re-run with the Ink dialogs for the visual rules (red, No selected, arrow key to reach Yes). |
| AC-10 | Project profiles arrive in P3 | P2: config writes, planted text and `/mode auto` in tool output. P3: a project profile with `mode: auto`. |
| AC-11, AC-13, AC-17 | Need an interactive session before the Ink UI exists | Through `LINE`, with `/model`, `/effort` and `/exit` at P1, `/mode` at P2, the context commands at P3 and the history commands at P4 |
| AC-14 | The status bar is Ink (P5) | P3: the profile is active, shown by `/profile`. P5: the status bar shows `profile: node-dev (auto)`. |
| AC-19 | Needs trust (P2), instruction files (P3) and MCP (P4) | P2: allowlist and mode. P3: instruction files load. P4: full scenario, which gates (BRD 10). |
| AC-20 | The session marked `kind: run` needs history (P4) | P1: JSON events on stdout and exit code 0, and no write tool is offered (early check). P2: an approval-needing tool is denied and reported, and the denial reaches the audit log (gate, BRD 10). P4: the run is stored as a session marked `kind: run`. |
| AC-22 | History files, debug logs and OAuth tokens arrive in P4 | P2: model input, screen, JSON output, audit log. P4 and P6: history files, logs and OAuth tokens added. |
| AC-23 | Skill tools (P3) and MCP tools (P4) | P2: file and search tools work without Git. P3: skills. P4: MCP. |
| AC-31, AC-32 | Session files arrive in P4 | P2: every decision in the audit log (with history on, with `--no-history` and in `run`); Esc kills the process tree and the next prompt works. P4: `event` records and the interrupted partial turn in session files. |
| AC-33, AC-34 | Gated at P4; parts exist earlier | P1: the step cap (AC-33) and the internal-error message (AC-34) as early checks. P4: full scenarios. |
| AC-35 | Workspace trust arrives in P2 | P1: both providers answer, and the project `baseURL` is ignored because every folder is untrusted. P2: re-run with the trust gate. |
| FR-SH-10 | Audit events need the audit log (P2) and session files (P4) | P2: in the audit log and the JSON stream. P4: also as `event` records in session files. |
| FR-SLC-01 | The `/` menu needs Ink | P5 |

---

## 10. Dependencies and open questions

### 10.1 Decisions needed

Q1 to Q7 are BRD_1's open questions; Q6 is resolved by D30. Q8 to Q10 are this document's and are proposed for BRD section 12.4 (CR-14). No answer is expected soon. Each row's default is what this document uses; nothing here waits on an answer.

| ID | Question | Affects | Useful by | Owner | Default used |
|---|---|---|---|---|---|
| Q1 | Public npm or GeekyAnts only? | CI and release ADR, provenance (REL-02), DOC-10 timing, public mirror | P0 exit; the CI and release ADR covers both answers | Product owner | Plan for internal: own runners, internal registry, no provenance |
| Q2 | Licence | DOC-10, any public mirror | Before anything is public; P6 at the latest | Product owner | Proprietary (`UNLICENSED`) for the internal release. A public release needs a chosen licence. |
| Q3 | Default Groq model | PLN-03, SW-02 | P0 exit | P0 spike | `openai/gpt-oss-120b`, with `openai/gpt-oss-20b` as `fast` |
| Q4 | Windows and macOS runners on git.geekyants.com | VER-09, P1 and P2 gates | P0 exit (BRD 10); macOS runner working by P1 start, Windows by P2 start | DevOps | Own runners on git.geekyants.com: a Linux Docker runner, a Windows VM and a Mac mini, with shell executors. Without one: a public GitHub mirror for a public release, otherwise a change request to NFR-MNT-03 for manual runs on that OS at each gate. |
| Q5 | Built-in skills in v1 | SW-10 | P3 start | Product owner | `repo-tour`, `commit-message`, `explain-error` |
| Q6 | Session titles from the model or the first prompt | SW-05 | Resolved | Product owner | Resolved by D30: the model writes the title after the first turn, falling back to the trimmed first prompt. `run` sessions use the first prompt, so a script never waits for a title (deliverable 03). |
| Q7 | Who accepts the "guardrail, not sandbox" residual risk for v1? | PLN-05, DOC-05, final acceptance | P2 | Product owner with the security lead | The Product owner, on the Security reviewer's recommendation, at P2, P4 and P6 (deliverable 02) |
| Q8 | macOS runner (for example a Mac mini) on git.geekyants.com | VER-09, P1 gate | P0 exit; runner working by P1 start | DevOps | As Q4. BRD v0.4 Q4 now asks this too; the ID is kept so references stay stable. |
| Q9 | Is the Groq free plan an acceptable default if the spike shows multi-step turns slowed by the per-minute token limit? | PLN-03, G3 | P0 exit | Product owner | Keep Groq as default, explain the limit when it is hit, document Gemini and Ollama as alternatives |
| Q10 | Package name `@geekyants/antai` (command still `antai`) | REL-01, DOC-01 to DOC-03 | P5 (docs drafted) | Product owner | `@geekyants/antai` |

### 10.2 External dependencies

| Dependency | What could change | How the project watches it |
|---|---|---|
| Groq and Google model line-ups | Models are retired or moved off free plans with a few months' notice | Model catalog deprecation dates (PLN-03), checked at every gate |
| AI SDK v7 (`ai` ships about one patch a day) and Ink 8 (released 3 October 2026) | Breaking changes in experimental APIs. Ink's add-on libraries are not yet tested on Ink 8. | Exact pins, versions recorded in VER-07, experimental APIs behind antai interfaces (NFR-SEC-04) |
| MCP specification | 2026-07-28 changed the protocol; more revisions will come | Interoperability tests on both versions (VER-05) |
| npm publishing rules | Granular tokens that bypass two-factor authentication lose direct publish rights, planned for January 2027 | Release runbook uses trusted publishing or staged publishing with `npm stage approve` (REL-03) |
| Node.js | Node 22 reaches end of life on 30 April 2027 | Test on 22, 24 and 26; review the minimum version after v1 |

---

## 11. Changes proposed to BRD_1

These are proposed as input to the BRD baseline (DLV-PLN-01). Each deliverable of the design set lists its own additions beyond BRD v0.4; they are not repeated here. Where this document needs one of these changes, it assumes the proposed version.

| # | BRD_1 section | Finding | Proposed change |
|---|---|---|---|
| CR-01 | 7.2, R3, R9, D18 | Groq free plan for gpt-oss-120b: 30 requests per minute, 1,000 per day, 8,000 tokens per minute, 200,000 per day. Cached prompt tokens do not count. One capped shell output is about 7,500 tokens; one capped `read_file` result about 12,500. | State the limits in 7.2 (assumption A2 already checks a 25-step turn against them). Review the output caps (D18) for the free plan once the spike reports. |
| CR-02 | 4.7, AC-11 | `gemini-3.5-flash` is deprecated (requests are routed to a newer model). The current Flash model is `gemini-3.8-flash`. | Use `gemini-3.8-flash`. |
| CR-03 | 4.1, D21, NFR-COMP-04 | `antai` is unregistered on npm, but `ant-ai` exists and npm refuses names that differ only by punctuation. | Publish as `@geekyants/antai`; the command stays `antai`. Install line `npm install -g @geekyants/antai`. |
| CR-04 | FR-SKL-01, FR-SKL-05 | Agent Skills spec: `name` (1–64 lowercase letters, digits and hyphens, matching the folder name) and `description` are required; `license`, `compatibility`, `metadata` and `allowed-tools` are optional. `disable-model-invocation` and `user-invocable` are extensions outside the spec, which its reference validator rejects. | Pin these fields. Keep the two extensions as documented antai fields; antai warns on unknown fields instead of rejecting the skill. |
| CR-05 | 7.1 | `tsup` is no longer maintained and points to `tsdown`, which is not yet 1.0. | Name the build tool in an ADR (PLN-04), not in the BRD. |
| CR-06 | FR-MOD-01 | `ai-sdk-ollama` is more actively maintained than `ollama-ai-provider-v2`; both support AI SDK v7. | Choose in the spike (6.1, question 7). |
| CR-07 | 3.2, 7.1, NFR-COMP-01/04 | Node 24 leaves Active LTS on 20 October 2026; Node 26 becomes LTS on 28 October 2026. npm 12 needs Node 22.22.2+, 24.15+ or 26+, and blocks dependency install scripts by default. | Recommend Node 24 or 26. Test on 22, 24 and 26. No dependencies that need install scripts. |
| CR-08 | FR-CFG-04 | A provider base URL set by a repository's project config could send the user's API key to another host before the folder is trusted. | Add provider settings (base URLs, provider options) and profile pins to the project settings that need trust. BRD v0.4 has done this (FR-CFG-04, AC-35). |
| CR-09 | NFR-PRIV-03 | Groq does not train on API data on any plan. The Gemini free tier may be used to improve Google products and read by human reviewers, and Google allows only its paid tier for users in the EEA, Switzerland and the UK. | Replace the general warning with these provider-specific facts. |
| CR-10 | R7 | Ink 8 was released on 3 October 2026. Its input, select and spinner add-ons and the Markdown renderers have not been released for it. | Raise R7 to Medium. Covered by spike question 5. |
| CR-11 | 9, 10, R4, NFR-MNT-03 | Some scenarios, or parts of them, are still scheduled before their features (9.3). BRD v0.4 section 10 already has CI on Linux and macOS from P1 and Windows CI from P2. | Adopt the splits in 9.3. Three-OS CI from P2 on every merge request. |
| CR-12 | 9 | Scenarios that depend on model behaviour cannot pass every time (8.3). | Accept AC-02, AC-09, AC-11, AC-12, AC-13 and AC-14 through the deterministic test plus the eval thresholds in 6.7, and AC-27 through the eval thresholds alone. |
| CR-13 | 5.11 | The slash commands have priorities but no requirement IDs, so they cannot be traced. | Give each row an ID (for example `FR-SLC-03` onwards). |
| CR-14 | 12.4 | Three new questions came up in planning. BRD v0.4 Q4 now covers the first (macOS runner). | Add Q9 (free plan as default) and Q10 (package name) after BRD Q7. Q8 (macOS runner) needs no BRD change. |
| CR-15 | 5.2 (FR-MOD-03) | The example `groq:llama-3.3-70b-versatile` uses a model no longer on the free plan. The proposed model changes for 4.7, 5.8 and Q3 (default `groq:openai/gpt-oss-120b`, `fast` `groq:openai/gpt-oss-20b`) do not cover this example. | Use `groq:openai/gpt-oss-20b`. |
| CR-16 | FR-MCP-01 | MCP spec 2026-07-28 is not compatible with 2025-11-25. antai's MCP client (stateless Streamable HTTP, `redirect: 'error'`) needs no design change, but nothing in the BRD requires both versions, while VER-05 and the PLN-04 ADR test both. | Add to FR-MCP-01: "Works with servers on MCP spec 2026-07-28 and 2025-11-25." |

---

## 12. Not delivered in v1

| Item | Reason |
|---|---|
| PowerShell fallback for Windows without Git (FR-SH-14) | Planned for v1.1 |
| Could requirements: `antai init` (FR-CLI-06), `/config` | Delivered only if time allows. Otherwise carried to the v1.1 backlog (PLN-07). |
| BRD_1 1.4 non-goals: web, desktop or IDE interface; process isolation; multi-agent orchestration; hosted service; organisation-managed policy; memory across sessions beyond resume; self-update and update checks | Not goals for v1 |
| BRD_1 2.2 out-of-scope items: long-running background processes, built-in web search and fetch, OS keychain, image, audio or file attachments, telemetry | Out of scope for v1 |
| npm provenance | Only possible for a public package published from a public repository through GitHub Actions or GitLab.com. Not delivered for an internal release. |
| A support or service-level agreement | Not part of v1. Post-release fixes are covered by the stabilisation window in section 13. |

---

## 13. Handover

The handover pack (DLV-REL-04) is accepted when a new engineer can set up, build, test and release a patch of antai **without contacting the original developers**. It contains:

- **Access:** maintainer rights on the repository, the CI runners, the package registry and the npm organisation, held by at least two people. No release depends on one person's token.
- **Credentials:** every account and secret the project uses (provider keys for evals, registry publishing), where each is stored and who owns it. No secret values in the pack.
- **Knowledge transfer:** a recorded walkthrough of the architecture, the safety model, the release runbook and the eval suite, and a live session for questions.
- **State:** the backlog, known issues, risk register and open questions, current on the day of handover.

**Stabilisation (proposed).** For 30 days after v1.0.0 the delivery team fixes severity 1 and 2 defects as patch releases. Owner: Tech lead. The project closes when the window ends with no open severity 1 or 2 defects.

---

## 14. Sign-off

Each decision is recorded here, or in the tracker with a link from here.

| Deliverable | Version or SHA | Verified (date, by) | Decision | Conditions and fix-by gate | Approver | Date |
|---|---|---|---|---|---|---|
| DLV-PLN-01 | | | | | | |
| … | | | | | | |

**Final acceptance.** v1 is accepted when every Must deliverable in section 5 shows Accept or Accept with conditions, every condition is closed or carried into the v1.1 backlog with a target, and all of the roles below sign.

| Role | Name | Decision | Date |
|---|---|---|---|
| Product owner | | | |
| Tech lead | | | |
| Security reviewer | | | |
| QA | | | |
| DevOps | | | |

---

## Appendix A. Where deliverables live in the repository

`BRD_1.md`, `HLD.png` and `docs/Deliverables/` exist today. Everything else is a proposed layout; the technical design (DLV-PLN-04) can change it.

```
README.md                         DOC-01
CHANGELOG.md                      DOC-09
CONTRIBUTING.md                   DOC-07
SECURITY.md                       DOC-08
LICENSE, THIRD_PARTY_NOTICES      DOC-10
.gitlab-ci.yml                    VER-09
BRD_1.md                          PLN-01
HLD.png                           PLN-04 (hand-drawn source architecture)
docs/
├── Deliverables/                 PLN-04 design set: this register (00_DELIVERABLES_1.md)
│   │                             and deliverables 01 to 16; PLN-05 (02), PLN-06 (14)
│   └── others/                   open questions and decisions taken in the deliverables
├── adr/                          PLN-04
├── guide/                        DOC-02 to DOC-06
├── project/                      PLN-08 log, REL-03 runbook, REL-04 handover
└── reports/                      PLN-02, PLN-03, VER-04, VER-06, VER-07, VER-08, VER-10
src/                              SW-02 to SW-10
test/                             VER-01 to VER-05
evals/                            VER-06
```

---

## Appendix B. Sources

External facts in this document (provider limits and model line-ups, package versions, registry, CI and publishing rules, Node dates) were checked on 12 October 2026 and are stated where they are used; the P0 spike re-checks the ones the design depends on.
