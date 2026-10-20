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
# 공유 지침이 실제 브리프에 도달해야 한다. 파일을 링크만 하는 것은 전달이 아니다.
python3 - "$OUT" "$HERE/../../skills/testing-policy/references/testing-rules.md" <<'PY'
from pathlib import Path
import sys
brief, rules = (Path(p).read_text(encoding="utf-8") for p in sys.argv[1:])
assert brief.count(rules.strip()) == 1, "공통 테스트 지침 원문이 정확히 한 번 포함돼야 함"
assert "{{TESTING_RULES}}" not in brief, "미치환 지침 슬롯"
assert "Implementation tasks follow TDD" not in brief, "기존 TDD 강제가 남음"
assert "counts as RED" not in brief, "컴파일 오류를 RED로 인정하는 옛 규칙이 남음"
PY
echo "$stats" | grep -q '작업 블록 [0-9]*줄 · Shared design [0-9]*줄 · Goal [0-9]*줄' || { echo "통계에 구성 요소별 줄 수가 없음"; fail=1; }
grep -q '상한 초과' "$OUT.stats" && { echo "최소 픽스처에서 상한 초과 경고가 남"; fail=1; }
# ---- 탈락해야 하는 입력(Codex 검토 2026-10-20에서 재현한 구멍) ----
TMP=$(dirname "$OUT")
# 실행자 템플릿에서 전달 슬롯이 빠지거나 지침이 비면 조립에 실패해야 한다.
mkdir -p "$TMP/skills/plan-executor/references" "$TMP/skills/testing-policy/references"
cp "$SCRIPT" "$TMP/skills/plan-executor/references/"
cp "$HERE/../../skills/plan-executor/references/executor-brief-template.md" "$TMP/skills/plan-executor/references/"
cp "$HERE/../../skills/testing-policy/references/testing-rules.md" "$TMP/skills/testing-policy/references/"
for mode in missing-slot empty-rules; do
  cp "$HERE/../../skills/plan-executor/references/executor-brief-template.md" "$TMP/skills/plan-executor/references/executor-brief-template.md"
  if [ "$mode" = missing-slot ]; then
    sed '/{{TESTING_RULES}}/d' "$HERE/../../skills/plan-executor/references/executor-brief-template.md" > "$TMP/skills/plan-executor/references/executor-brief-template.md"
  else
    : > "$TMP/skills/testing-policy/references/testing-rules.md"
  fi
  if python3 -I "$TMP/skills/plan-executor/references/assemble_brief.py" --spec "$HERE/spec.md" \
      --plan "$HERE/plan.md" --task T1 --model haiku --worktree /tmp/wt --branch chk \
      --out "$TMP/b-$mode.md" > "$TMP/b-$mode.stats" 2>&1; then
    echo "공통 테스트 지침 전달 실패($mode)를 조립기가 통과시킴"; fail=1
  elif ! grep -Eq 'TESTING_RULES|공통 테스트 지침' "$TMP/b-$mode.stats"; then
    echo "공통 지침 전달 실패($mode)의 원인이 보고되지 않음"; fail=1
  fi
