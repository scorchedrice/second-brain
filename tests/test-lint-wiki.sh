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
    "$vault/raw/sources/courses" \
    "$vault/raw/notes" \
    "$vault/raw/assets" \
    "$vault/wiki/sources/papers" \
    "$vault/wiki/sources/web" \
    "$vault/wiki/sources/youtube" \
    "$vault/wiki/sources/courses" \
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

seed_course_source() {
  local vault="$1"
  printf '%s\n' '- [[wiki/sources/courses/Intro|Intro]]' >> "$vault/wiki/index.md"
  printf 'pptx fixture\n' > "$vault/raw/sources/courses/0. INTRO.pptx"
  printf 'pdf fixture\n' > "$vault/raw/sources/courses/0. INTRO.pdf"
  cat > "$vault/wiki/sources/courses/Intro.md" <<'PAGE'
---
type: source
source_type: course
status: unread
ingestion_status: complete
created: 2026-08-03
updated: 2026-08-03
aliases: []
tags: []
formats:
  - pptx
  - pdf
raw_sources:
  - "[[raw/sources/courses/0. INTRO.pptx]]"
  - "[[raw/sources/courses/0. INTRO.pdf]]"
sources: []
related: []
---
# Intro
PAGE
}

course_valid="$TMP_ROOT/course-valid"
seed_vault "$course_valid"
seed_course_source "$course_valid"
"$course_valid/scripts/lint-wiki.sh" > "$TMP_ROOT/course-valid.out"
grep -Fq 'wiki lint: PASS' "$TMP_ROOT/course-valid.out"

course_format="$TMP_ROOT/course-format"
seed_vault "$course_format"
seed_course_source "$course_format"
sed -i.bak 's/  - pdf/  - docx/' "$course_format/wiki/sources/courses/Intro.md"
rm "$course_format/wiki/sources/courses/Intro.md.bak"
if "$course_format/scripts/lint-wiki.sh" > "$TMP_ROOT/course-format.out" 2>&1; then
  printf 'expected unsupported course format to fail\n' >&2
  exit 1
fi
grep -Fq "unsupported course format 'docx'" "$TMP_ROOT/course-format.out"

course_missing="$TMP_ROOT/course-missing"
seed_vault "$course_missing"
seed_course_source "$course_missing"
rm "$course_missing/raw/sources/courses/0. INTRO.pdf"
if "$course_missing/scripts/lint-wiki.sh" > "$TMP_ROOT/course-missing.out" 2>&1; then
  printf 'expected missing course Raw file to fail\n' >&2
  exit 1
fi
grep -Fq 'broken wikilink' "$TMP_ROOT/course-missing.out"

course_mismatch="$TMP_ROOT/course-mismatch"
seed_vault "$course_mismatch"
seed_course_source "$course_mismatch"
sed -i.bak '/  - pdf/d' "$course_mismatch/wiki/sources/courses/Intro.md"
rm "$course_mismatch/wiki/sources/courses/Intro.md.bak"
if "$course_mismatch/scripts/lint-wiki.sh" > "$TMP_ROOT/course-mismatch.out" 2>&1; then
  printf 'expected course format and Raw extension mismatch to fail\n' >&2
  exit 1
fi
grep -Fq 'course formats do not match raw_sources extensions' "$TMP_ROOT/course-mismatch.out"

printf 'wiki lint tests: PASS\n'
