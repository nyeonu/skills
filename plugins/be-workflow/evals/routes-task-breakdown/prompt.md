---
description: 승인된 스펙을 작업 단위로 나눠 달라는 요청이 task-breakdown으로 가고 스펙 재작성·실행으로 새지 않는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: task-breakdown 발동. plan-template을 읽고 추적성 표가 있는 계획 초안을 만든다. 실행(코드 변경)이나 스펙 수정 없음
---

`docs/spec/2026-10-07-feature-profile-bio.md` 스펙 승인됐어. 이걸 어떻게 나눠서 작업할지 정리해줘.
