# Course Source Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PPTX와 PDF 수업자료를 하나의 `course` Source로 등록하고 provenance, 학습 상태와 lint 검증을 기존 LLM Wiki 흐름 안에서 관리한다.

**Architecture:** `raw/sources/courses/`와 `wiki/sources/courses/`를 평면 Source 저장소로 추가하고, `templates/source-course.md`가 여러 format variant를 `formats`와 `raw_sources` 목록으로 표현한다. 기존 Source subtype은 단일 `raw_source`를 계속 사용하며, shell lint는 `course`에만 목록 필드와 `.pptx`/`.pdf` 일치 규칙을 적용한다.

**Tech Stack:** Markdown, YAML frontmatter, Bash 3-compatible shell, Obsidian wikilink, Git

---

## File map

- Create `raw/sources/courses/.gitkeep`: 사용자가 PPTX/PDF를 넣는 immutable Raw 경로를 추적한다.
- Create `wiki/sources/courses/.gitkeep`: 생성된 Course Source 페이지 경로를 추적한다.
- Create `templates/source-course.md`: Course Source metadata와 본문 section을 정의한다.
- Modify `scripts/lint-wiki.sh`: 필수 경로, `course` folder/type, list field, 확장자와 format 일치를 검증한다.
- Modify `tests/test-vault-structure.sh`: 새 디렉터리를 요구한다.
- Modify `tests/test-templates.sh`: Course template의 필드와 기본 상태를 요구한다.
- Modify `tests/test-lint-wiki.sh`: valid Course Source와 invalid format, missing Raw file, format mismatch를 검증한다.
- Modify `tests/test-agent-schema.sh`: 운영 schema가 Course ingest와 coverage 규칙을 포함하는지 검증한다.
- Modify `tests/test-readme.sh`: 사용자 문서가 수업자료 등록 흐름을 포함하는지 검증한다.
- Modify `AGENTS.md`: `course` subtype, local Course ingest, coverage와 Raw 안전 규칙을 정의한다.
- Modify `README.md`: 수업자료 위치, 등록 요청과 format variant 사용법을 설명한다.
- Modify `wiki/index.md`: Sources 아래 `Courses` section을 추가한다.

### Task 1: Course 구조와 template 계약

**Files:**
- Modify: `tests/test-vault-structure.sh`
- Modify: `tests/test-templates.sh`
- Create: `raw/sources/courses/.gitkeep`
- Create: `wiki/sources/courses/.gitkeep`
- Create: `templates/source-course.md`
- Modify: `wiki/index.md`

- [ ] **Step 1: 새 경로와 template을 요구하는 실패 테스트 작성**

`tests/test-vault-structure.sh`의 `required_dirs`를 다음처럼 바꾼다.

```bash
required_dirs=(
  raw/sources/papers raw/sources/web raw/sources/youtube raw/sources/courses
  raw/notes raw/assets
  wiki/sources/papers wiki/sources/web wiki/sources/youtube wiki/sources/courses
  wiki/concepts wiki/thoughts wiki/questions
)
```

Sources heading 검증 뒤에 다음 assertion을 추가한다.

```bash
grep -Fq '### Courses' "$ROOT/wiki/index.md"
```

`tests/test-templates.sh`의 Source template 검증과 별도로 다음 block을 추가한다.

```bash
[[ -f "$ROOT/templates/source-course.md" ]] || {
  printf 'missing template: source-course\n' >&2
  exit 1
}

course_template="$ROOT/templates/source-course.md"
for field in type source_type status ingestion_status created updated formats raw_sources sources related; do
  grep -Eq "^${field}:" "$course_template" || {
    printf 'source-course missing %s\n' "$field" >&2
    exit 1
  }
done
grep -Fq 'source_type: course' "$course_template"
grep -Fq 'ingestion_status: partial' "$course_template"
grep -Fq '## Source files and coverage' "$course_template"
grep -Fq '## Equations and methods' "$course_template"
```

