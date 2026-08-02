#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/AGENTS.md"

required=(
  '# LLM Wiki Agent Schema'
  '## Three-layer ownership'
  '## Language policy'
  '## Claim labels'
  '## Graph contract'
  '## Register ingest'
  '## URL capture'
  '## Study and query'
  '## Knowledge ingest'
  '## Lint'
  '## Raw safety'
  '## Git and reporting'
  'transcript-only'
  'unread -> learning -> understood -> integrated'
  '사용자의 명시적 선언'
)

for token in "${required[@]}"; do
  grep -Fq "$token" "$FILE" || { printf 'AGENTS.md missing: %s\n' "$token" >&2; exit 1; }
done

printf 'agent schema: PASS\n'
