# Open questions for Daksh

Work did not stop on any of these. Each one shows the default I used. Write your answer under it and I will apply it.

## U-01 · Two similar file names

The register is at `docs/DELIVERABLES_1.md`, which you approved. The compiled design set is at `docs/deliverables/DELIVERABLE_1.md`, which you asked for. The two names differ by one letter.

- **Default used:** keep both names as given.
- **Other option:** rename the register to `docs/DELIVERABLES_REGISTER_1.md`.
- **Answer:**

## U-02 · Register items still unconfirmed

You confirmed the file name and the eval pass bar. These are still only proposed:

- review windows of 3 working days, or 5 for security items;
- a team of at least 2 people;
- a 30-day stabilisation window after v1.0.0;
- Q7 (macOS runner), Q8 (Groq free plan as default) and Q9 (`@geekyants/antai`).

- **Default used:** treated as proposed. The design docs assume them.
- **Answer:**

## U-03 · BRD review items that are not agreed yet

BRD review batch 4 onwards, ARCHITECTURE_1 corrections A-C1..C14, gaps A-S1..S11 and register CR-01..CR-16 are proposals.

- **Default used:** the design docs assume the proposed fix and label it "pending BRD review".
- **Other option:** design only to BRD v0.3 as written.
- **Answer:**

## U-04 · GitLab version on git.geekyants.com

GitLab 18.0–18.10 renders Mermaid 10.7. GitLab 19.x renders Mermaid 11. Diagrams that use Mermaid 11 syntax show as errors on older GitLab.

- **Default used:** every diagram is checked against both Mermaid 10.7 and 11.16, so it renders on either.
- **Answer (GitLab version, if known):**

## From 01 HLD

- **U-05 (Q01-5)** · Remove provider-key variables the user exported from command environments? · Default: keep them; remove only antai's own variables. · **Answer:**
- **U-06 (Q01-6)** · Keep the line-mode renderer as a user-facing fallback after P5? · Default: automatic fallback with a notice, no new flag. · **Answer:**
- **U-07 (Q01-14)** · Will GeekyAnts host an HTTPS client document, so MCP OAuth can use Client ID Metadata Documents? · Default: defer to v1.1 and use dynamic registration. · **Answer:**
- **U-08 (Q01-16)** · When a server with `trustReadOnlyHints` changes a tool's annotations, does that tool lose Safe until you accept the change? · Default: yes, and the tool stays available at Normal. · **Answer:**
- **U-09 (Q01-18)** · BRD P2 says approvals are "tested through the plain renderer", which has no human. Change it to the line-mode renderer? · Default: line-mode renderer. · **Answer:**
- **U-10 (Q01-19)** · A prompt typed while a turn is running: queue it or refuse it? · Default: refuse. · **Answer:**
- **U-11** · BRD v0.4 arrived after the register (`docs/DELIVERABLES_1.md` v0.2, based on v0.3) was copied. Its phase mapping, AC range (now AC-01..35) and Q6 are stale. · Default: I refresh the register to v0.4 at the end of this run. · **Answer:**

## From 04 Data & Storage

