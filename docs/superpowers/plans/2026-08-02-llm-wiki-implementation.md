# LLM Wiki Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Obsidian-native, Git-versioned LLM Wiki that preserves immutable paper, Web, YouTube, and user-note sources while Codex maintains a provenance-aware concept graph through register ingest, study/query, knowledge ingest, and lint workflows.

**Architecture:** The vault has three explicit layers: immutable captures under `raw/`, LLM-managed graph nodes under `wiki/`, and the operational schema in `AGENTS.md` plus `templates/`. Markdown pages and vault-relative Obsidian wikilinks form the graph; YAML frontmatter stores node type, lifecycle state, provenance, and typed relationships. A dependency-light Bash linter enforces the structural subset of the schema, while semantic checks remain mandatory agent procedures.

**Tech Stack:** Markdown, YAML frontmatter, Obsidian wikilinks, Bash 3.2+, standard Unix text tools, Git, Obsidian

---

## Planned file map

- `AGENTS.md`: authoritative Codex schema and register-ingest/study/integrate/query/lint procedures.
- `README.md`: concise Korean user guide and natural-language command examples.
- `.gitignore`: exclude machine-local Obsidian state while allowing the required vault setting.
- `.obsidian/app.json`: route pasted/downloaded attachments to `raw/assets/`.
- `raw/sources/{papers,web,youtube}/.gitkeep`: immutable source capture locations.
- `raw/notes/.gitkeep`: immutable user utterance and note captures.
- `raw/assets/.gitkeep`: locally preserved images and attachments.
- `wiki/index.md`: content-oriented graph catalog read before every query.
- `wiki/log.md`: append-only parseable operation history.
- `wiki/{sources/{papers,web,youtube},concepts,thoughts,questions}/.gitkeep`: LLM-managed node locations.
- `templates/source-{paper,web,youtube}.md`: evidence-node templates by source subtype.
- `templates/raw-{web,youtube,note}.md`: immutable capture formats.
- `templates/{concept,thought,question}.md`: knowledge, personal reasoning, and inquiry node templates.
- `scripts/lint-wiki.sh`: structural, status, source-path, index, and wikilink validator.
- `tests/test-repo-config.sh`: repository and Obsidian safety test.
- `tests/test-lint-wiki.sh`: isolated linter behavior tests.
- `tests/test-vault-structure.sh`: required directory and seed-page contract.
- `tests/test-templates.sh`: template frontmatter and section contract.
- `tests/test-agent-schema.sh`: operational-schema coverage contract.
- `tests/test-readme.sh`: user-workflow documentation contract.
- `tests/run-all.sh`: deterministic test entry point.

`{{date}}`, `{{title}}`, `{{url}}` and similar values below are intentional runtime tokens in the shipped Markdown templates. They are replaced by Obsidian or the maintaining agent when a page is created; they are not unfinished implementation instructions.

### Task 1: Protect local Obsidian state and configure attachments

**Files:**
- Create: `.gitignore`
- Modify: `.obsidian/app.json`
- Create: `tests/test-repo-config.sh`

- [ ] **Step 1: Write the failing repository configuration test**

Create `tests/test-repo-config.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

grep -Fxq '.DS_Store' "$ROOT/.gitignore"
grep -Fxq '.obsidian/*' "$ROOT/.gitignore"
grep -Fxq '!.obsidian/app.json' "$ROOT/.gitignore"
grep -Eq '"attachmentFolderPath"[[:space:]]*:[[:space:]]*"raw/assets"' \
  "$ROOT/.obsidian/app.json"

printf 'repo config: PASS\n'
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
bash tests/test-repo-config.sh
```

Expected: non-zero exit because `.gitignore` does not exist and `.obsidian/app.json` does not define `attachmentFolderPath`.

- [ ] **Step 3: Add the minimal repository and Obsidian configuration**

Create `.gitignore`:

```gitignore
.DS_Store
.obsidian/*
!.obsidian/app.json
```

Replace `.obsidian/app.json` with:

```json
{
  "attachmentFolderPath": "raw/assets"
}
```

Make the test executable:

```bash
chmod +x tests/test-repo-config.sh
```

- [ ] **Step 4: Run the test and verify it passes**

Run:

```bash
bash tests/test-repo-config.sh
```

Expected: `repo config: PASS`.

- [ ] **Step 5: Commit**

```bash
git add .gitignore .obsidian/app.json tests/test-repo-config.sh
git commit -m "chore: configure obsidian source attachments"
```

### Task 2: Build the structural wiki linter with tests

