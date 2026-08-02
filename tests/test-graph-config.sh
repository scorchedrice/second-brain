#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GRAPH="$ROOT/.obsidian/graph.json"

if git -C "$ROOT" check-ignore -q .obsidian/graph.json; then
  printf 'graph.json must be tracked as project configuration\n' >&2
  exit 1
fi

grep -Fq '"search": "path:\"wiki/\" -file:\"index.md\" -file:\"log.md\""' "$GRAPH"
grep -Fq '"showAttachments": false' "$GRAPH"
grep -Fq '"hideUnresolved": true' "$GRAPH"
grep -Fq '"showOrphans": true' "$GRAPH"
grep -Fq '"showArrow": true' "$GRAPH"
grep -Fq 'tests/test-graph-config.sh' "$ROOT/tests/run-all.sh"

printf 'graph config: PASS\n'
