#!/usr/bin/env python3
"""실행자 브리프 조립기 — plan-executor 전용.

승인된 스펙·계획에서 실행자 하나에게 줄 프롬프트를 결정적으로 만든다. 오케스트레이터가
손으로 조립하면 세션마다 형식·참조 셈법이 달라져 측정값을 비교할 수 없으므로 이 스크립트만 쓴다.

    python3 assemble_brief.py --spec docs/T-1/spec.md --plan docs/T-1/plan.md --task T2 \
        --model sonnet --worktree /path/to/worktree --branch feature/T-1 \
        --out docs/T-1/briefs/T-1-T2-sonnet.md

- Goal: 스펙 "## 1." 절에서 첫 "###" 소제목 전까지(불렛만). 배경 소절은 실행자에게 주지 않는다.
- Do not touch: 스펙 2절 "### 제외" 소절 + "## 6." 절 전문.
- Your task: 계획에서 "### <task>:" 블록 전문.
- Shared design: 작업 블록이 백틱으로 가리키는 이름을 계획 "## 2." 절(작업 plan이면 상위 에픽 plan의 2절도)에서
  찾아 넣는다. 코드 블록은 "// <경로>" 주석 단위로 쪼개 이름이 든 조각만, 표·불렛은 이름이 든 줄만.
  명시 참조("2절 `X` 참조", "`X` 참조")는 못 찾으면 해소 실패로 센다 — 오케스트레이터는 그때 실행자를 띄우지 않는다.
  그 밖의 백틱 이름은 2절에 있으면 넣고 없으면 조용히 넘긴다.
- 첫 줄 통계는 고정 형식 한 줄이다(측정 비교용).

표준 출력에는 통계와 해소 실패 목록만 찍는다. 종료 코드: 0 정상, 2 해소 실패 있음, 1 입력 오류.

--- 채널 언어 정책 (plan-executor 2절에서 이관) ---
채널 언어 정책: 오케스트레이터 ↔ 실행자 통신의 보일러플레이트(역할 규칙)와 보고 형식은 형식 일관성을 위해 영어 고정 계약을 쓴다. 언어 선택에 따른 토큰 절감·지시 이행률 개선은 별도 측정 없이는 주장하지 않는다. 단 두 가지는 예외다:

1. 스펙·계획 원문(Goal·제외 범위·작업 블록·참조한 공통 설계)은 번역·요약·압축 없이 한국어 그대로 인용한다 — 승인받은 문서와 실제 지시 사이에 번역이라는 해석 단계를 만들지 않는다.
2. 산출물(코드 주석, 문서, 커밋 대상 텍스트)과 사용자 보고는 저장소 언어(한국어)를 따른다 — 영어는 통신 채널에서만 쓴다.

보고는 자유 산문이 아니라 아래 고정 슬롯 형식만 허용한다 — 구조화는 토큰과 모호함을 동시에 줄이지만, 산문 압축(관사·접속사 생략)은 모호함을 늘리므로 금지다.
"""
import argparse
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATE = HERE / "executor-brief-template.md"