**Files:**
- Create: `scripts/lint-wiki.sh`
- Create: `tests/test-lint-wiki.sh`

- [ ] **Step 1: Write failing linter behavior tests**

Create `tests/test-lint-wiki.sh`:

```bash
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
bash tests/test-lint-wiki.sh
```

Expected: non-zero exit because `scripts/lint-wiki.sh` does not exist.

- [ ] **Step 3: Implement the minimal Bash linter**

Create `scripts/lint-wiki.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0

error() {
  printf 'ERROR: %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

frontmatter_value() {
  local file="$1"
  local key="$2"
  sed -n '2,/^---$/p' "$file" | awk -v key="$key" '
    index($0, key ":") == 1 {
      sub("^[^:]+:[[:space:]]*", "", $0)
      gsub(/^"|"$/, "", $0)
      print
      exit
    }
  '
}

require_field() {
  local file="$1"
  local key="$2"
  if ! sed -n '2,/^---$/p' "$file" | grep -Eq "^${key}:"; then
    error "${file#$ROOT/}: missing field '$key'"
  fi
}

required_paths=(
  raw/sources/papers
  raw/sources/web
  raw/sources/youtube
  raw/notes
  raw/assets
  wiki/sources/papers
  wiki/sources/web
  wiki/sources/youtube
  wiki/concepts
  wiki/thoughts
  wiki/questions
  wiki/index.md
  wiki/log.md
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$ROOT/$path" ]]; then
    error "missing required path: $path"
  fi
done

if [[ -d "$ROOT/wiki" ]]; then
  while IFS= read -r file; do
    rel="${file#$ROOT/}"
    first_line="$(sed -n '1p' "$file")"
    if [[ "$first_line" != '---' ]]; then
      error "$rel: missing opening YAML delimiter"
      continue
    fi

    for field in type status created updated aliases tags sources related; do
      require_field "$file" "$field"
    done

    actual_type="$(frontmatter_value "$file" type)"
    actual_status="$(frontmatter_value "$file" status)"
    expected_type=''

    case "$rel" in
      wiki/sources/*) expected_type='source' ;;
      wiki/concepts/*) expected_type='concept' ;;
      wiki/thoughts/*) expected_type='thought' ;;
      wiki/questions/*) expected_type='question' ;;
    esac

    if [[ -n "$expected_type" && "$actual_type" != "$expected_type" ]]; then
      error "$rel: type '$actual_type' does not match folder '$expected_type'"
    fi

    case "$actual_type" in
      source)
        require_field "$file" source_type
        require_field "$file" ingestion_status
        require_field "$file" raw_source
        source_type="$(frontmatter_value "$file" source_type)"
        expected_source_type=''
        case "$rel" in
          wiki/sources/papers/*) expected_source_type='paper' ;;
          wiki/sources/web/*) expected_source_type='web' ;;
          wiki/sources/youtube/*) expected_source_type='youtube' ;;
        esac
        if [[ -n "$expected_source_type" && "$source_type" != "$expected_source_type" ]]; then
          error "$rel: source_type '$source_type' does not match folder '$expected_source_type'"
        fi
        case "$actual_status" in
          unread|learning|understood|integrated|revisit) ;;
          *) error "$rel: invalid source status '$actual_status'" ;;
        esac
        ingestion_status="$(frontmatter_value "$file" ingestion_status)"
        case "$ingestion_status" in
          complete|partial) ;;
          *) error "$rel: invalid ingestion_status '$ingestion_status'" ;;
        esac
        ;;
      concept)
        case "$actual_status" in
          draft|integrated|revisit|deprecated) ;;
          *) error "$rel: invalid concept status '$actual_status'" ;;
        esac
        ;;
      thought)
        require_field "$file" kind
        case "$actual_status" in
          proposed|testing|supported|weakened|refuted|superseded) ;;
          *) error "$rel: invalid thought status '$actual_status'" ;;
        esac
        ;;
      question)
        case "$actual_status" in
          open|answered|misframed|superseded) ;;
          *) error "$rel: invalid question status '$actual_status'" ;;
        esac
        ;;
    esac

    index_target="${rel%.md}"
    if [[ -f "$ROOT/wiki/index.md" ]] && \
       ! grep -Fq "[[$index_target" "$ROOT/wiki/index.md"; then
      error "$rel: not registered in wiki/index.md"
    fi
  done < <(find "$ROOT/wiki/sources" "$ROOT/wiki/concepts" \
    "$ROOT/wiki/thoughts" "$ROOT/wiki/questions" -type f -name '*.md' 2>/dev/null | sort)

  while IFS= read -r file; do
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      target="${link#\[\[}"
      target="${target%\]\]}"
      target="${target%%|*}"
      target="${target%%#*}"
      [[ -z "$target" ]] && continue
      if [[ ! -e "$ROOT/$target" && ! -e "$ROOT/$target.md" ]]; then
        error "${file#$ROOT/}: broken wikilink '[[$target]]'"
      fi
    done < <(grep -Eo '\[\[[^]]+\]\]' "$file" || true)
  done < <(find "$ROOT/wiki" -type f -name '*.md' | sort)
fi

if [[ "$FAILURES" -gt 0 ]]; then
  printf 'wiki lint: FAIL (%d error(s))\n' "$FAILURES" >&2
  exit 1
fi

printf 'wiki lint: PASS\n'
```

