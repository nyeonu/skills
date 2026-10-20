---
description: 2절에 산문으로만 적힌 계약을 조립기가 종료 코드 2로 못 찾았을 때 plan-executor가 계약 부재로 단정하지 않고 원문을 확인, 표기 보정·재조립 뒤 실행자를 배정하는지.
tags: [boundary, reference-handling]
model: sonnet
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
expected_outcome: plan-executor 발동. 조립기 종료 2를 보고 실행자를 바로 띄우지 않고 계획 2절 원문을 확인, 산문 계약을 코드 블록 선언으로 옮겨 재조립(복구 1회, 복구 기록) 뒤 실행자를 띄운다. 사용자에게 묻지 않음. src 직접 수정 없음
---

`docs/CHK-1/plan.md` 승인했으니 시작해.
