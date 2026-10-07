---
description: 승인된 계획의 되돌리기 비싼 결정을 남겨 달라는 요청이 adr-writer로 가고, 기존 ADR 다음 번호의 Proposed ADR을 쓰는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: adr-writer 발동. docs/decisions/의 기존 ADR을 확인해 ADR-002 Proposed로 작성하고 검토한 대안을 적는다. 계획 수정이나 구현 없음
---

`docs/plan/2026-10-07-feature-profile-bio.md` 계획 승인했어. bio를 별도 테이블로 가져가기로 한 결정, 나중에 왜 그랬는지 알 수 있게 남겨줘.