Make both files executable:

```bash
chmod +x scripts/lint-wiki.sh tests/test-lint-wiki.sh
```

- [ ] **Step 4: Run linter tests and verify they pass**

Run:

```bash
bash tests/test-lint-wiki.sh
```

Expected: `wiki lint tests: PASS`.

- [ ] **Step 5: Commit**

```bash
git add scripts/lint-wiki.sh tests/test-lint-wiki.sh
git commit -m "feat: add structural wiki lint"
```

### Task 3: Create the three-layer vault skeleton

**Files:**
- Create: `tests/test-vault-structure.sh`
- Create: `raw/sources/papers/.gitkeep`
- Create: `raw/sources/web/.gitkeep`
- Create: `raw/sources/youtube/.gitkeep`
- Create: `raw/notes/.gitkeep`
- Create: `raw/assets/.gitkeep`
- Create: `wiki/sources/papers/.gitkeep`
- Create: `wiki/sources/web/.gitkeep`
- Create: `wiki/sources/youtube/.gitkeep`
- Create: `wiki/concepts/.gitkeep`
- Create: `wiki/thoughts/.gitkeep`
- Create: `wiki/questions/.gitkeep`
- Create: `wiki/index.md`
- Create: `wiki/log.md`

- [ ] **Step 1: Write the failing vault structure test**

Create `tests/test-vault-structure.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

required_dirs=(
  raw/sources/papers raw/sources/web raw/sources/youtube
  raw/notes raw/assets
  wiki/sources/papers wiki/sources/web wiki/sources/youtube
  wiki/concepts wiki/thoughts wiki/questions
)

for path in "${required_dirs[@]}"; do
  [[ -d "$ROOT/$path" ]] || { printf 'missing directory: %s\n' "$path" >&2; exit 1; }
done

grep -Fq '# LLM Wiki Index' "$ROOT/wiki/index.md"
grep -Fq '## Sources' "$ROOT/wiki/index.md"
grep -Fq '## Concepts' "$ROOT/wiki/index.md"
grep -Fq '## Thoughts' "$ROOT/wiki/index.md"
grep -Fq '## Questions' "$ROOT/wiki/index.md"
grep -Fq '# LLM Wiki Log' "$ROOT/wiki/log.md"
grep -Fq '## [YYYY-MM-DD] operation | title' "$ROOT/wiki/log.md"

printf 'vault structure: PASS\n'
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
bash tests/test-vault-structure.sh
```

Expected: non-zero exit reporting the first missing directory.

- [ ] **Step 3: Create the directories and seed pages**

Create the directories listed above and place an empty `.gitkeep` in each leaf directory.

Create `wiki/index.md`:

```markdown
---
type: index
created: 2026-08-02
updated: 2026-08-02
---

# LLM Wiki Index

Query와 ingest를 시작할 때 먼저 읽는 지식 지도다. 새 Wiki 페이지는 상태와 한 줄 설명을 포함해 아래에 등록한다.

## Sources

### Papers

### Web

### YouTube

## Concepts

## Thoughts

## Questions
```

Create `wiki/log.md`:

````markdown
# LLM Wiki Log

Append-only 작업 기록이다. 기존 항목을 수정하거나 재정렬하지 않는다.

형식:

```text
## [YYYY-MM-DD] operation | title
- Changed: vault-relative paths
- Summary: what changed and why
- Open: unresolved issue or `none`
```
````

Make the test executable:

```bash
chmod +x tests/test-vault-structure.sh
```

- [ ] **Step 4: Run structure and lint tests**

Run:

```bash
bash tests/test-vault-structure.sh
bash scripts/lint-wiki.sh
```

Expected: `vault structure: PASS` and `wiki lint: PASS`.

