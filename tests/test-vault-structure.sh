#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

required_dirs=(
  raw/sources/papers raw/sources/web raw/sources/youtube raw/sources/courses
  raw/notes raw/assets
  wiki/sources/papers wiki/sources/web wiki/sources/youtube wiki/sources/courses
  wiki/concepts wiki/thoughts wiki/questions
)

for path in "${required_dirs[@]}"; do
  [[ -d "$ROOT/$path" ]] || { printf 'missing directory: %s\n' "$path" >&2; exit 1; }
done

grep -Fq '# LLM Wiki Index' "$ROOT/wiki/index.md"
grep -Fq '## Sources' "$ROOT/wiki/index.md"
grep -Fq '### Courses' "$ROOT/wiki/index.md"
grep -Fq '## Concepts' "$ROOT/wiki/index.md"
grep -Fq '## Thoughts' "$ROOT/wiki/index.md"
grep -Fq '## Questions' "$ROOT/wiki/index.md"
grep -Fq '# LLM Wiki Log' "$ROOT/wiki/log.md"
grep -Fq '## [YYYY-MM-DD] operation | title' "$ROOT/wiki/log.md"

printf 'vault structure: PASS\n'