- [ ] **Step 2: 테스트를 실행해 요구사항이 아직 실패하는지 확인**

Run:

```bash
bash tests/test-vault-structure.sh
bash tests/test-templates.sh
```

Expected: 첫 명령은 `missing directory: raw/sources/courses`, 두 번째 명령은 `missing template: source-course`로 실패한다.

- [ ] **Step 3: 디렉터리, index section과 Course template 최소 구현**

빈 파일 `raw/sources/courses/.gitkeep`와 `wiki/sources/courses/.gitkeep`를 만든다.

`wiki/index.md`의 `### YouTube` 다음에 추가한다.

```markdown
### Courses
```

`templates/source-course.md`를 다음 내용으로 만든다.

```markdown
---
type: source
source_type: course
status: unread
ingestion_status: partial
created: {{date}}
updated: {{date}}
aliases: []
tags: []
formats: []
raw_sources: []
instructor:
institution:
published:
supports: []
challenges: []
extends: []
uses: []
sources: []
related: []
---

# {{title}}

## Source metadata

## Source files and coverage

PPTX는 확인한 slide와 speaker notes 범위를, PDF는 확인한 page 범위를 기록한다.

## Learning status

## Learning objectives

## Outline

## Main claims

각 항목을 `[Source] 주장 ([[raw/sources/courses/...|PPTX]], slide N)` 또는 `[Source] 주장 ([[raw/sources/courses/...|PDF]], p. N)` 형식으로 기록한다.

## Equations and methods

## Figures, diagrams, and demonstrations

## Limitations and missing context

## LLM 사전 분석

## Related concepts

## Related thoughts

## Open questions
```

- [ ] **Step 4: 구조와 template 테스트 통과 확인**

Run:

```bash
bash tests/test-vault-structure.sh
bash tests/test-templates.sh
```

Expected:

```text
vault structure: PASS
templates: PASS
```

- [ ] **Step 5: 변경 단위 commit**

```bash
git add raw/sources/courses/.gitkeep wiki/sources/courses/.gitkeep \
  templates/source-course.md wiki/index.md \
  tests/test-vault-structure.sh tests/test-templates.sh
git commit -m "schema: add course source structure"
```

### Task 2: Course lint 규칙

**Files:**
- Modify: `tests/test-lint-wiki.sh`
- Modify: `scripts/lint-wiki.sh`

- [ ] **Step 1: test vault에 Course 경로 추가**

`tests/test-lint-wiki.sh`의 `seed_vault`에 다음 두 경로를 추가한다.

```bash
"$vault/raw/sources/courses" \
"$vault/wiki/sources/courses" \
```

- [ ] **Step 2: valid Course Source와 실패 사례 테스트 작성**

`tests/test-lint-wiki.sh`의 마지막 PASS 출력 전에 다음 fixture를 추가한다.

```bash
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
```

- [ ] **Step 3: lint test를 실행해 새 사례가 실패하는지 확인**

Run:

```bash
bash tests/test-lint-wiki.sh
```

Expected: `course-valid` fixture에서 현재 lint가 `source_type 'course'`와 `raw_source` 필드를 처리하지 못해 실패한다.

- [ ] **Step 4: YAML list 추출 helper 추가**

`scripts/lint-wiki.sh`의 `frontmatter_value` 다음에 추가한다.

```bash
frontmatter_list_items() {
  local file="$1"
  local key="$2"
  sed -n '2,/^---$/p' "$file" | awk -v key="$key" '
    $0 == key ":" { in_list = 1; next }
    in_list && /^[^[:space:]]/ { exit }
    in_list && /^[[:space:]]*-[[:space:]]*/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      gsub(/^"|"$/, "", $0)
      print
    }
  '
}
```

- [ ] **Step 5: required path와 folder/type mapping 추가**

`required_paths`에 다음을 추가한다.

```bash
raw/sources/courses
wiki/sources/courses
```

