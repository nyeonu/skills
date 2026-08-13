---
name: code-review-and-quality
description: 다축(multi-axis) 코드 리뷰를 수행한다. 모든 변경 사항을 머지 전 검토할 때 사용한다. 본인, 다른 에이전트, 또는 사람이 작성한 코드를 코드 리뷰할 때 사용한다. PR이 메인 브랜치에 들어가기 전에 여러 차원에서 코드 품질을 평가해야 할 때 사용한다.
---

# 코드 리뷰와 품질 (Code Review and Quality)

## 개요

품질 게이트(quality gate)를 갖춘 다차원 코드 리뷰. 모든 변경은 머지 전에 리뷰를 거친다 — 예외는 없다. 리뷰는 다섯 가지 축을 다룬다: 정확성, 가독성, 아키텍처, 보안, 성능.

**승인 기준:** 변경이 완벽하지 않더라도 전체 코드 건강도(code health)를 확실히 개선한다면 승인한다. 완벽한 코드는 존재하지 않는다 — 목표는 지속적인 개선이다. 자신이 작성했을 방식과 정확히 같지 않다는 이유로 변경을 막지 마라. 코드베이스를 개선하고 프로젝트의 컨벤션을 따른다면 승인하라.

## 사용 시점

- PR이나 변경 사항을 머지하기 전
- 기능 구현을 완료한 후
- 다른 에이전트나 모델이 생성한 코드를 평가해야 할 때
- 기존 코드를 리팩터링할 때
- 버그 수정 후 (수정 사항과 회귀 테스트를 모두 리뷰)

## 5축 리뷰 (The Five-Axis Review)

모든 리뷰는 다음 차원에 걸쳐 코드를 평가한다:

### 1. 정확성 (Correctness)

코드가 주장하는 대로 동작하는가?

- 스펙 또는 작업 요구사항과 일치하는가?
- 엣지 케이스가 처리되는가(null, 빈 값, 경계값)?
- 에러 경로가 처리되는가(해피 패스만이 아니라)?
- 모든 테스트를 통과하는가? 테스트가 실제로 올바른 것을 검증하고 있는가?
- 오프바이원(off-by-one) 오류, 레이스 컨디션, 상태 불일치가 있는가?

### 2. 가독성과 단순성 (Readability & Simplicity)

작성자의 설명 없이 다른 엔지니어(또는 에이전트)가 이 코드를 이해할 수 있는가?

- 이름이 서술적이고 프로젝트 컨벤션과 일치하는가? (맥락 없는 `temp`, `data`, `result` 금지)
- 제어 흐름이 직관적인가(중첩 삼항 연산자, 깊은 콜백 지양)?
- 코드가 논리적으로 구성되어 있는가(관련 코드는 묶여 있고, 모듈 경계가 명확한가)?
- 단순화해야 할 "영리한" 트릭이 있는가?
- **더 적은 줄 수로 가능한가?** (100줄이면 충분한 곳에 1000줄은 실패다)
- **추상화가 그 복잡성에 걸맞은 가치를 내고 있는가?** (세 번째 사용 사례가 나오기 전에는 일반화하지 마라)
- 명백하지 않은 의도를 명확히 하는 데 주석이 도움이 되는가? (단, 명백한 코드에는 주석을 달지 마라.)
- 죽은 코드 잔재가 있는가: no-op 변수(`_unused`), 하위 호환 심(shim), `// removed` 주석 등?

### 3. 아키텍처 (Architecture)

변경이 시스템 설계에 부합하는가?

- 기존 패턴을 따르는가, 아니면 새 패턴을 도입하는가? 새 패턴이라면 정당한 이유가 있는가?
- 깨끗한 모듈 경계를 유지하는가?
- 공유되어야 할 코드 중복이 있는가?
- 의존성이 올바른 방향으로 흐르는가(순환 의존성 없음)?
- 추상화 수준이 적절한가(과도한 설계도 아니고, 지나친 결합도 아닌가)?

### 4. 보안 (Security)

상세한 보안 지침은 `security-and-hardening`을 참고하라. 변경이 취약점을 유발하는가?

