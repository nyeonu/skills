# be-workflow 평가 묶음

`claude plugin eval`로 돌리는 케이스다. `fixture.sh`가 빈 작업 공간에 프로필 서비스 저장소를 만들고, 케이스에 따라 승인된 스펙·계획·기존 ADR·버그를 심는다.

## 케이스

`routes-tdd-config-change`는 `boundary` 태그이고 나머지는 `routing` 태그다. 재는 것은 두 층이다: 스킬이 발동했는가(`skill-fired`), 발동했다면 그 스킬의 첫 산출물 모양이 나왔는가(참고자료 Read 또는 마지막 메시지 regex). 결과 품질을 심판(llm)으로 재는 채점기는 `routes-spec-conformance-check`에만 있다.

| 케이스 | 요청 | 기대 스킬 | 산출물 확인 |
|---|---|---|---|
| `routes-using-agent-skills` | "어디서부터 시작해야 해?" | using-agent-skills | 진입점으로 spec-writer 또는 interview-me를 지목 |
| `routes-interview-me` | 대상·이유·성공 기준이 빠진 "대시보드 같은 거 만들어줘" | interview-me | `확신 정도`를 밝히고 `추정`을 붙여 묻는다 |
| `routes-spec-writer` | 요구사항은 명확하고 스펙이 없는 새 기능 | spec-writer | 스펙을 쓰기 전에 `가정`을 드러내고 확인을 요청하며 멈춘다 |
| `routes-task-breakdown` | 승인된 스펙을 "어떻게 나눠서 작업할지" | task-breakdown | plan-template Read, `추적성` |
| `routes-plan-executor` | draft 상태 계획을 "계획대로 진행해줘" | plan-executor | 실행하지 않고 `승인`을 묻는다 |
| `routes-tdd` | "올해 생년이 거절돼. 고쳐줘" (버그) | tdd | `재현` 언급, 테스트 파일에 `@Test` 3개 이상(기존 2개 + 추가), 5개 미만(재현 1개 + 경계 1개까지) |
| `routes-tdd-config-change` | application.yml 값 하나를 바꿔 달라는 요청 (경계) | 없음 | tdd와 다른 워크플로우 스킬이 발동하지 않고 Edit로 직접 고친다 |
| `routes-adr-writer` | 승인된 계획의 스키마 결정을 "남겨줘" | adr-writer | `Proposed`, 기존 ADR 다음 번호 `ADR-002` |
| `routes-spec-conformance-check` | "스펙대로 됐는지 확인해줘" | spec-conformance-check | 기준별 판정과 검증 공백 보고(llm) |

케이스마다 `no-other-workflow-skill`(또는 `no-wrong-entry-skill`) 채점기가 다른 워크플로우 스킬로 새지 않았는지를 양쪽 arm에서 함께 센다.

## 실행

플러그인 루트(`plugins/be-workflow`)에서:

```bash
claude plugin eval . --tag routing --runs 3 --ablation none --scaffold --trust-plugin --no-publish --allow-tools Write Edit -j 2 --json evals/results/<이름>.json
```

- `--ablation none`: description 전후 비교처럼 "플러그인 있음" arm만 필요할 때. 기준선 arm까지 보려면 빼면 된다(비용 2배).
- `--allow-tools Write Edit`: spec-writer·tdd 같은 스킬이 파일을 쓸 수 있게 한다. Bash는 없으므로 테스트 실행은 불가능하고, 케이스는 그 전제로 쓰여 있다.
- `--model fable`: 실행 모델을 바꾼다. 스킬 선택은 사용자가 쓰는 세션 모델이 하므로 실제 조건은 fable이고, sonnet은 지시를 덜 따르는 하한이다. 두 값이 다르면 fable이 실제 발동률이다(tdd: sonnet 11/18, fable 12/12). fable은 한 회 비용이 sonnet의 3~5배다.
- `--judge-model sonnet`: llm 채점기가 있는 `routes-spec-conformance-check`를 포함할 때 붙인다. haiku 심판은 루브릭을 오독한 전력이 있다.
- 이 저장소의 Claude Code 세션 안에서 중첩 실행할 때는 `env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u ANTHROPIC_BASE_URL -u ANTHROPIC_API_KEY`를 앞에 붙인다(`.zshrc`의 Ollama 변수가 인증을 가로챈다).

채점기 점검용 단일 실행: `--case <이름> --runs 1`. 모델은 `prompt.md`가 sonnet으로 고정하고 있고 `--model`로 덮어쓴다. `results/`는 커밋하지 않는다. 한 케이스 1회가 0.2~0.5달러, 8케이스 3회 묶음이 7~10달러다.

