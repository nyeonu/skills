# be-workflow description 재작성 B: 측정 결과

측정일: 2026-10-08 (Asia/Seoul). 브랜치: `feature/rewrite-description-b`. 기준 커밋: `4939e16`.

## 1. 판단과 깨지는 조건

**description은 1,974자에서 1,412자로 28.5% 줄었다. Codex에서 동일한 요청으로 원본과 B안을 각각 24회 실행했다.** 명시적 스킬 선택은 원본·B 모두 24/24였지만, 가정 확인 전 스펙 작성은 원본 0/3회에서 B 2/3회로 관찰됐다. **간결화는 달성했으나 동작 개선은 입증하지 못했으며, 사전 확인 동작의 회귀 후보를 재검증하기 전에는 채택을 보류한다.** 이 실험은 Claude의 자동 발동률 또는 성능 향상을 증명하지 않는다.

새로운 요청에서 오선택이 늘거나 승인·검증 규칙이 약해지면 이 후보를 다시 검토해야 한다. 같은 요청 세 번은 안정성을 확정할 충분한 표본이 아니며, 8개 긍정 케이스는 과잉 발동·스킬 간 경계의 전체 범위를 검사하지 않는다.

## 2. 측정 방법

- 사용자 요청에 따라 Anthropic 호출 없이 현재 Codex 모델을 상속한 fresh-context 실행자를 사용했다. 모델 ID는 서브에이전트 도구가 노출하지 않아 정확한 모델 버전은 기록할 수 없다. 두 안은 같은 세션 모델·지침·도구 조건으로 실행했다.
- 공통 커밋의 8개 prompt 본문·fixture·grader를 그대로 사용했다. 8케이스 × 3회 × 2안 = 48회. 정답·변경 의도·이전 결과·다른 안의 문구를 실행자에게 제공하지 않았다.
- 각 실행은 별도의 프로젝트 복사본과 8개 스킬 목록을 받았다. 이름·description으로 먼저 선택을 기록하고 선택한 본문을 읽은 뒤 실제 요청을 수행했다. `none` 선택도 허용했다.
- 원본과 B안의 trial 배치는 seed 1008로 섞었고, 독립 검증자를 위한 슬롯 확보 때문에 실제 시작 순서는 조정했다. 선택·응답·파일·입력 해시를 모두 보존했다.
- 평가 요청의 셸 제약을 유지해 실행자는 테스트·빌드·앱을 실행하지 않았다. 파일 읽기·검색·쓰기만 허용했다. TDD 산출물은 이후 별도 로컬 검증에서 실제 JUnit으로 실행했다.
- 스킬 선택/Read 지표는 실행자가 남긴 selection.json·events.json으로 측정했다. 네이티브 Claude Skill/Read 도구 추적과 같지 않다. 특히 다른 스킬을 참고로 읽는 것과 다른 워크플로우를 발동하는 것은 달라 `no-other-workflow-skill`과 `no-wrong-entry-skill`은 점수를 부여하지 않았다.
- response.md에는 기존 regex를 그대로 적용했다. conformance-verdict는 원래 네 조건으로 별도 Codex 채점자가 마지막 응답만 판정했다. 채점자는 원본/B 매핑과 기존 판정을 받지 않았지만 이전에 fixture 한 건을 정적으로 검토한 맥락은 있었다. 기존 haiku 심판과 동일한 측정은 아니다.
- 이전 Claude 기준선 21/24는 배경값이며 이번 Codex 결과와 증감 계산하지 않는다. 비용·토큰은 별도 집계하지 않았고, 문자 수 감소를 토큰·실행 비용 절감 실측으로 표현하지 않는다.

## 3. 스킬 선택과 본문 로드

여기서 선택은 명시적 목록 선택 실험의 결과다. 일반 대화에서 자동으로 발동한 비율을 뜻하지 않는다.

