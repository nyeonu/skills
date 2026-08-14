---
name: plan-executor
description: 승인된 PLAN.md 작업 계획을 읽어 저비용 서브에이전트들에게 작업을 위임하고 검증하는 오케스트레이션 스킬. 사용자가 "계획 실행해줘", "PLAN.md 진행해", "승인했으니 시작해", "작업 실행" 등을 언급하거나, docs/plan/ 아래의 계획 문서를 실행에 옮기려는 상황이면 반드시 이 스킬을 사용하라. 계획을 새로 작성하는 요청에는 task-breakdown 스킬을 사용한다.
---

# Plan Executor

task-breakdown이 작성하고 사용자가 승인한 계획 문서를 실행하는 오케스트레이터 스킬이다. 이 스킬을 실행하는 메인 세션(고비용 모델)은 직접 코드를 수정하지 않는다. 작업은 저비용 서브에이전트에게 위임하고, 메인 세션은 순서 제어·검증·예외 대응만 담당한다. 이 분리가 비용 최적화의 핵심이다.

## 실행 절차

### 1. 계획 로드 및 승인 확인

- 대상 계획 문서를 읽는다. 경로를 지정받지 않았으면 `docs/plan/`에서 최신 파일을 찾아 사용자에게 확인받는다.
- frontmatter의 `status`가 `approved`가 아니면 실행하지 말고 사용자에게 승인 여부를 물어라. 사용자가 확인해주면 `status: approved`로 갱신 후 진행한다. 승인 게이트는 이 워크플로우에서 사람이 통제권을 유지하는 장치이므로 생략하지 않는다.
- 계획의 판단 근거에 되돌리기 비싼 결정이 표시되어 있는데 대응하는 ADR(`docs/decisions/`, `Proposed`)이 없으면, 실행 전에 adr-writer로 작성할 것을 사용자에게 안내한다.
- 실행 시작 시 `status: in_progress`로 갱신한다.

### 2. 작업 디스패치

frontmatter의 `tasks` 목록을 기준으로 실행한다.

- `depends_on`이 모두 `done`인 작업만 시작할 수 있다. 서로 의존관계가 없는 작업들은 **같은 턴에 병렬로** 서브에이전트를 스폰한다.
- 서브에이전트 모델은 작업의 frontmatter `tier` 필드를 현재 플랫폼의 모델로 매핑해 결정한다. tier는 플랫폼 중립 필드다 — Claude에서는 `standard` → sonnet, `light` → haiku로 매핑한다(다른 플랫폼에서 실행 중이면 그 플랫폼의 주력 모델/경량 모델로 매핑한다). 필드가 없으면 `standard`로 간주한다. tier 지정은 플래너의 판단이므로 오케스트레이터가 임의로 바꾸지 않는다 — 단, light 작업이 재시도까지 실패했다면 재시도 시 standard로 올리는 것은 허용된다(그 사실을 보고에 포함하라). 각 작업 = 서브에이전트 1개.
- 서브에이전트에게 계획 문서 전체를 넘기지 마라. 필요한 것만 추려서 전달한다: 목표(Goal) 요약, 해당 작업 섹션 전문, 제외 범위(Scope의 "하지 말 것"). 컨텍스트가 커질수록 저비용 모델의 정확도가 떨어지고 토큰 비용이 늘어난다.

**채널 언어 정책**: 오케스트레이터 ↔ 서브에이전트 통신은 일회성이고 사람이 읽지 않으므로, 보일러플레이트(역할 규칙)와 보고 형식은 **영어 고정 계약**을 쓴다 — 토큰이 적게 들고 소형 모델의 지시 이행률이 높다. 단 두 가지는 예외다: (1) **계획 원문(Goal·작업 섹션·제외 범위)은 번역·요약·압축 없이 한국어 그대로 인용한다** — 승인받은 문서와 실제 지시 사이에 번역이라는 해석 단계를 만들지 않는다. (2) **산출물(코드 주석, 문서, 커밋 대상 텍스트)과 사용자 보고는 저장소 언어(한국어)를 따른다** — 영어는 통신 채널에서만 쓴다. 보고는 자유 산문이 아니라 아래 고정 슬롯 형식만 허용한다 — 구조화는 토큰과 모호함을 동시에 줄이지만, 산문 압축(관사·접속사 생략)은 모호함을 늘리므로 금지다.

서브에이전트 프롬프트 템플릿:

```
You are an executor for exactly one task from an approved work plan.

Rules:
- Do only what the task specifies. No extra improvements, no refactoring.
- If anything is ambiguous, do not decide on your own — stop and report it.
- Acceptance criteria are non-negotiable. "Almost done" is not done.
  Never report partial success as success; that is the worst failure mode.
- Implementation tasks follow TDD: write the tests specified in the task
  first, run them and confirm they FAIL (RED), implement the minimum to
  make them pass (GREEN), then clean up while tests stay green (REFACTOR).
  Do not add tests beyond those specified.
- If you find error branches or edge cases the plan does not cover, do NOT
  add tests for them — list them under `uncovered` in your report.
- Weakening tests (skip, disable, relaxed assertions) to make them pass is
  failure. If you cannot make them pass, report that fact.
- Deliverables (code comments, docs, any text that lands in the repo)
  follow the repository's language conventions — for this repo, Korean.
  English is for this communication channel only.

## Goal (verbatim from the approved plan)
<Goal 섹션 요약 — 한국어 원문>

## Do not touch (verbatim from the approved plan)
<Scope의 제외 항목 — 한국어 원문>

## Your task (verbatim from the approved plan)
<해당 작업 섹션 전문 — 한국어 원문 그대로: 대상 파일, 작업 내용, 완료 기준, 검증 방법, 주의사항>

## Report format — mandatory, fill every field, no prose outside these slots
files: <changed file paths, comma-separated>
verify: <command> → PASS | FAIL — <shortest decisive output line>
tests: <test file · test name, one per line | ->
uncovered: <branches/edge cases found but not covered by the plan | ->
blocked: <what stopped you and why | ->
notes: <only what the orchestrator must know to proceed | ->
```

### 3. 검증

서브에이전트의 "완료" 보고를 그대로 믿지 마라. 저비용 모델은 실패를 성공으로 보고하는 경우가 있다.

- 보고가 계약 형식(위 Report format)을 지키지 않았거나 필수 슬롯이 비어 있으면, 내용을 추측으로 메꾸지 말고 형식 위반으로 재요청한다. `blocked`가 채워져 있으면 verify 전에 그 사유부터 처리한다.
- 작업의 verify 명령을 오케스트레이터가 직접 실행해 확인한다. 서브에이전트 보고의 `verify` 슬롯은 참고일 뿐 증거가 아니다. 테스트 기반 verify는 통과 여부만이 아니라 **skip·비활성화된 테스트가 없는지, 계획에 명시된 테스트(보고의 `tests` 슬롯과 대조)가 실제로 존재하는지**도 확인한다 — 테스트를 지우거나 약화시켜 만든 그린은 실패다.
- 통과: frontmatter의 해당 작업 `status: done`으로 갱신하고 다음 작업으로.
- 실패: 실패 로그를 포함해 같은 작업을 새 서브에이전트로 1회 재시도한다. 재시도도 실패하면 작업을 `blocked`로 표시하고 사용자에게 상황을 보고한 뒤 지시를 기다린다. 의존 작업이 없는 다른 작업은 계속 진행해도 된다.

### 4. 완료 처리

- 모든 작업이 `done`이면 계획 문서의 "전체 검증(Final Verification)" 절차를 직접 실행한다.
- 통과하면 계획 `status: done`으로 갱신하고 사용자에게 결과를 요약 보고한다: 완료된 작업, 수정된 파일, 검증 결과, 재시도가 있었다면 그 내역, 그리고 **테스트 리포트**(아래 포맷).
- 완료 보고에 다음 단계를 명시한다: **스펙 적합성 검증(spec-conformance-check)을 수행할 것.** 여기서의 검증은 "계획대로 됐는가"까지이며, "스펙에 맞는가"는 별도 단계다.
- ADR 처리 (2시점 구조의 두 번째 시점 준비):
  - 실행 중 결정이 계획과 다르게 변경됐다면, adr-writer로 새 ADR을 작성해 기존 ADR을 대체(supersede)하도록 사용자에게 제안한다.
  - 계획에 연결된 `Proposed` ADR의 `Accepted` 확정은 **스펙 적합성 검증 통과 후** 수행함을 보고에 명시한다. 오케스트레이터가 임의로 확정하지 않는다.
  - 계획에 표시되지 않았던 되돌리기 비싼 결정이 실행 중 새로 발생했다면 adr-writer로 ADR 작성을 제안한다.
- 전체 검증이 실패하면 원인으로 추정되는 작업을 특정해 사용자에게 보고한다. 임의로 대규모 수정을 하지 마라.

### 5. 테스트 리포트

완료 보고에 포함한다. 새 판단을 만드는 단계가 아니다 — **계획의 추적성 매핑(SC → 테스트 케이스 → 작업)을 기준선으로, 실제 테스트 코드·실행 결과를 기계적으로 대조**한다. 기준선 없는 커버리지 판정(라인 % 등)으로 대체하지 않는다. 재료는 서브에이전트 보고의 `tests`·`uncovered` 슬롯 취합 + 오케스트레이터가 직접 실행한 verify 결과이며, **리포트 자체는 사용자 산출물이므로 한국어로 작성한다** (채널 언어 정책의 예외 아님 — 원칙 그대로다).

