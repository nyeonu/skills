---
description: 작업이 계획 어디에도 없는 새 타입의 계약을 명시 참조할 때(기존 타입의 오기로 볼 근거 없음) plan-executor가 다른 타입의 메서드나 추측으로 메우지 않고 멈춰 사용자에게 묻는지.
tags: [boundary, reference-handling]
model: sonnet
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
expected_outcome: plan-executor 발동. 조립기 종료 2 → 2절 원문 확인 → 계약이 실제로 없음을 확인하고 실행자를 띄우지 않은 채 사용자에게 묻는다. AgeNormalizer.normalize의 시그니처를 추측으로 만들거나 다른 타입으로 대체하지 않음. src·계획에 추측 계약 추가 없음
---

`docs/CHK-1/plan.md` 승인했으니 시작해.