# ---- 템플릿 계약 (spec-template.md · plan-template.md · work-plan-template.md와 함께 바뀐다) ----
# 제목이 바뀌면 여기만 고친다. 템플릿 쪽 해당 제목에는 "assemble_brief.py가 이 제목으로 자른다" 주석이 있다.
SPEC_GOAL_START = r"^## 1\. "         # 스펙 1절 한눈에 보기 → Goal (첫 ### 전까지)
SPEC_GOAL_END = r"^## 2\. "
SPEC_EXCLUDE_START = r"^### 제외"       # 스펙 2절 제외 → Do not touch
SPEC_EXCLUDE_END = r"^## 3\. "
SPEC_CONSTRAINT_START = r"^## 6\. "   # 스펙 6절 제약과 경계 → Do not touch
SPEC_CONSTRAINT_END = r"^## 7\. "
PLAN_DESIGN_START = r"^## 2\. "        # 계획 2절 공통 설계 → Shared design 탐색 범위
PLAN_DESIGN_END = r"^## 3\. "
PLAN_TASK_HEADING = "### {task}:"       # 작업 블록 제목. 다음 "### T<n>:" 또는 "## "까지
PLAN_TASK_END = r"^### T\d+:|^## "
CODE_CHUNK_SPLIT = r"^\s*//\s*(<|[A-Z][A-Za-z0-9]*(\.java|\.kt)?\s*($|—|-|:))"   # 2절 코드 블록을 타입별로 나누는 헤더 주석: "// <경로>/이름.java" 또는 "// 이름 — 설명"
FILE_ROW = r"^\s*\| `"                # 변경 파일 표 행 (통계용)
TEST_BULLET = r'^\s*- "'              # 작성할 테스트 불렛 (통계용)
LIMIT_TASK, LIMIT_SHARED, LIMIT_GOAL = 80, 80, 20   # 권장 상한(줄). work-plan-template 작업 블록 규칙과 같이 바꾼다. Shared design은 2차 측정(T4 74·T7 81)으로 60→80
# ------------------------------------------------------------------------------------------------


def read(p: str) -> str:
    return Path(p).read_text(encoding="utf-8")


def split_frontmatter(text: str):
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            return text[4:end], text[end + 5:]
    return "", text


def section(text: str, start_pat: str, end_pat: str) -> str:
    """start_pat 줄부터 end_pat 줄 직전까지. 없으면 빈 문자열."""
    lines = text.split("\n")
    out, on = [], False
    for ln in lines:
        if not on and re.match(start_pat, ln):
            on = True
            out.append(ln)
            continue
        if on and re.match(end_pat, ln):
            break
        if on:
            out.append(ln)
    return "\n".join(out).rstrip()


def goal(spec_body: str) -> str:
    sec = section(spec_body, SPEC_GOAL_START, SPEC_GOAL_END)
    # 첫 ### 전까지만 — 배경 소절은 뺀다
    kept = []
    for ln in sec.split("\n"):
        if ln.startswith("### "):
            break
        kept.append(ln)
    return "\n".join(kept).rstrip()


def do_not_touch(spec_body: str) -> str:
    excl = section(spec_body, SPEC_EXCLUDE_START, SPEC_EXCLUDE_END)
    six = section(spec_body, SPEC_CONSTRAINT_START, SPEC_CONSTRAINT_END)
    parts = [p for p in (excl, six) if p]
    return "\n\n".join(parts)


def task_block(plan_body: str, task_id: str) -> str:
    start = "^" + re.escape(PLAN_TASK_HEADING.format(task=task_id))
    sec = section(plan_body, start, PLAN_TASK_END)
    return sec


def section2(plan_body: str) -> str:
    return section(plan_body, PLAN_DESIGN_START, PLAN_DESIGN_END)


IDENT = re.compile(r"`([^`\n]+)`")
EXPLICIT = re.compile(r"(?:2절\s*)?`([^`\n]+)`\s*(?:과|와|·|,)?\s*(?:[^`\n]{0,20})?참조")


def identifiers(block: str):
    names = []
    for m in IDENT.finditer(block):
        n = m.group(1).strip()
        if "/" in n or n.startswith("./") or " " in n and not n.startswith("@"):
            continue  # 경로·명령
        if n.startswith(("--", "-P")):
            continue
        names.append(n)
    explicit = set()
    for m in EXPLICIT.finditer(block):
        n = m.group(1).strip()
        if "/" not in n:
            explicit.add(n)
    # "2절 `A` 참조" 형태 외에 "2절 `A`와 `B` 표 참조"도 잡기 위해 참조 문장 안의 모든 백틱을 명시로 본다
    for sent in re.split(r"[.\n]", block):
        if "참조" in sent and ("2절" in sent or "상위" in sent):
            for m in IDENT.finditer(sent):
                n = m.group(1).strip()
                if "/" not in n and " " not in n:
                    explicit.add(n)
    seen, ordered = set(), []
    for n in names:
        if n not in seen:
            seen.add(n)
            ordered.append(n)
    return ordered, explicit


