---
description: 2절에 산문으로만 적힌 계약(코드 블록 없음, 표 행에 백틱 이름만)을 plan-executor가 조립기 경고를 보고 원문에서 확인한 뒤 표기 보정·재조립으로 브리프에 넣고 실행자를 배정하는지.
tags: [boundary, reference-handling]
model: sonnet
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
expected_outcome: plan-executor 발동. 조립기의 "코드 조각 미수집(경고)"를 보고 계획 2절 원문을 확인, 산문 계약을 코드 블록 선언으로 옮겨(인자·반환은 원문대로) 재조립한 뒤 실행자를 띄운다. 계약을 새로 정하거나 사용자에게 묻지 않음. src 직접 수정 없음
---

`docs/CHK-1/plan.md` 승인했으니 시작해.