- [ ] **Step 5: Commit**

```bash
git add raw wiki tests/test-vault-structure.sh
git commit -m "feat: scaffold llm wiki layers"
```

### Task 4: Add source, capture, knowledge, and reasoning templates

**Files:**
- Create: `tests/test-templates.sh`
- Create: `templates/source-paper.md`
- Create: `templates/source-web.md`
- Create: `templates/source-youtube.md`
- Create: `templates/raw-web.md`
- Create: `templates/raw-youtube.md`
- Create: `templates/raw-note.md`
- Create: `templates/concept.md`
- Create: `templates/thought.md`
- Create: `templates/question.md`

- [ ] **Step 1: Write the failing template contract test**

Create `tests/test-templates.sh`:

```bash
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
bash tests/test-templates.sh
```

Expected: non-zero exit reporting `missing template: source-paper`.

- [ ] **Step 3: Create the three Source templates**

Create `templates/source-paper.md`:

```markdown
---
type: source
source_type: paper
status: unread
ingestion_status: complete
created: {{date}}
updated: {{date}}
aliases: []
tags: []
raw_source: "[[raw/sources/papers/{{file_name}}]]"
doi:
arxiv_id:
supports: []
challenges: []
extends: []
uses: []
sources: []
related: []
---

# {{title}}

## Bibliography

## Learning status

## Research question

## Method

## Data and experimental setup

## Results

## Limitations

## Source claims

각 항목을 `[Source] 주장 ([[wiki/sources/papers/...|Paper]], p./§/fig./table/equation)` 형식으로 기록한다.

## LLM 사전 분석

## Related concepts

## Related thoughts

## Open questions
```

Create `templates/source-web.md`:

```markdown
---
type: source
source_type: web
status: unread
ingestion_status: complete
created: {{date}}
updated: {{date}}
aliases: []
tags: []
canonical_url: {{url}}
site:
author:
published:
accessed: {{date}}
raw_source: "[[raw/sources/web/{{capture_file}}]]"
supports: []
challenges: []
extends: []
uses: []
sources: []
related: []
---

# {{title}}

## Source metadata

## Learning status

## Main claims

각 항목을 `[Source] 주장 ([[raw/sources/web/...|snapshot]], section heading)` 형식으로 기록한다.

## Evidence and examples

## Limitations and freshness

## LLM 사전 분석

## Related concepts

## Related thoughts

## Open questions
```

Create `templates/source-youtube.md`:

```markdown
---
type: source
source_type: youtube
status: unread
ingestion_status: complete
coverage: transcript-only
created: {{date}}
updated: {{date}}
aliases: []
tags: []
canonical_url: {{url}}
video_id:
channel:
published:
duration:
accessed: {{date}}
transcript_language:
raw_source: "[[raw/sources/youtube/{{capture_file}}]]"
supports: []
challenges: []
extends: []
uses: []
sources: []
related: []
---

# {{title}}

## Source metadata

## Learning status

## Timestamped claims

각 항목을 `[Source] 주장 ([[raw/sources/youtube/...|transcript]], HH:MM:SS)` 형식으로 기록한다.

## Demonstrations and visual material

`coverage: transcript-only`이면 직접 확인하지 않은 화면 내용을 작성하지 않는다.

## Limitations and freshness

## LLM 사전 분석

## Related concepts

## Related thoughts

## Open questions
```

- [ ] **Step 4: Create immutable capture templates**

Create `templates/raw-web.md`:

```markdown
---
capture_type: web
canonical_url: {{url}}
title: {{title}}
author:
published:
accessed: {{date}}
captured_by: Codex
---

# {{title}}

> Immutable capture. 이 파일은 생성 후 수정하지 않는다.

## Captured content
```

Create `templates/raw-youtube.md`:

```markdown
---
capture_type: youtube
canonical_url: {{url}}
video_id:
title: {{title}}
channel:
published:
accessed: {{date}}
transcript_language:
coverage: transcript-only
captured_by: Codex
---

# {{title}}

> Immutable capture. 이 파일은 생성 후 수정하지 않는다.

## Chapters

## Timestamped transcript
```

Create `templates/raw-note.md`:

```markdown
---
capture_type: user-note
created: {{datetime}}
context: {{context}}
captured_by: Codex
---

# 사용자 원문

> Immutable capture. 맞춤법과 표현을 포함해 사용자의 원문을 변경하지 않는다.

{{verbatim_user_text}}
```

- [ ] **Step 5: Create Concept, Thought, and Question templates**

