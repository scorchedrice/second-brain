# LLM Wiki 설계

## 1. 목적

이 저장소는 대학원 연구, 논문, 전공지식, 개발 지식과 사용자가 직접 형성한 이해를 장기간 축적하는 개인 LLM Wiki다. 단순히 원문을 검색해 매번 답을 재생성하는 RAG 저장소가 아니라, LLM이 원문을 읽고 기존 지식과 연결해 지속적으로 갱신하는 영속적인 Markdown 지식 그래프를 만든다.

사용자는 자료를 선택하고, 공부하며 질문하고, 자신의 생각을 제공하고, 어떤 내용을 실제로 이해했는지 선언한다. LLM은 원문 보존, 요약, 출처 추적, 개념 통합, 상충 관계 기록, 링크 관리, 색인 및 변경 이력을 담당한다.

설계의 기준은 다음과 같다.

- 논문과 자료가 말한 내용, 사용자의 생각, LLM의 분석을 엄격히 구분한다.
- 사용자가 이해했다고 선언하지 않은 자료는 개인의 확정 지식으로 취급하지 않는다.
- 새로운 자료와 질문이 기존 위키를 갱신하여 지식이 누적되게 한다.
- 잘못된 질문과 반증된 가설도 정정 이력과 함께 보존한다.
- 기본 서술은 한국어로 하되 논문 제목, 데이터셋, 모델, 알고리즘, API 및 전문용어는 영어 원문을 유지한다.
- 별도 데이터베이스 없이 Markdown, Obsidian wikilink, YAML frontmatter 및 Git으로 시작한다.

## 2. 핵심 아키텍처

Karpathy의 LLM Wiki 패턴에 따라 세 계층을 둔다.

### 2.1 Raw sources

`raw/`는 사용자가 소유하는 변경 불가능한 원본 계층이다. 논문 PDF, supplementary material, 사용자가 제공한 원문 메모, 이미지와 표 등을 보존한다. LLM은 사용자가 대화에서 보존을 요청한 원문을 새 파일로 생성할 수 있지만, 생성되거나 사용자가 추가한 기존 파일은 수정하거나 덮어쓰지 않는다.

### 2.2 Wiki

`wiki/`는 LLM이 소유하고 관리하는 지식 계층이다. 논문별 근거 노트, 개념 종합, 사용자 생각의 구조화본, 열린 질문, 색인 및 작업 로그를 포함한다. 새 원본이 추가되거나 중요한 질문이 해결될 때 기존 페이지를 함께 갱신한다.

### 2.3 Schema

루트 `AGENTS.md`는 LLM의 운영 schema다. 디렉터리 책임, 페이지 형식, 관계 타입, 상태 전이, 출처 표기, ingest/query/lint 절차, 금지 행동 및 검증 규칙을 정의한다. `templates/`는 schema를 실제 페이지 형식으로 보조한다. 사용 패턴이 확인되면 schema도 함께 발전시키되, 관계 타입이나 상태를 임의로 늘리지 않는다.

## 3. 디렉터리 구조

```text
second-brain/
├── AGENTS.md
├── README.md
├── raw/
│   ├── papers/
│   ├── notes/
│   └── assets/
├── wiki/
│   ├── index.md
│   ├── log.md
│   ├── concepts/
│   ├── papers/
│   ├── thoughts/
│   └── questions/
├── templates/
└── docs/superpowers/specs/
```

폴더는 AI, 수학, 시스템, 개발처럼 지식 분야별로 나누지 않고 페이지 역할별로 나눈다. 분야는 태그, alias 및 wikilink로 표현한다. 이를 통해 서로 다른 분야의 개념이 폴더 경계 없이 연결된다.

`inbox/`는 두지 않는다. 사용자는 새 논문을 `raw/papers/`, 자신의 원문 메모를 `raw/notes/`, 첨부물을 `raw/assets/`에 바로 둔다. 처리 여부와 학습 상태는 원본 위치가 아니라 Wiki 페이지의 metadata로 관리한다.

## 4. 지식 그래프

각 Markdown 페이지는 그래프의 노드이고 Obsidian wikilink는 엣지다. YAML frontmatter에는 관계의 의미를 기록하고 본문에는 사람이 따라갈 수 있는 문맥 있는 링크를 둔다.

### 4.1 노드 유형

- `paper`: 논문의 실제 내용과 학습 상태를 추적하는 근거 노드
- `concept`: 여러 근거를 종합한 현재 지식의 중심 노드
- `thought`: 사용자의 해석, 비판, 가설 또는 연구 아이디어
- `question`: 아직 해결되지 않았거나 과거에 해결·수정된 질문

