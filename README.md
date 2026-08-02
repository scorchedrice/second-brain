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
