---
type: regex
target: { source: file, path: docs/PROFILE-7/plan.md }
# 범위는 다음 ## 제목 전까지(3절 안의 ### 묶음 소제목은 허용). 머리글 `| 스펙 기준 |` + 구분선 + 데이터 행 1개 이상.
pattern: '## 3\. 추적성(?:(?!\n## )[\s\S])*?\| 스펙 기준 \|[^\n]*\n\|[-| :]+\n\| *[^\s|][^\n]*\|'
---