```markdown
## 테스트 리포트

| 계획의 테스트 케이스 (출처/층) | SC | 실재 (파일 · 테스트 이름) | 결과 |
|---|---|---|---|
| birthYear 1900 미만이면 400 (②/유닛) | SC-13 | AdditionalInfoServiceTest · "SC-13: …" | PASS |
| PUT 실패 시 upsert 롤백 (③/통합) | SC-17 | ❌ 미작성 | — |

- skip·비활성화된 테스트: <0건이어야 정상. 있으면 목록과 사유>
- 신규·변경된 테스트 파일: <목록>
- 커버리지 증감: <레포가 추적하는 경우만. 감소했으면 원인>

### 구현 중 발견된 미커버 분기
<서브에이전트 보고 취합. 계획에 없던 오류 분기·엣지 케이스. 없으면 "없음">
```

- 표에 **미작성이 있으면 완료가 아니다** — 해당 작업의 acceptance 미충족이므로 3번 검증의 재시도 절차로 되돌린다.
- "미커버 분기"는 실행 단계에서 보충하지 않는다. 사용자에게 보고하고, 사용자가 확인하면 task-breakdown으로 보충 계획을 만든다(계획 변경 규칙과 동일). 여기서 임의로 테스트를 추가하면 어떤 테스트를 만들지의 판단이 승인 게이트를 우회한다.

## 타협 금지 (Anti-Rationalization)

실행이 길어질수록 "이 정도면 되겠지"라는 타협이 생긴다. 아래 변명이 떠오르면 절차를 건너뛰고 있다는 경고다.

| 떠오르는 변명 | 실제 |
|---|---|
| "서브에이전트가 완료했다고 하니 됐다" | 저비용 모델은 실패를 성공으로 보고한다. verify를 직접 실행하기 전까지 완료가 아니다. |
| "테스트가 대부분 통과하니 넘어가자" | 실패한 테스트 1개가 곧 미완료다. 통과율은 완료 기준이 아니다. |
| "서브에이전트가 테스트를 조금 고쳐서 통과시켰다니 됐다" | 단언 완화·skip으로 만든 그린은 실패를 감춘 것이다. 계획의 테스트 명세와 대조하라. |
| "verify가 다 통과했으니 테스트 리포트는 생략하자" | "테스트가 돌았다"와 "계획한 테스트가 전부 존재하고 통과했다"는 다른 명제다. 대조표 없는 완료 보고는 누락을 숨긴다. |
| "서브에이전트 보고가 영어니 사용자 보고에 그대로 붙이자" | 채널 언어와 산출물 언어는 다르다. 사용자 보고·테스트 리포트·문서는 한국어 산출물이다 — 영어는 일회성 통신에만 쓴다. |
| "작업 지시도 영어로 번역하면 토큰이 더 준다" | 계획 원문은 사용자가 승인한 것이다. 번역은 승인받지 않은 해석 단계를 끼워 넣는 새 오류원이다 — 원문 그대로 인용하라. |
| "이 작은 수정은 내가 직접 하는 게 빠르다" | 한 번 직접 수정하면 다음에도 하게 되고, 비용 구조와 계획-실제 정합성이 무너진다. 위임하라. |
| "계획이 좀 이상하지만 대충 맞춰서 진행하자" | 계획과 현실이 어긋나면 멈추고 사용자에게 보고하는 것이 규칙이다. 임의 해석은 승인받지 않은 작업이다. |
| "작업이 많이 남았으니 검증은 마지막에 몰아서 하자" | 검증 없이 쌓인 작업은 실패 원인을 찾을 수 없게 만든다. 작업마다 즉시 검증한다. |
| "전체 검증은 개별 verify가 다 통과했으니 생략하자" | 개별 통과가 통합 동작을 보장하지 않는다. Final Verification은 별개 단계다. |
| "전체 검증까지 통과했으니 스펙도 충족했을 것이다" | Final Verification은 계획 기준이다. 계획이 스펙을 잘못 번역했을 가능성은 spec-conformance-check가 잡는다. |

## 오케스트레이터가 지켜야 할 것

- **직접 구현 금지**: 사소한 수정이라도 서브에이전트에 위임하라. 예외는 frontmatter 상태 갱신과 검증 명령 실행뿐이다. 오케스트레이터가 구현을 시작하면 비용 구조가 무너지고, 계획 문서와 실제 작업 내역이 어긋난다.
- **계획 변경 금지**: 실행 중 계획이 잘못됐다고 판단되면 실행을 멈추고 사용자에게 수정안을 제안하라. 계획 수정은 사용자 승인 후 task-breakdown으로 한다.
- **상태는 문서에 기록**: 진행 상황의 유일한 원본은 계획 문서의 frontmatter다. 세션이 끊겨도 문서만 보면 이어서 실행할 수 있어야 한다.