| 스킬 | 원본 첫 선택 | B 첫 선택 | 기대 본문 로드 원본 → B |
| --- | --- | --- | --- |
| adr-writer | 3/3 | 3/3 | 3/3 → 3/3 |
| interview-me | 3/3 | 3/3 | 3/3 → 3/3 |
| plan-executor | 3/3 | 3/3 | 3/3 → 3/3 |
| spec-conformance-check | 3/3 | 3/3 | 3/3 → 3/3 |
| spec-writer | 3/3 | 3/3 | 3/3 → 3/3 |
| task-breakdown | 3/3 | 3/3 | 3/3 → 3/3 |
| tdd | 3/3 | 3/3 | 3/3 → 3/3 |
| using-agent-skills | 3/3 | 3/3 | 3/3 → 3/3 |
| 합계 | 24/24 | 24/24 | 24/24 → 24/24 |

## 4. 기존 산출물 채점기를 적용한 결과

regex 실패를 의미상 동작 실패와 합치지 않는다. 테스트 여부는 응답 문구뿐 아니라 실제 파일과 실행 결과로 다시 확인했다.

| 스킬 | 채점기 | 원본 | B | 차이 |
| --- | --- | --- | --- | --- |
| adr-writer | next-adr-number | 3/3 | 3/3 | +0 |
| adr-writer | status-proposed | 3/3 | 3/3 | +0 |
| interview-me | asks-with-estimate | 3/3 | 3/3 | +0 |
| interview-me | states-confidence | 0/3 | 0/3 | +0 |
| plan-executor | asks-approval | 3/3 | 3/3 | +0 |
| spec-conformance-check | conformance-verdict | 3/3 | 3/3 | +0 |
| spec-writer | surfaces-assumptions | 3/3 | 2/3 | -1 |
| task-breakdown | has-traceability | 0/3 | 0/3 | +0 |
| task-breakdown | reads-plan-template | 3/3 | 3/3 | +0 |
| tdd | writes-reproduction-test-first | 0/3 | 0/3 | +0 |
| using-agent-skills | names-entry-skill | 3/3 | 3/3 | +0 |
| 합계 | 기존 산출물 채점기 | 24/33 | 23/33 | -1 |

## 5. 실제 산출물 점검

| 관찰한 동작 | 원본 | B |
| --- | --- | --- |
| 가정 확인 전 스펙 파일을 작성하지 않음 | 3/3 | 1/3 |
| draft 계획을 실행하지 않고 승인 요청 | 3/3 | 3/3 |
| 인터뷰 중 문서·코드 미작성 | 3/3 | 3/3 |
| 진입 안내 중 문서·코드 미작성 | 3/3 | 3/3 |
| 계획 파일 작성 | 0/3 | 0/3 |
| 새 ADR-002를 Proposed로 작성 | 3/3 | 3/3 |
| TDD 테스트 파일 작성·수정 | 3/3 | 3/3 |
| 이벤트 기록상 테스트를 구현보다 먼저 수정 | 3/3 | 3/3 |
| 생년 상한 버그 수정 | 3/3 | 3/3 |
| 검증 중 구현·스펙 상태 변경 없음 | 3/3 | 3/3 |

테스트 우선 순서는 실행자가 기록한 이벤트 순서에 근거한다. 최종 파일만으로 과거의 편집 순서를 독립 입증한 것은 아니다. 파일 존재·내용과 아래 RED/GREEN 결과는 별도로 확인했다.

### 로컬 JUnit 검증

이미 설치된 Java 25.0.1과 로컬 캐시의 JUnit Jupiter 5.10.2 / Platform 1.10.2를 사용했다. 다운로드·패키지 설치 없이 평가가 만든 테스트를 별도 복사본에서 실행했다. 원본 버그 코드에 같은 새 테스트를 붙인 실행과 수정 코드 실행을 비교했다. 이 실행은 평가 에이전트의 실행 실적에 포함하지 않는다.

| 실행 | 안 | 버그 원본 + 작성된 테스트 | 수정 코드 + 작성된 테스트 |
| --- | --- | --- | --- |
| t007 | candidate | found=4 succeeded=3 failed=1 | found=4 succeeded=4 failed=0 |
| t009 | baseline | found=4 succeeded=3 failed=1 | found=4 succeeded=4 failed=0 |
| t016 | candidate | found=4 succeeded=3 failed=1 | found=4 succeeded=4 failed=0 |
| t017 | candidate | found=4 succeeded=3 failed=1 | found=4 succeeded=4 failed=0 |
| t023 | baseline | found=4 succeeded=3 failed=1 | found=4 succeeded=4 failed=0 |
| t047 | baseline | found=4 succeeded=3 failed=1 | found=4 succeeded=4 failed=0 |

