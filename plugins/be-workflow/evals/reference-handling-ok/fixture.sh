#!/usr/bin/env bash
# 평가용 픽스처. 프로필 서비스 저장소를 만든다.
set -euo pipefail
export GIT_AUTHOR_NAME=eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main .
mkdir -p src/main/java/com/example/profile src/test/java/com/example/profile
cat > build.gradle <<'GRADLE'
plugins { id 'java' }
repositories { mavenCentral() }
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'
}
test { useJUnitPlatform() }
GRADLE
cat > README.md <<'MD'
# profile-api

회원 프로필(닉네임, 생년)을 저장·조회하는 서비스. 테스트는 `./gradlew test`.
MD
cat > src/main/java/com/example/profile/ProfileRequest.java <<'JAVA'
package com.example.profile;

public record ProfileRequest(String nickname, int birthYear) {}
JAVA
cat > src/main/java/com/example/profile/InvalidRequestException.java <<'JAVA'
package com.example.profile;

/** 400 응답으로 변환되는 예외. code는 기존 규칙(-3: 값 범위 오류)을 따른다. */
public class InvalidRequestException extends RuntimeException {
    private final int code;

    public InvalidRequestException(int code, String message) {
        super(message);
        this.code = code;
    }

    public int code() {
        return code;
    }
}
JAVA
cat > src/main/java/com/example/profile/BirthYearValidator.java <<'JAVA'
package com.example.profile;

import java.time.Year;

public final class BirthYearValidator {

    private static final int MIN_YEAR = 1900;

    private BirthYearValidator() {}

    public static void validate(int birthYear) {
        int thisYear = Year.now().getValue();
        if (birthYear < MIN_YEAR || birthYear > thisYear) {
            throw new InvalidRequestException(-3, "birthYear out of range: " + birthYear);
        }
    }
}
JAVA
cat > src/main/java/com/example/profile/ProfileService.java <<'JAVA'
package com.example.profile;

import java.util.ArrayList;
import java.util.List;

public class ProfileService {

    private final List<ProfileRequest> saved = new ArrayList<>();

    public void save(ProfileRequest request) {
        BirthYearValidator.validate(request.birthYear());
        saved.add(request);
    }

    public List<ProfileRequest> saved() {
        return List.copyOf(saved);
    }
}
JAVA
cat > src/test/java/com/example/profile/ProfileServiceTest.java <<'JAVA'
package com.example.profile;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ProfileServiceTest {

    private final ProfileService service = new ProfileService();

    @Test
    @DisplayName("1900년 미만 birthYear로 저장하면 코드 -3으로 거절한다")
    void rejectsBefore1900() {
        InvalidRequestException e = assertThrows(InvalidRequestException.class,
            () -> service.save(new ProfileRequest("nick", 1899)));
        assertEquals(-3, e.code());
    }

    @Test
    @DisplayName("1900년 이상 올해 이하 birthYear는 그대로 저장된다")
    void savesInRange() {
        service.save(new ProfileRequest("nick", 1990));
        assertEquals(1, service.saved().size());
    }
}
JAVA
git add -A && git commit -qm "프로필 서비스 초기 구현"
mkdir -p docs/PROFILE-7
mkdir -p docs/CHK-1
cat > docs/CHK-1/spec.md <<'MD'
---
spec_id: CHK-1
title: 생년 검증 상한 (조립기 점검용)
status: approved
created: 2026-10-18
---

# 생년 검증 상한

## 1. 한눈에 보기

- 해결할 문제: 생년을 올해로 넣으면 저장이 거절된다
- 바뀌는 결과: 올해까지 허용된다
- 완료 판단: 5절 기준이 전부 통과한다

### 배경 — 용어

- 이 소절은 Goal에 들어가면 안 된다

## 2. 범위

### 포함

- 생년 상한 검증

### 제외

- 생년 하한 변경

## 3. 확인한 사실과 가정

없음

## 4. 외부 계약과 흐름

해당 없음

## 5. 성공 기준

### 생년 검증

- 올해 생년은 저장된다

## 6. 제약과 경계

- 지켜야 할 조건: 기존 컨벤션 준수
- 하지 않을 것: 하한 변경

## 7. 미해결 사항

없음
MD
cat > docs/CHK-1/plan.md <<'MD'
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
MD
# 변형: 정상 참조 — 2절 코드 블록에 선언이 있고 작업이 그것을 명시 참조
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("docs/CHK-1/plan.md"); v = p.read_text(encoding="utf-8")

p.write_text(v, encoding="utf-8")
PY
git add -A && git commit -qm "CHK-1 스펙·승인된 계획"
