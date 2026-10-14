#!/usr/bin/env bash
# PostToolUse on Edit|Write: name the Knowledge files that declare the edited path in
# their code_refs. PostToolUse cannot block. Always exits 0.
#
# Matching is PATH CONTAINMENT, not text search. Grepping for each ancestor directory as a
# substring makes the candidate "src/" match every code_refs line containing "src/anything",
# and the hook flags four or five files on every edit. A staleness signal that fires on
# everything is noise, which is worse than no signal: it trains you to ignore it.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
[ -d Knowledge ] || exit 0

INPUT=$(cat 2>/dev/null || true)
FILE=$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -z "$FILE" ] && exit 0

REL="${FILE#"$PWD"/}"
case "$REL" in
  Knowledge/*|Tasks/*|docs/*|.claude/*|CLAUDE.md|/*) exit 0 ;;
esac

python3 - "$REL" <<'PY'
import glob, io, json, os, re, sys

edited = sys.argv[1]
hits = []

for path in glob.glob('Knowledge/**/*.md', recursive=True):
    if os.path.basename(path) == 'INDEX.md':
        continue

    head = io.open(path, encoding='utf-8').read(4000)
    match = re.search(r'^code_refs:\s*(.+)$', head, re.M)
    if not match:
        continue

    for ref in match.group(1).split(','):
        ref = ref.split('::')[0].split(' (')[0].strip().rstrip(')')
        if not ref or ref == 'null':
            continue

        # A ref matches when it IS the edited file, or is a directory containing it.
        # Comparing on segment boundaries is what stops "src/" matching "src-old/...".
        # Refs must carry their extension (Knowledge/Meta/okf.md): no extension is guessed.
        if ref == edited:
            hits.append(path); break
        if ref.endswith('/') and (edited + '/').startswith(ref):
            hits.append(path); break

if hits:
    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext':
            f"Edited {edited}. These Knowledge files declare it in code_refs and may now be stale: "
            + ' '.join(sorted(set(hits))[:6])
            + " — update them and set okf synced true on the ledger entry, or say plainly that you did not."}}))
PY
exit 0
