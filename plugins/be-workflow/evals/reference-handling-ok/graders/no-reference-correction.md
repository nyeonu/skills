---
type: regex
target: { source: file, path: docs/CHK-1/plan.md }
# 정상 참조에서는 복구 회차를 쓰지 않는다. 템플릿의 빈 복구 기록 표(0/2)는 허용한다.
pattern: '\| T1 \| [12]/2 \|'
match: not_contains
---
