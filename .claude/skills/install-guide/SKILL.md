---
name: install-guide
description: 이 레포의 스킬·MCP 플러그인을 새 사용자 환경에 설치하는 대화형 가이드. 사용자가 "스킬 설치해줘", "설치 가이드", "이 레포 세팅해줘", "온보딩" 등을 언급하거나, 이 레포를 처음 클론한 사용자가 설치 방법을 물으면 반드시 이 스킬을 사용하라. MCP 서버부터 스킬 플러그인까지 하나씩 설명하고 설치 여부를 물어본 뒤, 선택된 것만 공식 플러그인 메커니즘(claude plugin install)으로 설치한다.
---

# 설치 가이드 (대화형 인스톨러)

이 레포는 Claude Code 플러그인 마켓플레이스다. 이 스킬은 새 사용자가 자기 환경에 필요한 것만 골라 설치하도록 안내한다. **사용자가 명시적으로 선택하지 않은 플러그인은 절대 설치하지 않는다.**

## 절차

### 0. 현재 상태 확인

이미 설치된 것을 다시 설치하지 않기 위해 먼저 확인한다:

```bash
claude plugin list
```

`be-agentic-workflow` 마켓플레이스의 플러그인이 이미 있으면 그 사실을 알리고, 없는 것만 아래 절차로 진행한다.

### 1. 마켓플레이스 등록

```bash
claude plugin marketplace add nyeonu/skills
```

GitHub 접근이 안 되는 환경(사내망, private 접근 권한 없음)이면 클론된 레포 경로로 등록한다:

```bash
claude plugin marketplace add /path/to/skills
```

(이 스킬이 발동됐다면 현재 작업 디렉토리가 그 레포이므로 절대 경로를 확인해 사용한다.)

### 2. MCP 서버 선택 — 스킬보다 먼저

AskUserQuestion(multiSelect)으로 아래 3개를 설명과 함께 제시하고 필요한 것만 고르게 한다. **셋 다 선택 사항이며, 하나도 안 골라도 워크플로우 스킬은 정상 동작한다**는 점을 반드시 말한다.

| 플러그인 | 역할 | 설치 후 추가 조치 |
|---|---|---|
| `mcp-context7` | 라이브러리·프레임워크 최신 공식 문서 조회. 스펙 작성·실행 단계에서 학습 데이터 대신 최신 문서 참조 | 없음 (API 키 없이 동작, 키가 있으면 `CONTEXT7_API_KEY`로 요율 제한 완화) |
| `mcp-atlassian` | Jira 티켓·Confluence 기획서를 직접 읽어옴. 요구사항 소스가 Atlassian일 때 interview-me·spec-writer에서 사용 | 첫 사용 시 `/mcp`에서 OAuth 로그인 필요 |
| `mcp-chrome-devtools` | 성능 트레이스·Core Web Vitals 측정. performance-optimization 스킬이 사용 | 로컬 Chrome 설치 필요 |

선택된 것만 설치한다:

```bash
claude plugin install mcp-context7@be-agentic-workflow --scope user
```

### 3. 스킬 플러그인 선택

AskUserQuestion(multiSelect)으로 아래 2개를 제시한다:

| 플러그인 | 내용 | 권장 대상 |
|---|---|---|
| `be-workflow` | 워크플로우 코어 7종: using-agent-skills(메타 라우터), interview-me, spec-writer, task-breakdown, plan-executor, spec-conformance-check, adr-writer. 승인 게이트·문서 상태로 서로 연결되어 있어 묶음 설치만 지원 | 스펙→계획→실행→검증 워크플로우를 쓸 사람 전부 |
| `be-review` | 리뷰 스킬 3종(코드 품질·보안·성능) + 리뷰어/보안 감사 에이전트 2종 | 코드 리뷰만 필요해도 단독 설치 가능 |

```bash
claude plugin install be-workflow@be-agentic-workflow --scope user
claude plugin install be-review@be-agentic-workflow --scope user
```

`--scope user`가 기본 권장이다(모든 프로젝트에서 사용 가능). 특정 프로젝트에서만 쓰려면 사용자에게 물어보고 `--scope project`로 바꾼다.

### 4. 설치 확인과 마무리 안내

1. `claude plugin list`로 설치 결과를 보여준다.
2. 안내할 것:
   - 스킬은 **새 세션부터** 로딩된다.
   - `mcp-atlassian`을 설치했다면 새 세션에서 `/mcp`를 열어 Atlassian OAuth 로그인을 해야 도구가 활성화된다.
   - 워크플로우 사용법은 레포 README의 "실행 순서" 도식과 각 SKILL.md가 원본이다.
   - 업데이트는 `claude plugin marketplace update be-agentic-workflow` 후 재설치.

## 금지 사항

- 사용자 선택 없이 설치하는 것 (전부 설치 요청을 받았어도 각 항목의 역할과 추가 조치를 먼저 보여준다)
- MCP 인증 정보(API 키, 토큰)를 대신 입력하는 것 — 안내만 한다
- 이 레포의 파일을 수정하는 것 — 이 스킬은 읽기와 설치 명령만 수행한다
