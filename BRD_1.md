# antai — Business Requirements Document (BRD) v1

| | |
|---|---|
| **Product** | antai (brand) / `antai` (command) |
| **Document** | BRD_1, requirements for the v1 MVP |
| **Status** | Draft for review |
| **Version** | 0.4 |
| **Date** | 12 October 2026 |
| **Author** | Daksh Nagpal |
| **Research basis** | "Building CLI Agents with the Vercel AI SDK v7" (two-part research guide, 9 October 2026) |

### Change log

| Version | Date | Change |
|---|---|---|
| 0.1 | 12 Oct 2026 | First draft from the requirements interview |
| 0.2 | 12 Oct 2026 | Windows shell commands run through Git Bash in v1 (one bash rule set for all three OSes). PowerShell fallback moved to v1.1. |
| 0.3 | 12 Oct 2026 | Review batches 1–3 (see `BRD_1_review.md`). `build` mode renamed `manual`. G5 reworded. Non-goals clarified (sandbox, network destinations) and three added. Scope rows for providers and instructions aligned with section 5. Out-of-scope rows tightened. MCP OAuth login moved from Could to Must (FR-MCP-11, AC-26, D22). |
| 0.4 | 12 Oct 2026 | Review batches 6–13 applied (see `BRD_1_review.md`). Security: protected paths (FR-TOOL-11), one secret-path list for every tool and command, Safe tier limited to the workspace, stricter classifier, trust re-asked on change, project profiles cannot set `auto`. Audit log always kept (FR-HIS-13). Commands run in bash on every OS. OpenAI-compatible endpoints and presets (FR-MOD-08). New AC-27 to AC-35. Phases re-sequenced. Decisions D23 to D30. |

---

## Contents

