---
description: 버그 수정 요청이 tdd로 가서 수정 전에 재현 테스트부터 쓰는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: tdd 발동. 수정 전에 버그를 재현하는 테스트를 먼저 쓴다(Prove-It). 테스트를 실행할 수 없음을 숨기지 않는다. 스펙·계획 작성 없음
---

생년을 올해로 넣으면 저장이 거절돼. 올해까지는 허용이어야 해. 고쳐줘. 셸은 못 쓰니까 테스트 실행은 안 돼.
