# be-workflow 평가 묶음

`claude plugin eval`로 돌리는 케이스다. `fixture.sh`가 빈 작업 공간에 프로필 서비스 저장소를 만들고, 케이스에 따라 승인된 스펙·계획·기존 ADR·버그를 심는다.

## 케이스

모두 `routing` 태그다. 재는 것은 두 층이다: 스킬이 발동했는가(`skill-fired`), 발동했다면 그 스킬의 첫 산출물 모양이 나왔는가(참고자료 Read 또는 마지막 메시지 regex). 결과 품질을 심판(llm)으로 재는 채점기는 `routes-spec-conformance-check`에만 있다.

| 케이스 | 요청 | 기대 스킬 | 산출물 확인 |
|---|---|---|---|
| `routes-using-agent-skills` | "어디서부터 시작해야 해?" | using-agent-skills | 진입점으로 spec-writer 또는 interview-me를 지목 |
| `routes-interview-me` | 대상·이유·성공 기준이 빠진 "대시보드 같은 거 만들어줘" | interview-me | `확신 정도`를 밝히고 `추정`을 붙여 묻는다 |
| `routes-spec-writer` | 요구사항은 명확하고 스펙이 없는 새 기능 | spec-writer | 스펙을 쓰기 전에 `가정`을 드러내고 확인을 요청하며 멈춘다 |
| `routes-task-breakdown` | 승인된 스펙을 "어떻게 나눠서 작업할지" | task-breakdown | plan-template Read, `추적성` |
| `routes-plan-executor` | draft 상태 계획을 "계획대로 진행해줘" | plan-executor | 실행하지 않고 `승인`을 묻는다 |
| `routes-tdd` | "올해 생년이 거절돼. 고쳐줘" (버그) | tdd | `재현` 테스트 언급 |
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
- `--judge-model sonnet`: llm 채점기가 있는 `routes-spec-conformance-check`를 포함할 때 붙인다. haiku 심판은 루브릭을 오독한 전력이 있다.
- 이 저장소의 Claude Code 세션 안에서 중첩 실행할 때는 `env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u ANTHROPIC_BASE_URL -u ANTHROPIC_API_KEY`를 앞에 붙인다(`.zshrc`의 Ollama 변수가 인증을 가로챈다).

채점기 점검용 단일 실행: `--case <이름> --runs 1`. 모델은 `prompt.md`가 sonnet으로 고정하고 있고 `--model`로 덮어쓴다. `results/`는 커밋하지 않는다. 한 케이스 1회가 0.2~0.5달러, 8케이스 3회 묶음이 7~10달러다.

## 결과 기록

`results/`는 원시 실행 디렉터리(HTML 보고서 포함)라 커밋하지 않는다. 보관할 결과는 `--json`으로 쓴 JSON을 `history/<측정일>-v<버전>-<무엇>.json`으로 복사하고 `history/README.md` 색인에 한 줄 추가한다. 비교 표(케이스별 `skill-fired` 통과 수와 산출물 채점기 통과 수)는 `CUSTOMIZATIONS.md`의 해당 절에 옮겨 적는다.