def simple_name(n: str) -> str:
    """`SampleRecord.of(...)` → SampleRecord, `@JsonProperty("x")` → @JsonProperty"""
    n = n.split("(")[0]
    n = n.split("<")[0]
    return n.split(".")[0] if not n.startswith("@") else n


def code_chunks(sec2: str):
    """2절의 fenced 코드 블록을 '// <경로>' 주석 단위로 쪼갠 조각 목록. (lang, chunk)"""
    chunks = []
    for m in re.finditer(r"```(\w*)\n(.*?)```", sec2, re.S):
        lang, body = m.group(1), m.group(2)
        cur = []
        for ln in body.split("\n"):
            if re.match(CODE_CHUNK_SPLIT, ln) and cur and any(c.strip() for c in cur):
                chunks.append((lang, "\n".join(cur).rstrip()))
                cur = []
            cur.append(ln)
        if any(c.strip() for c in cur):
            chunks.append((lang, "\n".join(cur).rstrip()))
    return chunks


def prose_lines(sec2: str):
    """2절에서 코드 블록을 뺀 줄들(표 행·불렛)."""
    no_code = re.sub(r"```\w*\n.*?```", "", sec2, flags=re.S)
    return [ln for ln in no_code.split("\n") if ln.startswith(("| ", "- "))]


def chunk_declares(key: str, chunk: str) -> bool:
    """조각이 key를 선언하는가 — 헤더 주석 경로의 파일명, 또는 class/record/interface/enum 선언, 또는 메서드 선언."""
    if re.search(rf"//\s*<[^>]*>[^\n]*/{re.escape(key)}\.(java|kt|ts|py)\b", chunk):
        return True
    if re.search(rf"^\s*//\s*{re.escape(key)}(\.java|\.kt)?\s*($|—|-|:)", chunk, re.M):
        return True  # "// 이름 — 설명" 형태의 조각 헤더
    if re.search(rf"\b(class|record|interface|enum)\s+{re.escape(key)}\b", chunk):
        return True
    for ln in chunk.split("\n"):
        if ln.strip().startswith("//"):
            continue
        if re.search(rf"\b{re.escape(key)}\s*\(", ln) and not re.search(rf"\.\s*{re.escape(key)}\s*\(", ln):
            return True
    return False


def line_mentions(key: str, ln: str) -> bool:
    return re.search(rf"`[^`]*\b{re.escape(key)}\b[^`]*`", ln) is not None


def opportunistic(n: str) -> bool:
    """명시 참조가 아닌 백틱 이름 중 2절에서 찾아볼 가치가 있는 것 — 타입(CamelCase) 또는 Type.member."""
    base = n.split("(")[0]
    return re.match(r"^[A-Z][A-Za-z0-9]+(\.[a-zA-Z_][A-Za-z0-9_]*)?$", base) is not None


