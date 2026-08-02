#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for name in source-paper source-web source-youtube raw-web raw-youtube raw-note concept thought question; do
  [[ -f "$ROOT/templates/$name.md" ]] || { printf 'missing template: %s\n' "$name" >&2; exit 1; }
done

for name in source-paper source-web source-youtube; do
  file="$ROOT/templates/$name.md"
  for field in type source_type status ingestion_status created updated raw_source sources related; do
    grep -Eq "^${field}:" "$file" || { printf '%s missing %s\n' "$name" "$field" >&2; exit 1; }
  done
  grep -Fq 'ingestion_status: partial' "$file" || {
    printf '%s must default to partial ingestion\n' "$name" >&2
    exit 1
  }
done

grep -Fq 'source_type: web' "$ROOT/templates/source-web.md"
grep -Fq 'canonical_url:' "$ROOT/templates/source-web.md"
grep -Fq 'source_type: youtube' "$ROOT/templates/source-youtube.md"
grep -Fq 'coverage: transcript-only' "$ROOT/templates/source-youtube.md"
grep -Fq '## Timestamped claims' "$ROOT/templates/source-youtube.md"

for name in concept thought question; do
  file="$ROOT/templates/$name.md"
  for field in type status created updated aliases tags sources related; do
    grep -Eq "^${field}:" "$file" || { printf '%s missing %s\n' "$name" "$field" >&2; exit 1; }
  done
done

grep -Fq 'kind: interpretation' "$ROOT/templates/thought.md"
grep -Fq '## 사용자 원문' "$ROOT/templates/thought.md"
grep -Fq '## 해결 조건' "$ROOT/templates/question.md"

printf 'templates: PASS\n'
