---
description: 접근 판정이 Repository·HTTP 리액티브 체인 안에 끼어 들어간 변경의 리뷰. 저장소 CLAUDE.md에 "국소 추론 판정 기준 합의" 선언이 있으므로 심각도 표를 그대로 적용해 Important가 나와야 한다.
tags: [review, local-reasoning]
model: sonnet
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: code-review-and-quality 발동, local-reasoning-checklist 로드, 분리 지적이 Important, 같은 파일 static 메서드 우선
---

머지 전 리뷰해줘. 작업 공간에 git 저장소가 있고, 변경 내용은 HEAD 커밋이자 `CHANGES.diff` 파일이야. 전체 소스는 `src/` 아래에 있어.

변경 목적: 숨김 게시판의 글은 관리자만, 멤버십 전용 글은 해당 아티스트 멤버십 회원과 관리자만 조회할 수 있게 한다.

`BoardRepository`·`MembershipClient`·`BoardDTO`·`AccessDeniedException`은 다른 기능에서 이미 쓰던 기존 코드라 diff에 없어.

테스트는 아직 돌리지 못했어. 셸 실행 없이 코드만 보고 리뷰해줘.