Source folder mapping에 다음 case를 추가한다.

```bash
wiki/sources/courses/*) expected_source_type='course' ;;
```

- [ ] **Step 6: Course 전용 필드와 format/Raw extension 검증 구현**

`actual_type == source` 처리에서 공통 `raw_source` 요구를 제거하고 subtype 확인 뒤 다음 분기를 사용한다.

```bash
if [[ "$source_type" == 'course' ]]; then
  require_field "$file" formats
  require_field "$file" raw_sources

  format_count=0
  format_pptx=0
  format_pdf=0
  while IFS= read -r format; do
    [[ -z "$format" ]] && continue
    format_count=$((format_count + 1))
    case "$format" in
      pptx) format_pptx=1 ;;
      pdf) format_pdf=1 ;;
      *) error "$rel: unsupported course format '$format'" ;;
    esac
  done < <(frontmatter_list_items "$file" formats)

  raw_count=0
  raw_pptx=0
  raw_pdf=0
  while IFS= read -r raw_link; do
    [[ -z "$raw_link" ]] && continue
    raw_count=$((raw_count + 1))
    target="${raw_link#\[\[}"
    target="${target%\]\]}"
    target="${target%%|*}"
    case "$target" in
      raw/sources/courses/*.pptx) raw_pptx=1 ;;
      raw/sources/courses/*.pdf) raw_pdf=1 ;;
      *) error "$rel: invalid course raw source '$target'" ;;
    esac
  done < <(frontmatter_list_items "$file" raw_sources)

  if [[ "$format_count" -eq 0 ]]; then
    error "$rel: formats must contain at least one item"
  fi
  if [[ "$raw_count" -eq 0 ]]; then
    error "$rel: raw_sources must contain at least one item"
  fi
  if [[ "$format_pptx" -ne "$raw_pptx" || "$format_pdf" -ne "$raw_pdf" ]]; then
    error "$rel: course formats do not match raw_sources extensions"
  fi
else
  require_field "$file" raw_source
fi
```

이 분기 뒤에 기존 status와 `ingestion_status` 검증을 그대로 둔다. 전역 wikilink 검사가 `raw_sources`의 각 link 존재 여부를 검증한다.

- [ ] **Step 7: lint 테스트 통과 확인**

Run:

```bash
bash tests/test-lint-wiki.sh
```

Expected:

```text
wiki lint tests: PASS
```

- [ ] **Step 8: 변경 단위 commit**

```bash
git add scripts/lint-wiki.sh tests/test-lint-wiki.sh
git commit -m "schema: validate course source variants"
```

### Task 3: 운영 schema와 사용자 문서

**Files:**
- Modify: `tests/test-agent-schema.sh`
- Modify: `tests/test-readme.sh`
- Modify: `AGENTS.md`
- Modify: `README.md`

- [ ] **Step 1: schema와 README 요구사항 실패 테스트 작성**

`tests/test-agent-schema.sh`의 `required` 목록에 추가한다.

```bash
'Source subtype은 `paper`, `web`, `youtube`, `course`다.'
'## Local course ingest'
'raw/sources/courses/'
'slide N'
'speaker notes'
```

`tests/test-readme.sh`의 `required` 목록에 추가한다.

```bash
'## 수업자료 등록'
'raw/sources/courses/'
'PPTX와 PDF'
'같은 내용을 담은'
```

- [ ] **Step 2: 문서 테스트가 실패하는지 확인**

Run:

```bash
bash tests/test-agent-schema.sh
bash tests/test-readme.sh
```

Expected: 두 테스트 모두 새 필수 문구가 없어서 실패한다.

- [ ] **Step 3: AGENTS.md의 subtype과 ingest 규칙 갱신**

`Page and link rules`의 subtype 문장을 다음으로 바꾼다.

```markdown
- Source subtype은 `paper`, `web`, `youtube`, `course`다.
```

`Register ingest` 다음에 추가한다.

