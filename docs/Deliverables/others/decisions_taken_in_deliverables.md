# Decisions taken while writing the deliverables

One line each: what was chosen, then the other option. A line `NN-xx` summarises decision `xx` in the design-decision table of deliverable NN (HLD-D, SEC-D, SD-D, DS-D, DFD-D, UML-D, RT-D, MP-D, EXT-D); a line `NN-Ox` records a choice made while writing NN that has no number in that table. Where a line and its deliverable differ, the deliverable is right.

## Set-up

- D-001 · Register copied to `docs/Deliverables/00_DELIVERABLES_1.md` as v0.2: MCP OAuth (FR-MCP-11, AC-26) made Must to match BRD v0.3, eval pass bar marked agreed. · Other: copy v0.1 unchanged.
- D-002 · 16 design deliverables (01 to 16) plus the register (00), old web-app index adapted to a terminal agent. · Other: keep the old 12-item index as is.
- D-003 · "Database Design" became "Data & Storage Design" (local files, JSONL, no database). · Other: keep the old name.
- D-004 · "Backend Architecture" became "Agent Runtime Architecture". · Other: keep the old name.
- D-005 · "API Contracts & Conventions" became "Interface Contracts & Conventions" (internal TypeScript interfaces, event and config schemas). · Other: drop it, since there is no HTTP API.
- D-006 · "API Endpoints — Params & Responses" became "CLI, Slash Commands & Tool Schemas — Params & Responses". · Other: drop it.
- D-007 · "Observability — APM" became local logs, audit, usage and diagnostics, with no remote APM (BRD: no telemetry). · Other: opt-in OpenTelemetry export.
- D-008 · Threat model lives inside 02 Security & Authorization Design; the register's PLN-05 points there. · Other: separate `docs/security/threat-model.md`.
- D-009 · Test strategy is 14 QA; the register's PLN-06 points there. · Other: separate `docs/design/test-strategy.md`.
- D-010 · New docs added: Prompt & Context, Model & Provider, Extensibility, Terminal UI, Build/CI/Distribution. · Other: fold them into the runtime doc.
- D-011 · The duplicate "Class / UML (resolved)" entry was dropped; state machines go inside 06. · Other: a separate state-diagram doc.
- D-012 · File names are `NN_snake_case.md`. A single compiled copy, when one is made, is a plain append in number order, with a generated header and contents list. · Other: put a version in each file name.
- D-013 · Docs cross-reference each other by number and section or diagram ID, not by relative links, so references still work when the files are moved or appended into one file. · Other: Markdown links between files.
- D-014 · Diagrams are Mermaid, limited to types GitLab renders (flowchart, sequence, class, state, ER), and each is test-rendered with mermaid-cli 11.16. · Other: PlantUML, or draw.io images.
- D-015 · The deliverables are the only design of record and are read without any other design document; their choices, for example `manual` mode, are stated in them directly. · Other: keep a separate architecture document in step with them.
- D-016 · Questions for Daksh go in `others/open_questions.md`; each deliverable keeps its own open questions in its own section, and the register (00, section 10) holds the project-level ones. · Other: one file for both.
- D-017 · Creation order: library and provider fact checks, then 01 HLD, then 03 sequence and 04 storage, then 05 DFD and 06 UML, then the rest, then a consistency review. · Other: write all in parallel.
- D-018 · Diagrams must render in both Mermaid 10.7.0 (GitLab 18.0–18.10) and 11.16 (GitLab 19.x); no Mermaid 11-only syntax. · Other: target Mermaid 11 only.
- D-019 · Design set based on BRD v0.4, which landed mid-work and added decisions D23–D30. · Other: stay on v0.3.

## 01 HLD / Architecture

