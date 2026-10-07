---
description: 요구사항은 명확하지만 스펙이 없는 새 기능 요청이 spec-writer로 가고 계획·구현으로 새지 않는지.
tags: [routing, description]
model: sonnet
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
expected_outcome: spec-writer 발동. 스펙을 쓰기 전에 "내가 하고 있는 가정"을 드러내고 확인을 요청하며 멈춘다(비대화형이라 여기서 끝난다). 작업 계획이나 코드 변경 없음
---

프로필에 자기소개(bio) 필드를 추가하는 기능을 시작하려고 해. 저장할 때 선택으로 받고 최대 200자, 조회할 때 같이 내려줘야 해. 금칙어 필터링은 이번에 안 해. 구현 들어가기 전에 요구사항부터 문서로 정리해줘.
