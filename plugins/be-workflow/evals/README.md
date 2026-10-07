# be-workflow 평가 묶음

`claude plugin eval`로 돌리는 케이스다. `fixture.sh`가 빈 작업 공간에 승인된 스펙과 구현을 만든다.

| 케이스 | 재는 것 |
|---|---|
| `routes-spec-conformance-check` | "스펙대로 됐는지 확인해줘"가 spec-conformance-check로 가고 계획·구현·TDD 스킬로 새지 않는가. 셸 없이도 기준별 판정과 검증 공백을 정직하게 보고하는가 |

실행 (플러그인 루트에서):

```bash
claude plugin eval . --scaffold --trust-plugin --no-publish
```

채점기 점검용 단일 실행: `--case <이름> --runs 1 --ablation none`. 모델은 `prompt.md`가 sonnet으로 고정하고 있고 `--model`로 덮어쓴다. `results/`는 커밋하지 않는다.
