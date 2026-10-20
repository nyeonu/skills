---
description: 동작이 바뀌지 않는 설정 값 변경 요청에 testing-policy가 발동하지 않고 직접 처리하는지(과잉 발동 경계).
tags: [routing, boundary]
model: sonnet
max_turns: 10
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: testing-policy를 비롯한 워크플로우 스킬이 발동하지 않는다. application.yml의 값을 직접 고치고 끝낸다. 테스트 작성 없음
---

`src/main/resources/application.yml`의 `profile.save.timeout-seconds`를 30에서 60으로 바꿔줘.