Raw 파일은 원본 노드로 취급하되 LLM 생성 metadata를 원본 파일에 삽입하지 않는다. 대응하는 Paper 또는 Thought 페이지에서 원본 경로를 참조한다.

### 4.2 관계 유형

초기 관계 타입은 다음으로 제한한다.

- `supports`: 대상 주장이나 개념을 지지한다.
- `challenges`: 대상과 충돌하거나 적용 범위를 제한한다.
- `extends`: 기존 지식이나 방법을 확장한다.
- `uses`: 방법, 데이터셋, 모델 또는 도구를 사용한다.
- `derived-from`: 사용자 생각이나 분석이 어떤 근거에서 출발했는지 나타낸다.
- `about`: 페이지가 다루는 중심 대상을 나타낸다.
- `requires`: 이해에 필요한 선행 개념을 나타낸다.
- `motivates`: 질문, 가설 또는 후속 연구 방향을 유발한다.
- `related`: 더 구체적인 관계로 안전하게 분류할 수 없는 연결이다.

실제 사용 중 반복적으로 필요한 관계만 schema 검토를 거쳐 추가한다.

### 4.3 그래프 무결성

- 모든 Paper 페이지는 정확한 Raw 원본을 참조한다.
- Concept의 주요 사실 주장은 하나 이상의 통합된 근거를 가진다.
- `unread` 또는 `learning` Paper는 확정된 Concept 주장의 근거가 될 수 없다.
- 모든 Thought는 `derived-from` 또는 `about` 관계를 가진다.
- 모든 Question은 관련 Paper, Concept 또는 Thought와 연결된다.
- 새 Wiki 페이지는 `index.md`에 등록되고 적어도 하나의 기존 노드와 연결된다. 최초 seed 페이지는 예외로 한다.
- 의미상 양방향인 관계는 관련 페이지 양쪽에 탐색 가능한 링크를 둔다.
- 상충하는 근거는 삭제하거나 임의로 통합하지 않고 `challenges` 관계와 적용 조건을 기록한다.

## 5. 공통 metadata

모든 LLM 생성 페이지는 최소한 다음 metadata를 가진다.

```yaml
---
type: concept
status: integrated
created: 2026-08-02
updated: 2026-08-02
aliases: []
tags: []
sources: []
related: []
---
```

페이지 유형에 따라 raw source, DOI, arXiv ID, 관계, 학습 상태 등을 추가한다. `status`는 페이지 유형별 지식·학습 상태를 나타내고, Paper의 원본 처리 성공 여부는 별도의 `ingestion_status` 필드에서 `complete` 또는 `partial`로 관리한다. 날짜는 ISO 8601 형식을 사용한다. 빈 배열은 필드가 누락된 것과 구분한다.

## 6. 페이지 모델

### 6.1 Concept

Concept은 논문 하나의 요약이 아니라 여러 자료를 종합한 현재의 이해다. 다음 내용을 포함한다.

- 한눈에 보기
- 근거가 확인된 핵심 지식
- 주장 단위의 출처와 원문 위치
- 여러 출처를 종합한 내용
- 상충하는 관점과 조건
- 관련 및 선행 개념
- 관련 Thought
- 열린 Question

사용자의 생각은 Concept의 사실 서술에 섞지 않고 별도 Thought를 연결한다.

### 6.2 Paper

Paper는 논문이 실제로 무엇을 말했는지 추적하는 근거 페이지다. 서지정보, 학습 상태, research question, method, data and experimental setup, results, limitations, 저자가 명시한 주장, LLM 사전 분석, 관련 Concept·Thought·Question을 포함한다.

`LLM 사전 분석`은 읽기 안내일 뿐 확정된 사용자 지식이 아니다. 논문 내용을 기록할 때 가능한 경우 page, section, figure, table 또는 equation 위치를 포함한다.

### 6.3 Thought

Thought는 사용자의 interpretation, critique, hypothesis 또는 research idea를 구조화한다. 사용자 원문 파일, 구조화된 생각, 출발 근거, 반대 근거, 검증 방법 및 관련 Question을 포함한다. LLM은 원문보다 강한 주장으로 확대하거나 확실성을 높이지 않는다.

### 6.4 Question

Question은 질문, 발생 배경, 필요한 선행지식, 관련 자료, 현재까지의 부분 답변 및 해결 조건을 포함한다. 해결되거나 잘못 구성된 질문도 삭제하지 않고 상태와 대체 질문을 기록한다.

## 7. 지식과 상태 구분

Paper의 학습 상태는 다음과 같다.

- `unread`: 등록했지만 아직 읽지 않았다.
- `learning`: 읽거나 질문하며 학습 중이다.
- `understood`: 사용자가 이해했다고 명시적으로 선언했다.
- `integrated`: 정식 Knowledge ingest로 Concept graph 반영을 마쳤다.
- `revisit`: 이전 이해를 다시 검토해야 한다.