파일 내용 채점기(`regex`에 `target: { source: file, path: … }`)는 실행 후 작업 공간의 그 파일만 본다. routes-tdd의 테스트 개수 채점기는 `ProfileServiceTest.java`만 검사하므로, 모델이 새 테스트 파일을 따로 만들면 세지 못한다.

## 브리프 조립기 고정 점검

plan-executor의 `references/assemble_brief.py`는 스펙·계획 템플릿의 제목(`## 1.`, `### 제외`, `## 6.`, `## 2.`, `### T<n>:`)과 2절 코드 블록의 `// <경로>` 주석 규약에 묶여 있다. 템플릿의 그 부분을 고치면 반드시 아래를 돌린다. 모델 호출이 없어 비용 0이다.

```bash
bash plugins/be-workflow/evals/assembler-check/run.sh
```

`assembler-check/{spec.md,plan.md}`는 새 형식의 최소 문서이고 `expected.txt`가 통계 첫 줄의 기대값이다. 통계가 바뀌는 것이 의도된 변경이면 `expected.txt`를 갱신한다. 같은 스크립트가 탈락해야 하는 입력도 돌린다 — 스펙 6절·제외 소절이 없는 변형(종료 코드 1, 빠진 절 이름 보고), 명시 참조 `Type.member`의 멤버가 그 타입 조각에 없는 변형(없는 멤버·다른 타입의 멤버·없는 타입, 종료 코드 2), 있는 멤버의 명시 참조(통과), 파일명 꼴 `Type.java` 명시 참조(통과), 2절 산문 한 줄에 타입과 다른 타입의 멤버가 같이 있는 변형(종료 코드 2)과 같은 줄에 `Type.member`가 통째로 있는 변형(통과), 암묵 `Type.member`(통과하되 다른 타입 조각 미포함).

## 알려진 검증 공백

- routes-plan-executor는 계획이 `draft`라 승인 질문에서 끝난다. 그래서 디스패치 이후(브리프 조립, 실행자 보고 검증, `references/report-template.md` 서식의 사용자 보고)는 이 묶음이 검증하지 못한다. 승인된 계획으로 실행자(Agent 도구)까지 띄우는 케이스는 비용·시간이 커 만들지 않았고, 이전 버전의 비식별화 실행 기록은 참고 자료이며, 보고 서식 분리 이후의 동작 검증을 대신하지 않는다.
- 산출물 채점기는 마지막 메시지나 파일의 정규식·LLM 판정이라 "참고 파일을 읽었는가"(`tool_used: Read`)와 "산출물에 그 규칙의 흔적이 있는가"(파일 정규식)까지만 본다. 규칙을 제대로 적용했는지는 LLM 채점기 없이는 판정하지 않는다.

## 언제 재는가

측정은 바꾼 것이 채점기에 닿을 때만 한다. 한 묶음이 7~10달러이므로 매 수정마다 돌리지 않는다.

| 바꾼 것 | 재는 범위 |
|---|---|
| description | 라우팅 케이스 전체(발동률이 바뀔 수 있음). 실제 조건 확인은 fable로 |
| 본문 절차·참고자료·템플릿 | 그 스킬의 케이스만(`--case`). 산출물 채점기가 그 부분을 보지 않으면 생략 |
| 픽스처·채점기·프롬프트 | 그 케이스 1회 연기 테스트로 채점기 동작만 확인 |
| 문구만(오타, 줄바꿈) | 생략 |

## 결과 기록

`results/`는 원시 실행 디렉터리(HTML 보고서 포함)라 커밋하지 않는다. 보관할 결과는 `--json`으로 쓴 JSON을 `history/<측정일>-v<버전>-<무엇>.json`으로 복사하고 `history/README.md` 색인에 한 줄 추가한다. 비교 표(케이스별 `skill-fired` 통과 수와 산출물 채점기 통과 수)는 `CUSTOMIZATIONS.md`의 해당 절에 옮겨 적는다.

## 공개용 기록

픽스처의 `com.example` 소스와 생성되는 프로젝트 지침은 평가용 합성 자료다. 실제 애플리케이션 코드·서비스명·업무 티켓·조직 전용 설정을 가져오지 않는다.

보관된 평가 JSON의 개인 경로는 `/workspace/…`로 비식별화했다. 이 경로는 탐색 가능한 원본 파일 주소가 아니다. 측정 수치·판정은 유지하며, 합성 픽스처와 비식별화한 실제 실행 기록을 구분한다.
