#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/README.md"

required=(
  '# Second Brain LLM Wiki'
  '## 빠른 시작'
  '## 논문 등록'
  '## Web URL 등록'
  '## YouTube 등록'
  '## 학습과 질문'
  '## 정식 지식 통합'
  '## Lint'
  'bash scripts/lint-wiki.sh'
  '정식 반영해줘'
)

for token in "${required[@]}"; do
  grep -Fq "$token" "$FILE" || { printf 'README missing: %s\n' "$token" >&2; exit 1; }
done

printf 'readme: PASS\n'