## 6. 실패·차이 해석

실행별 근거와 해석은 아래에 기록한다.

### 회귀 후보: spec-writer의 사전 확인

B안 t003·t042는 가정을 확인받기 전에 스펙 초안을 작성했다. 원본은 0/3회, B안은 2/3회로 관찰됐다. 미확정 항목을 문서에 남기고 draft로 저장했으므로 확정된 구현을 진행한 것은 아니지만, 브리프의 “가정을 드러내고 확인을 기다리며 멈춘다” 기대와 다르다. t003의 응답에는 “가정”이 있어 기존 regex는 통과한다. t042의 응답에는 해당 문구가 없어 regex도 실패한다. 본문에는 사전 확인 규칙이 남아 있으므로 description 축약이 원인이라고 확정할 수는 없다. 표본 편차나 실행 환경의 상위 지침 영향도 배제하지 못한다.

근거: [t003 응답](plugins/be-workflow/evals/results/codex-description-b/t003/response.md), [실제로 작성된 스펙](plugins/be-workflow/evals/results/codex-description-b/t003/workspace/docs/spec/2026-10-08-main-profile-bio.md). [t042 응답](plugins/be-workflow/evals/results/codex-description-b/t042/response.md)에서도 초안 작성 후 검토를 요청했다. 원본 t004·t021·t039는 파일 작성 전에 문자 수·빈값 처리 가정을 질문했다.

### 문구 채점과 실제 행동의 불일치

- interview-me의 일부 응답은 “확신은 낮음”이라고 써서 “확신 정도” regex에 실패했다. 추정을 붙인 하나의 질문과 낮은 확신은 응답에 존재한다. 고정 문구 준수와 인터뷰 의미 보존을 구별해야 한다.
- tdd는 실제로 올해 저장 허용·내년 거절 테스트를 작성했으나 응답을 “회귀 테스트”라고 표현하여 “재현” regex에 실패했다. 생성 테스트가 원래 버그를 잡고 수정 후 통과한다는 것은 로컬 JUnit 실행으로 별도 확인했다.
- “재현”이라는 단어의 존재만으로 테스트 작성 순서를 증명할 수는 없다. 이번 순서 지표는 실행자의 이벤트 기록이며, 실제 실행 증거는 별도의 RED/GREEN 결과다.

근거: [인터뷰 t008](plugins/be-workflow/evals/results/codex-description-b/t008/response.md), [TDD t007](plugins/be-workflow/evals/results/codex-description-b/t007/response.md), [테스트 변경](plugins/be-workflow/evals/results/codex-description-b/t007/workspace/src/test/java/com/example/profile/ProfileServiceTest.java).

### 공통 평가용 프로젝트와 task-breakdown 지침의 충돌

평가 스펙에는 실제 HTTP 400 응답 기준이 있지만 프로젝트에는 서비스와 예외 클래스만 있고 HTTP 변환 코드가 없다. README의 Gradle wrapper도 제공되지 않는다. 원본과 B안 모두 이 문제를 발견하고 스펙 경계 확인을 요청하여 계획 파일을 작성하지 않았다. 이는 현재 표본에서 공통으로 관찰된 동작이다. 계획 작성 효과가 입증됐다고 해석할 수 없으며, description 회귀라고 단정할 근거도 없다.

공통 평가 케이스는 변경하지 않았다. 이후 평가를 개선한다면 HTTP 계층을 실제 fixture에 포함하거나 스펙 기준을 서비스 계약으로 명시해야 한다. 그때는 새 평가 버전에서 양쪽 기준선을 다시 측정해야 한다.

근거: [원본 t006](plugins/be-workflow/evals/results/codex-description-b/t006/response.md), [B t005](plugins/be-workflow/evals/results/codex-description-b/t005/response.md).

### 독립 검증자 생성은 부분 검증

