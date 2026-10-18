#!/usr/bin/env bash
# assemble_brief.py 고정 점검 — 스펙·계획 템플릿 제목이 바뀌어 추출이 깨지면 여기서 떨어진다.
# 사용: bash plugins/be-workflow/evals/assembler-check/run.sh
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SCRIPT="$HERE/../../skills/plan-executor/references/assemble_brief.py"
OUT=$(mktemp -d)/brief.md
python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$HERE/plan.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$OUT" > "$OUT.stats"
stats=$(head -1 "$OUT")
expected=$(cat "$HERE/expected.txt")
fail=0
[ "$stats" = "$expected" ] || { echo "통계 줄 불일치"; echo "  기대: $expected"; echo "  실제: $stats"; fail=1; }
grep -q '^- 해결할 문제' "$OUT" || { echo "Goal에 1절 불렛이 없음"; fail=1; }
grep -q '배경 — 용어' "$OUT" && { echo "Goal에 배경 소절이 들어감"; fail=1; }
grep -q '^### 제외' "$OUT" && grep -q '^## 6\. ' "$OUT" || { echo "Do not touch에 제외/6절이 없음"; fail=1; }
grep -q 'BirthYearValidator.java' "$OUT" || { echo "Shared design에 참조 타입 조각이 없음"; fail=1; }
grep -q 'ProfileService.java' "$OUT" && { echo "Shared design에 참조하지 않은 조각이 들어감"; fail=1; }
grep -q '^### T1: 검증 상한 수정' "$OUT" || { echo "Your task에 작업 블록이 없음"; fail=1; }
grep -q 'do NOT work' "$OUT" || { echo "템플릿 규칙(우회 금지)이 없음"; fail=1; }
if [ $fail = 0 ]; then echo "OK — $stats"; else exit 1; fi
