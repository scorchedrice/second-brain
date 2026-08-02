# Course Source 설계

## 1. 목적

PPTX와 PDF 형식의 수업자료를 LLM Wiki의 정식 Source로 등록하고 학습할 수 있게 한다. 사용자가 `raw/sources/courses/`에 자료를 넣으면 LLM은 원본을 변경하지 않은 채 내용을 확인하고, 학습 상태와 provenance를 `wiki/sources/courses/`에서 관리한다.

이번 변경은 PPTX와 PDF만 지원한다. DOCX 등 다른 형식은 실제 반복 수요가 생겼을 때 같은 `course` Source subtype의 지원 형식으로 추가한다.

## 2. 설계 결정

- Source subtype에 `course`를 추가한다.
- PPTX 또는 PDF 강의자료 한 묶음을 Source 하나로 취급한다.
- 같은 내용을 담은 PPTX와 PDF는 별도 Source로 만들지 않고 한 Source의 format variant로 연결한다.
- 과목, 주차 또는 강의별 하위 폴더와 별도 Course 노드는 만들지 않는다.
- 사용자는 파일을 `raw/sources/courses/`에 직접 넣는다.
- Wiki Source 페이지는 `wiki/sources/courses/`에 생성한다.
- PPTX 인용 위치는 `slide N`, PDF 인용 위치는 `p. N`으로 기록한다.
- 기존 `paper`, `web`, `youtube` Source의 구조와 필드는 변경하지 않는다.

## 3. 대안 검토

### 3.1 `course` subtype 추가

채택한 방식이다. 현재 Source 상태 머신, claim label, graph contract와 ingest 절차를 그대로 재사용하면서 수업자료에 필요한 format과 coverage만 추가할 수 있다.

### 3.2 범용 `document` subtype 추가

PPTX, PDF, DOCX와 기타 파일을 한 번에 수용할 수 있지만 아직 필요하지 않은 형식의 추출, 인용 위치와 검증 규칙까지 정의해야 한다. 현재 범위에서는 불필요하게 넓다.

### 3.3 `raw/assets/` 첨부물로만 보존

schema 변경은 작지만 PPTX 자체의 학습 상태, 주장, 질문과 provenance를 추적할 수 없다. 사용자가 이 자료를 직접 학습하려는 목적과 맞지 않는다.

## 4. 디렉터리 구조

다음 경로를 추가한다.

```text
raw/sources/courses/
wiki/sources/courses/
templates/source-course.md
```

폴더는 평면으로 유지한다. 예시는 다음과 같다.

```text
raw/sources/courses/0. INTRO.pptx
raw/sources/courses/0. INTRO.pdf
raw/sources/courses/1. BASIC THEORY.pptx
```

동일한 파일명이 이미 존재하면 기존 Raw 파일을 덮어쓰지 않는다. 사용자가 새 revision을 제공하면 별도 파일로 보존하고 기존 Source에 revision으로 연결한다.

## 5. Course Source metadata

Course Source는 공통 Source 필드와 다음 필드를 사용한다.

```yaml
---
type: source
source_type: course
status: unread
ingestion_status: partial
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
```

`formats`에는 실제로 연결된 형식만 기록한다. `raw_sources`는 같은 내용을 표현하는 immutable format variant 목록이다. 기존 Source subtype이 사용하는 단일 `raw_source` 필드는 그대로 유지하고, `course`에서만 `raw_sources`를 사용한다.

`instructor`, `institution`, `published`는 자료에서 직접 확인되거나 사용자가 제공한 경우만 채운다. 과목 분류용 필수 metadata는 추가하지 않는다. 자료가 무엇을 다루는지는 Source 본문, tags, 관련 Concept과 index의 한 줄 설명으로 표현한다.

## 6. Course Source 본문

`templates/source-course.md`는 다음 section을 제공한다.

- Source metadata
- Source files and coverage
- Learning status
- Learning objectives
- Outline
- Main claims
- Equations and methods
- Figures, diagrams, and demonstrations
- Limitations and missing context
- LLM 사전 분석
- Related concepts
- Related thoughts
- Open questions

직접 확인한 주장은 다음과 같이 정확한 variant와 위치를 표시한다.

```text
[Source] CHE는 proton과 electron의 chemical potential을 수소 기준으로 치환한다
([[raw/sources/courses/0. INTRO.pptx|PPTX]], slide 6).
```

PDF에서 확인했다면 `([[raw/sources/courses/0. INTRO.pdf|PDF]], p. 6)`처럼 기록한다. PPTX와 PDF의 위치가 다르면 둘을 하나의 모호한 위치로 합치지 않는다.

## 7. Register ingest 흐름

1. `raw/sources/courses/`에서 대상 PPTX 또는 PDF를 확인한다.
2. 기존 Raw 파일과 Wiki Source를 검색해 exact duplicate, format variant 또는 revision인지 판단한다.
3. 같은 내용을 담은 PPTX와 PDF이면 한 Source의 `raw_sources`와 `formats`에 함께 등록한다.
4. PPTX는 모든 슬라이드, speaker notes와 포함된 시각 자료를 확인한다.
5. PDF는 모든 페이지를 확인한다.
6. 제목, 학습 목표, outline, 선행 개념, 읽을 질문과 확인 가능한 coverage를 기록한다.
7. 확인하지 못한 분석은 `[LLM analysis]`로 표시한다.
8. `wiki/index.md`의 `Courses` section과 `wiki/log.md`를 갱신한다.
9. 구조 lint를 실행하고 `ingest: ...` commit을 만든다.

