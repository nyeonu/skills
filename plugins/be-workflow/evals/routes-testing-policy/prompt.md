---
description: 버그 수정 요청이 testing-policy로 가서 회귀 테스트를 보완하고 실행 불가를 보고하는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: testing-policy 발동. 작성 순서와 무관하게 버그를 재현하는 테스트를 추가한다. 테스트를 실행할 수 없음을 숨기지 않는다. 스펙·계획 작성 없음
---

생년을 올해로 넣으면 저장이 거절돼. 올해까지는 허용이어야 해. 고쳐줘. 회귀 테스트는 기존 ProfileServiceTest.java에 반영해줘. 셸은 못 쓰니까 테스트 실행은 안 돼.