- 01-01 · One local Node process; background work runs on its event loop; no worker threads. · Other: a helper daemon for MCP and history.
- 01-02 · Fresh ToolLoopAgent for every stream call (each turn and each approval resumption), built from an immutable session snapshot. · Other: one long-lived agent changed in place.
- 01-03 · The event boundary carries events, commands and interaction requests (approval, trust, secret entry, terminal lease). · Other: the core calls renderer methods directly.
- 01-04 · Approval policy (POL) has no side effects and reads only read-only ports; the approval coordinator (APR) owns dialogs, audit and responses. · Other: one combined approval module.
- 01-05 · The tool registry (TREG) wraps every tool's execute with the output filter, so it can't be skipped. · Other: each tool redacts its own output.
- 01-06 · Only the process supervisor (PSV) spawns processes. · Other: spawn wherever needed.
- 01-07 · Own retry and quota guard (RTY) as model middleware, with SDK `maxRetries: 0`. · Other: SDK default retries.
- 01-08 · antai's own stdio MCP transport, spawned through PSV, if P0 confirms custom transports work. · Other: wrap `Experimental_StdioMCPTransport`.
- 01-09 · Interim UI for P1–P4 is LINE, a line-mode renderer on the event boundary. · Other: `@ai-sdk/tui` `runAgentTUI`.
- 01-10 · Experimental SDK APIs are imported only in `src/sdk/`. · Other: direct imports everywhere.
- 01-11 · Layer rules enforced in CI by dependency-cruiser and ESLint. · Other: code review only.
- 01-12 · Runtime dependencies bundled into `dist/` with lazy chunks and exact pins. · Other: normal dependencies with ranges.
- 01-13 · Zod 4 is the single schema source; JSON Schema is generated from it. · Other: hand-written JSON Schema plus Ajv.
- 01-14 · Bash parser is tree-sitter-bash WASM, loaded lazily (pending P0). · Other: `shell-quote` tokenizer.
- 01-15 · ripgrep only from PATH, never bundled, never from the workspace. · Other: bundle ripgrep.
- 01-16 · Workspace root found by walking up to `.git`, no git process. · Other: `git rev-parse`.
- 01-17 · Tool calls with side effects are serialised within a session. · Other: run a step's calls concurrently.
- 01-18 · One turn at a time; Enter is refused while a turn runs. · Other: queue the next prompt.
- 01-19 · Streamed model text is redacted (EVM) before any renderer sees it. · Other: redact only at history write.
- 01-20 · Provider keys go straight to provider factories, never into `process.env`. · Other: environment variables.
- 01-21 · The `.env` known-value scan runs in the background; tool output waits for it. · Other: scan before the prompt shows.
- 01-22 · `antai run` waits a bounded time for MCP servers before its first step. · Other: start without MCP tools.
- 01-23 · Resume closes pending approvals as interrupted (BRD). · Other: ask again on resume.
- 01-24 · Ollama through `ai-sdk-ollama`, behind the registry. · Other: `ollama-ai-provider-v2`.
- 01-25 · Own input and select components on Ink 8 hooks. · Other: `ink-text-input` and `ink-select-input`, untested on Ink 8.
- 01-26 · OAuth listener binds 127.0.0.1 and ::1; redirect URI is `http://localhost:<port>/callback`. · Other: 127.0.0.1 in the redirect URI.
- 01-27 · Debug log through a private telemetry integration; no OpenTelemetry, no devtools. · Other: `@ai-sdk/otel`.
- 01-28 · Safety rules are one data module (`src/rules/`) shared by the classifier, path guard, redactor and search. · Other: rules inside each component.

## 04 Data & Storage

