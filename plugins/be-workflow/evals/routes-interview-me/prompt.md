---
description: 대상·이유·성공 기준이 빠진 모호한 요청이 interview-me로 가서 질문 하나와 추정으로 답하는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: interview-me 발동. 현재 이해·확신 정도·아직 모르는 점을 밝히고 질문 하나에 추정을 붙여 묻는다. 스펙·계획·코드 작성 없음
---

프로필 쪽에 운영에서 보기 편한 대시보드 같은 거 하나 만들어줘.