- 사용자 입력이 검증되고 정제(sanitize)되는가?
- 시크릿이 코드, 로그, 버전 관리에서 제외되어 있는가?
- 필요한 곳에서 인증/인가가 확인되는가?
- SQL 쿼리가 파라미터화되어 있는가(문자열 연결 금지)?
- XSS 방지를 위해 출력이 인코딩되는가?
- 의존성이 알려진 취약점이 없는 신뢰할 수 있는 출처에서 온 것인가?
- 외부 소스(API, 로그, 사용자 콘텐츠, 설정 파일)의 데이터를 신뢰할 수 없는 것으로 취급하는가?
- 외부 데이터 흐름이 로직이나 렌더링에 사용되기 전에 시스템 경계에서 검증되는가?

### 5. 성능 (Performance)

상세한 프로파일링과 최적화는 `performance-optimization`을 참고하라. 변경이 성능 문제를 유발하는가?

- N+1 쿼리 패턴이 있는가?
- 무제한(unbounded) 루프나 제약 없는 데이터 페칭이 있는가?
- 비동기여야 할 동기 작업이 있는가?
- UI 컴포넌트에서 불필요한 리렌더링이 있는가?
- 목록 엔드포인트에 페이지네이션이 누락되어 있는가?
- 핫 패스(hot path)에서 생성되는 큰 객체가 있는가?

## 변경 크기 (Change Sizing)

작고 집중된 변경은 리뷰하기 쉽고, 머지가 빠르며, 배포가 안전하다. 다음 크기를 목표로 하라:

```
~100 lines changed   → Good. Reviewable in one sitting.
~300 lines changed   → Acceptable if it's a single logical change.
~1000 lines changed  → Too large. Split it.
```

**"하나의 변경"으로 간주되는 것:** 한 가지를 다루고, 관련 테스트를 포함하며, 제출 후에도 시스템이 정상 동작하도록 유지하는 자기완결적(self-contained)인 단일 수정. 기능의 한 부분이지 — 기능 전체가 아니다.

**변경이 너무 클 때의 분할 전략:**

| 전략 | 방법 | 시점 |
|----------|------|------|
| **스택(Stack)** | 작은 변경을 제출하고, 그것을 기반으로 다음 변경을 시작 | 순차적 의존성이 있을 때 |
| **파일 그룹별(By file group)** | 서로 다른 리뷰어가 필요한 그룹별로 변경을 분리 | 횡단 관심사(cross-cutting concerns) |
| **수평 분할(Horizontal)** | 공유 코드/스텁을 먼저 만들고, 그다음 소비자(consumer)를 작성 | 계층형 아키텍처 |
| **수직 분할(Vertical)** | 기능을 더 작은 풀스택 조각(slice)으로 분해 | 기능 작업 |

**큰 변경이 허용되는 경우:** 파일 전체 삭제와 자동화된 리팩터링처럼 리뷰어가 모든 줄이 아닌 의도만 확인하면 되는 경우.

**리팩터링과 기능 작업을 분리하라.** 기존 코드를 리팩터링하면서 새 동작을 추가하는 변경은 두 개의 변경이다 — 따로 제출하라. 소소한 정리(변수 이름 변경)는 리뷰어 재량으로 포함할 수 있다.

## 변경 설명 (Change Descriptions)

모든 변경에는 버전 관리 히스토리에서 독립적으로 이해되는 설명이 필요하다.

**첫 줄:** 짧고, 명령형이며, 독립적일 것. "Deleting the FizzBuzz RPC"가 아니라 "Delete the FizzBuzz RPC". 히스토리를 검색하는 사람이 diff를 읽지 않고도 변경을 이해할 수 있을 만큼 정보가 충분해야 한다.

**본문:** 무엇이 왜 바뀌는지. 코드 자체에서 보이지 않는 맥락, 결정, 근거를 포함하라. 관련이 있다면 버그 번호, 벤치마크 결과, 설계 문서 링크를 넣어라. 접근 방식에 단점이 있다면 인정하라.

**안티패턴:** "Fix bug," "Fix build," "Add patch," "Moving code from A to B," "Phase 1," "Add convenience functions."