- 04-01 · Local JSON and JSONL files, no database. · Other: SQLite.
- 04-02 · Session ID `YYYY-MM-DD_HHMM_<6 hex>` in UTC; file created with `wx`. · Other: UUIDs or local time.
- 04-03 · Session file created at the first user message. · Other: create it at start.
- 04-04 · Every record has `type`, `seq` and `ts`; `formatVersion` only in the header. · Other: a version on every line.
- 04-05 · Never append to an older-format file; resume forks it. · Other: files with mixed versions.
- 04-06 · Response messages written at the end of each stream call, so before every approval dialog (AC-17). · Other: write at turn end only.
- 04-07 · Synthetic "interrupted" results and repair events are written to the file. · Other: repair in memory on each resume.
- 04-08 · The model gets the stored, redacted records, so live and resumed sessions send the same bytes. · Other: keep the SDK's raw messages.
- 04-09 · The redactor works on string values inside records and leaves opaque provider fields alone. · Other: redact the serialised JSON text.
- 04-10 · Usage stored under antai's own field names, with a running session total. · Other: store the SDK usage object.
- 04-11 · Keep `index.json` (locked, atomic, no fsync, reconciled with the folder). · Other: append-only `index.jsonl` (kept as a proposal).
- 04-12 · One lock helper: `wx` lock files with pid and host. · Other: `proper-lockfile`.
- 04-13 · Audit log is one shared file per UTC day; one `O_APPEND` write per record (max 8 KB), no lock. · Other: lock per write, or one file per process.
- 04-14 · Audit record written before the matching session record. · Other: session record first.
- 04-15 · Every event goes to audit too, plus audit-only kinds and an `mcp-call` event per MCP call. · Other: audit only approvals and commands.
- 04-16 · OAuth tokens keyed by canonical MCP server URL with issuer pin; client registrations keyed by issuer. · Other: key tokens by server name.
- 04-17 · PKCE verifiers, `state` and auth codes stay in memory only. · Other: write them to disk.
- 04-18 · Atomic replace via `atomically` with 7.5 s Windows retry; fsync for credentials, trust, fingerprints, MCP files. · Other: `write-file-atomic` without retries.
- 04-19 · Windows permissions: profile folder ACLs plus best-effort `icacls` on `~/.antai`. · Other: encryption or DPAPI.
- 04-20 · `trusted.json` stores trusted and untrusted answers with a settings hash and redacted snapshot. · Other: hashes of trusted folders only.
- 04-21 · Drift baselines in `mcp-fingerprints.json` with full tool definitions; updated only when the user accepts. · Other: hashes inside `mcp.json`.
- 04-22 · Retention sweep in background with a lock; checks index time and file time; skips if config invalid. · Other: sweep before the prompt, trusting the index.
- 04-23 · Corrupt files moved aside as `.corrupt-<ts>`; unreadable sessions go to `quarantine/`. · Other: overwrite or delete.
- 04-24 · Debug log is one JSONL per session, 10 MiB, one rotation; crash reports separate. · Other: one global log.
- 04-25 · No cross-session prompt history file. · Other: a cross-session `history.jsonl` of prompts.
- 04-26 · `antai mcp add/remove` keep comments and leave `mcp.json.bak`. · Other: rewrite with `JSON.stringify`.
- 04-27 · Workspace = home folder: `~/.antai` loaded once, as global. · Other: load it twice.
- 04-28 · No fsync per record; one fsync when the handle closes. · Other: fsync per record or per turn.
- 04-29 · If the audit log can't be written, calls that need an audit record are denied (beyond the BRD). · Other: warn and continue.

## 03 Sequence Diagrams

