---
plan_id: CHK-1
title: 생년 검증 상한 계획
kind: single
status: approved
spec: spec.md
tasks:
  - id: T1
    title: 검증 상한 수정
    depends_on: []
    status: pending
    tier: light
---

# 생년 검증 상한 계획

## 1. 선택한 방식과 이유

- 상수 하나만 고친다.

## 2. 공통 설계

경로 약어: `<main>` = `src/main/java/com/example`.

### 인터페이스

```java
// <main>/profile/BirthYearValidator.java
public static boolean isValid(int year, int thisYear);
```

```java
// <main>/profile/ProfileService.java
public void save(Profile p);   // 이 조각은 T1 브리프에 들어가면 안 된다
```

### 결정 로직 위치

| 결정 | 위치 | 유닛 테스트 |
|---|---|---|
| 생년 상한 | `BirthYearValidator.isValid` static | `BirthYearValidatorTest` (T1) |

### 관련된 암묵적 동작

- 없음

## 3. 추적성

| 스펙 기준 | 테스트 이름 (출처/층) | 충족 위치 |
|---|---|---|
| 올해 생년은 저장된다 | "올해 생년은 저장된다" (①/유닛) | T1 완료 기준 |

## 4. 작업

### T1: 검증 상한 수정

- **변경 파일**

  | 파일 | 신규/수정 | 변경 요지 |
  |---|---|---|
  | `<main>/profile/BirthYearValidator.java` | 수정 | 상한을 올해로 |
  | `<test>/profile/BirthYearValidatorTest.java` | 신규 | 아래 테스트 |

- **인터페이스**: 2절 `BirthYearValidator` 참조.
- **결정 로직**: 없음
- **작성할 테스트**
  - "올해 생년은 저장된다"
- **완료 기준**: 위 테스트 통과
- **검증 방법**: `./gradlew test`
- **주의사항**: 없음

## 5. 전체 검증

없음

## 6. 위험과 롤백

없음