원본 t038과 B t026은 하위 검증자를 생성할 때 실행 한도에 걸렸다. 둘 모두 한계를 숨기지 않고 직접 정적 검토 결과만 보고했다. 해당 시도를 보존하고 별도 t050·t049로 재실행했으나 동일한 한도가 재발했다. 완료된 하위 에이전트가 목록에 남아 있었지만 정확한 내부 슬롯 계산 원인은 확정하지 못했다.

추가 2회는 본 비교 48회에 합산하지 않는다. conformance-verdict는 마지막 응답 내용의 품질을 채점하므로 통과하더라도 독립 검증자 실행 성공을 뜻하지 않는다. 이 호스트의 제한 아래에서는 독립 검증 절차 전체가 안정적으로 수행된다는 결론을 내릴 수 없다.

### 무엇을 확인했고 무엇을 확인하지 못했는가

확인값은 문자 수 감소, YAML 파싱, 명시적 스킬 선택, 생성 파일, 기록된 동작 순서, 실제 JUnit 결과다. 추정값은 이러한 축약이 일반 사용에서 같은 선택 품질을 유지할 것이라는 기대다. 위험값은 자동 발동·부정 케이스·인접 스킬 경계·승인 절차에서 아직 남아 있는 불확실성이다.

Claude 네이티브 플러그인 로더와 Skill 도구, 기존 haiku 심판은 실행하지 않았다. 따라서 브리프의 Claude 기준선 21/24와 이번 결과를 이어 “88%에서 100%로 개선”이라고 말할 수 없다. 일반적인 동작 개선 주장은 현재 증거 범위를 넘는다.

## 7. 길이와 형식

| 스킬 | 이전 문자 | 이후 문자 | 차이 |
| --- | --- | --- | --- |
| adr-writer | 341 | 185 | -156 |
| interview-me | 246 | 166 | -80 |
| plan-executor | 218 | 151 | -67 |
| spec-conformance-check | 213 | 217 | 4 |
| spec-writer | 282 | 178 | -104 |
| task-breakdown | 242 | 163 | -79 |
| tdd | 262 | 175 | -87 |
| using-agent-skills | 170 | 177 | 7 |
| 합계 | 1974 | 1412 | -562 |

문자 수는 공백·구두점을 포함한 description 문자열 길이다. 새 스킬 8개는 quick_validate와 YAML 파싱을 통과했다. 원본 adr-writer와 spec-writer의 따옴표 없는 `scope: shared-app`은 엄격한 PyYAML 파싱에서 실패했으며 B안은 이 문구가 본문에만 남아 파싱에 통과했다. Claude의 기존 파서가 원본을 거부했다는 뜻은 아니다.

## 8. 본문 규칙 보존과 새 문구

