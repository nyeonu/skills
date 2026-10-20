# 에이전틱 개발 워크플로우 스킬 세트

요구사항 수집 → 스펙 → 계획 → 실행 → 검증 → 품질 검토 → 결정 기록을 하나의 환경(Cowork 또는 Claude Code CLI)에서 완결하는 워크플로우와 스킬 모음. 각 단계의 상세 규칙은 해당 스킬의 SKILL.md가 원본이다.

## 설치

이 레포는 Claude Code **플러그인 마켓플레이스**다. 두 가지 설치 경로가 있다.

### 방법 A — 대화형 설치 (처음이면 이걸 권장)

레포를 클론하고 그 안에서 Claude Code를 연 뒤 이렇게 말한다:

```
스킬 설치해줘
```

설치 가이드 스킬([.claude/skills/install-guide](.claude/skills/install-guide/SKILL.md))이 발동해서 MCP 서버 3종 → 스킬 플러그인 2종 순서로 각각의 역할을 설명하고, 필요한 것만 골라 설치해준다.

### 방법 B — 직접 설치

```bash
claude plugin marketplace add nyeonu/skills
```

이후 `/plugin` 메뉴에서 설명을 보고 고르거나, CLI로 직접 설치한다:

```bash
claude plugin install be-workflow@be-agentic-workflow --scope user
```

| 플러그인 | 내용 | 비고 |
|---|---|---|
| `be-workflow` | 워크플로우 코어 스킬 8종 (아래 도식의 파이프라인 전체 + 테스트 지침 testing-policy) | 상호 의존이라 묶음 설치 |
| `be-review` | 리뷰 스킬 3종 + 페르소나 에이전트 2종 | 단독 사용 가능 |
| `mcp-context7` | 라이브러리 최신 문서 조회 MCP | 선택. API 키 불필요 |
| `mcp-atlassian` | Jira·Confluence 원격 MCP | 선택. 첫 사용 시 `/mcp`에서 OAuth 로그인 |
| `mcp-chrome-devtools` | 성능 트레이스 측정 MCP | 선택. 로컬 Chrome 필요 |

MCP 3종은 전부 선택 사항이고, 없어도 스킬들은 동작한다.

## 구조

```
.claude-plugin/marketplace.json    # 마켓플레이스 정의 (플러그인 5종 목록)
.claude/skills/install-guide/      # 대화형 설치 가이드 (레포 안에서만 발동)
plugins/
  be-workflow/skills/
    using-agent-skills/        # 메타 라우터: 진입점 판단 + 공통 운영 규칙
    interview-me/              # [정의] 모호한 요구사항의 의도 추출
    spec-writer/               # [정의] 코드 기반 스펙 문서화
    task-breakdown/            # [계획] 승인된 스펙 → docs/<티켓 키>/plan.md 분해 (기준→테스트→작업 추적성 매핑)
    plan-executor/             # [실행] 계획 실행 오케스트레이션 (tier 기반 고/저비용 분리)
    testing-policy/            # [공통] 테스트 설계·작성·실행 지침 (작성 순서 자유, 도출 5출처)
    spec-conformance-check/    # [검증] 구현물 ↔ 스펙 독립 검증 (fail-fast 게이트)
    adr-writer/                # [기록] ADR 2시점 기록 (Proposed → Accepted)
  be-review/
    skills/
      code-review-and-quality/   # [리뷰] 다축 리뷰: 정확성·가독성·아키텍처 + 보안·성능 1차 확인
      security-and-hardening/    # [리뷰] 보안 (OWASP 기준, 체크리스트 필수 로드)
      performance-optimization/  # [리뷰] 성능 (백엔드 우선, 백엔드/프런트엔드 체크리스트 분리)
    agents/
      code-reviewer.md           # 리뷰 페르소나 (스킬과 동일한 심각도·판정 계약)
      security-auditor.md        # 보안 감사 페르소나
  mcp-context7/ · mcp-atlassian/ · mcp-chrome-devtools/   # MCP 서버 동봉 플러그인
```

