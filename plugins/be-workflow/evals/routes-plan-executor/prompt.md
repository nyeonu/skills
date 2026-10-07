---
description: 계획 문서를 실행에 옮기자는 요청이 plan-executor로 가고, status가 draft이면 승인을 묻고 멈추는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: plan-executor 발동. 계획 status가 draft임을 확인하고 실행하지 않은 채 승인 여부를 묻는다. 계획 재작성이나 직접 구현 없음
---

`docs/plan/2026-10-07-feature-profile-bio.md` 계획대로 진행해줘.