- 03-01 · Trust check and prompt come before the key lookup at start (01 updated to match). · Other: key prompt first.
- 03-02 · Instruction files and skills load in the background; the first submit waits; profiles stay on the critical path. · Other: load everything before the prompt.
- 03-03 · Session file (header, lock) created with the first user message, as in 04-03. · Other: create the file at start.
- 03-04 · Step messages kept from `onStepEnd` and written when a stream call ends or on abort. · Other: write at turn end only.
- 03-05 · After an approval, the agent is rebuilt with `isStepCount(maxSteps − used)` (01 updated to match). · Other: reuse the agent, which restarts the cap.
- 03-06 · AG's `toolApproval` wrapper records the policy decision by `toolCallId`; automatic decisions audited from `isAutomatic` parts. · Other: POL writes audit itself.
- 03-07 · "Don't ask again" only for Normal shell commands, exact text, in memory, not restored on resume. · Other: also for writes, or persisted.
- 03-08 · Esc in a dialog = No and the turn continues; Ctrl+C in a dialog interrupts the turn. · Other: Esc interrupts the turn.
- 03-09 · Synthetic interrupted results written at interruption, worded "check effects before re-running". · Other: bare "interrupted", repaired on resume.
- 03-10 · Still over the context limit after pruning: typed error, turn stops with a `/compact` hint. · Other: send anyway and map the provider error.
- 03-11 · Title call runs in the background through RTY, skipped when the budget is short; `run` uses the first prompt. · Other: title call before `run` exits.
- 03-12 · An explicit trust "No" is stored; `/trust` changes it from the next start. · Other: ask at every start.
- 03-13 · No network check of a new key at first run; Esc exits 2. · Other: validate by listing models.
- 03-14 · `antai login` needs a TTY. · Other: read the key from stdin.
- 03-15 · Windows: the shell runner refuses `sudo` with a tool error. · Other: run it and let it fail.
- 03-16 · OAuth provider attached only to HTTP servers with no configured `Authorization` header. · Other: attach to every HTTP server.
- 03-17 · Step-up on 403 asks before a new browser login; `run` gets a tool error. · Other: automatic browser login.
- 03-18 · Drift baseline replaced only when acknowledged in `/mcp`. · Other: replace after one warning.
- 03-19 · Index lock busy after 2 s: skip the write, reconcile later. · Other: wait for the lock.
- 03-20 · Retention sweep skipped when config is unreadable. · Other: fall back to 30 days.
- 03-21 · `--continue` with nothing to continue starts a new session with a notice. · Other: exit 2.
- 03-22 · Resume appends its repairs before the first new turn. · Other: repair in memory each time.
- 03-23 · Shell card shows elapsed time; output appears when the command ends. · Other: live output in the card.

## 05 Data Flow Diagrams

- 05-01 · Each flow gets a sensitivity class and a separate trust level. · Other: one combined label.
- 05-02 · `SEC` (may go nowhere) kept apart from `CRD` (may go only to its owner). · Other: one "secret" class.
- 05-03 · Classic DFD shapes in flowcharts; forbidden flows drawn as "never" arrows that tests check. · Other: prose list of forbidden flows.
- 05-04 · Level 0 shows workspace and `~/.antai` as external entities; level 1 splits them into stores D1–D13. · Other: stores at level 0.
- 05-05 · Flow IDs X (boundary) and N (internal), separate from 04's F/W IDs. · Other: number flows per diagram.
- 05-06 · Every stored record reaches the stores only through the redactor (6.0); only credentials, trust answers, drift baselines and CLI MCP file edits bypass it. · Other: redaction drawn as a sub-step inside persistence.
- 05-07 · Redactor drawn as its own level 1 process (6.0), on all five paths. · Other: one redaction step per path.
- 05-08 · Memory-only stores M1–M4 drawn, so "never stored" claims can be checked. · Other: leave memory out.
- 05-09 · `sudo` password and browser sign-in drawn as flows that bypass antai. · Other: omit them.
- 05-10 · Indirect outbound paths (approved commands, stdio servers, `npx`) listed with antai's own. · Other: antai's own connections only.
- 05-11 · MCP tool definitions treated as a prompt-injection input of their own. · Other: treat them as configuration.
- 05-12 · Model output classed untrusted even after storage. · Other: conversation content only.
- 05-13 · Level 1 processes follow the data, not the code layers. · Other: one process per layer.
- 05-O1 · (Orchestrator) First user message waits, bounded, for the `.env` scan; 03 updated. Fixed 04's W5/W6 diagram labels to match its table. · Other: send without waiting.

## 09 Model & Provider Integration

