---
type: regex
target: { source: file, path: docs/PROFILE-7/plan.md }
# "### 결정 로직 위치" 절 본문(다음 제목 전까지)에 위치를 가리키는 식별자가 있는가.
# plan-template은 이 절에 "어느 파일의 무엇인지"를 요구할 뿐 표를 요구하지 않는다. 실제 산출물은
# `src/.../BioValidator.java`의 `validate` 또는 `BioValidator.validate(String)` 꼴로 쓰므로,
# 백틱 안에 `.` 또는 `/`가 든 토큰(클래스.메서드 또는 경로)을 통과 조건으로 한다.
# 범위를 다음 제목(\n#) 전까지로 제한해 뒤쪽 추적성 표나 작업 블록으로 통과하지 않게 한다.
pattern: '### 결정 로직 위치(?:(?!\n#)[\s\S])*?`[^`\n]*[./][^`\n]*`'
---