`understood` 전이는 사용자 선언으로만 발생한다. LLM은 대화 길이, 질문 수 또는 답변 정확도를 근거로 이해 완료를 추정하지 않는다.

Thought 상태는 `proposed`, `testing`, `supported`, `weakened`, `refuted`, `superseded`를 사용한다. Question 상태는 `open`, `answered`, `misframed`, `superseded`를 사용한다.

반증된 Thought와 잘못 구성된 Question은 삭제하지 않는다. 틀린 이유, 반증 근거, 수정된 이해 및 대체 노드를 연결한다. 단, 사소한 오타나 즉시 정정된 표현은 별도 노드로 승격하지 않는다.

## 8. 출처와 주장 규칙

주요 주장은 페이지 하단의 참고문헌 목록에만 의존하지 않고 주장 가까이에 근거와 원문 위치를 표시한다.

내용의 성격을 다음과 같이 구분한다.

- `[Source]`: 원문에서 직접 확인된 사실 또는 저자의 명시적 주장
- `[Synthesis]`: 둘 이상의 출처를 종합해 도출한 결론
- `[User interpretation]`: 사용자의 해석 또는 비판
- `[Hypothesis]`: 아직 검증되지 않은 사용자 가설
- `[LLM analysis]`: LLM이 생성했으며 사용자가 확인하지 않은 분석

`[LLM analysis]`는 사용자 선언 없이 `[Synthesis]`나 개인의 확정 지식으로 승격하지 않는다. 논문이 제시하지 않은 결론을 저자의 주장처럼 기록하지 않고, 상관관계를 인과관계로 바꾸지 않으며, 확인할 수 없는 인용 위치를 생성하지 않는다.

## 9. 운영 절차

### 9.1 Register ingest

아직 읽지 않은 자료도 Raw source로 등록하고 학습 가능한 상태로 만든다.

1. Raw 원본과 중복 여부를 확인한다.
2. Paper 페이지를 만들거나 기존 페이지에 새 revision을 연결한다.
3. 학습 상태를 `unread` 또는 `learning`으로 둔다.
4. 서지정보, 다루는 주제, 필요한 선행 개념, 읽을 때 확인할 질문 및 연결 후보를 정리한다.
5. 연결 후보는 확정 근거로 사용하지 않는다.
6. `index.md`와 `log.md`를 갱신한다.

### 9.2 Study/query

학습 중 질문에는 `index.md`를 먼저 읽고 관련 Wiki 페이지와 Raw source를 찾아 근거 있는 답을 제공한다. 문단, 수식, 표와 실험 결과를 설명하고 필요한 선행 개념을 안내한다.

의미 있는 사용자 생각과 질문은 원문을 새 `raw/notes/` 파일로 보존하고 Thought 또는 Question으로 구조화한다. 기존 Raw note에 내용을 덧붙이지 않는다. 아직 이해 선언이 없으면 Concept의 확정 지식에는 반영하지 않는다.

좋은 비교, 분석 또는 연결이 대화에서 나와도 자동으로 확정 지식에 저장하지 않는다. 사용자에게 저장 또는 통합 의사를 확인한 뒤 적절한 페이지로 반영한다.

### 9.3 Knowledge ingest

사용자가 이해했다고 선언하고 정식 반영을 요청한 경우 수행한다.

1. Paper 상태를 `understood`로 전환한다.
2. 논문의 주장, 방법, 결과, 한계와 인용 위치를 검증한다.
3. 관련 Concept을 생성하거나 기존 내용을 새 근거에 맞게 갱신한다.
4. 기존 자료와의 일치, 확장 및 상충 관계를 기록한다.
5. 사용자 Thought 및 관련 Question을 연결한다.
6. 새 링크와 graph integrity를 검사한다.
7. `index.md`와 `log.md`를 갱신한다.
8. 검증 완료 후 Paper 상태를 `integrated`로 바꾼다.

### 9.4 Query 결과의 축적

일반 질문에는 Wiki를 우선 사용하고 필요할 때 Raw source를 확인한다. 답에는 Wiki 페이지와 원문 근거를 연결한다. 재사용 가치가 있는 비교, 분석 또는 새로운 연결은 사용자 확인 후 Concept, Thought 또는 Question에 편입하여 chat history에만 남지 않게 한다.

### 9.5 Lint

정기 lint는 다음을 검사한다.

