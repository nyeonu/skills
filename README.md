# AI Agent Skills

고비용 에이전트가 계획하고 저비용 에이전트가 실행하는 비용 최적화 개발 워크플로우를 위한 스킬 모음.

## 스킬

| 스킬 | 역할 |
|---|---|
| [plan-writer](plan-writer/SKILL.md) | 요구사항 인터뷰 → 코드베이스 분석 → `docs/plan/YYYY-MM-DD-<주제>.md` 작업 계획 작성. 사용자 승인 게이트 포함. |
| [plan-executor](plan-executor/SKILL.md) | 승인된 계획을 읽어 작업별 tier(standard/light)에 따라 서브에이전트에 위임·검증하는 오케스트레이터. |
| [adr-writer](adr-writer/SKILL.md) | 되돌리기 비싼 결정을 `docs/decisions/`에 ADR로 기록. 계획의 판단 근거 섹션을 초안 재료로 사용. |

## 워크플로우

```
요구사항 → plan-writer(인터뷰·계획 작성) → 사용자 승인 → plan-executor(위임·검증) → 완료 보고
                                                            └→ 되돌리기 비싼 결정 발견 시 adr-writer(ADR 기록)
```

- 계획 문서 포맷: Markdown 본문 + YAML frontmatter (기계 파싱용 tasks/status/depends_on/tier)
- `tier`는 플랫폼 중립 필드 — 실행자가 플랫폼별 모델로 매핑 (Claude: standard→sonnet, light→haiku)
- 두 스킬 모두 타협 금지(anti-rationalization) 표 포함

## 참고

- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — interview-me, anti-rationalization 패턴 참고
