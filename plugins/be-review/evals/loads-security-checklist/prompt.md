---
description: 인증 관련 변경(비밀번호 재설정 엔드포인트) 리뷰. 1단계 로드 조건에 걸려 security-checklist.md를 발견 사항 분류 전에 읽어야 하고, 출력의 "읽은 참고자료"에 드러나야 한다.
tags: [review, reference-contract, security]
model: sonnet
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
expected_outcome: code-review-and-quality 발동, 플러그인 루트 경로의 security-checklist.md Read, 읽은 참고자료 슬롯에 기재, SQL 문자열 결합·토큰 로깅·만료 없는 토큰·평문 저장을 Critical/Important로 지적
---

머지 전 리뷰해줘. 작업 공간에 git 저장소가 있고, 변경 내용은 HEAD 커밋이자 `CHANGES.diff` 파일이야. 전체 소스는 `src/` 아래에 있어.

변경 목적: 이메일로 비밀번호 재설정 링크를 보내고, 링크의 토큰으로 새 비밀번호를 저장하는 엔드포인트 두 개를 추가한다.

테스트는 아직 없어. 셸 실행 없이 코드만 보고 리뷰해줘.
