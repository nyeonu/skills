# 작업 브리프: be-workflow 스킬 description 재작성 (병렬 비교용)

이 문서는 같은 작업을 서로 다른 도구(세션 A는 Claude Code, 세션 B는 다른 AI 도구)가 독립적으로 수행한 뒤 결과를 비교하기 위한 공통 지시문이다. 두 세션은 같은 커밋에서 분기한 각자의 브랜치에서 작업하고, 같은 평가 묶음과 같은 명령으로 효과를 잰다.

## 1. 배경

- 저장소 nyeonu/skills의 Claude Code 플러그인 be-workflow에는 스킬 8개가 있다. 각 스킬의 `SKILL.md` frontmatter `description`은 모든 세션의 시스템 프롬프트에 항상 실리는 스킬 목록이며, 모델이 어느 스킬을 발동할지 고르는 유일한 근거다.
- 2026-10-04 Anthropic "Skill 작성 모범 사례" 대조에서 description이 "언제 쓰는가"를 넘어 "어떻게 동작하는가"까지 담아 길다는 지적이 나왔다.
- be-review 플러그인의 스킬 3개를 2026-10-07에 먼저 고쳤다. "핵심 용례 한 문장 → 사용자 문구 예시 → 반드시 이 스킬을 사용하라 → 인접 스킬 경계" 네 요소만 남기자 발동률이 43%에서 89%로 올랐고, 절차 설명을 빼고 줄여도 발동률은 같았다. 그 결과가 "description에는 라우팅에 필요한 정보만 두고 절차는 본문으로 보낸다"는 원칙의 근거다.
- be-workflow 쪽은 이미 대부분 사용자 문구 예시와 "반드시"가 들어 있다. 이번 작업의 주된 문제는 "발동이 안 된다"가 아니라 "길고 절차가 섞여 있다"이다.

## 2. 목적과 성공 조건

1. 여덟 description을 네 요소 구조로 통일하고, 절차·규칙은 본문으로 보낸다.
2. 길이를 줄인다. 현재 합계 1,974자, 목표 1,400자 안팎. 가장 긴 adr-writer(341자)는 220자 안팎.
3. 발동률은 떨어뜨리지 않는다. 기준선(아래 5절)과 같거나 높아야 한다. 산출물 채점기(참고자료 Read, 보고 형식 regex)도 유지한다.

## 3. 대상과 현재 상태

파일: `plugins/be-workflow/skills/<스킬>/SKILL.md`의 `description:` 한 줄.

| 스킬 | 현재 길이 | 지금 섞여 있는 절차·문제 |
|---|---|---|
| adr-writer | 341자 | Proposed/Accepted 시점 규칙이 절반을 차지 |
| spec-writer | 282자 | "공통 스펙부터 쓴다", "스펙 없이 코드 금지"는 발동 뒤 규칙 |
| tdd | 262자 | "코드를 작성하는 상황이면 사용하라"가 권고 어조, "반드시"는 버그 수정에만. 엠대시 |
| interview-me | 246자 | "한 번에 질문 하나씩, 추정을 붙여 묻는다"는 절차 |
| task-breakdown | 242자 | 대체로 구조에 맞음, 길이만 |
| plan-executor | 218자 | 대체로 구조에 맞음, 길이만 |
| spec-conformance-check | 213자 | 인접 스킬을 "review 스킬들"로 뭉뚱그림, 엠대시 |
| using-agent-skills | 170자 | 사용자 문구 예시 없음, "사용한다" 어조 |

## 4. 재작성 규칙

- 네 요소 순서를 지킨다: ① 이 스킬이 하는 일 한 문장 ② 사용자가 실제로 치는 말 예시(큰따옴표, 3~5개) ③ 발동 조건과 "반드시 이 스킬을 사용하라" ④ 인접 스킬 경계("…는 <스킬명>을 사용한다").
- 발동 뒤에 지켜야 할 절차·규칙은 description에서 뺀다. 빼는 문장이 본문에 없으면 본문의 알맞은 절에 옮긴다. 본문의 다른 내용은 바꾸지 않는다.
- `name`, 스킬 디렉터리 이름, 다른 파일은 손대지 않는다. 평가 케이스(`plugins/be-workflow/evals/`)는 공통 자이므로 수정하지 않는다.
- 역할 용어는 오케스트레이터 / 실행자 / 검증자만 쓴다. 엠대시는 쓰지 않는다.
- 참고용 완성본(be-review, 2026-10-07):
  `머지 전 코드 리뷰 스킬. 사용자가 "리뷰해줘", "코드 리뷰", "PR 봐줘", "머지해도 돼?", "변경 사항 검토"처럼 diff·커밋·PR·브랜치의 변경을 검토해 달라고 하거나, 다른 에이전트가 만든 코드를 평가해야 하면 반드시 이 스킬을 사용하라. 보안이 주제면 security-and-hardening, 성능 측정·최적화는 performance-optimization을 사용한다.`

## 5. 측정

평가 케이스는 `plugins/be-workflow/evals/`에 8개가 있다(스킬마다 "그 스킬이 받아야 할 요청" 하나씩, `routing` 태그). 자세한 내용은 그 디렉터리의 README.

수정 전 기준선은 세션 A가 한 번만 잰다. 수정 후는 각 세션이 자기 브랜치에서 같은 명령으로 잰다.

```bash
cd plugins/be-workflow
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u ANTHROPIC_BASE_URL -u ANTHROPIC_API_KEY \
  claude plugin eval . --tag routing --runs 3 --ablation none --scaffold --trust-plugin --no-publish \
  --allow-tools Write Edit -j 2 --max-cost-usd 15 --json evals/results/after-description-<세션>.json
```