- 09-01 · Providers, presets and models are data files (`providers.json`, `models.json`). · Other: logic in code.
- 09-02 · SDK `maxRetries: 0`; RTY middleware is the only retry. · Other: SDK default retries.
- 09-03 · 5 attempts (3 for timeouts), back-off 2 s doubling to 10 s ±20 %, server hints up to 60 s, 120 s total. · Other: 10 attempts.
- 09-04 · A server wait over 60 s is final, with the reset time shown. · Other: 300 s or 15 min.
- 09-05 · No retry after the first content part. · Other: retry whole steps.
- 09-06 · Per-minute token guard for Groq only in v1. · Other: guard every provider with headers.
- 09-07 · The guard counts the expected cached prefix as free until P0 measures. · Other: count every input token.
- 09-08 · No guard before the first rate-limit snapshot; no client-side RPM pacing. · Other: pace from catalogue limits.
- 09-09 · Always send `maxOutputTokens`; Groq gpt-oss 4,096 (provisional). · Other: provider defaults (65,536 alone exceeds 8K TPM).
- 09-10 · `/effort` keeps the BRD's five levels via portable `reasoning`. · Other: expose minimal, xhigh, max.
- 09-11 · SDK warnings become one notice per model and level; SDK console logger off. · Other: show raw SDK warnings.
- 09-12 · Unknown models allowed with a 32k default and a notice. · Other: catalogued models only.
- 09-13 · `models` key: no colon = alias, colon = metadata. · Other: a separate key.
- 09-14 · A bare word resolves as an alias first, then as a provider's default model. · Other: aliases only.
- 09-15 · No `--api-key` flag. · Other: a key flag for scripts.
- 09-16 · Keys passed explicitly to factories; key variables registered with RED. · Other: packages read their own variables.
- 09-17 · Key prefix check warns only. · Other: validate with a network call.
- 09-18 · Trust prompt names the key each provider setting would receive (CR-08). · Other: show base URLs only.
- 09-19 · On a switch, strip reasoning and other providers' metadata by producing provider. · Other: strip everything after any switch.
- 09-20 · OpenAI Responses with `store: false` and encrypted reasoning. · Other: default `store: true`.
- 09-21 · Google `includeThoughts: true`. · Other: no thought summaries.
- 09-22 · Ollama via `ai-sdk-ollama`, `numCtx` 32,768; P0 spike decides. · Other: decide without a bake-off.
- 09-23 · Google data-use notice once per session; only global config silences it. · Other: persisted acknowledgement.
- 09-24 · Title call on the provider's `fast` model with low effort. · Other: the session model.
- 09-25 · Retired models kept in the catalogue; warn, never block. · Other: remove or block them.
- 09-26 · Connection refused on loopback is not retried. · Other: retry like any network error.
- 09-27 · Provider packages loaded lazily. · Other: import all at start.
- 09-28 · Quota and error-text patterns kept as data. · Other: hard-coded parsing.

## 10 Extensibility