## 리뷰 프로세스 (Review Process)

### 1단계: 맥락 이해

코드를 보기 전에 의도를 이해하라:

```
- What is this change trying to accomplish?
- What spec or task does it implement?
- What is the expected behavior change?
```

### 2단계: 테스트를 먼저 리뷰

테스트는 의도와 커버리지를 드러낸다:

```
- Do tests exist for the change?
- Do they test behavior (not implementation details)?
- Are edge cases covered?
- Do tests have descriptive names?
- Would the tests catch a regression if the code changed?
```

"엣지 케이스를 커버하는가"는 감으로 판정하지 말고 **테스트 도출 5출처**를 렌즈로 훑어라 — 각 출처에서 빠진 묶음이 곧 커버리지 구멍이다:

| 출처 | 리뷰 질문 |
|---|---|
| ① 성공 기준 | 이 변경이 구현하는 스펙 기준(SC-N) 각각에 대응 테스트가 있는가 |
| ② 동등 분할·경계값 | 입력 묶음(정상/없음/형식 오류/누락)과 경계(0건·1건·최대·최대+1)에서 빠진 대표가 있는가 |
| ③ 오류 분기 | **diff의 모든 `if`·의존성 실패 경로에 이름 붙은 테스트가 있는가** — 리뷰 시점엔 실제 코드가 있으므로 계획 단계 도출이 놓친 분기를 여기서 잡는다 |
| ④ 상태·순서 | 멱등성, 수정 직후 조회, 트랜잭션 실패 복원이 관련 있다면 검증되는가 |
| ⑤ 과거 버그 | 버그 수정이라면 수정 전에 실패했을 재현 테스트가 포함됐는가 |

한 가지 주의: 실제 인프라가 있어야 검증되는 동작(트랜잭션 롤백, 캐시 무효화의 실제 적중)을 목(mock) 기반 유닛 테스트가 "호출 확인"으로 때우고 있으면 커버된 것이 아니다 — 통합 테스트를 요구하라.

### 3단계: 구현 리뷰

다섯 가지 축을 염두에 두고 코드를 훑어라:

```
For each file changed:
1. Correctness: Does this code do what the test says it should?
2. Readability: Can I understand this without help?
3. Architecture: Does this fit the system?
4. Security: Any vulnerabilities?
5. Performance: Any bottlenecks?
```

### 4단계: 발견 사항 분류

작성자가 무엇이 필수이고 무엇이 선택인지 알 수 있도록 모든 코멘트에 심각도 라벨을 붙여라:

| 접두어 | 의미 | 작성자의 조치 |
|--------|---------|---------------|
| *(접두어 없음)* | 필수 변경 | 머지 전에 반드시 처리 |
| **Critical:** | 머지 차단 | 보안 취약점, 데이터 손실, 기능 파손 |
| **Nit:** | 사소함, 선택 사항 | 작성자가 무시해도 됨 — 포매팅, 스타일 선호 |
| **Optional:** / **Consider:** | 제안 | 고려할 가치는 있으나 필수는 아님 |
| **FYI** | 정보 제공용 | 조치 불필요 — 향후 참고를 위한 맥락 |

이렇게 하면 작성자가 모든 피드백을 필수로 여겨 선택적 제안에 시간을 낭비하는 것을 방지할 수 있다.

### 5단계: 검증의 검증 (Verify the Verification)

작성자의 검증 스토리를 확인하라:

```
- What tests were run?
- Did the build pass?
- Was the change tested manually?
- Are there screenshots for UI changes?
- Is there a before/after comparison?
```

## 멀티 모델 리뷰 패턴 (Multi-Model Review Pattern)

리뷰 관점별로 서로 다른 모델을 사용하라:

```
Model A writes the code
    │
    ▼
Model B reviews for correctness and architecture
    │
    ▼
Model A addresses the feedback
    │
    ▼
Human makes the final call
```

이렇게 하면 단일 모델이 놓칠 수 있는 문제를 잡아낼 수 있다 — 모델마다 사각지대가 다르다.