## 사용 방법

이 스킬 세트는 절차와 frontmatter 계약 같은 **메커니즘**만 제공한다. 팀 단위로 쓸 때의 **운영 규칙**(티켓 모양, 브랜치, 승인 후 변경 처리)은 각 조직의 운영 문서가 정한다. 아래는 스킬 파이프라인 자체의 사용법이다.

### 실행 순서

```mermaid
flowchart TD
    start([요구사항 도착])
    interview["1. interview-me<br>의도 확정"]
    spec["2. spec-writer<br>docs/&lt;티켓&gt;/spec.md 작성"]
    gate1{스펙 승인}
    plan["3. task-breakdown<br>docs/&lt;티켓&gt;/plan.md 작성"]
    gate2{계획 승인}
    exec["4. plan-executor<br>실행자(저비용 모델) 위임 실행"]
    verify["5. spec-conformance-check<br>스펙 적합성 독립 검증"]
    review["6. review 3종 병렬<br>품질 · 보안 · 성능"]
    done([완료])
    adr1["adr-writer<br>ADR Proposed 작성"]
    adr2["adr-writer<br>ADR Accepted 확정"]
    testing_policy["testing-policy<br>테스트 지침"]

    start -->|모호함| interview
    start -->|명확함| spec
    interview --> spec
    spec --> gate1
    gate1 -->|반려| spec
    gate1 -->|승인| plan
    plan --> gate2
    gate2 -->|반려| plan
    gate2 -->|승인| exec
    gate2 -.->|되돌리기 비싼<br>결정 포함 시| adr1
    testing_policy -.->|테스트 도출 5출처| plan
    testing_policy -.->|"공통 테스트 지침<br>원문 자동 삽입"| exec
    exec --> verify
    verify -->|FAIL| recovery["원인 진단 · 제한된 복구"]
    recovery -->|허용 범위 · 잔여 회차| exec
    recovery -->|승인 필요한 변경| plan
    recovery -->|한도 초과 · 새 근거 없음| blocked["보존 후 사용자 보고"]
    verify -->|PASS| review
    verify -.->|PASS| adr2
    review -->|수정 필요| recovery
    review -->|통과| done

    style gate1 fill:#f9e2af,color:#000
    style gate2 fill:#f9e2af,color:#000
    style adr1 fill:#cba6f7,color:#000
    style adr2 fill:#cba6f7,color:#000
    style testing_policy fill:#a6e3a1,color:#000
```

노란 마름모 2곳은 최초 스펙·계획 승인이다. 실행 중에는 제한된 자동 복구를 적용하고, 승인 경계 밖 변경·한도 초과·새 근거 없는 반복만 사람에게 올린다. 보라색은 단계가 아니라 두 시점에 끼어드는 ADR 기록이고, 초록색은 계획(테스트 도출)과 실행(하위 에이전트 지시문)에 주입되는 테스트 지침 testing-policy다.

### 진입점 — 모든 작업이 1번부터 시작하지 않는다

- 요구사항이 모호하다 → 1 (interview-me)
- 요구사항은 명확, 스펙 없음 → 2 (spec-writer)
- 승인된 스펙(`status: approved`) 존재 → 3 (task-breakdown). `implemented`·`superseded` 스펙은 완료된 변경의 기록이라 분해 대상이 아니다
- 승인된 계획 존재 / 실행 중 계획 존재 → 4 (plan-executor, frontmatter `status`로 재개)
- 버그·장애 → testing-policy(결함을 검출하는 회귀 테스트)와 디버깅, 수정 범위가 크면 3으로 합류
- 구현 끝, 스펙 충족 확인 필요 → 5 (spec-conformance-check). 전체 PASS면 스펙 `status`를 `implemented`로 바꾼다
- 코드 품질·보안·성능 검토 → 6 (be-review 3종)
- 되돌리기 비싼 결정 기록 → adr-writer (계획 승인 직후 `Proposed`, 스펙 적합성 검증 통과 후 `Accepted`)
- 사소한 변경(단일 파일, 명확한 범위) → 워크플로우 생략, 직접 처리 (동작 변경이면 testing-policy 적용)

