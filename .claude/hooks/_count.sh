#!/usr/bin/env bash
# Shared counters. Sourced, not executed. grep -c already prints 0 on no-match and exits 1,
# so the exit code is swallowed rather than a second value being echoed.
cnt() { local n; n=$(grep -cE "$1" "$2" 2>/dev/null) || true; printf '%s' "${n:-0}"; }
cnt_files() { local n; n=$(grep -rlE "$1" "$2" --include='*.md' 2>/dev/null | wc -l) || true; printf '%s' "$(echo "${n:-0}" | tr -d ' ')"; }
