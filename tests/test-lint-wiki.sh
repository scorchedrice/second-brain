#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

seed_vault() {
  local vault="$1"
  mkdir -p \
    "$vault/scripts" \
    "$vault/raw/sources/papers" \
    "$vault/raw/sources/web" \
    "$vault/raw/sources/youtube" \
    "$vault/raw/notes" \
    "$vault/raw/assets" \
    "$vault/wiki/sources/papers" \
    "$vault/wiki/sources/web" \
    "$vault/wiki/sources/youtube" \
    "$vault/wiki/concepts" \
    "$vault/wiki/thoughts" \
    "$vault/wiki/questions"

  cp "$ROOT/scripts/lint-wiki.sh" "$vault/scripts/lint-wiki.sh"
  chmod +x "$vault/scripts/lint-wiki.sh"
  printf '# Index\n\n- [[wiki/concepts/Test Concept|Test Concept]]\n' > "$vault/wiki/index.md"
  printf '# Log\n' > "$vault/wiki/log.md"
  cat > "$vault/wiki/concepts/Test Concept.md" <<'PAGE'
---
type: concept
status: draft
created: 2026-08-02
updated: 2026-08-02
aliases: []
tags: []
sources: []
related: []
---
# Test Concept
PAGE
}

valid="$TMP_ROOT/valid"
seed_vault "$valid"
"$valid/scripts/lint-wiki.sh" > "$TMP_ROOT/valid.out"
grep -Fq 'wiki lint: PASS' "$TMP_ROOT/valid.out"

missing="$TMP_ROOT/missing"
seed_vault "$missing"
sed -i.bak '/^type:/d' "$missing/wiki/concepts/Test Concept.md"
rm "$missing/wiki/concepts/Test Concept.md.bak"
if "$missing/scripts/lint-wiki.sh" > "$TMP_ROOT/missing.out" 2>&1; then
  printf 'expected missing metadata case to fail\n' >&2
  exit 1
fi
grep -Fq "missing field 'type'" "$TMP_ROOT/missing.out"

broken="$TMP_ROOT/broken"
seed_vault "$broken"
printf '\nRelated: [[wiki/concepts/Missing Concept]]\n' >> \
  "$broken/wiki/concepts/Test Concept.md"
if "$broken/scripts/lint-wiki.sh" > "$TMP_ROOT/broken.out" 2>&1; then
  printf 'expected broken link case to fail\n' >&2
  exit 1
fi
grep -Fq 'broken wikilink' "$TMP_ROOT/broken.out"

subtype="$TMP_ROOT/subtype"
seed_vault "$subtype"
printf '%s\n' '- [[wiki/sources/web/Example|Example]]' >> "$subtype/wiki/index.md"
printf '# immutable capture\n' > "$subtype/raw/sources/web/example.md"
cat > "$subtype/wiki/sources/web/Example.md" <<'PAGE'
---
type: source
source_type: youtube
status: unread
ingestion_status: complete
created: 2026-08-02
updated: 2026-08-02
aliases: []
tags: []
raw_source: "[[raw/sources/web/example]]"
sources: []
related: []
---
# Example
PAGE
if "$subtype/scripts/lint-wiki.sh" > "$TMP_ROOT/subtype.out" 2>&1; then
  printf 'expected source subtype mismatch to fail\n' >&2
  exit 1
fi
grep -Fq "source_type 'youtube' does not match folder 'web'" "$TMP_ROOT/subtype.out"

printf 'wiki lint tests: PASS\n'