진행 상태의 단일 원본은 `docs/<티켓 키>/spec.md`·`plan.md` frontmatter의 `status`다. 세션이 끊겨도 문서 상태를 읽으면 중단 지점부터 잇는다.

에픽(업무 단위 티켓)이면 `docs/<에픽 키>/spec.md`와 `plan.md`(`kind: epic`, 공통 설계·추적성·분할 순서)를 두고, 승인된 뒤 작업 티켓마다 `docs/<에픽 키>/<작업 티켓 키>/plan.md`를 써서 하나씩 승인·실행한다. 실행자에게 주는 브리프는 plan-executor가 스펙 1·2·6절과 계획 2절·작업 블록에서 스크립트로 조립한다.

### 핵심 규칙

1. 승인 게이트 2개(스펙, 계획)는 생략 불가 — 사람이 통제권을 유지하는 장치.
2. 스펙 성공 기준 ↔ 테스트 ↔ 계획 작업 추적성 매핑 필수 (예방) + 5번 독립 검증 (확인). 5번 검증자에게 계획 문서를 주지 않는다.
3. fail-fast: 앞 게이트가 실패하면 뒤 단계 비용이 발생하지 않는다.
4. 계획 밖 병렬 실행은 읽기 전용 작업(검토)에만. 코드 수정은 반드시 계획 루프를 통한다. 승인된 계획 안에서 `depends_on` 없는 작업을 plan-executor가 병렬 실행하는 것은 계획 승인에 포함된 병렬성이다.
5. 단일 환경 진행: 작업 시작 시 Cowork/CLI 중 하나를 정하고 끝까지 그 환경에서. 산출물이 전부 레포 안(`docs/`)이라 다음 작업은 다른 환경에서 시작해도 된다. 요구사항 소스가 외부 채널(기획서·메신저) 중심이면 Cowork, 코드 중심이면 CLI가 유리하다.


### 테스트 지침 (be-workflow 0.1.31)

`testing-policy`가 테스트 설계·작성·실행 기준을 제공한다. 계획 단계에서 변경 기능·주요 로직·관련 조건의 검증 기준을 정하고, 실행자 브리프에는 공통 지침 원문을 자동 삽입한다. 완료 시 실제 테스트·실행 결과를 대조한다. 테스트와 구현의 작성 순서나 작성자 분리는 강제하지 않는다. 기존 테스트 재사용을 허용하며, 버그는 결함을 구별하는 회귀 테스트와 가능한 경우 수정 전후 확인으로 검증한다. 구현 중 발견한 누락은 보고하고 승인 범위 안에서 보완한다.

기존 `tdd` 스킬은 `testing-policy`로 교체했다. 직접 호출이나 개인 지침에서 `tdd`를 참조했다면 새 이름으로 바꾼다. 과거 TDD 평가 결과는 새 지침의 결함·시간·비용 효과를 입증하지 않는다.

### 제한된 자동 복구 (be-workflow 0.1.17)

실행 중 실패는 오케스트레이터가 원인을 분류하고 승인된 동작·범위·제약 안에서 부분 수정으로 복구한다. 최초 실행 이후 작업당 최대 2회이며 새 근거 없는 동일 가설 반복은 중단한다. 완료 코드를 보존하고 영향받는 부분만 재검증한다. 계획의 `복구 기록`에 회차·근거·보정·검증을 남기므로 임시 브리프 파일 없이도 이력을 유지한다. 권한 경계 밖 변경이나 한도 초과는 사용자에게 보고한다. 상세 조건은 [복구 정책](plugins/be-workflow/skills/plan-executor/references/recovery-policy.md)을 따른다.

### 리뷰 스킬의 참고자료 계약