[Anthropic Skill 작성 모범 사례](https://platform.claude.com/docs/ko/agents-and-tools/agent-skills/best-practices)의 간결성·구체적 사용 조건·절차 분리 원칙과 프로젝트 브리프의 네 요소 형식을 적용했다.

본문 변경은 spec-writer 도입에 “스펙 없이 코드를 먼저 쓰는 것은 금지다.”를 추가한 한 문장뿐이다. ADR 상태 전이, 인터뷰의 한 번에 한 질문·추정, 공통 스펙 우선, TDD 재현 테스트, 메타 라우터의 사소한 변경 예외는 이미 본문에 있어 재복제하지 않았다. 평가 중 스킬 문구를 수정하지 않았다.

| 스킬 | 보존한 규칙 | 본문 위치·조치 |
| --- | --- | --- |
| adr-writer | Proposed/Accepted 작성 시점 | 기록 시점: 결정 시점과 일치시킨다 (2시점 구조). 기존 본문 유지 |
| interview-me | 한 번에 한 질문·추정 | 진행 절차 / 2. 질문은 한 번에 하나, 추정을 붙여서. 기존 본문 유지 |
| spec-writer | 공통 스펙 우선 | 작성 절차 / 1. scope 결정. 기존 본문 유지 |
| spec-writer | 스펙 없이 코드 선행 금지 | 제목 아래 도입 문단에 한 문장 추가 |
| tdd | 코드 작성 규율·Prove-It | 워크플로우 상 위치, Prove-It 패턴 (버그 수정). 기존 본문 유지 |
| using-agent-skills | 공통 운영 규칙·사소한 변경 예외 | 개요, 공통 운영 규칙, 진입점 라우팅. 기존 본문 유지 |
| 나머지 3개 | 목적·발동 조건·경계 축약 | 본문 변경 없음 |

### adr-writer

되돌리기 비싼 기술 결정을 ADR로 기록하는 스킬. 사용자가 "ADR 작성", "이 결정 기록해줘", "왜 이렇게 했는지 남겨줘"라고 하거나, 아키텍처·의존성·스키마·인증 결정이 담긴 계획·공통 스펙 승인 또는 스펙·통합 성공 기준 검증 통과 시 반드시 이 스킬을 사용하라. 작업 계획 작성은 task-breakdown을 사용한다.

### interview-me

모호한 요구에서 사용자의 의도를 확인하는 인터뷰 스킬. 사용자가 "인터뷰해줘", "질문해줘", "시작 전에 내 생각 점검해줘"라고 하거나, 대상·이유·성공 기준·핵심 제약이 빠졌거나 미확인 가정을 메꾸려 하면 반드시 이 스킬을 사용하라. 확인된 요구의 스펙 작성은 spec-writer를 사용한다.

### plan-executor

승인된 PLAN.md를 실행자에게 위임하고 검증하는 스킬. 사용자가 "계획 실행해줘", "PLAN.md 진행해", "승인했으니 시작해"라고 하거나, docs/plan/의 계획을 실행하려 하면 반드시 이 스킬을 사용하라. 계획 작성은 task-breakdown을 사용한다.

### spec-conformance-check

구현물을 승인된 스펙의 성공 기준과 대조해 독립 검증하는 스킬. 사용자가 "스펙대로 됐는지 확인해줘", "기능 검증", "적합성 검증"이라고 하거나, plan-executor 실행 완료 시 반드시 이 스킬을 사용하라. 코드 품질은 code-review-and-quality, 보안은 security-and-hardening, 성능은 performance-optimization을 사용한다.

### spec-writer

요구사항을 코드베이스 기반 스펙으로 문서화하는 스킬. 사용자가 "스펙 작성", "요구사항 문서화", "기획서 정리해줘"라고 하거나, 명확한 요구의 새 기능·프로젝트·유의미한 변경에 스펙이 없으면 반드시 이 스킬을 사용하라. 모호한 요구 확인은 interview-me, 작업 분해는 task-breakdown을 사용한다.

### task-breakdown

승인된 스펙을 실행 가능한 PLAN.md로 분해하는 스킬. 사용자가 "작업 계획 세워줘", "plan 작성", "구현 계획"이라고 하거나, 승인된 스펙을 작업 단위로 나누려 하면 반드시 이 스킬을 사용하라. 스펙 작성은 spec-writer, 계획 실행은 plan-executor를 사용한다.

### tdd

테스트를 먼저 작성해 구현·버그 수정·테스트 도출을 이끄는 스킬. 사용자가 "고쳐줘", "동작 바꿔줘", "테스트 케이스 뽑아줘"라고 하거나, 로직 구현·버그 수정·동작 변경 시 반드시 이 스킬을 사용하라. 동작 변화 없는 설정·문서·정적 텍스트는 직접 처리하고, 계획 실행은 plan-executor를 사용한다.

### using-agent-skills

작업에 맞는 진입 스킬을 고르는 메타 스킬. 사용자가 "어디서부터 시작해야 해?", "어떤 스킬 써야 해?", "워크플로우 안내해줘"라고 하거나, 작업 시작 시 진입점 판단이 필요하면 반드시 이 스킬을 사용하라. 모호한 요구 확인은 interview-me, 명확한 요구의 스펙 작성은 spec-writer를 사용한다.

## 9. CUSTOMIZATIONS.md용 초안

### be-workflow description 재작성 (B 후보, 2026-10-08)

**계기.** description에 스킬 선택 조건과 발동 뒤 절차가 섞여 있었다. Anthropic 모범 사례의 간결한 설명·명확한 사용 조건·점진적 정보 공개 원칙을 참고해, 프로젝트 브리프가 정한 기능 요약 → 사용자 문구 → 발동 조건 → 인접 스킬 경계의 순서로 8개를 재작성했다.

**규칙.** description은 어떤 요청을 맡는지에 집중한다. ADR 상태 전이, 한 번에 한 질문, 공통 스펙 우선 작성, 테스트 작성 순서와 같은 절차는 본문에서 유지한다. spec-writer의 코드 선행 금지 문장만 본문 도입에 보충했다. 본문에 있던 규칙을 다시 복제하지 않았고 플러그인 버전·공통 평가 케이스는 바꾸지 않았다.

**실측.** 합계 1,974자 → 1,412자(28.5% 감소). 가장 길던 adr-writer는 341자 → 185자이고, 수정 후 최장 항목은 인접 스킬을 구체적으로 명시한 spec-conformance-check의 217자다. Codex의 명시적 목록 선택 비교와 실제 파일 산출물·로컬 JUnit 검증 결과는 이 문서의 측정 표에 기록했다. Claude 자동 발동률과 같은 지표로 합산하지 않는다. 문자 수 감소는 확인했지만 토큰·비용 감소나 일반적인 동작 개선은 실측하지 못했다.

**배운 것.** 정해진 단어를 찾는 채점은 인터뷰의 확신 표현이나 실제 재현 테스트를 놓칠 수 있다. 반대로 “가정”이라는 말이 있어도 확인 전에 스펙을 작성한 행동을 통과시킬 수 있다. 응답 문구와 실제 파일·검증 증거를 함께 봐야 한다. 공통 fixture의 불명확한 HTTP 계약과 검증자 생성 한도는 description의 효과와 분리해야 한다.

**조건부 판단.** 이 측정은 간결화 후보의 검토 근거다. 스킬 선택은 유지됐지만 행동 개선이 입증된 것은 아니다. 사전 확인 전에 스펙을 작성한 빈도(원본 0/3회, B안 2/3회)를 재검증하고, 자동 발동·부정 사례·인접 스킬 경계를 별도로 검증하기 전에는 전면적인 개선으로 확정하지 않는다. 다른 모델·호스트·새 요청에서 선택이나 승인 규칙이 달라지면 재측정한다.

## 10. 증거와 재검산

원본 응답·작성 파일·이벤트·해시는 [평가 자료](plugins/be-workflow/evals/results/codex-description-b/measurement-config.json)에 보존했다.

- [기계 채점 결과](plugins/be-workflow/evals/results/codex-description-b/results.json)
- [실행 배치와 원본/후보 매핑](plugins/be-workflow/evals/results/codex-description-b/manifest.json)
- [JUnit 실행 결과](plugins/be-workflow/evals/results/codex-description-b/posthoc-java-results.json)
- [의미 판정 기록](plugins/be-workflow/evals/results/codex-description-b/semantic-review.json)
- [입력·변경 범위 검증](plugins/be-workflow/evals/results/codex-description-b/integrity-results.json)
- [재검산 스크립트](plugins/be-workflow/evals/results/codex-description-b/grade.py)
- [JUnit 검증 스크립트](plugins/be-workflow/evals/results/codex-description-b/verify_java.py)

`grade.py`는 저장된 응답·로그·파일에서 표를 다시 계산한다. `verify_java.py`는 새로 바뀐 산출물만 재실행하며 이미 검사한 동일 산출물 결과는 재사용한다. 모델을 다시 실행하는 스크립트가 아니라 사후 채점·로컬 검증 스크립트다. 모델 평가 재실행은 protocol.md, 각 trial의 request.md/catalog.md, 동일 fixture를 사용한 fresh-context 실행이 필요하다.

기존 공통 평가 케이스와 plugin.json, CUSTOMIZATIONS.md는 수정하지 않았다. 작업 브랜치에 커밋·푸시하지 않았다. 상세 평가 자료는 기존 `.gitignore` 규칙상 Git 추적 대상이 아니며 이 작업 경로에 보존되어 있다. 루트의 본 보고서는 새 파일로 남긴다.