- 10-01 · Instruction files re-read before each turn; profiles, skills and MCP config read at start (04 updated). · Other: everything at start only.
- 10-02 · A whitespace-only instruction file counts as absent. · Other: load the empty file as "first found".
- 10-03 · No import or include syntax in instruction files. · Other: `@path` import lines.
- 10-04 · Extension files resolved with realpath; secret targets and project links outside the workspace refused. · Other: follow links as they are.
- 10-05 · Instruction, profile and skill text passes RED before reaching the model. · Other: send as written.
- 10-06 · A skill's identity is its folder name; a missing or different `name` only warns (beyond the BRD). · Other: skip the skill (FR-SKL-01).
- 10-07 · Untrusted project skills and profiles never replace a global or built-in one of the same name. · Other: BRD as written (global skills only).
- 10-08 · `load_skill` takes an enum of catalogue names; hidden when the catalogue is empty. · Other: free-text name, always present.
- 10-09 · Skill bodies capped at 20 KB. · Other: 50 KB like `read_file`.
- 10-10 · `load_skill` is Safe in every mode, including research. · Other: Normal tier.
- 10-11 · `antai run "/<skill> …"` expands user-invocable skills. · Other: interactive only.
- 10-12 · Built-in skills use only the six spec fields. · Other: extra frontmatter fields outside the spec.
- 10-13 · Profile `match` allows `*` and `?` on root entry names, no paths. · Other: exact names.
- 10-14 · Unknown `--profile`: error notice interactively, exit 2 in `run`. · Other: always start, or always fail.
- 10-15 · An unknown pinned profile means no profile, no fallback to auto-match. · Other: fall back to auto-match.
- 10-16 · `${VAR}` and `${VAR:-default}` only in `env` and `headers`. · Other: all five fields (`command`, `args`, `url`, `env`, `headers`).
- 10-17 · Project MCP files can't reference provider-key or `ANTAI_*` variables. · Other: allow once trusted.
- 10-18 · `url` without `type` treated as `http` with a warning; `streamable-http` alias accepted. · Other: skip the entry.
- 10-19 · Server name clash after sanitising skips the later server. · Other: hash suffixes.
- 10-20 · Tool names over 64 chars cut plus 8 hex of a hash. · Other: sequential numbers.
- 10-21 · New per-server `enabled`, `startupTimeoutMs` (30 s), `toolTimeoutMs` (120 s) (04 updated). · Other: global timeouts only.
- 10-22 · A crashed stdio server isn't restarted automatically; Reconnect in `/mcp`. · Other: auto restart with back-off.
- 10-23 · First interactive turn doesn't wait for MCP; `run` waits up to each server's start-up timeout. · Other: one fixed global wait.
- 10-24 · MCP tool descriptions cut at 2,000 chars; server `instructions` never sent to the model. · Other: pass both as given.
- 10-25 · No MCP resources, prompts, sampling, roots, logging or elicitation in v1. · Other: MCP prompts as slash commands.
- 10-26 · Non-text MCP results become placeholders. · Other: pass images to the model.
- 10-27 · Protocol headers in config dropped with a warning. · Other: allow overrides.
- 10-28 · `antai mcp add --project` updates the trust hash only if nothing else changed. · Other: always re-ask, or always update.
- 10-29 · Non-loopback `http://` MCP URLs refused; OAuth endpoints https and not private (loopback exception for loopback MCP servers, AC-26 tests). · Other: warn and allow.
- 10-30 · Login refused when authorization-server metadata is missing. · Other: rely on the SDK's legacy fallback.
- 10-31 · Validation never blocks start: findings per unit, summary line, details in slash views. · Other: fail on first error.
- 10-32 · `PROFILE.md` `name` strict; `SKILL.md` `name` lenient. · Other: one rule for both.

## 06 Class / UML & Domain Model

- 06-01 · One mutable SessionState inside SC; a frozen SessionSnapshot per stream call for everyone else. · Other: a shared mutable settings object.
- 06-02 · Lower layers declare narrow views (PolicySnapshot, TurnSpec, ToolSetSpec) that the snapshot satisfies. · Other: one snapshot type in shared/.
- 06-03 · New types-only module `src/shared/domain/` (01 updated). · Other: duplicate the unions per layer.
- 06-04 · Discriminated unions with kebab-case `type` for events, commands, answers. · Other: class hierarchies.
- 06-05 · Classes only for stateful or port-injected components; the rest pure functions. · Other: everything a class.
- 06-06 · POL uses antai types; AG converts to and from SDK types. · Other: POL takes SDK types.
- 06-07 · Tier includes `hard-floor` as top rank; `maxTier([])` gives dangerous. · Other: separate hard-floor flag.
- 06-08 · Dialog plan is an ordered list of DialogKind (`confirm`, `danger`). · Other: a dialog count.
- 06-09 · ToolPreviewer port (implemented by TREG) for approval previews. · Other: APR calls BT directly.
- 06-10 · One InteractionRequest per dialog. · Other: one request for both dialogs.
- 06-11 · POL reads read-only ports (audit health, MCP status, path guard); no side effects, not strictly pure (01 updated). · Other: freeze these facts in the snapshot.
- 06-12 · MCP status is one state machine per server; drift is a sub-state of Connected. · Other: status string plus drift flag.
- 06-13 · MOA has an explicit mode (login or background). · Other: two provider classes.
- 06-14 · Credential is abstract (ProviderKey, OAuthTokenSet); client registration separate, keyed by issuer. · Other: one flat secrets map.
- 06-15 · EVM created per turn with one RedactionStream per text id. · Other: one stream for all text.
- 06-16 · EVM's switch over all 26 stream parts is exhaustive. · Other: a default branch.
- 06-17 · AgentEvent adds turn-start, tool-progress and approval (01 updated). · Other: renderers infer them.
- 06-18 · Session allow-list checked only where the matrix asks (Normal shell calls). · Other: check before the matrix.
- 06-19 · Tool set built once per turn; approval resumptions reuse it. · Other: rebuild per stream call.
- 06-20 · `/mode` may leave skip; nothing re-enters it. · Other: skip locked until restart.
- 06-21 · HS and AUD call RED themselves and write only RedactedText; `HS.reserveSeq` gives the shared seq. · Other: each producer redacts before append.
- 06-O1 · (Orchestrator) Agent rebuilt per stream call, not per turn (01 HLD-D2 updated to match 03). · Other: per turn.