Create `templates/concept.md`:

```markdown
---
type: concept
status: draft
created: {{date}}
updated: {{date}}
aliases: []
tags: []
supports: []
challenges: []
requires: []
sources: []
related: []
---

# {{title}}

## 한눈에 보기

## 핵심 지식

주요 주장은 `[Source]` 또는 `[Synthesis]`와 근거 위치를 바로 붙인다.

## 근거

## 상충하는 관점

## 선행 및 관련 개념

## 관련 Thought

## 열린 Question
```

Create `templates/thought.md`:

```markdown
---
type: thought
kind: interpretation
status: proposed
created: {{date}}
updated: {{date}}
aliases: []
tags: []
derived_from: []
about: []
sources: []
related: []
---

# {{title}}

## 사용자 원문

[[raw/notes/{{raw_note}}|원문]]

## 구조화된 생각

`[User interpretation]` 또는 `[Hypothesis]`로 표시한다.

## 근거

## 반대 근거

## 검증 방법

## 정정 이력
```

Create `templates/question.md`:

```markdown
---
type: question
status: open
created: {{date}}
updated: {{date}}
aliases: []
tags: []
about: []
requires: []
motivates: []
sources: []
related: []
---

# {{title}}

## 질문

## 발생 배경

## 필요한 선행지식

## 관련 자료

## 현재까지의 부분 답변

## 해결 조건

## 정정 또는 대체 질문
```

Make the test executable and run it:

```bash
chmod +x tests/test-templates.sh
bash tests/test-templates.sh
```

Expected: `templates: PASS`.

- [ ] **Step 6: Commit**

```bash
git add templates tests/test-templates.sh
git commit -m "feat: add provenance aware wiki templates"
```

### Task 5: Encode the LLM Wiki operating schema in AGENTS.md

**Files:**
- Create: `AGENTS.md`
- Create: `tests/test-agent-schema.sh`

- [ ] **Step 1: Write the failing schema coverage test**

Create `tests/test-agent-schema.sh`:

```bash
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
bash tests/test-agent-schema.sh
```

Expected: non-zero exit because `AGENTS.md` does not exist.

- [ ] **Step 3: Create the authoritative agent schema**

Create `AGENTS.md` with the following complete operational content:

```markdown
# LLM Wiki Agent Schema

이 저장소는 LLM이 유지보수하는 개인 지식 그래프다. 사용자는 source 선정, 질문, 학습과 이해 선언을 담당하고 LLM은 원문 보존, provenance, 구조화, 연결, 색인, 로그와 일관성을 담당한다.

## Three-layer ownership

- `raw/`: 사용자 소유의 immutable source layer. 새 capture는 만들 수 있지만 기존 파일은 수정·덮어쓰기·삭제하지 않는다.
- `wiki/`: LLM 소유의 generated knowledge layer. 작업 시 관련 노드를 함께 갱신한다.
- `AGENTS.md`와 `templates/`: schema layer. 반복되는 필요가 확인되지 않으면 상태와 관계 타입을 늘리지 않는다.

## Language policy

기본 설명은 한국어로 쓴다. 논문 제목, dataset, model, algorithm, API와 의미가 흐려질 수 있는 technical term은 영어 원문을 유지한다.

## Session start

Wiki 작업을 시작할 때 `wiki/index.md`와 `wiki/log.md`의 최근 항목을 먼저 읽는다. 그다음 관련 Source, Concept, Thought, Question과 필요한 Raw source를 읽는다. index만 보고 사실을 단정하지 않는다.

## Page and link rules

- 노드 타입은 `source`, `concept`, `thought`, `question`이다.
- Source subtype은 `paper`, `web`, `youtube`다.
- wikilink는 확장자를 제외한 vault-relative path를 사용한다. 표시명은 alias로 붙인다.
- 모든 새 Wiki 노드는 `wiki/index.md`에 상태와 한 줄 설명으로 등록한다.
- 모든 새 노드는 최소 하나의 기존 노드와 연결한다. 최초 seed는 예외다.
- `created`는 보존하고 변경 시 `updated`만 갱신한다.

## Claim labels

- `[Source]`: 원문에서 직접 확인한 사실 또는 작성자의 명시적 주장
- `[Synthesis]`: 둘 이상의 integrated Source를 종합한 결론
- `[User interpretation]`: 사용자의 해석 또는 비판
- `[Hypothesis]`: 아직 검증되지 않은 사용자 가설
- `[LLM analysis]`: LLM이 생성했으며 사용자가 확인하지 않은 분석

주요 주장 바로 뒤에 Source 노드와 page, section, figure, table, equation, heading 또는 timestamp를 표기한다. 확인하지 못한 위치를 만들지 않는다. `[LLM analysis]`를 자동으로 `[Synthesis]`로 승격하지 않는다.

## Graph contract

허용 관계는 `supports`, `challenges`, `extends`, `uses`, `derived_from`, `about`, `requires`, `motivates`, `related`다.

- 모든 Source는 정확한 Raw source 또는 immutable capture를 가리킨다.
- Concept의 확정 주장은 하나 이상의 integrated Source를 가진다.
- unread 또는 learning Source는 확정 근거가 아니다.
- Thought는 `derived_from` 또는 `about`을 가진다.
- Question은 Source, Concept 또는 Thought와 연결된다.
- 상충하는 근거는 지우거나 억지로 합치지 않고 `challenges`와 적용 조건을 기록한다.
- 의미상 양방향 관계는 양쪽 페이지에 탐색 가능한 링크를 둔다.

## State machines

- Source: `unread -> learning -> understood -> integrated`; 필요하면 `revisit`로 전환한다.
- Concept: `draft`, `integrated`, `revisit`, `deprecated`.
- Thought: `proposed`, `testing`, `supported`, `weakened`, `refuted`, `superseded`.
- Question: `open`, `answered`, `misframed`, `superseded`.

Source의 `understood` 전이는 사용자의 명시적 선언으로만 수행한다. 질문의 수나 대화 길이로 이해 여부를 추정하지 않는다. 반증된 Thought와 잘못 구성된 Question은 삭제하지 않고 반증 근거, 수정된 이해와 대체 노드를 연결한다.

## Register ingest

1. Raw source와 duplicate를 확인한다.
2. Source 페이지를 새로 만들거나 revision을 기존 Source에 연결한다.
3. 상태를 `unread` 또는 `learning`으로 둔다.
4. metadata, 주제, 선행 개념, 읽을 질문과 연결 후보를 작성한다.
5. 사전 분석은 `[LLM analysis]`로 표시하고 Concept의 확정 지식은 바꾸지 않는다.
6. index와 log를 갱신하고 구조 lint를 실행한다.

## URL capture

Web URL은 canonical URL로, YouTube는 video ID로 duplicate를 확인한다. Web은 readable Markdown snapshot, metadata, accessed date와 필요한 local asset을 저장한다. YouTube는 metadata, chapter와 timestamp가 있는 transcript를 저장한다. capture는 생성 후 immutable이다.

transcript만 확인했으면 `coverage: transcript-only`를 사용하고 화면의 code, diagram, demo와 visual result를 봤다고 쓰지 않는다. 실제 영상과 transcript를 모두 확인한 경우만 `coverage: audiovisual`을 쓴다.

로그인, paywall, robots policy, 동적 page, transcript 부재 또는 지역 제한으로 capture가 불완전하면 `ingestion_status: partial`로 기록한다. 실패 범위와 필요한 사용자 입력을 남기고 Knowledge ingest를 완료하지 않는다.

URL만 주어지면 Register ingest까지만 수행한다. 학습 요청이 있으면 Study and query를 이어간다. 사용자가 이해 및 정식 반영을 선언한 경우에만 Knowledge ingest를 수행한다.

## Study and query

index에서 관련 노드를 찾고 Wiki와 Raw source를 함께 읽어 답한다. 답에는 주장 단위 provenance를 제공한다. 사용자의 의미 있는 생각이나 질문을 보존할 때는 원문을 새 timestamped `raw/notes/` 파일로 먼저 만들고 Thought 또는 Question으로 구조화한다. 기존 Raw note에 append하지 않는다.

재사용 가치가 있는 답, 비교나 분석은 사용자에게 Wiki 저장 여부를 확인한다. 저장 동의 없이 chat answer를 확정 지식에 편입하지 않는다.

## Knowledge ingest

사용자가 Source를 이해했고 정식 반영하라고 선언한 경우에만 실행한다.

1. Source를 `understood`로 전환한다.
2. 주장, 방법, 결과, 한계와 인용 위치를 Raw source에서 검증한다.
3. 관련 Concept을 생성하거나 갱신한다.
4. 기존 Source와의 supports, challenges, extends 관계와 조건을 기록한다.
5. 관련 Thought와 Question을 연결한다.
6. index와 log를 갱신한다.
7. `bash scripts/lint-wiki.sh`를 실행한다.
8. 검증이 통과하면 Source를 `integrated`로 바꾸고 다시 lint한다.

검증할 수 없는 범위가 있으면 `ingestion_status: partial`을 유지하고 통합을 끝내지 않는다.

## Lint

구조 lint는 `bash scripts/lint-wiki.sh`로 실행한다. 추가로 의미 lint에서 다음을 확인한다.

- 출처 없는 사실 주장과 위치 없는 인용
- Source, User interpretation, Hypothesis와 LLM analysis의 혼합
- 미통합 Source를 사용한 확정 주장
- 반증된 Thought를 사실처럼 참조한 내용
- 고아, 중복, 비대칭 관계와 상충 표시 누락
- 오래된 Concept 및 장기 unread, learning, revisit 상태
- local capture, accessed date, timestamp와 coverage 누락

링크·색인처럼 의미가 변하지 않는 오류는 수정할 수 있다. 확실성, 주장 또는 관계의 의미가 바뀌는 수정은 사용자에게 보고하고 승인받는다.

## Raw safety

- 기존 `raw/` 파일을 수정, 덮어쓰기, 삭제하지 않는다.
- 이름 변경이나 이동은 사용자 승인 후 수행한다.
- 사용자 원문은 맞춤법까지 verbatim으로 새 파일에 저장한다.
- Web과 YouTube capture에는 canonical URL과 accessed date를 기록한다.
- 새 revision은 별도 Raw 파일로 보존한다.

## Git and reporting

Source 하나의 register ingest, Knowledge ingest, 저장된 query 결과 또는 lint 수정 하나를 논리적 변경 단위로 다룬다. 관련 Wiki 페이지, index와 log를 함께 검증하고 작업 유형이 드러나는 commit을 만든다.

- `ingest: ...`
- `integrate: ...`
- `query: ...`
- `lint: ...`
- `schema: ...`

사용자에게 생성·수정한 페이지, 핵심 연결, 불확실성, 미해결 문제와 검증 결과를 요약한다. 원격 push는 사용자가 명시적으로 요청한 경우에만 수행한다.
```