상세 체크리스트의 원본은 전문 스킬(`security-and-hardening`, `performance-optimization`)의 `references/`에 하나씩 있고, `code-review-and-quality`는 자기 `references/`에 국소 추론 체크리스트만 두고 보안·성능 체크리스트는 `${CLAUDE_PLUGIN_ROOT}` 경로로 그 원본을 읽는다(사본 없음). 본문은 판단 규칙만 담는다. 로드는 권고가 아니라 계약이다:

- `security-and-hardening`: 발동 시 `security-checklist.md`를 **항상** 읽고 시작
- `performance-optimization`: 대상 영역별 필수 — 백엔드 작업 → `performance-checklist-backend.md`, UI·브라우저 작업 → `performance-checklist-frontend.md`, 풀스택·불분명 → 둘 다
- `code-review-and-quality`: diff와 작업 목적으로 조건을 판정해 발견 사항 분류 **전에** 해당 체크리스트를 읽고, 출력의 "읽은 참고자료" 슬롯으로 무엇을 읽었는지 드러낸다. 결정 로직·암묵적 동작·도메인 경계 변경이면 `local-reasoning-checklist.md`(에이전트가 파일 몇 개만 보고 안전하게 고칠 수 있는 구조인지의 판정 기준)도 읽는다

외부 공식 기준(OWASP 비밀번호 저장, Core Web Vitals)은 매 작업마다 조회하지 않는다. 각 참고자료의 출처 메타데이터(공식 출처·확인일·출처 버전·상태)에 기록된 값을 쓰고, 월 1회 원본 변경(commit SHA·Last updated)만 감지한다 — 변경이 있으면 자동 수정 없이 `needs_review`로 표시하고 사람이 검토해 갱신한다. 신규 비밀번호 저장 설계, 알고리즘·파라미터 확정, CWV를 스펙·SLA·CI 기준으로 확정하는 작업은 시점과 무관하게 공식 출처를 재확인한다.

## 평가

플러그인마다 `evals/`에 `claude plugin eval` 케이스가 있다 (be-review 3개, be-workflow 9개: 스킬마다 라우팅 케이스 하나씩 + 설정 값 변경에 testing-policy가 발동하지 않는지 보는 경계 케이스. 그 밖에 be-workflow에는 API 비용 없이 도는 브리프 조립기 고정 점검 `evals/assembler-check/run.sh`가 있다). 플러그인 루트에서 아래를 돌리면 플러그인 있음/없음 두 arm을 3회씩 실행해 점수 차이(Δ)를 보고한다. 케이스 목록과 각 케이스가 재는 것은 각 플러그인의 `evals/README.md`에 있다. 원시 결과(`evals/results/`)는 커밋하지 않고, 보관할 결과 JSON은 `evals/history/`에 단계별 이름으로 두고 색인에 적는다.

```bash
claude plugin eval . --scaffold --trust-plugin --no-publish
```

## 출처

- addyosmani/agent-skills (MIT): interview-me 원본, spec-writer·task-breakdown·testing-policy의 초기 방법론, review 3종·페르소나 번역 원문
- 기존 plan-writer/plan-executor/adr-writer: 포맷 계약과 오케스트레이션 구조

원본에서 무엇을 왜 바꿨는지는 [CUSTOMIZATIONS.md](CUSTOMIZATIONS.md)에 기록되어 있다.

## 공개 자료의 경계

플러그인에는 실제 애플리케이션의 소스 코드, 서비스명, 업무 티켓, 조직 전용 설정·정책·경로를 넣지 않는다. 참고자료와 평가 픽스처는 가상의 도메인·`com.example`·`example.com`으로 작성한다. 실제 산출물이나 `CLAUDE.md`를 예제로 복사하지 않는다.

실행 이력을 보관할 때는 식별 정보와 로컬 경로를 제거하고 비식별화 여부를 명시한다. 수치·판정·검증 한계는 보존하며 가명으로 바꾼 문자열을 원본 실행 증거라고 주장하지 않는다. 공개 전에는 현재 파일뿐 아니라 파일명·커밋 메시지·모든 공개 브랜치의 이력도 확인한다.