- **U-12 (Q04-1)** · Adopt an append-only `index.jsonl` instead of rewriting `index.json`? · Default: keep `index.json` for v1. · **Answer:**
- **U-13 (Q04-2)** · Write response messages after every step (a change to FR-HIS-02's "when the turn ends")? · Default: after each stream call, which includes before every approval dialog. · **Answer:**
- **U-14 (Q04-3)** · Read `history.retentionDays` and `audit.retentionDays` only from global config, so a cloned repo can't shorten them? · Default: global only. · **Answer:**
- **U-15 (Q04-5)** · Make tool reads of `~/.antai/sessions`, `audit` and `logs` at least Normal tier, even when the workspace is the home folder? · Default: Normal. · **Answer:**
- **U-16 (Q04-9)** · Deny side-effecting calls when the audit log cannot be written? · Default: deny. · **Answer:**
- **U-17 (Q04-10)** · Keep prompt history (up arrow) across sessions? · Default: current session only. · **Answer:**
- **U-18 (Q04-12)** · Add an `ANTAI_HOME` override for the home folder? · Default: no. · **Answer:**
- **U-19 (Q04-14)** · Do MCP tool arguments in the audit log count as "conversation text" under FR-HIS-13? · Default: store them redacted, capped at 1,000 characters. · **Answer:**

## From 03 Sequence Diagrams

- **U-20 (Q03-4)** · `run` sessions: model-generated title (D30) or the trimmed first prompt? A model call would delay every script's exit. · Default: first prompt. · **Answer:**
- **U-21 (Q03-5)** · Ask before an OAuth step-up login (403 insufficient scope)? · Default: ask. · **Answer:**
- **U-22 (Q03-6)** · Restore the "don't ask again" list when a session is resumed? · Default: no. · **Answer:**

## From 05 Data Flow Diagrams

- **U-23 (Q05-4)** · The research doesn't cover training and retention terms for OpenAI, Anthropic and the OpenAI-compatible presets. Research them before P6? · Default: yes; until then the docs link to each provider's terms. · **Answer:**
- **U-24 (Q05-5)** · A free Gemini key can't be told from a paid one. How should antai show the free-tier data-use notice? · Default: one line at the first `google` request of each session. · **Answer:**
- **U-25 (Q05-7)** · Should network commands (`git push`, `curl` downloads) ask at least once in `auto` mode? · Default: keep the BRD as is and state it in the privacy note. · **Answer:**
- **U-26 (Q05-10)** · Shorten the home folder to `~` in paths sent to the provider? · Default: no change in v1; state it in the privacy note. · **Answer:**

## From 09 Model & Provider

- **U-27 (Q09-4)** · Provisional defaults: OpenAI `gpt-6.1-sol` (fast `gpt-6-luna`), Anthropic `claude-sonnet-5-5` (fast `claude-haiku-5-5`). OK? · Default: yes, confirmed in P0. · **Answer:**
- **U-28 (Q09-7)** · Google free-tier data-use notice: once per session, or a persisted acknowledgement? · Default: once per session. · **Answer:**
- **U-29 (Q09-8)** · Accept `GEMINI_API_KEY` as a second variable for Google? · Default: no. · **Answer:**
- **U-30 (Q09-14)** · Two gates for the default model disagree: FR-MOD-02 (95 %, 10-step turn) and assumption A2 (90 %, 25-step turn, 30 turns a day). Which one? · Default: both must pass. · **Answer:**

## From 10 Extensibility

- **U-31 (Q10-1)** · Skill `name` missing or different from its folder: load with a warning or skip? · Default: load with a warning. · **Answer:**
- **U-32 (Q10-2)** · Also read `~/.agents/skills/` and `~/.claude/skills/` (user-level skill folders of other tools)? · Default: no in v1. · **Answer:**
- **U-33 (Q10-4)** · Is `"profile"` in global config a default below auto-match? · Default: yes. · **Answer:**
- **U-34 (Q10-5)** · May a profile disable tools (`tools.disabled`) in v1? · Default: no, v1.1. · **Answer:**
- **U-35 (Q10-7)** · Should the first interactive turn wait for MCP servers still connecting? · Default: no wait; notice when tools arrive. · **Answer:**
- **U-36 (Q10-10)** · A CLI command that validates extensions strictly, for team CI? · Default: not in v1. · **Answer:**
- **U-37 (Q10-11)** · How does a user turn off a trusted project's MCP server just for themselves? · Default: new global `mcp.disabledServers` key. · **Answer:**
- **U-38 (Q10-14)** · Untrusted folder: does a project profile replace a global one of the same name? · Default: no, global kept and the clash listed. · **Answer:**
- **U-39 (Q10-16)** · Allow `${VAR}` in `command`, `args` and `url` for `.mcp.json` compatibility? · Default: no, `env` and `headers` only. · **Answer:**

## From 06 Class / UML

- **U-40 (Q06-1)** · Can `/mode` leave skip-permissions mid-session? · Default: yes, and the red banner stays for the whole session. · **Answer:**
- **U-41 (Q06-8)** · May a global profile set `auto`? FR-CFG-05 and FR-PRF-02 disagree. · Default: no, ignored with a notice. · **Answer:**

## From 02 Security & Authorization

- **U-42 (Q02-1)** · Who signs the residual-risk acceptance (BRD Q7), and who is the independent Security reviewer? · Default: Product owner signs on the reviewer's recommendation; reviewer to be named. · **Answer:**
- **U-43 (Q02-2)** · Running a file the model wrote earlier in the session (`bash cleanup.sh`): Dangerous? · Default: no; documented as residual risk RR-03. · **Answer:**
- **U-44 (Q02-3)** · Accept the extra protected paths (shell start-up files, `~/.gitconfig`, `.envrc`, `.husky/`, `.vscode` settings, other agents' folders)? Also protect CI files? · Default: the additions, not CI files. · **Answer:**
- **U-45 (Q02-5)** · Should `ANTAI_MODE=auto` be refused (FR-CFG-05 doesn't list env vars as a source of `auto`)? · Default: refuse. · **Answer:**

## From 07 Agent Runtime

- **U-46 (Q07-6)** · On the last allowed step, remove tools to force a final answer? · Default: no, stop with the cap message. · **Answer:**
- **U-47 (Q07-7)** · An internal error inside a turn: end only that turn, or stop antai as FR-ERR-04 says? · Default: end the turn only, with a crash report. · **Answer:**