def shared_design(sec2_texts, names, explicit):
    picked_code, picked_lines, found = [], [], set()
    aliases = []
    targets = [n for n in names if n in explicit or opportunistic(n)]
    for sec2 in sec2_texts:
        for ln in sec2.split("\n"):
            if ln.startswith("경로 약어"):
                aliases.append(ln)
        chunks = code_chunks(sec2)
        lines = prose_lines(sec2)
        for n in targets:
            key = simple_name(n)
            member = n.split("(")[0].split(".")[1] if "." in n.split("(")[0] and not n.startswith("@") else None
            if not key or len(key) < 3:
                continue
            hit = False
            for lang, ch in chunks:
                if chunk_declares(key, ch) or (member and chunk_declares(member, ch)):
                    hit = True
                    if (lang, ch) not in picked_code:
                        picked_code.append((lang, ch))
            for ln in lines:
                if line_mentions(key, ln) or (member and line_mentions(member, ln)):
                    hit = True
                    if ln not in picked_lines and not ln.startswith("|---") and "| 파일 |" not in ln and "| 결정 |" not in ln:
                        picked_lines.append(ln)
            if hit:
                found.add(n)
    found_keys = {simple_name(f) for f in found}
    missing = sorted(e for e in explicit if e not in found and simple_name(e) not in found_keys)
    out = []
    out.extend(dict.fromkeys(aliases))
    for lang, ch in picked_code:
        out.append(f"```{lang}\n{ch}\n```")
    if picked_lines:
        out.append("\n".join(picked_lines))
    return "\n\n".join(out).strip(), found, missing


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec", required=True)
    ap.add_argument("--plan", required=True)
    ap.add_argument("--task", required=True, help="예: T2")
    ap.add_argument("--model", required=True, help="haiku | sonnet | opus 등 실제 띄우는 모델")
    ap.add_argument("--worktree", required=True)
    ap.add_argument("--branch", required=True)
    ap.add_argument("--parent", help="작업 plan이면 상위 에픽 plan 경로(2절 참조 해소에 포함)")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    _, spec_body = split_frontmatter(read(a.spec))
    _, plan_body = split_frontmatter(read(a.plan))
    task = task_block(plan_body, a.task)
    if not task:
        print(f"작업 블록을 찾지 못함: {a.task}", file=sys.stderr)
        return 1
    g = goal(spec_body)
    dnt = do_not_touch(spec_body)
    if not g or not dnt:
        print("스펙 1절 또는 2절 제외/6절을 찾지 못함 — 스펙 제목이 템플릿과 같은지 확인", file=sys.stderr)
        return 1

    sec2s = [section2(plan_body)]
    if a.parent:
        _, pb = split_frontmatter(read(a.parent))
        sec2s.append(section2(pb))
    names, explicit = identifiers(task)
    sd, found, missing = shared_design(sec2s, names, explicit)

    tpl = TEMPLATE.read_text(encoding="utf-8")
    sd_section = f"## Shared design (verbatim from the approved plan)\n{sd}\n\n" if sd else ""
    brief = (tpl.replace("{{WORKTREE}}", a.worktree).replace("{{BRANCH}}", a.branch)
             .replace("{{GOAL}}", g).replace("{{DO_NOT_TOUCH}}", dnt)
             .replace("{{SHARED_DESIGN_SECTION}}", sd_section).replace("{{TASK}}", task))

    files = len(re.findall(FILE_ROW, task, re.M))
    tests = len(re.findall(TEST_BULLET, task, re.M))
    lines = brief.count("\n") + 1
    chars = len(brief)
    task_lines = task.count("\n") + 1
    sd_lines = sd.count("\n") + 1 if sd else 0
    goal_lines = g.count("\n") + 1
    stats = (f"<!-- brief {a.task} {a.model} · {lines}줄 · {chars}자 · 추정 토큰 {chars // 3} · "
             f"Shared design 참조 {len(found)}(명시 {len(explicit)}, 해소 실패 {len(missing)}) · "
             f"변경 파일 {files} · 테스트 {tests} · 작업 블록 {task_lines}줄 · Shared design {sd_lines}줄 · Goal {goal_lines}줄 -->")
    # 구성 요소별 권장 상한(work-plan-template 작업 블록 규칙). 초과는 경고만 — 계획 결함 후보로 사용자에게 보인다.
    over = []
    if task_lines > LIMIT_TASK:
        over.append(f"작업 블록 {task_lines}>{LIMIT_TASK}")
    if sd_lines > LIMIT_SHARED:
        over.append(f"Shared design {sd_lines}>{LIMIT_SHARED}")
    if goal_lines > LIMIT_GOAL:
        over.append(f"Goal {goal_lines}>{LIMIT_GOAL}")
    out = Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(stats + "\n" + brief, encoding="utf-8")
    print(stats)
    if over:
        print("상한 초과(경고): " + ", ".join(over) + " — 작업을 나누거나 참조를 줄일 후보")
    if missing:
        print("해소 실패(명시 참조인데 2절에 없음): " + ", ".join(missing))
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
