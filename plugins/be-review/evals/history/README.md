# be-review 평가 결과 이력

`claude plugin eval --json`이 쓴 결과 파일을 단계별로 보관한다. 파일 이름은 `<측정일>-v<플러그인 버전>-<무엇>.json`. 각 파일에는 케이스별 실행 3회(또는 명시한 횟수)의 채점기 통과 여부, 턴 수, 비용, 오류가 들어 있다. 실행 기록(transcript)은 들어 있지 않다. 원시 실행 디렉터리(`results/`, HTML 보고서 포함)는 커밋하지 않는다.

| 파일 | 무엇을 쟀나 | 케이스별 결과 | 비용 |
|---|---|---|---|
| `2026-10-06-v0.1.7-baseline-full-run.json` | 평가 묶음 신설 직후 전체 실행(3케이스, 있음/없음 arm). be-review 발동률 43% 기준선의 원본 | loads-security-checklist: with 발동 2/3; without 발동 0/3<br>local-reasoning-with-declaration: with 발동 1/3; without 발동 0/3<br>local-reasoning-without-declaration: with 발동 0/3; without 발동 0/3 | $4.28 |
| `2026-10-06-v0.1.7-rerun1-local-reasoning.json` | 국소 추론 두 케이스 재실행(루브릭 수정 전) | local-reasoning-with-declaration: with 발동 2/3; without 발동 0/3<br>local-reasoning-without-declaration: with 발동 2/3; without 발동 0/3 | $3.57 |
| `2026-10-06-v0.1.7-rerun2-local-reasoning.json` | 국소 추론 두 케이스, 루브릭 "권장 조치만 본다"로 재작성 + sonnet 심판 | local-reasoning-with-declaration: with 발동 0/3; without 발동 0/3<br>local-reasoning-without-declaration: with 발동 2/3; without 발동 0/3 | $3.51 |
| `2026-10-06-v0.1.7-rerun3-without-declaration.json` | 선언 없음 케이스, "Suggestion 분리 제안 존재" 조건 추가 후 | local-reasoning-without-declaration: with 발동 2/3; without 발동 0/3 | $1.95 |
| `2026-10-07-v0.1.8-description-long.json` | description 트리거 보강 긴 판(263·250·238자) 적용 후, 있음 arm 3회 | loads-security-checklist: with 발동 2/3<br>local-reasoning-with-declaration: with 발동 3/3<br>local-reasoning-without-declaration: with 발동 3/3 | $2.74 |
| `2026-10-07-v0.1.8-description-short.json` | 축약판(217·222·206자, 채택) 적용 후, 있음 arm 3회. 발동률 8/9 | loads-security-checklist: with 발동 2/3<br>local-reasoning-with-declaration: with 발동 3/3<br>local-reasoning-without-declaration: with 발동 3/3 | $2.92 |
