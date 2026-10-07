---
description: 구현 완료 후 "스펙대로 됐는지 확인해줘" 요청이 spec-conformance-check로 가고, 계획·구현·TDD 스킬로 새지 않는지.
tags: [routing]
model: sonnet
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Agent]
expected_outcome: spec-conformance-check 발동. 기준별 판정 보고 형식이거나, 실행 증거를 만들 수 없음을 남은 불확실성으로 명시. 코드 수정·계획 작성·일반 코드 리뷰 없음
---

구현 끝났어. `docs/spec/2026-10-01-feature-birth-year-validation.md` 스펙대로 됐는지 확인해줘. 셸은 못 쓰니까 코드와 테스트 파일을 읽어서 판단해줘.
