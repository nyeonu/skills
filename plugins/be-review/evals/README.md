# be-review 평가 묶음

`claude plugin eval`로 돌리는 케이스다. 각 케이스는 `fixture.sh`로 빈 작업 공간에 git 저장소와 리뷰 대상 변경(`CHANGES.diff`)을 만든다. 리뷰 세션에는 셸이 없으므로 코드만 보고 판정한다.

| 케이스 | 재는 것 |
|---|---|
| `loads-security-checklist` | 인증 변경에서 1단계 로드 조건이 걸려 플러그인 루트 경로의 security-checklist.md를 읽고, "읽은 참고자료"에 적는가. 심어 둔 결함 다섯 개를 등급과 함께 잡는가 |
| `local-reasoning-without-declaration` | CLAUDE.md 선언이 없는 저장소에서 국소 추론 ② 발견이 Suggestion 상한·질문형으로 나오는가 |
| `local-reasoning-with-declaration` | CLAUDE.md에 "국소 추론 판정 기준 합의"가 있으면 같은 변경에 Important가 나오고, 분리 형태로 같은 파일 static 메서드를 먼저 제안하는가 |

실행 (플러그인 루트에서):

```bash
claude plugin eval . --scaffold --trust-plugin --no-publish --judge-model sonnet
```

국소 추론 두 케이스의 루브릭은 "권장 조치가 무엇인가"를 읽어야 해서 기본 심판(haiku)이 오독한다 — `--judge-model sonnet`을 붙인다. 채점기 점검용 단일 실행: `--case <이름> --runs 1 --ablation none`. 모델은 각 `prompt.md`가 sonnet으로 고정하고 있고 `--model`로 덮어쓴다. `results/`는 원시 실행 디렉터리라 커밋하지 않는다. 보관할 결과는 `--json`으로 쓴 JSON을 `history/<측정일>-v<버전>-<무엇>.json`으로 복사하고 `history/README.md` 색인에 한 줄 추가한다.
