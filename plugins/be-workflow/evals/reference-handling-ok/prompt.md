---
description: 정상 참조인 승인된 계획을 실행하라는 요청에 plan-executor가 불필요한 계획 보정이나 사용자 질문 없이 브리프를 조립해 실행자를 배정하는지.
tags: [boundary, reference-handling]
model: sonnet
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
expected_outcome: plan-executor 발동. assemble_brief.py로 브리프를 조립하고 실행자(Agent)를 띄운다. 계획 보정·사용자 질문·오케스트레이터의 src 직접 수정 없음
---

`docs/CHK-1/plan.md` 승인했으니 시작해.