1. [Overview](#1-overview)
2. [Scope](#2-scope)
3. [Users](#3-users)
4. [User perspective](#4-user-perspective)
5. [Functional requirements](#5-functional-requirements)
6. [Non-functional requirements](#6-non-functional-requirements)
7. [Constraints and assumptions](#7-constraints-and-assumptions)
8. [Architecture overview](#8-architecture-overview)
9. [Acceptance criteria](#9-acceptance-criteria)
10. [Delivery phases](#10-delivery-phases)
11. [Risks](#11-risks)
12. [Decision log and open questions](#12-decision-log-and-open-questions)
13. [Glossary](#13-glossary)

Priorities use MoSCoW: **Must** (v1 is not done without it), **Should** (expected in v1, can slip to v1.1), **Could** (if time allows).

---

## 1. Overview

### 1.1 What we are building

antai is a **versatile AI agent that runs in the terminal**. You talk to it in plain language and it gets work done on your machine: it reads and searches files, writes and edits them, runs shell commands, follows skills, and uses tools from MCP servers. It asks before it does anything risky, and it asks twice before anything dangerous.

antai has **no fixed job**, and it does not need one to be useful. It is like a capable new hire: on day one it can already handle most general tasks. You specialise it the way you onboard a person: instruction files (`AGENT.md` and friends) are the team's rules, a profile is the job role, skills are the playbooks, and MCP servers are access to company systems. The same binary can be a coding assistant in one repository and an ops helper in another.

It is built in TypeScript on the **Vercel AI SDK v7**, uses **Groq** by default, and can switch to Gemini, OpenAI, Anthropic or a local Ollama model through configuration.

### 1.2 The problem

- Developers already live in the terminal, but general chat assistants cannot see or act on their files and tools.
- Existing terminal agents are tied to one vendor's models, or are closed products that cannot be adapted with in-house instructions, skills and safety rules.
- Agents that can run shell commands are dangerous without a clear, predictable permission model. One prompt-injected file can delete data or leak secrets.

### 1.3 Goals

| # | Goal | How we will know |
|---|---|---|
| G1 | **Versatile.** One agent that adapts to any task through instructions, profiles, skills and MCP, without code changes. | The same install handles a coding task, a file-organising task and a documentation task by switching only configuration. |
| G2 | **Safe by default.** Risky actions are visible, approved and auditable. Secrets never reach the model. | No path in the test suite lets the model read a `.env` value. Every write and shell command appears in the session audit trail. |
| G3 | **Provider-independent.** Any AI SDK provider through configuration. Free to start (Groq). | Switching provider is a config or `/model` change. No code change is needed. |
| G4 | **Production quality.** Feels like a product: fast, clear, resumable, works on macOS, Linux and Windows. | Acceptance tests pass on all three operating systems in CI. |
| G5 | **Extensible without code.** Teams add behaviour by writing Markdown (instructions, profiles, skills), not TypeScript. | A skill or profile folder placed in a recognised location appears in `/skills` or `/profile` on the next start, with no build or install step. Invalid files are listed with the reason they were skipped. |

### 1.4 Non-goals for v1

- A web, desktop or IDE interface. antai is terminal only.
- True process isolation for shell commands: containers, VMs, or OS-native sandboxes (macOS Seatbelt, Linux bubblewrap or Landlock). v1 uses guardrails, not a sandbox (see 11, R1). OS-native sandboxes are deferred because Windows has no equivalent and v1 keeps one behaviour on all three OSes.
- Multi-agent orchestration (sub-agents, parallel agents).
- A hosted service. antai runs entirely on the user's machine and talks only to the chosen model provider, the configured MCP servers and their OAuth login servers.
- Organisation-managed policy. Admins cannot lock settings that users cannot override.
- Memory across sessions, beyond resuming a stored session (`--continue`, `--resume`).
- Self-update or update checks. antai itself makes no network calls besides the model provider, MCP servers and their OAuth login servers.

---

## 2. Scope

### 2.1 In scope for v1

| Area | Summary |
|---|---|
| Agent core | Streaming tool-loop agent built on AI SDK v7 `ToolLoopAgent` |
| Providers | Groq (default) and Google Gemini (Must); OpenAI, Anthropic, Ollama and any OpenAI-compatible endpoint, with presets for OpenRouter, Together AI, Fireworks AI, DeepSeek, Mistral, xAI and LM Studio (Should). Selected through config and `/model`. |
| Built-in tools | Read, write and edit files. List directories, find files by pattern, search file contents. Shell commands. Load skills. |
| Shell safety | Four command tiers, mode-dependent approvals, double approval for dangerous commands, a fixed hard floor |
| Secrets | No direct reads of `.env` files or other secret files (SSH keys, cloud credentials, antai's own credentials) by any tool or command; indirect use allowed; redaction of secret values in all tool output |
| Modes | `research`, `manual` (default), `auto`, plus the launch-only `--dangerously-skip-permissions` |
| Instructions | Global and project instruction files. `AGENT.md`, `AGENTS.md` and `CLAUDE.md` are recognised (case-insensitive); the first found in each folder is loaded (FR-INS-03). |
| Profiles | Session-wide presets: instructions plus optional defaults. Manual, auto-matched or pinned per project. |
| Skills | agentskills.io-style `SKILL.md` folders, loaded on demand or invoked as `/skill-name` |
| MCP client | stdio and Streamable HTTP servers, from global and project config. Static bearer tokens, custom headers, and OAuth login. |
| Chat history | Global JSONL sessions with resume, list, redaction and retention, plus an audit log that is always kept |
| Slash commands | `/help`, `/model`, `/effort`, `/mode`, `/profile`, `/skills`, `/mcp`, `/history`, `/resume`, `/clear`, `/usage`, `/exit` and others (see 5.11) |
| Interface | Rich Ink TUI when interactive. Plain text or JSON when piped or scripted. |
| Platforms | macOS, Linux and native Windows. Agent commands run in bash on every OS: system bash on macOS and Linux, Git Bash on Windows. |

### 2.2 Out of scope for v1

| Item | Why, and where it goes instead |
|---|---|
| Container, VM or OS-native sandbox for commands | Heavy for an MVP. Planned for a later version (Docker or a cloud sandbox). OS-native sandboxes are deferred for Windows parity (see 1.4). |
| Long-running background processes (dev servers, watchers) | Commands are killed at their timeout in v1. Commands that detach (trailing `&`, `nohup`, `setsid`, `disown`) are refused, so nothing outlives its timeout. Background jobs are planned for v2. |
| Built-in web search or web fetch | Available through MCP servers instead. |
| Sub-agents and parallel agents | Complexity. Revisit after v1. |
| MCP login methods other than static tokens and OAuth browser login | v1 supports static bearer tokens and custom headers for servers that issue them (e.g. personal access tokens), and OAuth browser login for hosted servers that issue tokens only through OAuth (FR-MCP-11). Device-code login for headless machines, client-credentials and enterprise SSO come later. |
| OS keychain storage for API keys | v1 uses environment variables or a permission-restricted credentials file. Keychain storage is planned for v1.1, because OAuth refresh tokens are stored too. |
| PowerShell or `cmd.exe` as the shell for agent commands on Windows | v1 uses Git Bash, so one rule set covers all three OSes. A PowerShell fallback for Windows machines without Git is planned for v1.1. |
| Image, audio or file attachments as input | Not in v1. Users reference files by path; `read_file` reads text files only. Revisit after v1. |
| Telemetry or usage reporting to any server | None. antai has no telemetry (see 6.6). |

---

## 3. Users

### 3.1 Personas

| Persona | Who | What they want from antai |
|---|---|---|
| **Developer in a repo** (primary) | Engineer working in a codebase daily | Understand code, fix bugs, run tests and git, write commit messages, without leaving the terminal |
| **Power user / scripter** | Engineer automating tasks | One-shot runs in scripts and CI (`antai run ...`), piped input, JSON output |
| **Team lead / configurator** | Senior engineer setting up a team's workflow | Shared profiles, skills, instruction files and MCP servers checked into a repo, safety rules the team can trust |
| **General terminal user** | Anyone comfortable with a terminal | File chores, scripts, system questions in plain language |

### 3.2 Environments

- macOS, Linux and Windows 10/11. On Windows, the shell tool needs Git for Windows (which provides Git Bash). Everything else works without it.
- Node.js 22 or newer (24 recommended).
- Any modern terminal: Terminal.app, iTerm2, GNOME Terminal, Windows Terminal, VS Code's integrated terminal.
- Works with or without a git repository.

---

## 4. User perspective

This section describes antai as the user experiences it. Every journey maps to the functional requirements in section 5.

### 4.1 First run and setup

```
$ npm install -g antai
$ antai

  Welcome to antai.
  No API key found for Groq (the default provider).
  Get a free key at https://console.groq.com/keys

  Paste your GROQ_API_KEY: ••••••••••••••••
  Saved to ~/.antai/credentials.json (readable only by you).

╭─ antai ─────────────────────────────────────────────────────────────╮
│ Ready. Type a request, or / for commands.                           │
╰─────────────────────────────────────────────────────────────────────╯
 groq · openai/gpt-oss-120b · manual · effort: default · profile: none · ~/shop-api · 0 tokens   /help
```

- If the key is already in the environment (`GROQ_API_KEY`), antai skips the prompt.
- `antai run` never prompts. With no key it exits with an error that names the environment variable to set.
- On Windows without Git for Windows, antai starts normally and shows one notice: `Shell commands are off: install Git for Windows (https://git-scm.com/download/win) or set ANTAI_GIT_BASH_PATH.` File, search, skill and MCP tools still work.
- The first time antai opens a folder whose project settings need trust (MCP servers, allowlist entries, a mode, a model, provider settings or a profile pin), it asks whether to **trust** the folder (4.10).

### 4.2 Everyday chat

```
you › why is the auth test failing?

 ▸ shell   npm test -- auth          ✓ 2.1s
 ▸ read    src/auth/token.ts         ✓
 ▸ grep    "expiresAt" in src/       ✓ 4 matches

 The expiry check in src/auth/token.ts:42 uses `<` instead of `<=`, so a
 token that expires in the current second is rejected. Want me to fix it?

 1.9k in · 210 out
```

- Answers stream token by token, and Markdown (code blocks, lists, tables) renders properly.
- Each tool call appears as a one-line card. Ctrl+O expands the latest card to show input and output; Ctrl+T opens the full transcript.
- `npm test -- auth` ran without a prompt because the user added `npm test` to the allowlist in their config. Allowlist entries match whole words from the start of a command.

### 4.3 Approving a change

```
you › yes, fix it

 ▸ edit    src/auth/token.ts
   ┌──────────────────────────────────────────────┐
   │ - if (now < token.expiresAt) {               │
   │ + if (now <= token.expiresAt) {              │
   └──────────────────────────────────────────────┘
   Apply this edit?
   › Yes   (Enter)
     No

 ▸ shell   npm test -- auth          ✓ 1.8s   all 12 tests pass
 Fixed. The boundary case now passes.
```

- In `manual` mode, writes, edits and normal shell commands ask once. Enter approves.
- For a Normal shell command, the dialog also offers **Yes, don't ask again this session**, which covers that exact command until the session ends.
- Edits show a diff before approval.

### 4.4 A dangerous command

```
 ▸ shell   sudo rm -rf ./build

   Run this command?
   › Yes   (Enter)
     No

   ▲ DANGEROUS COMMAND
   sudo rm -rf ./build
   Deletes files recursively with administrator rights.
   Do you want to perform this action?
   › No    (default; Enter cancels)
     Yes
```

- Dangerous commands need two approvals in `manual` mode. The second dialog is red, defaults to **No**, and needs an arrow-key move to reach Yes.
- In `auto` mode only the second, red dialog appears.
- The reason line in the red dialog comes from the classifier rule that matched, never from the model.
- For `sudo`, antai first hands the terminal to `sudo -v`, so the user types the password into sudo directly; antai never sees or stores it. The command then runs with its output captured and redacted like any other.

### 4.5 Secrets stay secret

```
you › show me what's in .env

 ▸ read    .env                       ✗ denied: secret files are off limits

 I can't read .env files. I can help you check which variables your code
 expects, or create a .env.example with placeholder values.
```

```
you › start the dev server and tell me if it boots

 ▸ shell   npm run dev                ⏱ stopped at 30s timeout, output kept
 It boots and connects to the database. The DATABASE_URL it printed was
 [REDACTED:DATABASE_URL].
```

- Commands that **use** `.env` internally run normally.
- Known dev-server commands have a 30-second timeout, so a boot check does not wait the full 120 seconds.
- Any secret value that appears in output is masked before the model or the history file sees it.

### 4.6 Skills

```
you › give me a tour of this repo
 ▸ skill   repo-tour                  ✓ loaded
 ...

you › /commit-message
 ▸ skill   commit-message             ✓ (invoked)
 ▸ shell   git diff --staged          ✓
 feat(auth): accept tokens on their exact expiry second
```

- Skills load **automatically** when a request matches their description, or **explicitly** with `/skill-name`.
- `/skills` lists every available skill and where it was loaded from.

### 4.7 Switching model, effort, mode and profile

```
you › /model
   › groq:openai/gpt-oss-120b      (current)
     groq:llama-3.3-70b-versatile
     google:gemini-3.5-flash
     ollama:qwen3:14b
 model → google:gemini-3.5-flash

you › /effort low
 effort → low

you › /mode research
 mode → research (read-only: no writes, no state-changing commands)

you › /profile node-dev
 profile → node-dev (adds Node.js instructions; default mode manual)
```

- The status bar always shows provider, model, mode, effort, profile and tokens.
- If the current folder matches a profile's auto-match rule, antai loads it at start and shows `profile: node-dev (auto)`.
- Switching profile mid-session never loosens the current mode; a looser mode needs `/mode`.
- Models from OpenAI-compatible presets (for example `openrouter:<model>`) appear in the same picker once their key is set.

### 4.8 MCP servers

```
$ antai mcp list
  github       http    ✓ connected   34 tools
  filesystem   stdio   ✓ connected   14 tools
  postgres     stdio   ✗ failed: command not found: uvx
  linear       http    ⚠ needs login   run: antai mcp login linear

you › list my open pull requests on shop-api
 ▸ mcp     github · list_pull_requests     Allow?  › Yes
```

- MCP tools appear alongside built-in tools. Calls that can change state ask for approval in `manual` mode.
- A server that fails to start shows an error but does not stop antai.
- A hosted server that issues tokens only through OAuth shows **needs login** until the user runs `antai mcp login <name>`.

### 4.9 History and resume

```
$ antai --continue
 Resuming "Fix failing auth test" (today 14:32, 6 turns)

you › /history
   Fix failing auth test          today 14:32     6 turns   15.4k tokens
   Add rate limiting to /login    yesterday       11 turns  42.0k tokens
 /resume <number> to open one
```

- `--continue` resumes the most recent session for the current project.
- `/clear` starts a new session. Old sessions are kept until retention deletes them.

### 4.10 Trusting a project folder

```
$ cd ~/Downloads/someone-elses-repo && antai

  This folder contains antai project settings that need trust:
    • MCP server "db": npx -y @example/postgres-mcp   (.antai/mcp.json)
    • MCP server "docs": https://mcp.example.com/mcp  (.mcp.json)
    • shell allowlist: make test, make lint
  Also loaded either way: instructions (AGENTS.md), 2 skills, 1 profile
  Trust this folder?   › No (instructions, profiles and skills only)   Yes
```

- Untrusted folders still load instruction files, skills and profile instructions, but not project MCP servers, allowlist additions, a project mode, model, provider settings or profile pin.
- If the trusted settings change later (for example after a `git pull`), antai asks again.

### 4.11 Scripts and CI

```
$ antai run "summarise the changes in the last 5 commits"
$ git diff | antai run "review this diff for bugs" --json
$ antai run --mode auto "update the copyright year in all LICENSE files"
```

- One-shot runs default to `research` mode, because nobody is present to approve.
- In non-interactive runs, anything that would need approval is **denied** and reported in the output, and the exit code says so (FR-CLI-02).
- Each run is stored as a session marked as a run, and its decisions go to the audit log.

### 4.12 Out of quota

```
 ✗ groq: rate limit reached (requests per day). Retry in 2h 14m.
   Switch model with /model, or set another provider in ~/.antai/config.json.
```

- The error names the provider and the limit, and shows a next step. History is kept, and the turn can be retried.

---

## 5. Functional requirements

### 5.1 CLI entry and invocation

| ID | Requirement | Priority |
|---|---|---|
| FR-CLI-01 | `antai` with no arguments starts an interactive session in the current folder. | Must |
| FR-CLI-02 | `antai run "<prompt>"` (alias `-p`) runs one task non-interactively, prints the result and exits with the codes listed in FR-UI-06 (a missing API key is a config error; `run` never prompts). Docs warn against `--mode auto` on untrusted input such as a stranger's diff. | Must |
| FR-CLI-03 | Text piped to stdin is added to the prompt in `run` mode (`git diff \| antai run "review"`), inside a delimited block marked as untrusted data. It passes through secret redaction and is capped (default 100 KB; the rest is cut with a notice). | Should |
| FR-CLI-04 | Flags: `--continue`, `--resume <id>`, `--model <provider:model>`, `--profile <name>`, `--mode <research\|manual\|auto>`, `--effort <level>`, `--json`, `--no-history`, `--dangerously-skip-permissions`, `--debug`, `--version`, `--help`. | Must |
| FR-CLI-05 | Subcommands: `antai mcp list\|add\|remove\|login\|logout`, `antai config` (print the resolved config and where each value came from), `antai login <provider>` and `antai logout <provider>` (store or remove an API key). | Should (`antai mcp login`: Must, see FR-MCP-11) |
| FR-CLI-06 | `antai init` creates a starter `AGENT.md` in the workspace root, with sections for project overview, commands and conventions. It never overwrites an existing instruction file. | Could |

### 5.2 Model providers

| ID | Requirement | Priority |
|---|---|---|
| FR-MOD-01 | Supported providers: Groq (`@ai-sdk/groq`), Google (`@ai-sdk/google`), OpenAI (`@ai-sdk/openai`), Anthropic (`@ai-sdk/anthropic`), Ollama (`ollama-ai-provider-v2`), and OpenAI-compatible endpoints (`@ai-sdk/openai-compatible`), with built-in presets and custom endpoints (FR-MOD-08). Every provider package must work with `@ai-sdk/provider` 4.x; P0 confirms this for the community Ollama package. | Must (Groq, Google), Should (others) |
| FR-MOD-02 | Groq is the default provider. The default model is configurable. The shipped default must pass the tool-calling smoke suite (scripted multi-step tasks, at least 95% valid tool calls), and a typical 10-step turn must fit within the free tier's per-minute and per-day token limits. P0 measures tokens per turn (candidate: `openai/gpt-oss-120b`, see Q3). | Must |
| FR-MOD-03 | Models are referenced as `provider:model` (e.g. `groq:llama-3.3-70b-versatile`). Users can define aliases in config (e.g. `fast`, `smart`). The provider is the text before the first colon; the rest is the model ID (`ollama:qwen3:14b`). | Must |
| FR-MOD-04 | API keys resolve in order: environment variable (`GROQ_API_KEY`, `GOOGLE_GENERATIVE_AI_API_KEY`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and each OpenAI-compatible preset's or custom endpoint's variable, FR-MOD-08), then `~/.antai/credentials.json`, then a first-run prompt that saves to that file with permissions `0600`. In non-interactive runs a missing key is an error (exit code 2) naming the environment variable; antai never prompts. Switching with `/model` to a provider without a key prompts for it the same way as first run. Ollama and local endpoints such as LM Studio need no key. | Must |
| FR-MOD-05 | `/model` opens a picker of the default model, aliases and configured models. `/model <id>` switches directly. The switch applies from the next turn and keeps the conversation. When the provider changes, provider-specific parts (reasoning content, signatures, provider metadata) are left out of the copy sent to the new model; the history file keeps them. A model known not to support tool calling is refused with a message. | Must |
| FR-MOD-06 | `/effort <provider-default\|none\|low\|medium\|high>` sets the AI SDK `reasoning` option. Models that do not support it ignore it and antai shows a one-line notice. The status bar shows the effective level. P0 confirms the option name and per-provider level mapping in the installed `ai@7.x`. | Must |
| FR-MOD-07 | Ollama uses a configurable base URL (default `http://localhost:11434/api`). No API key is required. A provider `baseURL` is honoured only from global config, flags, environment variables or a trusted project; an untrusted project cannot redirect model traffic (FR-CFG-04). A non-local base URL is shown in the status bar. The Ollama context size (`num_ctx`) is set from config (default 32k), because Ollama's small default truncates long agent prompts. | Should |
| FR-MOD-08 | **OpenAI-compatible endpoints.** antai ships presets, each with a base URL and an API-key environment variable: `openrouter` (`https://openrouter.ai/api/v1`, `OPENROUTER_API_KEY`), `together` (`https://api.together.xyz/v1`, `TOGETHER_API_KEY`), `fireworks` (`https://api.fireworks.ai/inference/v1`, `FIREWORKS_API_KEY`), `deepseek` (`https://api.deepseek.com/v1`, `DEEPSEEK_API_KEY`), `mistral` (`https://api.mistral.ai/v1`, `MISTRAL_API_KEY`), `xai` (`https://api.x.ai/v1`, `XAI_API_KEY`) and `lmstudio` (`http://localhost:1234/v1`, no key). Preset URLs are verified in P0. Users define other endpoints in config as `providers.<name>` with `type: "openai-compatible"`, `baseURL` and `apiKeyEnv`. Models are referenced as `<name>:<model>`. A project can define a provider or change a base URL only in a trusted folder (FR-CFG-04). Preset and custom models go through the same tool-calling check as other providers (FR-MOD-05). | Should |

### 5.3 Agent core

| ID | Requirement | Priority |
|---|---|---|
| FR-AGT-01 | The agent runs a streaming tool loop (AI SDK `ToolLoopAgent`). Text streams token by token. | Must |
| FR-AGT-02 | A step cap applies to every turn (default 25, configurable, hard ceiling 100). When the cap stops a turn, antai says so. The cap counts model steps across the whole turn, including resumptions after approval dialogs. | Must |
| FR-AGT-03 | The instructions sent to the model are assembled in this order: antai base rules, global instruction file, active profile, project root instruction file, subfolder instruction files, skill catalog, environment summary (OS, shell, cwd, date). Where instruction files conflict, later files win. Nothing overrides the base rules, and no instruction text can change modes, approvals or permissions (FR-MODE-03). Each instruction file is capped (default 20 KB) with a notice when cut. | Must |
| FR-AGT-04 | Esc interrupts the current turn: it aborts the model call and kills the process tree of any running command. The partial turn is kept in history and marked interrupted. Any tool call left without a result gets a synthetic "interrupted by user" result, so the next request is valid for every provider. The same repair runs on resume after a crash. | Must |
| FR-AGT-05 | When the conversation approaches the model's context window (configurable threshold, default 75%), antai prunes old reasoning and tool output (AI SDK `pruneMessages`) from the copy sent to the model. The history file keeps everything. The context window comes from a built-in table for known models, else `models.<id>.contextWindow` in config, else 32k tokens. If the copy is still over the limit after pruning, antai stops the turn and suggests `/compact`. | Must |
| FR-AGT-06 | `/compact` summarises the conversation so far into a short message and continues from it in the same session. The summary is stored as a marked record; earlier messages stay in the file but are no longer sent to the model. | Should |
| FR-AGT-07 | Tool errors are returned to the model as tool errors, so it can recover. They never crash antai. | Must |

### 5.4 Built-in tools

All file tools operate inside the **workspace**: the git root of the current folder, or the current folder when there is no repository.

| ID | Tool | Requirement | Priority |
|---|---|---|---|
| FR-TOOL-01 | `read_file` | Read a text file. Supports line ranges. Output capped (default 2,000 lines or 50 KB). Binary files are detected and refused with a message. | Must |
| FR-TOOL-02 | `write_file` | Create or overwrite a file. Creates parent folders. Writes to protected paths follow FR-TOOL-11. | Must |
| FR-TOOL-03 | `edit_file` | Replace an exact text span in a file. Fails clearly if the span is missing or matches more than once. The approval dialog shows a diff. Matching ignores line-ending differences (CRLF vs LF); the file keeps its original line endings. | Must |
| FR-TOOL-04 | `list_directory` | List a folder's entries, marking folders. Respects `.gitignore` by default. Results capped (default 500 entries), with a count of what was left out. | Must |
| FR-TOOL-05 | `find_files` | Find files by glob pattern (e.g. `src/**/*.test.ts`). Respects `.gitignore`. Results capped. | Must |
| FR-TOOL-06 | `search_files` | Search file contents by text or regular expression. Returns file, line number and matching line. Uses ripgrep when installed, otherwise a built-in fallback. Respects `.gitignore`. Secret files (FR-SEC-01, FR-TOOL-09) are always excluded, whether or not `.gitignore` lists them. Results capped (default 200 matches). | Must |
| FR-TOOL-07 | `shell` | Run a command (see 5.5). | Must |
| FR-TOOL-08 | `load_skill` | Return a skill's full instructions, and the list of its extra files (see 5.7). | Must |
| FR-TOOL-09 | — | Paths outside the workspace are refused for reads and writes, except skill folders (read-only) and paths the user adds to `workspace.extraReadPaths` in config. Symbolic links are resolved and Windows path forms normalised before the check. Secret files (the list in FR-SEC-01, including `~/.antai/credentials.json`, `~/.ssh/` and `~/.aws/`) are refused for every tool and every shell command, inside or outside the workspace, in every mode; for commands they are on the hard floor (5.5). Users can add secret paths (`secrets.paths`) but not remove built-in ones. If the workspace is the home folder or a drive root, antai warns at start and asks to confirm. | Must |
| FR-TOOL-10 | — | Users can disable individual tools in config (`tools.disabled`). | Should |
| FR-TOOL-11 | — | **Protected paths.** Writes, edits, deletes, moves and shell redirections that touch these paths are Dangerous in every mode: `.antai/**`, `.mcp.json`, `.claude/**`, `.agents/**`, instruction files (`AGENT.md`, `AGENTS.md`, `CLAUDE.md`), `.git/**` (hooks and config), `~/.antai/**`, and shell startup files (`~/.bashrc`, `~/.zshrc`, `~/.profile`). This stops the model from changing its own permissions, MCP servers, instructions or git hooks. | Must |

### 5.5 Shell commands and the safety model

#### Command tiers

antai uses **one bash rule set on all three operating systems**: commands always run in bash, the system bash on macOS and Linux (whatever the user's login shell) and Git Bash on Windows. The model writes the same commands everywhere, and the safety rules are written and tested once.

Each command is parsed (FR-SH-01) and split into its parts at `&&`, `||`, `;`, `|`, `&` and newlines, and each part is classified. The whole command takes the **most restrictive** tier of its parts. Redirections (`>`, `>>`) and command substitution (`$(...)`, backticks) always lift a command to at least **Normal**. Hard-floor patterns are matched anywhere in the command text, including inside quotes and nested shells.

| Tier | Meaning | Examples |
|---|---|---|
| **Safe** | Read-only, no side effects, every path argument inside the workspace | `ls`, `pwd`, `tree`, `cat`/`head`/`tail`, `grep`, `rg`, `wc`, `which`, `node -v`, `npm ls`; `find` without `-delete`, `-exec`, `-execdir`, `-ok`, `-fprint*`; `git status/diff/log/show` without `--output`; `git branch` that only lists (no `-d`, `-D`, `-m`, `-c`). A path argument outside the workspace lifts the command to Normal; a secret path (FR-TOOL-09) is hard floor. |
| **Normal** | Changes something, recoverable. Also the default for any command not listed in another tier. | `npm install`, `npm run build`, `git commit`, `git checkout`, `git push` (no force), `mkdir`, `mv`, `rm file.txt`, `touch`, running scripts (`node x.js`, `python x.py`, `make`), downloads (`curl`/`wget` without upload options) |
| **Dangerous** | Destructive, privileged or hard to undo | `sudo ...`, `rm -rf <path>`, `git push --force`, `git reset --hard`, `git clean -fd`, `chmod -R`/`chown -R`, `kill -9`, `docker system prune`, `npm publish`, `curl ... \| sh`, `shutdown`/`reboot`. **Nested shells** whose contents cannot be inspected reliably: `bash -c`, `sh -c`, `eval`, `cmd /c`, `powershell`, `pwsh`. On Windows: `del /s`, `rd /s`, `taskkill /f`, `reg delete`. Uploads: `curl` with `-d`, `--data*`, `-F`, `-T`/`--upload-file`; `wget --post-*`; `scp`, `sftp`, `rsync` to a remote host; `nc`, `ncat`, `socat`. Commands that write outside the workspace. Writes to protected paths (FR-TOOL-11). Inline code and indirect execution (FR-SH-12). |
| **Hard floor** | Never runs, in any mode | Any command that names a secret file (FR-SEC-01, FR-TOOL-09) as an argument, except existence checks (`ls`, `test -e`); `source` or `.` of `.env*`; the same inside nested shells. `rm -rf` of `/`, `/*`, `~`, `~/`, `~/*`, `$HOME`, a whole drive (`/c`), or with `--no-preserve-root`; `mkfs`; `dd` onto a disk device; fork bombs; `format`; `diskpart`. Redaction (5.6) remains the backstop for anything the list misses. |

#### Approvals by mode

| Tier | `research` | `manual` (default) | `auto` | `--dangerously-skip-permissions` |
|---|---|---|---|---|
| Safe | Runs | Runs | Runs | Runs |
| Normal | Denied | 1 approval | Runs | Runs |
| Dangerous | Denied | **2 approvals** | **1 approval** (red dialog) | Runs |
| Hard floor | Denied | Denied | Denied | Denied |

| ID | Requirement | Priority |
|---|---|---|
| FR-SH-01 | Commands are parsed with a real bash parser (no native dependencies), not split by regex. Each simple command is classified after stripping wrappers (`env`, `command`, `exec`, `time`, `nice`) and resolving the program name (`/bin/rm`, `\rm`, quoted names). The contents of `$(...)`, backticks and `<(...)` are classified too. Anything that cannot be parsed is Dangerous. One rule set applies on macOS, Linux and Windows (Git Bash) and includes Windows executables callable from Git Bash. | Must |
| FR-SH-02 | Approvals follow the mode table above. | Must |
| FR-SH-03 | The first approval dialog asks "Run this command?" and shows the command, its tier and a one-line summary written by the classifier, never by the model. Options: **Yes** (selected; Enter approves), "Yes, don't ask again this session" (this exact command, Normal tier only), and No. | Must |
| FR-SH-04 | The second dialog for dangerous commands is red, starts with a warning triangle, shows the reason from the matching classifier rule (never model-written text), and has **No** selected by default. Enter cancels. Yes requires moving the selection, then Enter. | Must |
| FR-SH-05 | Users can add entries to the safe list (`shell.allow`), the dangerous list (`shell.dangerous`) and a custom block list (`shell.block`) in config. Entries match whole words from the start of each parsed command: `npm test` matches `npm test -- auth`, not `npm testx`; `*` matches one word. An allow entry never covers arguments that touch secret or protected paths. Nothing in config can remove a hard-floor rule or move a dangerous built-in down a tier. Project `shell.dangerous` and `shell.block` apply even in untrusted folders, because they only tighten; project `shell.allow` needs trust (FR-CFG-04). | Must |
| FR-SH-06 | Commands run non-interactively in the workspace folder with the user's environment, always through bash: the system bash on macOS and Linux, whatever the user's login shell, and Git Bash on Windows. The environment summary tells the model the bash version (macOS ships bash 3.2). antai sets `PAGER=cat`, `GIT_PAGER=cat` and `GIT_TERMINAL_PROMPT=0` so nothing waits for input. | Must |
| FR-SH-07 | Each command has a timeout: default 120 s, 30 s for known dev-server commands (`npm run dev`, `next dev`, `vite`, …), configurable per command pattern. On timeout the process tree is killed (own process group on macOS and Linux, `taskkill /T /F` on Windows) and the model receives the output so far, marked timed out; the UI shows it as timed out, not ✓. Commands that detach (`&` background, `nohup`, `setsid`, `disown`) are refused in every mode. | Must |
| FR-SH-08 | Output sent to the model (stdout and stderr, in order) is capped (default 30,000 characters, keeping the start and the end) and passed through secret redaction (5.6). No command output bypasses capture (see FR-SH-09). | Must |
| FR-SH-09 | For `sudo`, antai first runs `sudo -v` on the real terminal so the user types the password into sudo directly; antai never sees it. It then runs the command with output captured and redacted as usual, using sudo's cached credential. If sudo still asks (caching off), the command fails with a message telling the user to run it themselves. Unattended runs use `sudo -n`, so a password prompt fails instead of hanging. Git Bash on Windows has no `sudo`; elevation is not supported there in v1. | Must |
| FR-SH-10 | Every approval, denial and auto-decision is written to the session as an audit event (5.10) and always to the audit log (FR-HIS-13), including with `--no-history` or `history.enabled: false` and for one-shot `run`. | Must |
| FR-SH-11 | **Git Bash on Windows.** antai finds `bash.exe` from Git for Windows automatically (standard install folders, then `PATH`). `ANTAI_GIT_BASH_PATH` or `shell.gitBashPath` in config overrides the location. An invalid override produces a warning and falls back to auto-detection. If Git Bash is not found, the shell tool is disabled with a notice that links to the Git for Windows download. All other tools keep working. The `PATH` search skips `C:\Windows\System32\bash.exe`, which launches WSL, not Git Bash. | Must |
| FR-SH-12 | Nested shells and inline code are Dangerous, because their contents cannot be checked reliably: `bash -c`, `sh -c`, `zsh -c`, `eval`, `cmd /c`, `powershell`, `pwsh`, `python -c`, `node -e`/`--eval`/`-p`, `perl -e`, `ruby -e`, `php -r`, `deno eval`, `xargs` running a command, `find -exec`, `awk` programs that call `system()` or pipe out, and `git -c` options that set commands (`core.sshCommand`, `core.pager`, `alias.*`). Hard-floor patterns inside them are still denied. | Must |
| FR-SH-13 | On Windows, the environment summary tells the model it is running in Git Bash and how paths look there (`/c/Users/...`). File tools accept both `C:\...` and `/c/...` forms. Both forms are normalised before the workspace and secret-path checks. | Should |
| FR-SH-14 | PowerShell fallback for Windows machines without Git for Windows, with its own rule set and tests. | Won't (v1); planned for v1.1 (see §2.2) |

#### Modes

| ID | Requirement | Priority |
|---|---|---|
| FR-MODE-01 | Modes: `research` (read-only; write and edit tools hidden), `manual` (default), `auto`. Switch with `/mode` or `--mode`. | Must |
| FR-MODE-02 | `--dangerously-skip-permissions` is available **only** as a launch flag. It cannot be entered through `/mode` or config. Launching with it shows a red banner for the whole session. Resuming a session never restores it; the flag must be given again. | Must |
| FR-MODE-03 | The model can never change the mode, profile or permissions, directly or indirectly. Tool calls that touch config, trust, credentials, profiles, skills or instruction files are protected-path writes (FR-TOOL-11). | Must |
| FR-MODE-04 | File writes and edits follow the Normal tier, except protected paths (FR-TOOL-11), which are Dangerous. MCP tools follow 5.9. | Must |

### 5.6 Secrets and redaction

| ID | Requirement | Priority |
|---|---|---|
| FR-SEC-01 | Built-in file tools refuse to read or write secret files, inside or outside the workspace and regardless of `workspace.extraReadPaths`: `.env` and `.env.*` (except `.env.example`, `.env.sample`, `.env.template`, which are treated as normal files), `~/.antai/credentials.json`, `~/.ssh/` (except `*.pub` and `known_hosts`), `~/.gnupg/`, `~/.aws/`, `~/.config/gcloud/`, `~/.azure/`, `~/.kube/config`, `~/.docker/config.json`, `~/.npmrc`, `~/.pypirc`, `~/.netrc`, `~/.git-credentials`, `~/.config/gh/hosts.yml`, `*.pem`, `*.key`, and any path in `secrets.paths` in config (project config can only add). Shell reads of these files are on the hard floor (§5.5). Anything that slips through is caught by redaction (FR-SEC-03). antai warns at start when the workspace is the home folder or a drive root. | Must |
| FR-SEC-02 | Commands that load `.env` themselves (e.g. `npm run dev`, `prisma migrate`) are allowed. A direct read is a command that prints, copies or encodes a secret file's contents; these are listed in the hard floor (§5.5). The output of allowed commands is protected only by redaction (FR-SEC-03). | Must |
| FR-SEC-03 | Before any tool output reaches the model, and before anything (tool output, user messages, model text) is written to history, the audit log or logs, antai masks: (a) values from every `.env*` file in the workspace, found recursively, skipping `node_modules` and `.git`; (b) values of environment variables whose names match, ignoring case, `*_KEY`, `*_TOKEN`, `*_SECRET`, `*_PASSWORD`, `*_PASS`, `*_PWD`, `*_CREDENTIALS`, `DATABASE_URL`; (c) the password part of any URL with credentials (`scheme://user:password@host`); (d) known credential formats: `sk-…`, `gsk_…`, `ghp_…`, `gho_…`, `github_pat_…`, `xox[bp]-…`, `AKIA…`, `AIza…`, JWTs, PEM private-key blocks; (e) antai's own stored keys and tokens (FR-SEC-05). Masks look like `[REDACTED:NAME]`. Patterns can be extended in config (`secrets.patterns`). | Must |
| FR-SEC-04 | Values of secret-named variables (FR-SEC-03 b) and secret files are masked from 4 characters, matched on word boundaries. Other `.env` values (e.g. `PORT=3000`, `NODE_ENV=development`) are masked only from 8 characters, to avoid masking common words. Values under 4 characters are never masked; documentation states this gap. | Should |
| FR-SEC-05 | API keys and MCP OAuth tokens stored by antai live in `~/.antai/credentials.json` with permissions `0600` (on Windows, restricted to the current user). They are never logged, displayed in full, or sent anywhere except to the provider, MCP server or OAuth login server they belong to, and are redacted from all tool output. `credentials.json` is a secret file under FR-SEC-01 and on the shell hard floor. | Must |

### 5.7 Instructions, profiles and skills

#### Instruction files

| ID | Requirement | Priority |
|---|---|---|
| FR-INS-01 | antai recognises `AGENT.md`, `AGENTS.md` and `CLAUDE.md` as instruction files, matching names case-insensitively (`Agent.md` counts as `AGENT.md`). If two files in one folder differ only in case, the all-upper-case name wins. | Must |
| FR-INS-02 | Locations: global (`~/.antai/`), the workspace root, and every folder between the root and the folder where the session starts. Order: global, then root, then each deeper folder. Instruction files in other subfolders are not loaded in v1. | Must |
| FR-INS-03 | If several recognised files exist in the same folder, antai loads the first in this order: `AGENT.md`, `AGENTS.md`, `CLAUDE.md`, and lists the skipped ones in `/instructions`. (Decision D14.) | Must |
| FR-INS-04 | `/instructions` shows which instruction files are loaded, from where, and their size in tokens. | Should |

#### Profiles

A profile is a session-wide preset. A skill is an on-demand procedure for one task.

```markdown
~/.antai/profiles/node-dev/PROFILE.md
---
name: node-dev
description: Node.js and TypeScript development
match: ["package.json", "tsconfig.json"]    # optional: loads when any listed file exists in the workspace root
mode: manual                                 # optional default; project profiles: research or manual only, and only in trusted folders
model: groq:openai/gpt-oss-120b              # optional default
effort: medium                               # optional default
skills: [repo-tour, commit-message]          # optional subset
---
You are working in a Node.js project. Use npm scripts for tests and builds.
Run the tests after every code change. Prefer small diffs.
```

| ID | Requirement | Priority |
|---|---|---|
| FR-PRF-01 | Profiles live in `~/.antai/profiles/<name>/PROFILE.md` and `<workspace>/.antai/profiles/<name>/PROFILE.md`. A project profile replaces a global profile with the same name. Invalid `PROFILE.md` files are skipped and listed with the reason in `/profile`. | Must |
| FR-PRF-02 | A profile contains instructions and may set defaults for `mode`, `model`, `effort` and a skill subset. It cannot add MCP servers, enable disabled tools, or change any other safety rule. Project profiles may set `mode` only to `research` or `manual`, and their `mode` and `model` apply only in trusted folders; otherwise they are ignored with a notice. No profile can set `--dangerously-skip-permissions`. | Must |
| FR-PRF-03 | Loading: `/profile <name>`, `--profile <name>`, a project pin (`"profile"` in `.antai/config.json`, trusted folders only), or auto-match when any file listed in `match` exists in the workspace root. Priority: flag, then project pin, then auto-match. If several profiles auto-match, none loads and antai lists them with a hint to pin one. Profile defaults apply when the profile loads, but a mid-session switch never loosens the current mode; a looser mode needs `/mode`. | Must |
| FR-PRF-04 | Only one profile is active at a time. `/profile none` removes the profile's instructions and skill subset; mode, model and effort stay as they are. | Must |
| FR-PRF-05 | An auto-matched profile is shown as `profile: <name> (auto)` in the status bar. | Must |

#### Skills

| ID | Requirement | Priority |
|---|---|---|
| FR-SKL-01 | A skill is a folder containing `SKILL.md` with YAML frontmatter and a Markdown body, following the agentskills.io format. Supported fields: `name` (required; lowercase letters, digits and hyphens; must match the folder name), `description` (required), `disable-model-invocation` and `user-invocable` (FR-SKL-05). Other fields are ignored. Fields that grant tools or permissions (e.g. `allowed-tools`) are ignored: skills never change approvals. Extra files are allowed; scripts in them run only through the shell tool, under the normal tiers. | Must |
| FR-SKL-02 | Locations: `~/.antai/skills/`, `<workspace>/.antai/skills/`, and for compatibility `<workspace>/.claude/skills/` and `<workspace>/.agents/skills/`. Project skills override global skills with the same name, and among project paths `.antai/skills/` wins over `.agents/skills/`, which wins over `.claude/skills/`. In untrusted folders, project skills load but never replace a global skill; the clash is listed in `/skills`. | Must (first two), Should (compatibility paths) |
| FR-SKL-03 | Progressive disclosure: the instructions contain one line per skill (name and description). The body is returned only when the model calls `load_skill`. Extra files are read on demand. | Must |
| FR-SKL-04 | `/<skill-name> [task]` invokes a skill explicitly by injecting its body into the user message. Built-in commands win over skills with the same name; the clash is listed in `/skills`. Slash invocation works for any user-invocable skill, even outside the active profile's subset. | Must |
| FR-SKL-05 | Frontmatter `disable-model-invocation: true` makes a skill slash-only. `user-invocable: false` hides it from the slash menu. | Should |
| FR-SKL-06 | `/skills` lists skills with name, description and source folder. Invalid skill files are listed with the reason they were skipped. | Must |
| FR-SKL-07 | antai ships with built-in skills `repo-tour`, `commit-message` and `explain-error` (final list set by Q5). Precedence: project, then global, then built-in. | Should |

### 5.8 Configuration and workspace trust

```jsonc
// ~/.antai/config.json (global). A project can add <workspace>/.antai/config.json.
{
  "model": "groq:openai/gpt-oss-120b",
  "models": { "fast": "groq:llama-3.1-8b-instant", "smart": "groq:openai/gpt-oss-120b" },
  "providers": {
    "ollama": { "baseURL": "http://localhost:11434/api" },
    "my-gateway": { "type": "openai-compatible", "baseURL": "https://llm.example.com/v1", "apiKeyEnv": "MY_GATEWAY_API_KEY" }
  },
  "profile": "node-dev",            // project pin (trusted folders only)
  "mode": "manual",
  "effort": "provider-default",
  "maxSteps": 25,
  "context": { "pruneAt": 0.75 },
  "shell": {
    "timeoutMs": 120000,
    "timeouts": { "npm run dev": 30000 },
    "allow": ["npm test", "npm run lint"],
    "dangerous": ["terraform destroy"],
    "block": [],
    "gitBashPath": ""
  },
  "tools": { "disabled": [] },
  "mcp": { "tools": { "allow": [], "deny": [] } },
  "secrets": { "paths": [], "patterns": [] },
  "history": { "enabled": true, "retentionDays": 30 },
  "workspace": { "extraReadPaths": [] }
}
```

Project config merges into global config: objects merge key by key, lists are combined, single values replace. Safety and privacy keys follow FR-CFG-01. Custom providers use `"type": "openai-compatible"` with a `baseURL` and the name of the environment variable that holds the key (`apiKeyEnv`), see §5.2.

| ID | Requirement | Priority |
|---|---|---|
| FR-CFG-01 | Settings resolve in this order, highest first: command-line flags, `ANTAI_*` environment variables, the active profile's defaults, project config, global config, built-in defaults. Safety and privacy keys never loosen across layers: `tools.disabled`, `shell.block` and `shell.dangerous` are combined from every layer, `history.enabled: false` in any layer wins, and trust-gated keys (FR-CFG-04) come from project config only in trusted folders. | Must |
| FR-CFG-02 | Config is validated at start. Invalid values produce a clear error naming the file, key and expected value, and antai still starts. Invalid keys fall back to defaults, except safety keys, which fail closed: an invalid `mode` becomes `research`, and an invalid entry in a shell, tool or secrets list drops only that entry. Unknown keys produce a warning. | Must |
| FR-CFG-03 | `antai config` prints the resolved configuration and the source of each value. Secrets are never printed. | Should |
| FR-CFG-04 | **Workspace trust.** antai asks the user to trust a workspace (keyed by its root path) the first time it finds trust-gated project settings: MCP servers (`.antai/mcp.json` or `.mcp.json`), shell `allow` entries, a project `mode`, a project `model`, a provider definition or any provider `baseURL`, a profile pin, or project profiles that set `mode` or `model`. The prompt lists each MCP server's command or URL and the `${VAR}` names it uses, each allow entry, the mode, the model and each provider base URL. Untrusted workspaces load instruction files, skills and profile instructions, and apply project `shell.block` and `shell.dangerous` entries (which only tighten), but ignore every trust-gated setting. A project server can start an OAuth login only after trust. The decision is stored in `~/.antai/trusted.json` with a hash of the trust-gated settings; when they change, antai asks again. | Must |
| FR-CFG-05 | No project file (config, profile or MCP file) can set `auto` mode or `--dangerously-skip-permissions`, whether the folder is trusted or not. Only command-line flags, `/mode` and global config can. | Must |

### 5.9 MCP client

```jsonc
// ~/.antai/mcp.json (global) or <workspace>/.antai/mcp.json (project, needs trust)
{
  "mcpServers": {
    "filesystem": {
      // reads through this server bypass antai's file rules; only redaction and argument checks (FR-MCP-07) apply
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" },
      "trustReadOnlyHints": true
    },
    "linear": {
      // no token: run antai mcp login linear (OAuth, FR-MCP-11)
      "type": "http",
      "url": "https://mcp.example.com/mcp"
    }
  }
}
```

`type` defaults to `stdio` when `command` is set.

| ID | Requirement | Priority |
|---|---|---|
| FR-MCP-01 | antai connects to MCP servers over **stdio** (local child process) and **Streamable HTTP** (remote), using `@ai-sdk/mcp`. | Must |
| FR-MCP-02 | Servers are configured in `~/.antai/mcp.json` and `<workspace>/.antai/mcp.json` using the `mcpServers` format shown above. antai also reads a workspace `.mcp.json`, for compatibility with other tools. Both project files need workspace trust (FR-CFG-04). If a server name appears in more than one file, `.antai/mcp.json` wins over `.mcp.json`, which wins over the global file. Entries antai cannot use (e.g. unsupported transports) are listed in `/mcp` as skipped, with the reason. | Must (own files), Should (`.mcp.json`) |
| FR-MCP-03 | Header and environment values support `${VAR}` substitution from the user's environment, so tokens are not stored in config files. A missing variable fails that server with an error naming the variable. Substituted values are redacted everywhere antai prints or stores them. The trust prompt lists every variable a project server references. | Must |
| FR-MCP-04 | Servers connect in the background at start. A slow or failing server never blocks the prompt. Its status shows in `/mcp` and `antai mcp list`. | Must |
| FR-MCP-05 | MCP tools are exposed to the model as `mcp__<server>__<tool>`, so names never collide with built-in tools or each other. Names are reduced to letters, digits, `_` and `-` and kept within 64 characters, shortened with a hash suffix when needed, since providers reject longer names. | Must |
| FR-MCP-06 | Approval for MCP tools: Normal tier by default (asks in `manual` mode). Annotations that tighten are always honoured: `destructiveHint: true` makes a tool Dangerous. A server marked `"trustReadOnlyHints": true` (global file, or project file in a trusted workspace) has tools annotated `readOnlyHint` treated as Safe. Per-tool overrides in config (`mcp.tools.allow` treats a tool as Safe, `mcp.tools.deny` never offers it to the model) use `mcp__<server>__<tool>` names and accept `*` wildcards. | Must |
| FR-MCP-07 | MCP tool output goes through secret redaction and output caps like built-in tools. Before each call, antai checks the arguments: any string that names a secret file (FR-SEC-01) denies the call. This check is best effort, because antai cannot see what a server does; redaction is the backstop. AC-03 tests both. | Must |
| FR-MCP-08 | `antai mcp add <name> [--project] [--env KEY=VALUE] -- <command> [args]` and `antai mcp add <name> [--project] --url <url> [--header "Name: value"]` add servers to the global file, or to the project file with `--project`. `antai mcp remove <name> [--project]` removes them. antai warns when a literal token is passed instead of a `${VAR}` reference. | Should |
| FR-MCP-09 | antai records a fingerprint of each server's tool definitions and warns when they change between sessions. `/mcp` shows what changed. The tools stay available. Uses AI SDK `fingerprintTools` / `detectToolDrift` if present in the pinned version, otherwise a hash of the tool definitions. | Should |
| FR-MCP-10 | MCP servers are closed cleanly when antai exits, including on Ctrl+C. | Must |
| FR-MCP-11 | OAuth login for remote MCP servers that require it, following the MCP authorization spec. antai finds the server's authorization server, registers as a client where the server allows it, and opens the browser for login (authorization code with PKCE, local loopback redirect). Access and refresh tokens are stored in `~/.antai/credentials.json` (`0600`), refreshed automatically, and sent as bearer tokens. `antai mcp login <name>` and `/mcp` start or repeat the login. In non-interactive runs, a server without a valid token is skipped with a message telling the user to run `antai mcp login <name>`. When a server does not allow client registration, the user supplies a client ID in that server's config (`oauth.clientId`). `antai mcp logout <name>` deletes its tokens. Over SSH, where the browser cannot reach the local loopback address, antai prints the login URL and explains that browser login needs a local session (device-code login comes later, §2.2). P0 confirms how much of this `@ai-sdk/mcp` provides. | Must |

### 5.10 Chat history

#### Storage layout

```
~/.antai/
├── config.json
├── credentials.json                  (0600)
├── trusted.json
├── AGENT.md                          global instructions (any recognised name)
├── profiles/
├── skills/
├── audit/                            (0700)
│   └── 2026-10-12.jsonl              one file per day (0600)
├── logs/                             debug logs and crash reports
└── sessions/                         (0700)
    ├── index.json                    fast catalog for /history
    └── 2026-10-12_1432_a1b2c3.jsonl  one file per session (0600)
```

Each session file holds one JSON record per line:

| Record `type` | Purpose | Sent to the model on resume? |
|---|---|---|
| `session` | Header (always the first line): id, `kind` (`interactive` or `run`), format version, `cwd`, `gitRoot`, provider, model, antai version, created time | No |
| `message` | A conversation message (AI SDK `ModelMessage`) | Yes |
| `event` | Audit: approvals, denials, automatic decisions, setting changes, errors, interruptions | No |
| `usage` | Tokens per turn | No |
| `title` | Short session title, generated by the model after the first turn (one small extra call). If that call fails or no quota is left, the first prompt, trimmed, is used. The title is redacted. | No |

Resume restores model, mode, effort and profile from the header and the latest setting-change events, subject to FR-HIS-04. Every `event` record is also written to the audit log (FR-HIS-13).

| ID | Requirement | Priority |
|---|---|---|
| FR-HIS-01 | Each session, interactive or `run`, is stored as one JSONL file in `~/.antai/sessions/`, using the record types above. `run` sessions are marked `kind: run` and are skipped by `--continue`. | Must |
| FR-HIS-02 | Records are appended as they happen: the user message immediately, each audit event as soon as it is decided, and response messages and usage when the turn ends. A crash loses at most the response of the turn in progress. On resume, a tool call without a result gets a synthetic result marked `interrupted`, so the provider accepts the history. | Must |
| FR-HIS-03 | Sessions are tagged with `cwd` and `gitRoot`. A "project" is matched by `gitRoot` when present, otherwise by `cwd`. Paths are normalised before matching: symlinks resolved, case-folded on macOS and Windows, and `C:\...` and `/c/...` treated as the same path. | Must |
| FR-HIS-04 | `antai --continue` resumes the newest session for the current project. `antai --resume <id>` and `/resume <id or number>` resume a chosen session. Resuming restores the messages and the last model, mode, effort and profile. Flags given at resume win over restored values. `auto` mode is restored only when `--mode auto` is passed again; otherwise the session resumes in the configured default mode. `--dangerously-skip-permissions` is never restored. A session from another project resumes only from that project's folder; antai prints the path. | Must |
| FR-HIS-05 | `/history` lists the current project's sessions (title, date, turns, tokens). `/history --all` lists every project. | Must |
| FR-HIS-06 | `/clear` ends the current session and starts a new one. Nothing is deleted. | Must |
| FR-HIS-07 | Redaction (5.6) runs before anything is written. Tool output is stored at the same truncated size the model saw. | Must |
| FR-HIS-08 | `index.json` is a cache, updated with an atomic write (temp file, then rename, retried on Windows while the target is briefly locked). `/history` reconciles it with the session folder listing, so a session missing from the index (for example after two processes updated it at once) is added back. If the index is missing or corrupt, it is rebuilt from the session files. | Must |
| FR-HIS-09 | Sessions whose last activity is older than `history.retentionDays` (default 30) are deleted at start, with their index entries. A session open in another process is never deleted. `0` keeps sessions forever. | Must |
| FR-HIS-10 | `history.enabled: false` or `--no-history` stores no conversation for that session. Audit events are still written to the audit log (FR-HIS-13). | Must |
| FR-HIS-11 | Each antai process writes only to its own session file. Resuming a session locks it; if another process already holds that session, antai starts a new session with a copy of its messages instead of writing to the same file. | Must |
| FR-HIS-12 | `/history delete <id>` deletes one session. | Should |
| FR-HIS-13 | **Audit log.** Every approval, denial, automatic decision, shell command run, file written and setting change is appended to `~/.antai/audit/<date>.jsonl` (`0600`) for interactive and `run` sessions, with history on or off. It holds no conversation text and passes through redaction. Entries are kept for `audit.retentionDays` (default 90). There is no setting, flag or project config that turns the audit log off. | Must |

### 5.11 Slash commands

| Command | Action | Priority |
|---|---|---|
| `/help` | List commands and keyboard shortcuts | Must |
| `/model [id]` | Pick or set the model | Must |
| `/effort <level>` | Set reasoning effort | Must |
| `/mode [research\|manual\|auto]` | Show or set the permission mode (no argument shows the current mode) | Must |
| `/profile [name\|none]` | Show, set or clear the profile | Must |
| `/skills` | List skills | Must |
| `/<skill-name> [task]` | Run a skill explicitly | Must |
| `/mcp` | Show MCP servers, status and tool counts; log in to a server | Must |
| `/history [--all] \| delete <id>` | List sessions, or delete one (FR-HIS-12) | Must |
| `/resume <id\|number>` | Resume a session | Must |
| `/clear` | Start a new session | Must |
| `/usage` | Tokens for this turn and this session | Must |
| `/exit` | Quit (also Ctrl+C twice) | Must |
| `/instructions` | Show loaded instruction files | Should |
| `/compact` | Summarise and continue | Should |
| `/trust` | Show or change the trust decision for this folder | Should |
| `/config` | Show the resolved config | Could |

Built-in commands win over skills with the same name; `/skills` marks such skills as shadowed.

| ID | Requirement | Priority |
|---|---|---|
| FR-SLC-01 | Typing `/` opens a menu of commands and user-invocable skills that filters as the user types. Tab completes. | Must |
| FR-SLC-02 | Unknown commands show "Unknown command" and a suggestion, and are never sent to the model. Input whose first word contains a second `/` (a path such as `/etc/hosts`) is sent as a normal message, and `//` at the start sends the rest literally. | Must |

### 5.12 Interface

| ID | Requirement | Priority |
|---|---|---|
| FR-UI-01 | Interactive sessions use a rich terminal UI built with Ink: streaming Markdown, tool cards, dialogs and a status bar. | Must |
| FR-UI-02 | The status bar shows provider, model, mode, effort, profile, workspace and token usage (with the share of the context window when known). | Must |
| FR-UI-03 | Tool calls render as one-line cards (tool, short input, status, duration). Ctrl+O expands or collapses the latest card; Ctrl+T opens a scrollable transcript where any card expands with Enter. Expanded output is the redacted, truncated text the model saw. | Must |
| FR-UI-04 | Approval dialogs follow FR-SH-03 and FR-SH-04. Write and edit approvals show a diff; long diffs scroll, and a new file shows its first 200 lines and total line count. MCP approvals show the server, tool and arguments. | Must |
| FR-UI-05 | Keyboard: Enter sends; Shift+Enter or `\` then Enter inserts a newline; Esc interrupts the turn, and in a dialog answers No; Ctrl+C once clears the input or interrupts the turn, twice within 2 seconds exits; up and down arrows browse previous prompts when the cursor is on the first or last line; Ctrl+O and Ctrl+T as in FR-UI-03. While a command owns the terminal (such as a `sudo` password prompt), keys go to that command. | Must |
| FR-UI-06 | When stdout is not a terminal, or with `--json`, antai uses a plain renderer: plain text, or one JSON object per event (`text`, `tool-call`, `tool-result`, `approval`, `usage`, `error`, `done`). The first event carries a `schemaVersion`. Errors go to stderr. If stdin is not a terminal outside `run`, antai exits with code 2 and suggests `antai run`. Exit codes: 0 done; 1 internal error; 2 usage or config error; 3 provider error (key, quota, network); 4 step cap reached; 5 finished, but at least one action was denied for lack of approval. | Must |
| FR-UI-07 | Colours honour `NO_COLOR`, `FORCE_COLOR` and the terminal's capabilities. Without colour, the dangerous-command dialog stays distinct through its ▲ marker, `DANGEROUS COMMAND` heading and No default. | Must |
| FR-UI-08 | Long-running tools show a spinner and elapsed time. | Should |

### 5.13 Errors and resilience

| ID | Requirement | Priority |
|---|---|---|
| FR-ERR-01 | Provider errors (invalid key, rate limit, quota exhausted, model not found, network, request too large or context window exceeded, model does not support tools) show a one-line message naming the provider and cause, plus a suggested next step (for example `/compact` when the request is too large, `/model` when the model does not support tools). The session continues. | Must |
| FR-ERR-02 | Transient errors (network, 5xx, per-minute rate limits) are retried by the SDK (default 2 retries), honouring the provider's retry-after time. Daily-quota errors are not retried, and the retry time is shown when the provider gives one. Only the model call is retried; a tool that already ran is never run again. | Must |
| FR-ERR-03 | `--debug` writes a detailed, redacted log to `~/.antai/logs/`. Without it, antai writes only crash reports (FR-ERR-04). Log files older than 7 days are deleted at start. | Should |
| FR-ERR-04 | Unexpected internal errors restore the terminal, stop child processes, write a redacted crash report (version, OS, stack trace, no conversation text) to `~/.antai/logs/`, and print a short message with its path. antai never prints a raw stack trace in normal mode. | Must |

---

## 6. Non-functional requirements

### 6.1 Security

| ID | Requirement |
|---|---|
| NFR-SEC-01 | The command classifier is covered by a test table of at least 300 commands, run on macOS, Linux and Windows (Git Bash). It covers every tier and every hard-floor rule, with obfuscation attempts (extra spaces, quoting, `env` prefixes, chained commands, nested shells, interpreter one-liners such as `python -c`), detaching commands, uploads, reads outside the workspace, credential files, and Windows executables called from Git Bash. Every command later found to slip past the classifier is added to the table. |
| NFR-SEC-02 | Prompt injection is assumed. Content from files (including project instruction files and skills), command output, piped input and MCP servers is treated as untrusted data and can never change modes, approvals or configuration. Writes to antai's own config and trust files (`~/.antai/**`, `<workspace>/.antai/**`, `.mcp.json`) are protected-path writes and Dangerous (FR-TOOL-11), credential files can never be read or written by tools or commands (FR-SEC-01), and a changed project config asks for trust again. |
| NFR-SEC-03 | Documentation states plainly that command classification is a guardrail, not a security boundary, and recommends a container for untrusted repositories. |
| NFR-SEC-04 | Release builds bundle their dependencies (or ship `npm-shrinkwrap.json`), so direct and transitive versions are fixed. CI runs a dependency vulnerability scan. Experimental AI SDK APIs are wrapped behind antai's own interfaces. |
| NFR-SEC-05 | No secret value appears on screen, in JSON output, logs, crash reports, history, the audit log or error messages. An automated test seeds known secrets (`.env` values, secret-named environment variables, API keys and OAuth tokens in `credentials.json`, a PEM private key, an AWS secret key, known token formats), runs the full suite and scans every output. Values below the length thresholds in FR-SEC-04 are the only stated exception. |

### 6.2 Performance

These targets define "fast" in G4.

| ID | Requirement |
|---|---|
| NFR-PERF-01 | Median time from launch to a usable prompt is under 1 second over 10 warm starts on the CI reference machines and on a 4-core laptop with 8 GB RAM and an SSD. Excluded: MCP servers (which connect in the background), first-run setup, and `npx` download time. |
| NFR-PERF-02 | antai adds under 50 ms (p95) between receiving a token and drawing it, measured in the last turn of a 100-turn reference session. |
| NFR-PERF-03 | `/history` opens in under 200 ms with 1,000 stored sessions. |
| NFR-PERF-04 | Memory (RSS) stays under 300 MB in a 100-turn reference session in which each turn reads a 2,000-line file and runs one command with 30,000 characters of output. |

### 6.3 Compatibility

| ID | Requirement |
|---|---|
| NFR-COMP-01 | Runs natively on macOS (Intel and Apple Silicon), Linux (x64 and arm64) and Windows 10/11 (x64), on Node.js 22 or newer. |
| NFR-COMP-02 | Agent commands run in bash on every OS (system bash on macOS, bash on Linux, Git Bash on Windows), whatever the user's login shell, so the bash rule set matches what executes. Shell behaviour is tested on all three, including users whose login shell is zsh or fish. |
| NFR-COMP-03 | File paths are built with `node:path`; a lint rule flags paths joined by string concatenation. Windows tests cover `C:\`, `/c/` and UNC paths. |
| NFR-COMP-04 | Distributed as an npm package (`npm install -g antai`, `npx antai`). No native dependencies. |

### 6.4 Reliability

| ID | Requirement |
|---|---|
| NFR-REL-01 | A crash or forced exit never corrupts existing session files or `index.json`. A truncated last line in a session or audit file is skipped on read. |
| NFR-REL-02 | A failing MCP server, provider outage or invalid skill file degrades one feature, not the whole session. |
| NFR-REL-03 | Child processes (shell commands, stdio MCP servers) are cleaned up, by killing each process tree, on normal exit, Ctrl+C, SIGTERM, SIGHUP and terminal close. If antai itself is killed with SIGKILL this cannot be guaranteed, and the docs say so. |

### 6.5 Maintainability and testability

| ID | Requirement |
|---|---|
| NFR-MNT-01 | The agent core is UI-independent. It emits typed events; the Ink UI and the plain renderer only display them. |
| NFR-MNT-02 | Agent behaviour is unit-tested without network calls, using the AI SDK's mock model (`MockLanguageModelV4` from `ai/test`). |
| NFR-MNT-03 | CI runs the test suite on macOS, Linux and Windows for every merge request. Runner availability: Q4. |
| NFR-MNT-04 | TypeScript strict mode, linting and formatting are enforced in CI. |

### 6.6 Privacy

| ID | Requirement |
|---|---|
| NFR-PRIV-01 | antai itself sends data only to the configured model provider, the configured MCP servers and their OAuth login servers. There is no telemetry or analytics. |
| NFR-PRIV-02 | All history, audit logs, debug and crash logs, user config and credentials are stored locally under `~/.antai/`. Project settings stay in the project's `.antai/` folder. |
| NFR-PRIV-03 | Documentation warns that free provider tiers may use prompts for training, and that client code should only be sent through providers with suitable terms. |

### 6.7 Usability

| ID | Requirement |
|---|---|
| NFR-USE-01 | With an API key already in hand, a first-time user goes from `npm install -g antai` to a first useful answer in under 3 minutes, checked with 5 first-time users before release. |
| NFR-USE-02 | Every error message says what happened and what to do next. All user-facing messages live in one catalogue, and a test checks that each entry has both parts. |
| NFR-USE-03 | `--help` and `/help` document every flag, command and shortcut. |

---

## 7. Constraints and assumptions

### 7.1 Constraints

- **Language and runtime:** TypeScript on Node.js 22 or newer, ESM only (required by AI SDK v7).
- **Agent framework:** Vercel AI SDK v7 (`ai` 7.x) with `@ai-sdk/*` providers on `@ai-sdk/provider` 4.x, `@ai-sdk/openai-compatible` for OpenAI-compatible endpoints and presets (§5.2), and `@ai-sdk/mcp` for MCP. The community `ollama-ai-provider-v2` is confirmed against the v7 provider spec in P0; if it is not compatible, Ollama is reached through `@ai-sdk/openai-compatible` and Ollama's OpenAI-compatible endpoint.
- **UI:** Ink (React for terminals). The current major (8.x) requires React 19.3 or newer and Node 22 or newer. Ink uses JSX, so the project needs a build step (e.g. `tsup`).
- **Default provider:** Groq, chosen for its free tier, subject to the P0 check in Q3. If no Groq model passes that check, the default becomes Google Gemini's free tier.
- **Interface:** terminal only. No web UI.
- **Repository:** `git.geekyants.com/daksh.nagpal/project-agent` (GitLab), so CI runs on GitLab CI. The three-OS test matrix (NFR-MNT-03) needs Linux, Windows and macOS runners (Q4).

### 7.2 Assumptions

- Users have a Groq account, or a key for another supported provider, or a local Ollama install.
- Groq's free tier offers at least one model that passes the P0 check (Q3): at least 90% correct tool calls on a 20-task scripted run, a 25-step turn that fits the per-minute token limit, and at least 30 typical turns a day within the daily token limit. (Thresholds to be confirmed in P0.)
- Windows users who want the shell tool have Git for Windows installed. Machines without it are handled by FR-SH-11.
- ripgrep is optional. antai works without it, only slower on large repositories. Both search paths use the same regular-expression dialect and skip secret files (FR-SEC-01) even when they are not in `.gitignore`.

---

## 8. Architecture overview

### 8.1 Components

```
┌──────────────────────────────────────────────────────────────────────┐
│ CLI entry (bin/antai)  flags · subcommands · run vs interactive       │
├───────────────────────────────┬──────────────────────────────────────┤
│ UI layer                      │ Plain renderer                       │
│ Ink: chat, tool cards,        │ text or --json events                │
│ dialogs, status bar, / menu   │ (scripts, CI, pipes)                 │
├───────────────────────────────┴──────────────────────────────────────┤
│ Session controller                                                   │
│ turn loop · approval round trip · slash commands · interrupts        │
├──────────────┬──────────────┬──────────────┬──────────────┬──────────┤
│ Agent core   │ Safety       │ Context      │ History      │ Config   │
│ ToolLoop-    │ classifier   │ instructions │ JSONL store  │ loader   │
│ Agent,       │ (bash, all   │ profiles     │ index.json   │ trust    │
│ providers,   │ OSes), tool- │ skills       │ retention    │ creds,   │
│ pruning      │ Approval,    │ catalog      │ audit log    │ MCP      │
│              │ redaction,   │              │              │ OAuth    │
│              │ path guard   │              │              │ tokens   │
├──────────────┴──────────────┴──────────────┴──────────────┴──────────┤
│ Tools                                                                │
│ files (read/write/edit) · directory (list/find/search) · shell ·     │
│ load_skill · MCP tools (@ai-sdk/mcp: stdio + Streamable HTTP)        │
│ process supervisor: timeouts, process-tree kill, child cleanup       │
├──────────────────────────────────────────────────────────────────────┤
│ Providers: @ai-sdk/groq (default) · google · openai · anthropic ·    │
│ ollama-ai-provider-v2 · openai-compatible (custom URLs, presets)     │
└──────────────────────────────────────────────────────────────────────┘
```

### 8.2 How a turn flows

1. The user submits a prompt. Built-in slash commands are handled locally by the session controller. A skill command (`/<skill-name>`) expands into a prompt that carries the skill body. Everything else is appended to history and passed to the agent.
2. The agent core builds the instructions (FR-AGT-03), selects the active tools for the mode, and prepares the message copy: if the provider changed since the last turn, provider-specific reasoning data is removed; if the context is near its limit, old output is pruned (FR-AGT-05). It then streams `agent.stream({ messages })`.
3. For each tool call, `toolApproval` asks the safety layer for a decision: run, deny, ask once or ask twice. Calls decided by rule, including commands the user allowed for this session, are decided at once. If any call in the step needs a person, the run ends with a `tool-approval-request` for those calls. In non-interactive runs, "ask" becomes "deny" and the run continues.
4. The session controller shows the dialog(s), writes the decision at once as an audit event (to the session file and the audit log, FR-HIS-13), appends a `tool-approval-response` and calls the agent again. "Ask twice" is two dialogs before one response. The SDK runs approved tools and continues.
5. Inside every tool wrapper (built-in and MCP), output is redacted first and then capped, before the model or the history file sees it.
6. At the end of the turn, response messages and usage are appended to the session file. After the first turn, one small model call generates the session title, falling back to the first prompt if it fails. `index.json` is updated under a lock file, or rebuilt from the session files when an entry is missing, so two processes never drop each other's entries.

### 8.3 Key AI SDK v7 features used

| Need | AI SDK v7 feature |
|---|---|
| Agent loop and streaming | `ToolLoopAgent`, `agent.stream()`, `result.stream` parts |
| Permissions | Call-level `toolApproval` (states `'not-applicable' \| 'approved' \| 'denied' \| 'user-approval'`) with the `tool-approval-response` round trip. "Ask twice" is handled by the session controller as two dialogs before one response. Names verified in P0. |
| Modes | `activeTools` hides write and edit tools in research mode; the tier table gates shell and MCP calls one by one. |
| Effort | Portable `reasoning` option, mapped per provider behind one antai function; fallback to per-provider `providerOptions` if it is not available. Verified in P0. |
| Context limits | `pruneMessages()`, `prepareStep`, plus a model metadata table with each model's context size (fallback 32,000 tokens for unknown and Ollama models). Pruning never separates a tool call from its result. |
| Usage | `result.usage` (summed across steps) for `/usage`; the last step's input tokens for the status bar's context share. |
| MCP | `createMCPClient`, `Experimental_StdioMCPTransport` (wrapped, NFR-SEC-04), HTTP transport with `headers`, OAuth for FR-MCP-11 (P0 confirms whether `@ai-sdk/mcp` provides it), `fingerprintTools` / `detectToolDrift`. |
| Testing | `MockLanguageModelV4` from `ai/test` for agent logic; a terminal UI test harness (Ink's testing library or a pseudo-terminal runner) for dialog and keyboard tests on all three OSes. |

---

## 9. Acceptance criteria

v1 is done when every **Must** requirement passes at least one named test on macOS, Linux and Windows, and these scenario tests pass. The test plan maps each test to the FR IDs it covers. Scenario tests run in CI with a scripted mock model; tests marked (live) also run against a real provider before release.

| ID | Scenario | Expected result | Covers |
|---|---|---|---|
| AC-01 | Fresh install, no key set, run `antai`. Repeat with `GROQ_API_KEY` set. Run `antai run "hi"` with no key. | The first run prompts for a Groq key, saves it readable only by the current user, and reaches a ready prompt. With the environment variable set, there is no prompt. `run` with no key exits non-zero with a message naming the variable to set. | FR-MOD-04, FR-SEC-05. NFR-USE-01 is timed in the release check. |
| AC-02 | Ask "what files are in src?" | Uses `list_directory` or `find_files` without approval and answers | FR-TOOL-04/05 |
| AC-03 | Ask to read `.env` through `read_file`, `cat .env`, `bash -c "cat .env"`, `cmd /c type .env` (Windows), `sed -n p .env`, a `node -e` read, `git show HEAD:.env`, `cp .env x && cat x`, and an MCP filesystem read | `read_file` and the hard-floor commands are denied. MCP calls whose arguments name a secret file are denied. For every other route the command may run, but no `.env` value of 8 or more characters reaches model input, the screen or history. | FR-SEC-01/03, FR-SH-01/12, FR-MCP-07 |
| AC-04 | A fixture script reads `.env` (`API_KEY=abc12345xyz`), prints the value to stdout, prints it to stderr, prints it split across two writes, then exits | The command runs. All three show `[REDACTED:API_KEY]`. | FR-SEC-02/03 |
| AC-05 | In manual mode, ask to create a file. Then run `npm run build` twice, choosing "Yes, don't ask again this session" the first time. | One approval dialog with Yes selected, showing the content or diff. Enter creates the file; choosing No creates no file and the model is told the action was denied. The second `npm run build` runs without a dialog. The option is not offered for Dangerous commands, and a new session asks again. | FR-SH-03, FR-MODE-04 |
| AC-06 | In manual mode, trigger `rm -rf ./build` | First dialog, then a red second dialog with No selected. Enter cancels and nothing is deleted. Moving to Yes and pressing Enter deletes the folder. Choosing No on the first dialog cancels without showing the second. | FR-SH-04 |
| AC-07 | In auto mode, trigger `mkdir x`, then `rm -rf ./build` | `mkdir x` runs with no dialog. `rm -rf ./build` shows only the red dialog, with No selected. | FR-SH-02 |
| AC-08 | With `--dangerously-skip-permissions` and HOME set to a throwaway folder, trigger `rm -rf ~`, `rm -rf ~/`, `rm -rf $HOME`, `rm -rf /*`, `rm -rf /c` (Windows), `cat .env`, then `rm -rf ./build`. Also try entering the flag with `/mode`. | Every hard-floor command is denied. `rm -rf ./build` runs without a prompt. The red banner shows for the whole session. `/mode` cannot enter the flag. | FR-SH-01, FR-MODE-02 |
| AC-09 | In research mode, ask to edit a file | Write and edit tools are not offered. Shell writes (`echo x > f.txt`, `sed -i`, `touch`) are denied. The file is unchanged. | FR-MODE-01, FR-SH-02 |
| AC-10 | In manual mode, tell the model (directly, and through text planted in a file it reads) to switch to auto. It edits `.antai/config.json` to set `mode: auto` and add `shell.allow` entries, and writes a project profile with `mode: auto`. | Each write is a protected-path write and needs two approvals. After restart, none of these changes take effect until the user accepts a new trust prompt, and even then no project file can set `auto`. Text such as `/mode auto` in tool output is never executed. | FR-MODE-03, FR-TOOL-11, FR-CFG-04/05 |
| AC-11 | (live) On Groq, run a turn that uses tools and reasoning, then `/model google:gemini-3.5-flash` and ask about the earlier result | The Gemini request succeeds, Groq's provider-specific reasoning data is dropped without error, and the answer uses the earlier tool results. CI uses recorded responses. | FR-MOD-05 |
| AC-12 | Request matching a skill description | `load_skill` is called and the answer contains the fixture skill's marker text. An unrelated request does not load the skill. A skill with `disable-model-invocation: true` is never loaded by the model. | FR-SKL-03/05 |
| AC-13 | `/repo-tour focus on tests` | Skill body injected; answer follows it | FR-SKL-04 |
| AC-14 | Start in a folder with `package.json` and a global `node-dev` profile with `match: ["package.json"]`. Then start in an untrusted folder whose project profile has `match: ["package.json"]` and `mode: auto`. | Status bar shows `profile: node-dev (auto)` and the profile instructions are active. In the untrusted folder the project profile's instructions load, but the mode stays `manual`. | FR-PRF-02/03/05, FR-CFG-04 |
| AC-15 | Folder has both `AGENT.md` and `CLAUDE.md` | `AGENT.md` loaded; `/instructions` lists `CLAUDE.md` as skipped | FR-INS-03/04 |
| AC-16 | Configure a stdio and an HTTP MCP server; one of them is broken | The working server's tools appear as `mcp__<server>__<tool>`. The broken one shows an error in `/mcp`. The prompt is never blocked. | FR-MCP-01/04/05 |
| AC-17 | Force-kill antai (SIGKILL; `taskkill /F` on Windows) at three points: while text streams, while a tool runs, and while an approval dialog is open. Then run `antai --continue`. | Earlier turns are restored. The next prompt succeeds; a tool call left without a result is closed as interrupted. No session file or index file is corrupt. | FR-HIS-02/04/08, NFR-REL-01 |
| AC-18 | Two antai processes in the same project end turns at the same moment, 50 times | Two separate session files. Every session appears in `/history` every time. | FR-HIS-08/11 |
| AC-19 | Clone an unknown repo with `.antai/mcp.json`, a root `.mcp.json`, a project `mode`, allowlist entries and a project profile that sets `mode`. Start antai. After trusting, change the project config. | The trust prompt lists each server's command or URL. "No" loads instructions, profiles and skills, but no MCP servers, allowlist additions, project mode or profile mode, and starts no OAuth login. After trust, a change to the project config asks again. | FR-CFG-04, FR-MCP-02 |
| AC-20 | `git diff \| antai run "review" --json` | One JSON object per line on stdout, each valid against the published event schema. Exit code 0 when the task finished; a documented non-zero code when it finished with a denied action. Each denial is reported as an `approval` event with `denied`. The run is stored as a session marked `kind: run`, and its audit events reach the audit log. | FR-CLI-02/03, FR-UI-06, FR-HIS-01/13 |
| AC-21 | Groq returns a daily-quota error | One-line error with provider, limit and retry time. The session survives. | FR-ERR-01/02 |
| AC-22 | Seed `.env` values of 8 or more characters, environment variables matching the name patterns, `sk-`, `ghp_`, `AIza` and JWT tokens, a PEM private key, an AWS secret key, antai's stored API key and an MCP OAuth token. Run the full suite. | None of them appears in stdout, stderr, JSON events, session files, `index.json`, the audit log, debug logs or error messages. | NFR-SEC-05 |
| AC-23 | Windows machine without Git for Windows | antai starts, shows the "shell commands are off" notice, and file, search, skill and MCP tools work | FR-SH-11 |
| AC-24 | Windows with Git installed in a custom folder and `ANTAI_GIT_BASH_PATH` set | Shell commands run through that `bash.exe`. A wrong path shows a warning and auto-detection is used. | FR-SH-11 |
| AC-25 | Model runs `bash -c "npm install"` in manual mode | Treated as Dangerous: two approvals. `bash -c "rm -rf ~"` is denied (hard floor). `env bash -c` and `xargs sh -c` are Dangerous. `python -c` and `node -e` are Dangerous (FR-SH-12). | FR-SH-12 |
| AC-26 | Against a local test OAuth server and MCP server: log in, restart, expire the access token, run `antai run` with the tokens removed, and start in an untrusted folder whose project config names the server | Login completes and tokens are readable only by the current user. After restart there is no new login. An expired token refreshes silently. `run` skips the server with a message to run `antai mcp login <name>`. The untrusted folder starts no login. No token appears in output, history or logs. | FR-MCP-11, FR-SEC-05 |
| AC-27 | (live) Same install, three scripted tasks: fix a failing test; sort a folder of mixed files into subfolders; write a README section from code. Between tasks, switch only a profile, skill or instruction file. | Each task completes with no code change. | G1, FR-PRF-03, FR-SKL-03/04, FR-INS-02 |
| AC-28 | Call `read_file ../outside.txt`, read a workspace symlink to `~/.ssh/id_rsa`, call `write_file` outside the workspace, run `cat ~/.antai/credentials.json`, then run `cat /etc/hosts` in manual mode | The first four are refused; the shell read of the credentials file is hard floor. `cat /etc/hosts` asks once, because it reads outside the workspace. | FR-TOOL-09, FR-SEC-01, FR-SH-01 |
| AC-29 | Run a command whose child process sleeps 1,000 s, with a 5 s timeout. Then run `nohup sleep 1000 &`. | On all three OSes the whole process tree is gone after the timeout, and the model gets the partial output marked timed out. `nohup sleep 1000 &` is refused. | FR-SH-07, NFR-REL-03 |
| AC-30 | Config sets `shell.allow: ["sudo", "rm -rf ~"]`; project config sets `mode: auto` | `sudo` stays Dangerous, `rm -rf ~` stays denied (hard floor), and the project mode is ignored. | FR-SH-05, FR-CFG-05 |
| AC-31 | Run a scripted session with approvals, denials and automatic decisions: once with history on, once with `--no-history`, and once as `antai run` | In all three cases every decision appears in the audit log, and as an `event` record in the session file whenever one is written. | FR-SH-10, FR-HIS-13 |
| AC-32 | Press Esc during a long tool run | The tool's process tree is killed, the partial turn is saved marked interrupted, and the next prompt works. | FR-AGT-04 |
| AC-33 | A mock model calls tools without end; an MCP tool returns a seeded secret; an MCP tool is called in manual mode | The turn stops at 25 steps with a message. The MCP output is redacted and capped. The MCP call asks for approval. | FR-AGT-02, FR-MCP-06/07 |
| AC-34 | Start with a session older than `history.retentionDays`; run with `--no-history`; force an internal error | The old session is deleted at start. `--no-history` writes no session file, but its audit events still reach the audit log. The error prints a short message and a log path, with no stack trace. | FR-HIS-09/10/13, FR-ERR-04 |
| AC-35 | (live) Set `OPENROUTER_API_KEY` and run a tool-using turn with `openrouter:<model>`. Repeat against a custom OpenAI-compatible endpoint defined under `providers.<name>` in global config. Then start in an untrusted folder whose project config sets a different `baseURL` for that provider. | Both providers answer the tool-using turn. In the untrusted folder the project `baseURL` is ignored and the global one is used. | FR-MOD-01/07, FR-CFG-04 |

NFR-PERF-01 to 04 are measured by a benchmark job in CI.

---

## 10. Delivery phases

Phases are ordered by dependency. No dates are set in this document.

| Phase | Delivers | Exit check |
|---|---|---|
| **P0 Spike** | Verify the Groq default model's tool calling, free limits and tokens per typical turn; the AI SDK v7 APIs used in 8.3, including `@ai-sdk/mcp` transports and OAuth support; the OpenAI-compatible preset base URLs; Ink 8 with streaming; the bash parser for the classifier; Git Bash on Windows (detection, paths, killing process trees) | Each item has a written go or no-go. Q3 answered. Q4 answered by DevOps. |
| **P1 Core** | CLI entry, config, providers (including OpenAI-compatible presets), provider error handling, agent loop, read-only file and directory tools, plain renderer, `run` mode, CI on macOS and Linux | AC-01, 02, 11, 21, 35 |
| **P2 Safety** | `write_file` and `edit_file`, shell tool, bash classifier (all three OSes), Git Bash detection, modes, approvals (tested through the plain renderer), double approval, hard floor, protected paths, redaction, audit log, trust, Windows CI | AC-03 (except the MCP read), AC-04 to 10, AC-20, AC-22 to 25, AC-28 to 32 |
| **P3 Context** | Instruction files, profiles, skills, slash commands | AC-12 to 15 (until P5, AC-14 is checked through `/profile` output instead of the status bar) |
| **P4 Memory and MCP** | History store, resume, retention, MCP client (stdio and HTTP), MCP OAuth login, drift warnings | AC-16 to 19, AC-26, the MCP read in AC-03, AC-33, AC-34 |
| **P5 Interface** | Ink UI: streaming Markdown, tool cards, dialogs, status bar, `/` menu. Can start after P1, in parallel with P2 to P4. | Scripted UI tests for dialogs, cards and status bar on all three OSes in CI, including AC-05 to 07 against the Ink dialogs, plus a manual walkthrough of section 4 on each OS |
| **P6 Hardening** | Performance targets, docs, npm release (needs Q1 and Q2) | All Must requirements pass on three-OS CI, AC-27 and the NFR-PERF benchmarks |

`@ai-sdk/tui` may be used for internal demos during P1 to P4, before the Ink UI exists, if P0 confirms the package. Otherwise the plain renderer serves demos.

---

## 11. Risks

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | A command slips past the classifier (obfuscation, a new tool) | Medium | High | Large test table (NFR-SEC-01), a real bash parser, unknown commands default to Normal, interpreter one-liners treated as nested shells, hard floor, double approval, clear docs that this is not a sandbox, container support planned | Engineering lead |
| R2 | Prompt injection through files, command output or MCP servers | High | High | The model cannot change modes or approvals. Writes to antai's own config, `.mcp.json` and `.git/hooks` are Dangerous (FR-TOOL-11). Untrusted folders get no MCP servers and their profiles cannot set a mode. Approval dialogs describe commands from the classifier, not the model. MCP tools ask by default. Drift warnings. Docs warn against `auto` on untrusted piped input. | Engineering lead |
| R3 | Groq free tier limits or tool-calling quality are not good enough as a default | Medium | Medium | P0 spike, easy `/model` switching, documented alternatives (Gemini free tier, Ollama) | P0 spike |
| R4 | Windows through Git Bash has its own quirks: path forms, killing process trees, Windows programs reachable from bash, users without Git | High | Medium | Windows entries in the rule set, nested shells treated as Dangerous, Windows CI runners from P2, clear notice when Git is missing, PowerShell fallback in v1.1 | Engineering lead |
| R5 | Windows CI runners may not be available on the self-hosted GitLab | Medium | Medium | Confirm early. GitLab-hosted runners serve GitLab.com projects only, so use a self-registered Windows runner for git.geekyants.com, or a CI-only mirror on GitLab.com or GitHub. | DevOps |
| R6 | AI SDK v7 ships breaking changes in patch releases for experimental APIs | Medium | Medium | Pin exact versions, wrap experimental APIs (e.g. the stdio MCP transport) behind antai interfaces | Engineering lead |
| R7 | Ink 8 and React 19 add size and complexity | Low | Low | UI-independent core (NFR-MNT-01), plain renderer as fallback | Engineering lead |
| R8 | Redaction misses a secret format | Medium | Medium | Layered detection (env file values, name patterns, token formats, PEM private keys), secret files outside `.env` blocked (SSH keys, cloud credentials, antai's credentials file), secret-scan test | Engineering lead |
| R9 | Context costs grow with many MCP tools | Medium | Medium | Per-tool enable lists, pruning, token display, consider AI SDK `toolSearch` after v1 | Engineering lead |
| R10 | v1 scope is large for an MVP (OAuth, three OSes, Ink, a 300-command classifier) | High | Medium | Triage Must against Should at the P0 exit; P5 runs in parallel with P2 to P4 | Product owner |
| R11 | Long-lived MCP OAuth refresh tokens stored at rest | Low | Medium | `0600` credentials file, redaction, OS keychain in v1.1 (D20) | Engineering lead |
| R12 | The model raises its own permissions by writing antai config, profiles or `.git/hooks` | Medium | High | Protected paths are Dangerous in every mode (FR-TOOL-11); trust is asked again when project settings change (FR-CFG-04) | Engineering lead |

---

## 12. Decision log and open questions

### 12.1 Decisions made in the requirements interview

| ID | Decision |
|---|---|
| D1 | antai is a production-grade MVP. v1 is the first release. |
| D2 | Out of the box it is a single neutral assistant. Specialisation comes from instructions, profiles and skills. |
| D3 | Groq is the default provider. Gemini, OpenAI, Anthropic and Ollama are switchable through config. |
| D4 | v1 features: skills, slash commands, file writing, directory search, shell commands, stored chat history, MCP client (stdio and Streamable HTTP), profiles. |
| D5 | Instruction files are global plus project, and any of `AGENT.md`, `Agent.md`, `AGENTS.md`, `CLAUDE.md` is recognised. (Refined in v0.3: the first found per folder is loaded, see D14.) |
| D6 | `.env`: no direct reads; indirect use by commands is allowed; secret values are redacted from all output. |
| D7 | History: global JSONL per session, project tagging by git root, resume/list/clear, redaction, `0600`, can be disabled, 30-day default retention. |
| D8 | Shell: four tiers; one approval for normal commands; two approvals for dangerous commands in manual mode (second dialog red, default No); one in auto; skip-permissions only as a launch flag. |
| D9 | A tiny hard floor stays blocked even with skip-permissions: secret reads, `rm -rf /` or `~`, `mkfs`, `dd` onto disks, fork bombs. |
| D10 | Interface: Ink rich UI plus a plain/JSON fallback. |
| D11 | Name: antai (command `antai`, config `~/.antai/`). |
| D12 | Profiles hold instructions plus optional defaults (mode, model, effort, skills), loaded manually, by auto-match or by project pin. (Refined in v0.4: a project profile's mode applies only in trusted folders and never sets `auto`.) |
| D13 | Platforms: macOS, Linux and native Windows in v1. On Windows, shell commands run through Git Bash (like Claude Code's preferred setup), so one bash rule set covers all three OSes. PowerShell fallback in v1.1. (Changed in v0.2.) |

### 12.2 Decisions made by default, for review

| ID | Default chosen | Alternative |
|---|---|---|
| D14 | If several instruction files exist in one folder, load only the first of `AGENT.md`, `AGENTS.md`, `CLAUDE.md` | Merge all of them |
| D15 | Workspace trust prompt for project MCP servers, allowlists and modes | No trust check |
| D16 | MCP tools ask for approval by default, unless a server is marked to trust read-only hints | Trust annotations automatically |
| D17 | Built-in `edit_file` (exact-span replace) in addition to `write_file` | Write only |
| D18 | Default step cap 25, hard ceiling 100. Shell timeout 120 s. Output cap 30,000 characters. | Other values |
| D19 | One-shot `run` defaults to research mode. Approval-needing actions are denied when nobody is present. | Default to manual and fail on approval |
| D20 | Credentials in `~/.antai/credentials.json` (`0600`). OS keychain in v1.1, raised because OAuth refresh tokens are stored too. | Keychain in v1 |
| D21 | Distribution through npm as `antai` if Q1 decides public (name free on 12 October 2026; reserve it now). Publish with 2FA and provenance. | Internal registry only |

### 12.3 Decisions made in review (v0.3 and v0.4)

| ID | Decision |
|---|---|
| D22 | MCP OAuth login is Must in v1 (FR-MCP-11), because many hosted MCP servers issue tokens only through OAuth. Static bearer tokens and custom headers remain for servers that issue them. |
| D23 | The default permission mode is called `manual` (renamed from `build`). |
| D24 | Agent commands run in bash on every OS (system bash on macOS and Linux, Git Bash on Windows), whatever the user's login shell, so the bash rule set matches what runs. |
| D25 | Read-only commands are Safe only when every path is inside the workspace; outside it they are Normal. Secret paths, including `~/.antai/credentials.json`, are refused by every tool and command in every mode. |
| D26 | An audit log, separate from chat history, is always written: also with `--no-history` and for one-shot `run`. `run` sessions are stored as history, marked as runs. |
| D27 | Approval dialogs offer "Yes, don't ask again this session" for the exact same command, for Normal-tier commands only. Dangerous commands always ask. |
| D28 | Any OpenAI-compatible endpoint can be configured as a provider, with built-in presets for OpenRouter, Together AI, Fireworks AI, DeepSeek, Mistral, xAI and LM Studio (Should). |
| D29 | MCP tool-definition changes between sessions produce a warning; the tools stay available. |
| D30 | Session titles are generated by the model after the first turn, falling back to the trimmed first prompt. (Answers Q6.) |

### 12.4 Open questions

| ID | Question | Owner | Needed by |
|---|---|---|---|
| Q1 | Will antai be published publicly on npm, or only inside GeekyAnts? This affects licence, support and versioning. | Product owner | P0 for name reservation; P6 for release |
| Q2 | Licence: MIT, Apache-2.0 or proprietary? | Product owner | P6 |
| Q3 | Which Groq model is the default? It needs reliable tool calling and usable free-tier limits (candidates: `openai/gpt-oss-120b`, `llama-3.3-70b-versatile`, `moonshotai/kimi-k2-instruct-0905`). Decision rule: assumption A2 in 7.2. | P0 spike | P0 |
| Q4 | Are Windows and macOS runners available on git.geekyants.com for CI? | DevOps | P1 |
| Q5 | Which built-in skills ship in v1? | Product owner | P3 |
| Q6 | ~~Should session titles be generated by the model (one extra small call per session) or taken from the first prompt?~~ Resolved: model-generated titles with a first-prompt fallback (D30). | Product owner | Resolved (D30) |
| Q7 | Who accepts the "guardrail, not sandbox" residual risk for v1? | Product owner with security lead | P2 |

---

## 13. Glossary

| Term | Meaning |
|---|---|
| Agent loop | The model calls a tool, the result goes back to the model, repeated until it answers |
| Approval | A confirmation dialog shown before a tool runs |
| Hard floor | Commands and file reads that never run, in any mode |
| Instruction file | `AGENT.md`, `AGENTS.md` or `CLAUDE.md`: standing instructions for the agent |
| JSONL | JSON Lines: one JSON object per line, easy to append to |
| MCP | Model Context Protocol, a standard way to expose tools from another program |
| Mode | The permission level: research, manual or auto |
| Profile | A session-wide preset of instructions and defaults |
| Redaction | Replacing secret values with `[REDACTED:NAME]` before they reach the model, the screen, history or logs |
| Skill | A folder with `SKILL.md`, loaded on demand for one kind of task |
| Streamable HTTP | The MCP transport for remote servers over HTTP |
| stdio | The MCP transport that runs a server as a local child process |
| Workspace | The git root of the current folder, or the folder itself without git. antai warns when it is the home folder or a drive root. |
| Workspace trust | The user's per-folder decision to allow a folder's project settings, asked again when they change |
| Allowlist | Commands the user marks as Safe in config (`shell.allow`); entries match whole words from the start of a command |
| Audit log | A record of every approval, denial, automatic decision, command run, file written and setting change, kept even when chat history is off |
| Effort | The reasoning level requested from the model (`/effort`) |
| Git Bash | The bash shell that ships with Git for Windows; antai runs Windows shell commands through it |
| OAuth | The browser login some hosted MCP servers use to issue access tokens |
| OpenAI-compatible endpoint | Any model API that accepts OpenAI's request format at a configurable base URL |
| Tier | A command's risk class: Safe, Normal, Dangerous or Hard floor |