## 02 Security & Authorization

- 02-01 · Threat model kept inside 02; STRIDE per DFD element; OWASP 2025/2026 and ASI mapping; updated at P2, P3, P4. · Other: separate threat-model file.
- 02-02 · Destructive raw-text matches are final; secret-path mentions confirmed after parsing, hard floor if parsing fails. · Other: raw-text match only.
- 02-03 · Safe rules list the options they allow; any other option makes the command Normal. · Other: lists of banned options.
- 02-04 · Variable assignments and `export` lift to Normal; PATH, LD_PRELOAD, GIT_SSH_COMMAND and similar are Dangerous. · Other: drop assignments silently.
- 02-05 · Dangerous additions: `rm -r`/globs, git commands that discard work, ssh, gh/glab publishing, persistence; `env`/`printenv` Normal. · Other: leave them Normal.
- 02-06 · `cd` outside the workspace lifts later segments; a non-literal program name is Dangerous. · Other: classify words as written.
- 02-07 · A classifier exception denies the call; a failed rule self-test disables shell, write, edit and MCP tools. · Other: treat as Dangerous.
- 02-08 · One secret-path list including `credentials.json*`. · Other: exact file only.
- 02-09 · `run` in a home-folder workspace continues in research/manual, exits 2 in auto/skip. · Other: always exit.
- 02-10 · `extraReadPaths` from global config only; entries under `~/.antai` dropped. · Other: any path.
- 02-11 · Windows paths: strip trailing dots and spaces; refuse alternate data streams, device and drive-relative paths. · Other: rely on realpath.
- 02-12 · Protected-path additions: more shell start-up files, `~/.gitconfig`, `.envrc`, `.husky/`, `.vscode` settings and tasks, other agents' folders. · Other: BRD list only.
- 02-13 · Instruction text, skill bodies and MCP descriptions redacted before each request. · Other: tool output only.
- 02-14 · Streamed text holds back the trailing word (a run without whitespace is released after 8 KB, except its last L − 1 characters), and an open PEM block until its end, at most 16 KB. · Other: no hold-back.
- 02-15 · `.env` values re-checked by modification time each turn and after each command. · Other: file watcher.
- 02-16 · Project `secrets.patterns` checked statically; unsafe ones dropped. · Other: require trust.
- 02-17 · Stored keys never shown, not even in part. · Other: show the last 4 characters.
- 02-18 · Trust table adopts 04's P3 and P6; extends CR-08 to `apiKeyEnv` and provider options. · Other: fewer gated keys.
- 02-19 · `ANTAI_MODE` cannot set `auto`. · Other: allow it as a config layer.
- 02-20 · Global `mcp.tools.allow` applies only to the same server identity. · Other: match by name.
- 02-21 · Explicit `destructiveHint: true` beats `mcp.tools.allow`; no hint means Normal. · Other: allow entry wins.
- 02-22 · `http://` MCP URLs refused unless loopback. · Other: connect without credentials.
- 02-23 · Windows `cmd.exe /c` launcher args with metacharacters refused. · Other: escape them.
- 02-24 · OAuth hardening: 32-byte `state`, Host check, bad callbacks keep login waiting, HTTPS and address checks (loopback MCP exception). · Other: SDK defaults.
- 02-25 · Piped stdin wrapped in delimiters with a per-process random token. · Other: fixed delimiter.
- 02-26 · Dialogs escape control, bidi and other invisible characters (FR-UI-04); renderers neutralise escape sequences from untrusted text. · Other: raw text.
- 02-27 · Audit failure denies side effects; no hash chain in v1. · Other: warn and continue.
- 02-28 · `sudo -k` after each captured sudo run. · Other: leave the credential cached.
- 02-29 · `${VAR}` only in `headers` and `env`; a reference in `command`, `args` or `url` skips the entry. · Other: substitute in `args`.
- 02-30 · Skip mode not gated further in non-interactive runs. · Other: extra environment opt-in.
- 02-31 · Product owner accepts residual risks on the Security reviewer's advice at P2, P4, P6. · Other: Tech lead accepts.