Make the test executable:

```bash
chmod +x tests/test-agent-schema.sh
```

- [ ] **Step 4: Run schema and lint tests**

Run:

```bash
bash tests/test-agent-schema.sh
bash scripts/lint-wiki.sh
```

Expected: `agent schema: PASS` and `wiki lint: PASS`.

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md tests/test-agent-schema.sh
git commit -m "feat: define llm wiki agent schema"
```

### Task 6: Document the user workflows

**Files:**
- Create: `README.md`
- Create: `tests/test-readme.sh`

- [ ] **Step 1: Write the failing README contract test**

Create `tests/test-readme.sh`:

```bash
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
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
bash tests/test-readme.sh
```

Expected: non-zero exit because `README.md` does not exist.

- [ ] **Step 3: Create README.md**

Create `README.md`:

```markdown
# Second Brain LLM Wiki

논문, Web, YouTube와 개인 메모를 LLM이 지속적으로 연결·유지하는 Obsidian 지식 그래프다. Raw source는 보존하고, 실제로 이해했다고 선언한 내용만 정식 Concept 지식으로 통합한다.

## 빠른 시작

1. 논문 파일을 `raw/sources/papers/`에 넣거나 대화에 Web·YouTube URL을 제공한다.
2. Codex에 자료 등록 또는 학습을 요청한다.
3. 질문과 자신의 생각을 함께 제공한다.
4. 이해가 끝났을 때만 “이 자료를 이해했어. 정식 반영해줘”라고 요청한다.
5. Obsidian에서 `wiki/index.md`, backlinks와 Graph View로 결과를 탐색한다.

## 논문 등록

```text
raw/sources/papers/example.pdf를 register ingest 해줘.
아직 읽지 않았으니 선행 개념과 읽을 질문만 정리해줘.
```

원본은 바꾸지 않고 Source 페이지를 `unread`로 등록한다.

## Web URL 등록

```text
이 URL을 register ingest 해줘: https://example.com/article
개발 학습 자료이고 아직 읽지 않았어.
```

본문과 metadata를 `raw/sources/web/`에 immutable snapshot으로 보존한다. 접근할 수 없는 범위가 있으면 `partial` 상태와 이유를 기록한다.

## YouTube 등록

```text
이 영상을 학습 자료로 등록하고 transcript 기준으로 개요와 선행지식을 정리해줘: https://youtube.com/watch?v=...
```

metadata와 timestamped transcript를 `raw/sources/youtube/`에 보존한다. transcript만 확인했으면 화면 속 code나 diagram을 확인한 것처럼 기록하지 않는다.