- 측정 도구 `claude plugin eval`은 이 컴퓨터에 설치된 Claude Code CLI(로그인 완료)로 돌린다. 수행 주체가 Claude가 아니어도 측정은 이 명령으로 한다. 일반 터미널에서 돌리면 `env -u …` 부분은 `.zshrc`의 Ollama 변수(`ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY`)만 빼면 된다. Claude Code 세션 안에서 돌릴 때는 Bash 샌드박스를 끄고 실행한다(OAuth 자격이 키체인에 있다).
- 예상 비용은 묶음당 7~10달러, 15~25분.
- 결과 JSON은 gitignore라 로컬에만 남는다. 아래 표 양식으로 옮겨 적는다.

### 기준선 (수정 전, 세션 A가 2026-10-07 측정, sonnet 실행, 케이스당 3회)

| 케이스 | skill-fired | 산출물 채점기 | 비고 |
|---|---|---|---|
| routes-using-agent-skills | 3/3 | names-entry-skill 3/3, no-wrong-entry-skill 3/3 | |
| routes-interview-me | 3/3 | states-confidence 3/3, asks-with-estimate 3/3, no-other 3/3 | 채점기 수정 후 재측정값. 채점기 점검용 별도 1회 실행에서는 발동하지 않고 질문 4개를 한꺼번에 던졌다 |
| routes-spec-writer | 3/3 | surfaces-assumptions 3/3, no-other 3/3 | 채점기 수정 후 재측정값 |
| routes-task-breakdown | 3/3 | reads-plan-template 3/3, has-traceability 3/3, no-other 3/3 | |
| routes-plan-executor | 3/3 | asks-approval 3/3, no-other 3/3 | draft 계획을 실행하지 않고 승인을 물었다 |
| routes-tdd | **0/3** | writes-reproduction-test-first 0/3, no-other 3/3 | 점검용 1회 실행도 미발동. 스킬 없이 조건식만 고치고 끝냈다(재현 테스트 없음) |
| routes-adr-writer | 3/3 | status-proposed 3/3, next-adr-number 3/3, no-other 3/3 | |
| routes-spec-conformance-check | 3/3 | conformance-verdict(llm, haiku 심판) 3/3, no-other 3/3 | |
| **합계** | **21/24 (88%)** | | 비용 5.96달러 + 재측정 1.0달러, 17분 |

- 원본 결과: `plugins/be-workflow/evals/results/before-description-be-workflow.json`(8케이스), 채점기 수정 뒤 다시 잰 두 케이스는 `before-description-spec-writer.json`, `before-description-interview-me.json`. 세션 A 로컬에만 있다.
- 채점기 수정 내역: spec-writer는 비대화형 환경에서 "내가 하고 있는 가정"을 드러내고 확인을 기다리며 멈추는 것이 계약이라, 마지막 메시지의 `성공 기준`과 spec-template Read 채점기를 `가정` regex로 바꿨다. interview-me의 `내 추정`은 `추정`으로 완화했다(스킬이 문구를 그대로 쓰지는 않는다).
- 읽는 법: 발동률은 tdd만 문제다. 나머지 일곱은 이미 3/3이므로 **수정 후에도 3/3을 유지하는 것**이 성공 조건이고, tdd는 **0/3에서 올리는 것**이 목표다. 산출물 채점기는 본문 동작이 유지됐는지를 보는 회귀 지표다.
- 실행 환경 메모: prompt.md의 `allowed_tools`에 Agent가 없어도 세션이 Agent를 띄운 사례가 있었고, 그 서브에이전트는 Bash를 썼다. 양쪽 측정에 똑같이 적용되는 조건이므로 비교에는 영향이 없다.

## 6. 산출물 (각 세션)

1. 여덟 description의 새 문구와 길이 표(이전 → 이후).
2. 본문으로 옮긴 문장 목록(어느 절로 옮겼는지).
3. 수정 후 측정 표(위 양식) 와 기준선 대비 차이.
4. `CUSTOMIZATIONS.md`에 넣을 절 초안("be-workflow description 재작성", 계기·규칙·실측·배운 것). plugin.json 버전은 올리지 않는다(비교 후 채택본만 올린다).
5. 커밋·푸시는 하지 않는다. 변경은 작업 트리에 두고 사용자가 확인한다.

## 7. 브랜치와 이 문서의 위치

이 문서는 저장소 루트 `rewrite-description-brief.md`로 커밋돼 있어 어느 브랜치에서든 같은 내용을 읽는다. 비교가 끝나 채택본을 정식 커밋할 때 이 파일은 제외한다.


- 공통 기준 커밋: `feature/rewrite-description`의 30e00cc "be-workflow 라우팅 평가 케이스 7개 추가"와 그 위의 이 문서 갱신 커밋. 세션 B는 `feature/rewrite-description`의 현재 끝(tip)에서 분기하면 된다.
- 세션 A: `feature/rewrite-description` (워크트리 `.claude/worktrees/local-reasoning-lens-review-39a61b`).
- 세션 B: 기준 커밋에서 `feature/rewrite-description-b`를 만들어 별도 워크트리에서 작업한다.

```bash
git worktree add .claude/worktrees/rewrite-description-b -b feature/rewrite-description-b feature/rewrite-description
```

## 8. 비교 기준 (사용자가 판단)

1. 발동률 합계(24회 중 몇 회)와 케이스별 분포. 기준선보다 떨어진 케이스가 있으면 그 쪽이 불리하다.
2. 산출물 채점기 통과 수(본문 동작이 유지됐는지).
3. 길이 합계와 최장 항목.
4. 읽기: 사용자 문구 예시가 실제로 칠 법한 말인지, 인접 스킬 경계가 서로 모순 없이 맞물리는지(spec-writer ↔ interview-me, task-breakdown ↔ plan-executor, tdd ↔ 사소한 변경).