- 필수 YAML 속성과 허용된 상태값
- 페이지 유형과 폴더의 일치
- 깨진 wikilink와 존재하지 않는 Raw source
- `index.md`에 등록되지 않은 페이지
- 출처 또는 인용 위치가 없는 주요 주장
- Source, User interpretation 및 LLM analysis의 혼합
- 미통합 Paper를 사용한 확정 주장
- 반증된 Thought를 사실로 참조하는 페이지
- 고아 노드, 중복 노드 및 비대칭 관계
- 오래된 Concept과 상충 표시 누락
- 장기간 `unread`, `learning` 또는 `revisit` 상태인 자료
- 이해 선언 후 통합되지 않은 자료
- 해결 조건이 불명확한 Question

명백한 링크 및 색인 오류는 반자동으로 수정할 수 있다. 지식의 의미나 확실성이 달라지는 변경은 사용자에게 보고하고 승인받는다.

## 10. 안전과 실패 처리

### 10.1 Raw 보호

- 기존 Raw 파일의 수정, 덮어쓰기 및 삭제를 금지한다.
- Raw 파일의 이름 변경이나 이동은 사용자 승인을 받는다.
- 새로운 사용자 메모는 타임스탬프가 포함된 별도 파일로 만든다.
- 원문이 틀렸거나 이후 생각이 바뀌어도 원문 자체는 변경하지 않는다.

### 10.2 부분 실패

PDF 페이지, 수식, 표, 이미지 또는 supplementary material을 읽지 못하면 Paper의 `ingestion_status`를 `partial`로 표시한다. 확인하지 못한 범위와 필요한 후속 자료를 기록하고 Knowledge ingest를 완료하지 않는다.

### 10.3 중복과 revision

DOI, arXiv ID, 제목 및 저자를 사용해 중복을 확인한다. 같은 버전이면 기존 Paper에 연결한다. 새 revision이면 원본을 별도로 보존하고 변경 내용을 비교한 뒤 기존 지식에 영향을 주는 부분만 갱신한다.

### 10.4 원자적 변경과 Git

논문 하나의 등록, 하나의 Knowledge ingest, 저장하기로 한 query 결과, 또는 lint 수정 하나를 하나의 논리적 변경 단위로 다룬다. 관련 페이지, index 및 log를 함께 검증한 뒤 작업 유형이 드러나는 Git commit으로 보존한다.

예시:

```text
ingest: register Attention Is All You Need
integrate: update transformer concepts from paper
query: preserve comparison of CNN and ViT
lint: repair orphaned concept links
```

`log.md`는 append-only 작업 기록이며 Git history는 파일 단위 복구와 변경 검토 수단이다.

## 11. Index와 Log

`wiki/index.md`는 내용 중심의 탐색 지도다. 페이지를 유형별로 분류하고 각 링크에 한 줄 요약, 상태 및 필요한 핵심 metadata를 제공한다. Query는 index를 먼저 읽고 관련 페이지로 이동한다.

`wiki/log.md`는 시간순 작업 기록이다. 각 항목은 파싱 가능한 형식을 사용한다.

```markdown
## [2026-08-02] ingest | Attention Is All You Need
```

작업 종류는 최소한 `ingest`, `integrate`, `query`, `lint`, `schema`를 구분한다. 각 항목은 수행한 작업, 변경된 주요 페이지, 미해결 문제를 간결히 기록한다.

## 12. 초기 구현 범위

첫 구현에는 다음을 포함한다.

- 디렉터리와 시작 페이지
- Codex 운영 schema인 `AGENTS.md`
- 사용자 안내인 `README.md`
- Concept, Paper, Thought, Question 템플릿
- `wiki/index.md`와 `wiki/log.md`
- Obsidian attachment 경로를 `raw/assets/`로 설정
- Markdown 및 shell 기반의 기본 구조·링크 lint
- Git 기반 변경 이력

embedding RAG, vector database, qmd, Dataview, Marp 및 복잡한 자동화는 초기 범위에서 제외한다. 수백 개 페이지 규모에서 index와 일반 텍스트 검색이 부족해질 때 추가한다.

## 13. 완료 기준

- 논문과 사용자 원문을 수정 없이 보존할 수 있다.
- 읽지 않은 자료를 확정 지식과 분리해 등록할 수 있다.
- 학습 중 질문과 설명을 기존 지식과 연결할 수 있다.
- 사용자 선언 후 Paper를 Concept graph에 통합할 수 있다.
- 논문 주장, 사용자 생각 및 LLM 분석이 명확히 구분된다.
- 반증된 가설과 잘못 구성된 질문의 이력이 보존된다.
- index에서 전체 위키를 탐색할 수 있다.
- Obsidian Graph View에서 Paper, Concept, Thought 및 Question 관계를 확인할 수 있다.
- lint가 구조, 근거, 상태 및 graph integrity 문제를 찾는다.
- Git으로 각 논리적 변경을 검토하고 복구할 수 있다.

## 14. 참고

- Andrej Karpathy, [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