done
# 스펙 6절 제거 / 제외 소절 제거 → 종료 코드 1, 빠진 절 이름을 보고
python3 - "$HERE/spec.md" "$TMP" <<'PY'
import re, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"); o = sys.argv[2]
pathlib.Path(o + "/spec-no6.md").write_text(re.sub(r"\n## 6\. [\s\S]*?(?=\n## 7\.|\Z)", "\n", s), encoding="utf-8")
pathlib.Path(o + "/spec-noex.md").write_text(re.sub(r"\n### 제외[\s\S]*?(?=\n### |\n## )", "\n", s), encoding="utf-8")
PY
for v in no6:6절 noex:제외; do
  f=${v%%:*}; name=${v#*:}
  if python3 -I "$SCRIPT" --spec "$TMP/spec-$f.md" --plan "$HERE/plan.md" --task T1 --model haiku \
       --worktree /tmp/wt --branch chk --out "$TMP/b-$f.md" > "$TMP/b-$f.stats" 2>&1; then
    echo "스펙 $name 누락인데 종료 코드 0"; fail=1
  elif ! grep -q "$name" "$TMP/b-$f.stats"; then
    echo "스펙 $name 누락인데 빠진 절 이름을 보고하지 않음"; fail=1
  fi
done
# 명시 참조의 멤버가 2절에 없음 → 종료 코드 2, 해소 실패에 그 이름
sed 's/2절 `BirthYearValidator` 참조/2절 `BirthYearValidator.missingMethod` 참조/' "$HERE/plan.md" > "$TMP/plan-mm.md"
rc=0; python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-mm.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-mm.md" > "$TMP/b-mm.stats" 2>&1 || rc=$?
[ $rc = 2 ] && grep -q 'missingMethod' "$TMP/b-mm.stats" || { echo "없는 멤버 명시 참조가 해소 실패로 잡히지 않음 (exit $rc)"; fail=1; }
# 다른 타입의 멤버 / 없는 타입의 멤버를 명시 참조 → 종료 코드 2 (멤버 이름만으로 다른 조각을 끌어오면 안 된다)
for r in BirthYearValidator.save UnknownValidator.save; do
  sed "s/2절 \`BirthYearValidator\` 참조/2절 \`$r\` 참조/" "$HERE/plan.md" > "$TMP/plan-x.md"
  rc=0; python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-x.md" --task T1 --model haiku \
    --worktree /tmp/wt --branch chk --out "$TMP/b-x.md" > "$TMP/b-x.stats" 2>&1 || rc=$?
  [ $rc = 2 ] || { echo "명시 참조 $r 이(가) 해소 실패로 잡히지 않음 (exit $rc)"; fail=1; }
  grep -q 'ProfileService.java' "$TMP/b-x.md" && { echo "명시 참조 $r 에 다른 타입(ProfileService) 조각이 들어감"; fail=1; }
done
# 암묵 참조 Type.member는 타입 단위 — 통과하되 다른 타입 조각을 끌어오지 않는다
sed 's/2절 `BirthYearValidator` 참조/`BirthYearValidator.save`를 쓴다/' "$HERE/plan.md" > "$TMP/plan-im.md"
python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-im.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-im.md" > "$TMP/b-im.stats" 2>&1 || { echo "암묵 참조 Type.member가 떨어짐"; fail=1; }
grep -q 'ProfileService.java' "$TMP/b-im.md" && { echo "암묵 참조에 다른 타입(ProfileService) 조각이 들어감"; fail=1; }
# 2절 산문 한 줄에 타입과 다른 타입의 멤버가 같이 있어도 근거가 아니다 → 종료 코드 2. 같은 줄에 `Type.member`가 통째로 있으면 통과
python3 - "$HERE/plan.md" "$TMP" <<'PY'
import sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").replace("2절 `BirthYearValidator` 참조", "2절 `BirthYearValidator.save` 참조")
i = s.index("\n## 3.")
pathlib.Path(sys.argv[2] + "/plan-prose-bad.md").write_text(s[:i] + "\n- `BirthYearValidator.isValid`로 검사한 뒤 `ProfileService.save`로 저장한다.\n" + s[i:], encoding="utf-8")
pathlib.Path(sys.argv[2] + "/plan-prose-ok.md").write_text(s[:i] + "\n- `BirthYearValidator.save`는 검증 결과를 함께 저장한다.\n" + s[i:], encoding="utf-8")
PY
rc=0; python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-prose-bad.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-pb.md" > "$TMP/b-pb.stats" 2>&1 || rc=$?
[ $rc = 2 ] || { echo "같은 줄의 다른 타입 멤버(ProfileService.save)가 BirthYearValidator.save의 근거로 잡힘 (exit $rc)"; fail=1; }
python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-prose-ok.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-po.md" > "$TMP/b-po.stats" 2>&1 || { echo "불렛에 통째로 적힌 Type.member 명시 참조가 떨어짐"; fail=1; }
# 산문 계약: (4a) 코드 블록 없이 "결정 로직 위치" 표 행에 백틱 이름만 → 종료 0 + "코드 조각 미수집(경고)";
#            (4b) 백틱도 없음 → 종료 2, 실패 안내는 "표기에서 찾지 못함"(계약 부재 판정이 아님)
python3 - "$HERE/plan.md" "$TMP" <<'PY'
import re, sys, pathlib
s = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"); o = sys.argv[2]
v = re.sub(r"```java\n// <main>/profile/BirthYearValidator\.java\n[\s\S]*?```\n", "", s)
i = v.index("\n## 3.")
v = v[:i] + "\n- BirthYearValidator는 연도와 올해를 받아 boolean을 돌려주는 static isValid를 둔다. IO 없음.\n" + v[i:]
v = v.replace("2절 `BirthYearValidator` 참조", "2절 `BirthYearValidator.isValid` 참조")
pathlib.Path(o + "/plan-prose-a.md").write_text(v, encoding="utf-8")
pathlib.Path(o + "/plan-prose-b.md").write_text(v.replace("| `BirthYearValidator.isValid` static |", "| BirthYearValidator.isValid static |"), encoding="utf-8")
PY
python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-prose-a.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-pa.md" > "$TMP/b-pa.stats" 2>&1 || { echo "산문+표 행(4a)이 떨어짐 — 종료 0이어야 함"; fail=1; }
grep -q '코드 조각 미수집(경고): BirthYearValidator.isValid' "$TMP/b-pa.stats" || { echo "산문+표 행(4a)에 코드 조각 미수집 경고가 없음"; fail=1; }
rc=0; python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-prose-b.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-pbb.md" > "$TMP/b-pbb.stats" 2>&1 || rc=$?
[ $rc = 2 ] && grep -q '표기에서 명시 참조를 찾지 못함' "$TMP/b-pbb.stats" || { echo "산문만(4b)이 종료 2와 표기 안내를 내지 않음 (exit $rc)"; fail=1; }
grep -q '코드 조각 미수집' "$OUT.stats" && { echo "기본 픽스처에서 코드 조각 미수집 경고가 남"; fail=1; }
# 파일명 꼴의 명시 참조(`Type.java`)는 멤버가 아니라 타입 참조 — 통과
sed 's/2절 `BirthYearValidator` 참조/2절 `BirthYearValidator.java` 참조/' "$HERE/plan.md" > "$TMP/plan-file.md"
python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-file.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-file.md" > "$TMP/b-file.stats" 2>&1 || { echo "파일명 꼴 명시 참조(Type.java)가 떨어짐"; fail=1; }
grep -q 'BirthYearValidator.java' "$TMP/b-file.md" || { echo "파일명 꼴 명시 참조에 타입 조각이 없음"; fail=1; }
# 있는 멤버의 명시 참조는 통과
sed 's/2절 `BirthYearValidator` 참조/2절 `BirthYearValidator.isValid` 참조/' "$HERE/plan.md" > "$TMP/plan-ok.md"
python3 -I "$SCRIPT" --spec "$HERE/spec.md" --plan "$TMP/plan-ok.md" --task T1 --model haiku \
  --worktree /tmp/wt --branch chk --out "$TMP/b-ok.md" > "$TMP/b-ok.stats" 2>&1 || { echo "있는 멤버 명시 참조가 떨어짐"; fail=1; }
if [ $fail = 0 ]; then echo "OK — $stats"; else exit 1; fi
