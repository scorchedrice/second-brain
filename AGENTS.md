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

새 Source의 `ingestion_status` 기본값은 `partial`이다. 필요한 본문, metadata, 인용 위치와 capture 범위를 확인한 뒤에만 `complete`로 바꾼다.

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
