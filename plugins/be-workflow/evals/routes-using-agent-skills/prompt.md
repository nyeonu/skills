---
description: 어디서부터 시작해야 하느냐는 진입점 질문이 using-agent-skills로 가고, 스펙 없는 새 기능이므로 spec-writer(또는 interview-me)를 진입점으로 고르는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: using-agent-skills 발동. 스펙이 없으므로 진입점으로 spec-writer(요구사항이 모호하면 interview-me)를 안내한다. 계획·실행·ADR 스킬로 새지 않음
---

회원 프로필에 공개/비공개 설정을 넣어야 해. 우리 워크플로우 기준으로 어디서부터 시작해야 해?
