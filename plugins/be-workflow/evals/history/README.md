# be-workflow 평가 결과 이력

`claude plugin eval --json`이 쓴 결과 파일을 단계별로 보관한다. 파일 이름은 `<측정일>-v<플러그인 버전>-<무엇>.json`. 각 파일에는 케이스별 실행 3회(또는 명시한 횟수)의 채점기 통과 여부, 턴 수, 비용, 오류가 들어 있다. 실행 기록(transcript)은 들어 있지 않다. 원시 실행 디렉터리(`results/`, HTML 보고서 포함)는 커밋하지 않는다.

| 파일 | 무엇을 쟀나 | 케이스별 결과 | 비용 |
|---|---|---|---|
| `2026-10-06-v0.1.7-baseline-full-run.json` | 평가 묶음 신설 직후(spec-conformance-check 1케이스, 있음/없음 arm). 발동 3/3 | routes-spec-conformance-check: with 발동 3/3; without 발동 0/3 | $1.57 |
| `2026-10-07-v0.1.8-smoke-interview-me.json` | 라우팅 케이스 7개 신설 뒤 interview-me 1회 연기 테스트 | routes-interview-me: with 발동 1/1 | $0.22 |
| `2026-10-07-v0.1.8-before-description.json` | description 수정 전 기준선, 8케이스 3회. 발동 21/24(tdd 0/3), spec-writer·interview-me는 채점기 수정 전 값 | routes-adr-writer: with 발동 3/3<br>routes-interview-me: with 발동 3/3<br>routes-plan-executor: with 발동 3/3<br>routes-spec-conformance-check: with 발동 3/3<br>routes-spec-writer: with 발동 3/3<br>routes-task-breakdown: with 발동 3/3<br>routes-tdd: with 발동 0/3<br>routes-using-agent-skills: with 발동 3/3 | $5.96 |
| `2026-10-07-v0.1.8-diag-tdd.json` | 기준선 진단 1회(tdd 미발동: 스킬 없이 조건식만 수정) | routes-tdd: with 발동 0/1 | $0.07 |
| `2026-10-07-v0.1.8-diag-spec-writer.json` | 기준선 진단 1회(가정 확인에서 멈춤 → 채점기를 "가정" regex로 수정하는 근거) | routes-spec-writer: with 발동 1/1 | $0.16 |
| `2026-10-07-v0.1.8-diag-interview-me.json` | 기준선 진단 1회(미발동, 질문 4개 일괄 → "추정" regex로 완화하는 근거) | routes-interview-me: with 발동 0/1 | $0.13 |
| `2026-10-07-v0.1.8-before-description-spec-writer-regraded.json` | 채점기 수정 후 spec-writer 기준선 재측정 3/3 | routes-spec-writer: with 발동 3/3 | $0.46 |
| `2026-10-07-v0.1.8-before-description-interview-me-regraded.json` | 채점기 수정 후 interview-me 기준선 재측정 3/3 | routes-interview-me: with 발동 3/3 | $0.55 |
| `2026-10-07-v0.1.8-after-A-full.json` | A안 적용 후 전체 8케이스. 24회 중 10회가 API 무응답 턴 0 시간 초과 → 무효, 해당 케이스 재측정 | routes-adr-writer: with 발동 3/3<br>routes-interview-me: with 발동 3/3<br>routes-plan-executor: with 발동 3/3<br>routes-spec-conformance-check: with 발동 3/3<br>routes-spec-writer: with 발동 3/3, 시간초과 1<br>routes-task-breakdown: with 발동 1/3, 시간초과 3<br>routes-tdd: with 발동 0/3, 시간초과 3<br>routes-using-agent-skills: with 발동 0/3, 시간초과 3 | $3.64 |
| `2026-10-08-v0.1.8-after-A-task-breakdown-rerun.json` | A안 task-breakdown 재측정 3/3 | routes-task-breakdown: with 발동 3/3 | $1.56 |
| `2026-10-08-v0.1.8-after-A-using-agent-skills-rerun.json` | A안 using-agent-skills 재측정 3/3 | routes-using-agent-skills: with 발동 3/3 | $0.25 |
| `2026-10-08-v0.1.8-after-A-tdd-rerun.json` | A안 첫 tdd 판("코드를 쓰는 작업이면 반드시") 재측정 0/3, 옛 프롬프트 | routes-tdd: with 발동 0/3 | $0.2 |
| `2026-10-08-v0.1.8-before-description-tdd-prompt-fixed.json` | tdd 프롬프트 보정("코드만 고쳐" 제거) 후 이전 description으로 기준선 재측정 1/3 | routes-tdd: with 발동 1/3 | $0.43 |
| `2026-10-08-v0.1.8-after-A-tdd-prompt-fixed.json` | A안 첫 tdd 판, 보정 프롬프트 0/3 | routes-tdd: with 발동 0/3 | $0.28 |
| `2026-10-08-v0.1.8-after-A2-tdd-prompt-fixed.json` | A안 tdd 채택판("한 줄 수정이라도 코드를 고치기 전에") 2/3 | routes-tdd: with 발동 2/3 | $0.39 |
| `2026-10-08-v0.1.8-after-B-full.json` | B안(다른 작성자) description을 같은 자로 측정, 8케이스 3회. 일곱 스킬 3/3, tdd 0/3 | routes-adr-writer: with 발동 3/3<br>routes-interview-me: with 발동 3/3<br>routes-plan-executor: with 발동 3/3<br>routes-spec-conformance-check: with 발동 3/3<br>routes-spec-writer: with 발동 3/3<br>routes-task-breakdown: with 발동 3/3, 시간초과 1<br>routes-tdd: with 발동 0/3<br>routes-using-agent-skills: with 발동 3/3 | $6.37 |
| `2026-10-08-v0.1.8-after-B-tdd-x6.json` | B안 tdd 판 추가 6회 → 1/6 (누적 1/9) | routes-tdd: with 발동 1/6 | $0.61 |
| `2026-10-08-v0.1.8-after-adopted-tdd.json` | 절충안(채택) tdd 3회 → 1/3 | routes-tdd: with 발동 1/3 | $0.39 |
| `2026-10-08-v0.1.8-after-adopted-tdd-x6.json` | 절충안 tdd 추가 6회 → 4/6 (채택판 누적 7/12) | routes-tdd: with 발동 4/6 | $0.77 |
| `2026-10-08-v0.1.8-after-adopted-using-agent-skills.json` | 절충안 using-agent-skills(공통 규칙 구절 복원) 3/3 | routes-using-agent-skills: with 발동 3/3 | $0.29 |

## 문서

- `2026-10-08-v0.1.8-description-rewrite-comparison.md`: description 재작성 두 안(A·B)과 절충안의 비교, tdd 누적 표, 채택안 전문, CUSTOMIZATIONS 절 초안.
- `2026-10-08-v0.1.8-description-rewrite-result-A.md`: A안의 길이 표, 본문으로 옮긴 문장, 측정 표, 새 description 전문.