파일명만 같다는 이유로 format variant로 자동 병합하지 않는다. 내용이 실질적으로 같은지 확인하거나 사용자의 명시적 설명이 있어야 한다. 내용이 다른 자료라면 별도 Source로 등록한다.

## 8. Coverage와 실패 처리

PPTX의 텍스트만 추출하고 시각 자료를 확인하지 못했다면 전체 내용을 확인한 것으로 기록하지 않는다. speaker notes, animation, embedded audio/video, 외부 link, 손상된 수식 또는 읽을 수 없는 이미지가 있으면 확인 범위와 실패 범위를 Source 페이지에 남긴다.

다음 조건을 모두 만족할 때만 `ingestion_status: complete`로 전환할 수 있다.

- 모든 연결 Raw 파일을 열 수 있다.
- PPTX의 모든 슬라이드와 speaker notes 또는 PDF의 모든 페이지를 확인했다.
- 주요 수식, 표, 그림과 인용 위치를 확인했다.
- 학습에 중요한 embedded media 또는 외부 의존성이 누락되지 않았다.

확인할 수 없는 범위가 학습에 영향을 주면 `partial`을 유지한다. 이는 학습을 시작할 수 없다는 뜻이 아니라, 검증되지 않은 범위를 정식 Knowledge ingest에 사용하지 않는다는 뜻이다.

## 9. Study와 Knowledge ingest

Course Source는 기존 Source 상태 머신을 그대로 따른다.

```text
unread -> learning -> understood -> integrated
```

사용자는 슬라이드나 페이지 단위로 질문하고 계산, 그림 해석과 이해 확인을 진행한다. 사용자의 생각이나 질문을 보존할 때는 기존 규칙대로 새 `raw/notes/` 파일과 Thought 또는 Question을 만든다.

사용자가 자료를 이해했다고 명시적으로 선언한 뒤에만 Knowledge ingest를 수행한다. 수업자료의 확정 주장은 Raw PPTX 또는 PDF에서 재검증한다. 자료가 다른 논문이나 Web source를 인용하지만 원문을 직접 확인하지 않았다면 그 내용을 해당 원문의 직접 주장으로 승격하지 않는다. 필요한 경우 인용된 primary Source를 별도로 등록해 교차 검증한다.

## 10. Schema와 문서 변경

구현 시 다음 파일을 함께 변경한다.

- `AGENTS.md`: `course` subtype, local course ingest, PPTX/PDF coverage와 Raw 안전 규칙
- `README.md`: 폴더 위치, 등록·학습 요청 예시와 동일 내용의 format variant 규칙
- `templates/source-course.md`: Course Source template
- `wiki/index.md`: `Sources` 아래 `Courses` section
- `scripts/lint-wiki.sh`: 필수 경로, folder/source_type 일치, `formats`, `raw_sources`와 지원 확장자 검증
- 관련 shell test 또는 verification fixture: 정상 Course Source와 잘못된 metadata를 검증

## 11. Lint 규칙

구조 lint는 다음을 추가로 검사한다.

- Course Raw 및 Wiki 디렉터리가 존재한다.
- `wiki/sources/courses/`의 페이지는 `type: source`, `source_type: course`다.
- Course Source에 `formats`와 `raw_sources`가 존재한다.
- `formats`의 값은 현재 `pptx`, `pdf`만 허용한다.
- `raw_sources`의 각 link는 `raw/sources/courses/` 아래의 실제 파일을 가리킨다.
- Raw 파일 확장자와 `formats`가 일치한다.
- Source 페이지가 `wiki/index.md`에 등록되어 있다.
- 모든 wikilink가 유효하다.

기존 paper, web, youtube Source에는 `formats`나 `raw_sources`를 요구하지 않는다.

## 12. 검증

구현 완료 전 다음을 확인한다.

1. 기존 빈 Wiki에서 `bash scripts/lint-wiki.sh`가 통과한다.
2. PPTX 하나만 연결한 Course Source가 통과한다.
3. 같은 Source에 PPTX와 PDF를 함께 연결한 경우 통과한다.
4. 지원하지 않는 DOCX format은 실패한다.
5. 존재하지 않는 Raw link는 실패한다.
6. `source_type`과 폴더가 불일치하면 실패한다.
7. index에 등록되지 않은 Course Source는 실패한다.
8. 기존 paper, web, youtube 검증이 회귀하지 않는다.

## 13. 완료 기준

- 사용자가 PPTX 또는 PDF를 `raw/sources/courses/`에 직접 넣을 수 있다.
- 같은 내용의 PPTX와 PDF를 Source 하나로 등록할 수 있다.
- 슬라이드와 PDF 페이지 단위 provenance를 기록할 수 있다.
- Course Source가 기존 학습 상태와 Knowledge ingest 절차를 따른다.
- 불완전한 시각 자료나 embedded media coverage를 `partial`로 보존한다.
- lint가 Course Source의 경로, 형식, Raw link, index와 metadata를 검증한다.
- 기존 Source subtype과 호환된다.
- DOCX 등 추가 형식은 schema 재설계 없이 이후 허용 형식과 처리 규칙을 확장할 수 있다.
