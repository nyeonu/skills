---
name: adr-writer
description: 되돌리기 비싼 기술 결정을 ADR(Architecture Decision Record)로 기록하는 스킬. 프레임워크·주요 의존성 선택, 데이터 모델·DB 스키마 설계, 인증 전략, API 아키텍처 결정이 포함된 계획이 승인됐거나(Proposed 작성 시점), 스펙 적합성 검증을 통과했거나(Accepted 확정 시점), 사용자가 "ADR 작성", "이 결정 기록해줘", "왜 이렇게 했는지 남겨줘" 등을 언급하면 반드시 이 스킬을 사용하라. 작업 계획 작성에는 task-breakdown을 사용한다.
---

# ADR Writer

코드는 "무엇을" 만들었는지 보여주지만 "왜 이렇게" 만들었는지는 보여주지 않는다. ADR은 결정의 맥락·검토한 대안·트레이드오프를 기록해, 미래의 팀원과 에이전트가 같은 논쟁을 반복하거나 이유를 모른 채 결정을 뒤집는 것을 막는다. 10분짜리 ADR이 6개월 뒤 2시간짜리 논쟁을 대체한다.

## 기록 시점: 결정 시점과 일치시킨다 (2시점 구조)

결정은 계획 단계에서 내려지므로 ADR도 그때 시작한다. 실행 완료까지 기다렸다가 쓰면, 실행이 중단·실패했을 때 결정 이력이 계획 문서 안에 묻혀 유실된다.

- **시점 1 — 계획 승인 직후**: 승인된 계획에 되돌리기 비싼 결정이 포함되어 있으면 즉시 `Proposed` 상태로 ADR을 작성한다. 계획 문서의 판단 근거(Rationale) 섹션이 초안 재료다 — 대안과 트레이드오프가 이미 정리되어 있다. 실행 전에 결정이 ADR 포맷으로 한 번 더 검토되는 효과가 있다.
- **시점 2 — 스펙 적합성 검증(spec-conformance-check) 통과 후**: `Proposed`를 `Accepted`로 확정한다. 실행 중 결정이 계획과 다르게 바뀌었다면 기존 ADR을 수정하지 말고 새 ADR을 작성해 대체(supersede)한다.

## ADR을 쓰는 기준: 되돌리기 비싼 결정

아래에 해당하면 ADR을 작성한다. 핵심 질문은 "이 결정을 나중에 뒤집으면 비용이 큰가?"다.

- 프레임워크·라이브러리·주요 의존성 선택
- 데이터 모델 또는 DB 스키마 설계
- 인증/인가 전략 선택
- API 아키텍처 결정 (REST vs GraphQL, 버저닝 정책 등)
- 빌드 도구, 호스팅, 인프라 선택
- 그 외 되돌리는 데 마이그레이션·대규모 수정이 필요한 모든 결정

**쓰지 않는 것**: 변수명·함수 분리 같은 지역적 선택, 프로토타입의 임시 결정, 코드만 봐도 자명한 것. ADR 남발은 신호를 소음에 묻히게 한다.

## 작성 절차

1. 결정의 맥락을 수집한다. task-breakdown이 작성한 계획 문서가 있다면 그 "판단 근거(Rationale)" 섹션이 초안 재료다 — 대안과 트레이드오프가 이미 정리되어 있다.
2. `docs/decisions/`에서 기존 ADR을 확인해 다음 번호를 정한다. 파일명: `ADR-NNN-<YYYY-MM-DD>-<브랜치명>-<주제-kebab-case>.md` (예: `ADR-003-2026-07-30-feature-login-session-storage.md`). 브랜치명은 `git branch --show-current`로 확인하고, `/`가 포함되면 `-`로 치환한다 (예: `feature/login` → `feature-login`).
3. 아래 템플릿으로 작성한다. 특히 **기각한 대안과 그 이유**를 생략하지 마라 — ADR 가치의 절반이 여기 있다.
4. 기존 결정을 뒤집는 경우, 옛 ADR을 삭제·수정하지 말고 새 ADR을 작성한 뒤 옛 것의 Status를 `Superseded by ADR-NNN-<YYYY-MM-DD>-<브랜치명>` 형식(새 ADR의 번호·날짜·브랜치명)으로 갱신한다. 파일명 앞부분과 일치시켜 대체한 ADR 파일을 바로 찾을 수 있게 한다. 옛 ADR은 역사적 맥락이다.

## 템플릿

```markdown
# ADR-NNN: <결정 한 줄 요약>

## Status
Proposed | Accepted | Superseded by ADR-NNN-<YYYY-MM-DD>-<브랜치명> | Deprecated

## Date
YYYY-MM-DD

## Context
<결정이 필요했던 배경과 요구사항·제약. 실제 확인된 사실만.>

## Decision
<내린 결정 1~2문장.>

## Alternatives Considered
### <대안 A>
- 장점: ...
- 단점: ...
- 기각 이유: ...
(검토한 대안마다 반복)

## Consequences
<이 결정으로 얻는 것, 감수하는 것, 팀·운영에 미치는 영향.>

## References
<관련 스펙(docs/spec/...), 계획 문서(docs/plan/...), 이슈, PR 링크>
```

## 라이프사이클

`Proposed → Accepted → (Superseded | Deprecated)`. 상태 변경은 있어도 삭제는 없다.