```markdown
## Local course ingest

PPTX와 PDF 수업자료는 `raw/sources/courses/`에서 duplicate와 format variant를 확인한다. 같은 내용을 담은 PPTX와 PDF는 Course Source 하나의 `raw_sources`에 연결하고, 내용이 다르면 별도 Source로 등록한다. 파일명만 같다는 이유로 자동 병합하지 않는다.

PPTX는 모든 slide, speaker notes와 학습에 필요한 figure, diagram을 확인한다. PDF는 모든 page를 확인한다. 인용 위치는 PPTX의 `slide N`, PDF의 `p. N`으로 구분한다. animation, embedded media, 손상된 수식 또는 읽을 수 없는 시각 자료가 있으면 실패 범위와 필요한 사용자 입력을 기록하고 `ingestion_status: partial`을 유지한다.

Course Source의 지원 형식은 `pptx`, `pdf`다. 새 형식은 반복 수요와 추출·인용 규칙이 확인된 뒤 schema 변경으로 추가한다.
```

`Raw safety`에 다음 bullet을 추가한다.

```markdown
- 같은 수업자료의 format variant와 새 revision도 각각 별도 Raw 파일로 보존한다.
```

`Lint`의 의미 lint 목록에 추가한다.

```markdown
- Course Source의 format, Raw 확장자, slide/page 인용 위치와 coverage 불일치
```

- [ ] **Step 4: README에 수업자료 등록 예시 추가**

YouTube 등록 다음에 추가한다.

````markdown
## 수업자료 등록

PPTX와 PDF 수업자료는 `raw/sources/courses/`에 직접 넣는다.

```text
raw/sources/courses/0. INTRO.pptx를 register ingest하고 학습을 시작해줘.
아직 정식 지식으로 통합하지 말고 전체 지도와 선행 개념부터 설명해줘.
```

같은 내용을 담은 PPTX와 PDF는 한 Course Source의 format variant로 연결한다. PPTX는 slide와 speaker notes, PDF는 page를 확인하며, 읽지 못한 animation이나 embedded media가 있으면 `partial` 상태와 범위를 기록한다.
````

빠른 시작 1번을 다음으로 바꾼다.

```markdown
1. 논문 파일은 `raw/sources/papers/`, PPTX와 PDF 수업자료는 `raw/sources/courses/`에 넣거나 대화에 Web·YouTube URL을 제공한다.
```

- [ ] **Step 5: schema와 README 테스트 통과 확인**

Run:

```bash
bash tests/test-agent-schema.sh
bash tests/test-readme.sh
```

Expected:

```text
agent schema: PASS
readme: PASS
```

- [ ] **Step 6: 변경 단위 commit**

```bash
git add AGENTS.md README.md tests/test-agent-schema.sh tests/test-readme.sh
git commit -m "docs: explain course source workflow"
```

### Task 4: 전체 회귀 검증

**Files:**
- Verify: `scripts/lint-wiki.sh`
- Verify: `tests/run-all.sh`
- Verify: all files changed in Tasks 1-3

- [ ] **Step 1: 실제 vault 구조 lint 실행**

Run:

```bash
bash scripts/lint-wiki.sh
```

Expected:

```text
wiki lint: PASS
```

- [ ] **Step 2: 전체 test suite 실행**

Run:

```bash
bash tests/run-all.sh
```

Expected 마지막 줄:

```text
all tests: PASS
```

- [ ] **Step 3: whitespace와 작업 트리 검증**

Run:

```bash
git diff --check
git status --short
```

Expected: `git diff --check` 출력 없음. `git status --short`는 출력이 없거나 구현 계획 checkbox 갱신처럼 의도한 문서 변경만 표시한다.

- [ ] **Step 4: 최종 상태 확인**

Run:

```bash
git log -4 --oneline
```

Expected: 설계 commit 뒤에 구조, lint, 문서의 논리적 commit이 순서대로 표시된다. 원격 push는 수행하지 않는다.