## 학습과 질문

```text
이 Source에서 12:30에 설명한 개념을 기존 Wiki와 연결해서 설명해줘.
내 생각은 “...”인데 원문을 보존하고 가설로 정리해줘.
```

질문을 많이 해도 자동으로 이해 완료로 처리하지 않는다. 논문 주장, 사용자 생각과 LLM 분석은 별도 label과 페이지로 구분한다.

## 정식 지식 통합

```text
이 자료는 이제 이해했어. 내 메모와 함께 정식 반영해줘.
```

이 선언 후에만 Source를 검증하고 관련 Concept, Thought, Question, index와 log를 함께 갱신한다.

## Lint

```bash
bash scripts/lint-wiki.sh
```

구조 lint는 metadata, 상태값, source path, index 등록과 깨진 wikilink를 검사한다. “위키 의미 lint 해줘”라고 요청하면 출처 혼합, 상충 주장, 고아 노드, 오래된 지식과 학습 중단 자료도 점검한다.

## 상태

- Source: `unread`, `learning`, `understood`, `integrated`, `revisit`
- Concept: `draft`, `integrated`, `revisit`, `deprecated`
- Thought: `proposed`, `testing`, `supported`, `weakened`, `refuted`, `superseded`
- Question: `open`, `answered`, `misframed`, `superseded`

잘못된 가설과 질문은 삭제하지 않는다. `refuted`, `misframed` 또는 `superseded`로 표시하고 수정된 이해와 근거를 연결한다.

## 변경 이력

`wiki/log.md`는 작업 이력을, Git은 파일 변경과 복구 이력을 제공한다. 원격 저장소 push는 별도로 요청한다.
```

Make the test executable:

```bash
chmod +x tests/test-readme.sh
```

- [ ] **Step 4: Run the documentation test**

Run:

```bash
bash tests/test-readme.sh
```

Expected: `readme: PASS`.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/test-readme.sh
git commit -m "docs: explain llm wiki workflows"
```

### Task 7: Add one deterministic test entry point

**Files:**
- Create: `tests/run-all.sh`

- [ ] **Step 1: Write the test runner**

Create `tests/run-all.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for test_file in \
  tests/test-repo-config.sh \
  tests/test-lint-wiki.sh \
  tests/test-vault-structure.sh \
  tests/test-templates.sh \
  tests/test-agent-schema.sh \
  tests/test-readme.sh; do
  printf '==> %s\n' "$test_file"
  bash "$ROOT/$test_file"
done

printf 'all tests: PASS\n'
```

- [ ] **Step 2: Make it executable and run the full suite**

Run:

```bash
chmod +x tests/run-all.sh
bash tests/run-all.sh
```

Expected: every individual `PASS` line followed by `all tests: PASS`.

- [ ] **Step 3: Run the production vault lint directly**

Run:

```bash
bash scripts/lint-wiki.sh
```

Expected: `wiki lint: PASS`.

- [ ] **Step 4: Commit**

```bash
git add tests/run-all.sh
git commit -m "test: add llm wiki verification entry point"
```

### Task 8: Verify the completed vault against the design

**Files:**
- Verify only; no expected file changes.

- [ ] **Step 1: Run all automated verification**

Run:

```bash
bash tests/run-all.sh
bash scripts/lint-wiki.sh
git diff --check
```

Expected: all tests and lint pass; `git diff --check` prints nothing.

- [ ] **Step 2: Verify tracked and ignored Obsidian state**

Run:

```bash
git check-ignore .obsidian/workspace.json
git check-ignore -q .obsidian/app.json; test "$?" -eq 1
```

Expected: the first command prints `.obsidian/workspace.json`; the second compound command exits zero, proving `app.json` is not ignored.

- [ ] **Step 3: Inspect the final repository state**

Run:

```bash
git status --short
git log --oneline --decorate -10
```

Expected: clean working tree and focused commits for configuration, lint, structure, templates, schema, documentation, and the test runner.

- [ ] **Step 4: Perform a manual schema trace**

Read `AGENTS.md`, `README.md`, one Source template, one Thought template, `wiki/index.md`, and `wiki/log.md`. Confirm this exact trace is possible without inventing a rule:

```text
URL -> immutable Raw capture -> unread Source -> Study/query
-> explicit user understanding declaration -> Knowledge ingest
-> Concept/Thought/Question links -> index/log -> lint -> Git commit
```

Expected: each arrow is explicitly defined and the Raw source is never edited after capture.