## 07 Agent Runtime

- 07-01 · Agent rebuilt per stream call with remaining steps; tool set and instruction sources fixed per turn. · Other: re-read sources each resumption.
- 07-02 · Steps counted from `onStepEnd` callbacks. · Other: count model requests in RTY.
- 07-03 · An approval request in the last allowed step is closed unrun with the cap message, no dialog. · Other: show the dialog and allow a 26th step.
- 07-04 · First user message waits up to 5 s for the `.env` scan, then sends with a notice. · Other: send at once.
- 07-05 · One FIFO lock by call index for writes, shell and MCP; read-only built-ins up to 4 in parallel. · Other: serialise everything.
- 07-06 · PSV kills leftover process-group members after a command's leader exits. · Other: leave survivors until shutdown.
- 07-07 · Every program spawned by absolute path resolved outside the workspace. · Other: spawn by bare name.
- 07-08 · SIGINT ignored by antai while the `sudo -v` terminal lease is active. · Other: spawn `sudo -v` detached.
- 07-09 · Command completion = leader exit, group sweep, then at most 500 ms of pipe drain. · Other: wait for 'close'.
- 07-10 · AbortController tree with typed reasons; tools ignoring abort abandoned after 2 s. · Other: per-component cancel flags.
- 07-11 · Stall watchdog: first part within 60 s (300 s local), notice at 20 s, abort at 90 s. · Other: no watchdog.
- 07-12 · Tool-output `.env` gate never opens on a timer; notice at 10 s. · Other: open after a timeout.
- 07-13 · Internal errors inside a turn end only that turn, with a crash report. · Other: exit on every internal error.
- 07-14 · Shutdown in bounded steps, 5 s watchdog, second signal forces exit. · Other: unbounded graceful shutdown.
- 07-15 · Entry chunk excludes `ai`, providers, Ink, MCP, parser, tokenizer; preloaded after the first frame. · Other: load on first use.
- 07-16 · Plain renderer pauses the model stream above 1 MiB buffered output. · Other: unbounded buffering.
- 07-17 · `mock:` provider only in the test build. · Other: env-var hook in the release build.
- 07-18 · Tools record effects through an `EffectRecorder`; SC writes audit then session. · Other: tools import HS/AUD.
- 07-19 · `toolApproval` wrapper idempotent per `toolCallId`, fails closed; POL keeps async read-only ports. · Other: pre-resolve facts in AG.
- 07-O1 · Child environments keep provider-key variables the user exported; only keys stored by antai are never added (follows 02). · Other: strip all provider-key variables.