**리뷰 에이전트를 위한 프롬프트 예시:**
```
Review this code change for correctness, security, and adherence to
our project conventions. The spec says [X]. The change should [Y].
Flag any issues as Critical, Important, or Suggestion.
```

## 죽은 코드 위생 (Dead Code Hygiene)

리팩터링이나 구현 변경 후에는 고아가 된(orphaned) 코드를 확인하라:

1. 이제 도달 불가능하거나 사용되지 않는 코드를 식별한다
2. 명시적으로 목록화한다
3. **삭제 전에 물어라:** "이제 사용되지 않는 다음 요소들을 제거할까요: [목록]?"

죽은 코드를 방치하지 마라 — 미래의 독자와 에이전트를 혼란스럽게 한다. 하지만 확신이 없는 것을 말없이 삭제하지도 마라. 의심스러우면 물어라.

```
DEAD CODE IDENTIFIED:
- formatLegacyDate() in src/utils/date.ts — replaced by formatDate()
- OldTaskCard component in src/components/ — replaced by TaskCard
- LEGACY_API_URL constant in src/config.ts — no remaining references
→ Safe to remove these?
```

## 리뷰 속도 (Review Speed)

느린 리뷰는 팀 전체를 막는다. 리뷰를 위한 컨텍스트 전환 비용은 다른 사람에게 부과되는 대기 비용보다 작다.

- **영업일 기준 1일 이내에 응답** — 이것은 최대치이지 목표치가 아니다
- **이상적인 주기:** 집중 코딩 중이 아니라면 리뷰 요청 도착 직후 응답하라. 일반적인 변경은 하루 안에 여러 리뷰 라운드를 완료해야 한다
- **빠른 최종 승인보다 빠른 개별 응답을 우선하라.** 여러 라운드가 필요하더라도 빠른 피드백이 좌절감을 줄인다
- **큰 변경:** 거대한 체인지셋을 하나로 리뷰하기보다 작성자에게 분할을 요청하라

## 의견 충돌 처리 (Handling Disagreements)

리뷰 분쟁을 해결할 때는 다음 위계를 적용하라:

1. **기술적 사실과 데이터**가 의견과 선호를 이긴다
2. **스타일 가이드**는 스타일 문제에 대한 절대적 권위다
3. **소프트웨어 설계**는 개인적 선호가 아닌 엔지니어링 원칙으로 평가해야 한다
4. **코드베이스 일관성**은 전체 건강도를 해치지 않는 한 허용 가능하다

**"나중에 정리하겠다"를 받아들이지 마라.** 경험적으로 미뤄진 정리는 거의 이루어지지 않는다. 진짜 비상 상황이 아니라면 제출 전 정리를 요구하라. 이번 변경에서 주변 문제를 처리할 수 없다면 본인에게 할당한(self-assigned) 버그 등록을 요구하라.

## 리뷰에서의 정직함 (Honesty in Review)

본인, 다른 에이전트, 또는 사람이 작성한 코드를 리뷰할 때:

- **고무도장 찍듯 승인하지 마라.** 리뷰의 근거 없는 "LGTM"은 누구에게도 도움이 되지 않는다.
- **실제 문제를 완곡하게 표현하지 마라.** 프로덕션에서 터질 버그를 두고 "사소한 우려일 수 있다"고 말하는 것은 부정직하다.
- **가능하면 문제를 정량화하라.** "이건 느릴 수 있다"보다 "이 N+1 쿼리는 목록의 항목당 ~50ms를 추가한다"가 낫다.
- **명백한 문제가 있는 접근에는 이의를 제기하라.** 아첨(sycophancy)은 리뷰의 실패 유형이다. 구현에 문제가 있으면 직접적으로 말하고 대안을 제시하라.
- **오버라이드는 품위 있게 수용하라.** 작성자가 전체 맥락을 알고 있으면서 동의하지 않는다면 그 판단을 존중하라. 사람이 아닌 코드에 대해 코멘트하라 — 개인에 대한 비판은 코드 자체에 초점을 맞추도록 재구성하라.

## 의존성 규율 (Dependency Discipline)

코드 리뷰의 일부는 의존성 리뷰다:

**의존성을 추가하기 전에:**
1. 기존 스택으로 해결되는가? (대개 그렇다.)
2. 의존성이 얼마나 큰가? (번들 영향을 확인하라.)
3. 활발히 유지보수되고 있는가? (마지막 커밋, 열린 이슈를 확인하라.)
4. 알려진 취약점이 있는가? (`npm audit`)
5. 라이선스는 무엇인가? (프로젝트와 호환되어야 한다.)

**원칙:** 새 의존성보다 표준 라이브러리와 기존 유틸리티를 선호하라. 모든 의존성은 부채(liability)다.

## 리뷰 체크리스트 (The Review Checklist)

```markdown
## Review: [PR/Change title]

### Context
- [ ] I understand what this change does and why

### Correctness
- [ ] Change matches spec/task requirements
- [ ] Edge cases handled
- [ ] Error paths handled
- [ ] Tests cover the change adequately

### Readability
- [ ] Names are clear and consistent
- [ ] Logic is straightforward
- [ ] No unnecessary complexity

### Architecture
- [ ] Follows existing patterns
- [ ] No unnecessary coupling or dependencies
- [ ] Appropriate abstraction level

### Security
- [ ] No secrets in code
- [ ] Input validated at boundaries
- [ ] No injection vulnerabilities
- [ ] Auth checks in place
- [ ] External data sources treated as untrusted

### Performance
- [ ] No N+1 patterns
- [ ] No unbounded operations
- [ ] Pagination on list endpoints

### Verification
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Manual verification done (if applicable)

### Verdict
- [ ] **Approve** — Ready to merge
- [ ] **Request changes** — Issues must be addressed
```
## 참고 자료 (See Also)

- 상세한 보안 리뷰 지침은 `references/security-checklist.md` 참고
- 성능 리뷰 점검 항목은 `references/performance-checklist.md` 참고

## 흔한 합리화 (Common Rationalizations)

| 합리화 | 현실 |
|---|---|
| "동작하니까 그걸로 충분하다" | 읽기 어렵거나, 안전하지 않거나, 아키텍처적으로 잘못된 동작하는 코드는 복리로 불어나는 부채를 만든다. |
| "내가 작성했으니 맞다는 걸 안다" | 작성자는 자신의 가정에 눈이 멀어 있다. 모든 변경은 다른 사람의 눈을 거칠 때 이득을 본다. |
| "나중에 정리하겠다" | 나중은 오지 않는다. 리뷰가 품질 게이트다 — 활용하라. 머지 후가 아니라 머지 전에 정리를 요구하라. |
| "AI가 생성한 코드는 아마 괜찮을 것이다" | AI 코드는 더 적은 검증이 아니라 더 많은 검증이 필요하다. 틀렸을 때조차 자신만만하고 그럴듯하다. |
| "테스트가 통과하니 좋은 코드다" | 테스트는 필요조건이지 충분조건이 아니다. 아키텍처 문제, 보안 이슈, 가독성 문제를 잡아내지 못한다. |

## 위험 신호 (Red Flags)

- 아무 리뷰 없이 머지된 PR
- 테스트 통과 여부만 확인하는 리뷰(다른 축 무시)
- 실제 리뷰의 근거 없는 "LGTM"
- 보안에 민감한 변경인데 보안 중심 리뷰가 없는 경우
- "제대로 리뷰하기에 너무 큰" 대형 PR (분할하라)
- 버그 수정 PR에 회귀 테스트가 없는 경우
- 심각도 라벨 없는 리뷰 코멘트 — 무엇이 필수이고 선택인지 불분명해진다
- "나중에 고치겠다"를 수용하는 것 — 절대 이루어지지 않는다

## 검증 (Verification)

리뷰 완료 후:

- [ ] 모든 Critical 이슈가 해결됨
- [ ] 모든 Important 이슈가 해결되었거나 정당한 사유와 함께 명시적으로 연기됨
- [ ] 테스트 통과
- [ ] 빌드 성공
- [ ] 검증 스토리가 문서화됨 (무엇이 바뀌었고, 어떻게 검증했는지)
