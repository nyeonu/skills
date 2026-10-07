#!/usr/bin/env bash
# 평가용 픽스처. 승인된 스펙 하나와 그 구현·테스트가 있는 작업 공간을 만든다.
set -euo pipefail
export GIT_AUTHOR_NAME=eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main .
mkdir -p docs/spec src/main/java/com/example/profile src/test/java/com/example/profile
cat > docs/spec/2026-10-01-feature-birth-year-validation.md <<'EOF'
---
spec_id: 2026-10-01-feature-birth-year-validation
title: 생년월일 저장 검증
status: approved
scope: app
author: eval
---

# 생년월일 저장 검증

## 1. 한눈에 보기

프로필 저장 API가 생년월일(birthYear)을 받을 때 값의 범위를 검증한다. 지금은 아무 값이나 저장되어 통계 집계가 깨진다.

## 2. 범위

### 포함
- birthYear 범위 검증과 거절 응답

### 제외
- 생년월일 수정 이력 저장

## 3. 확인한 사실과 가정

- 저장 API는 `ProfileService.save(ProfileRequest)`를 거친다 (확인값).
- 거절은 400 응답과 코드 -3으로 내려간다 (확인값, 기존 규칙).

## 4. 계약과 배포 순서

해당 없음

## 5. 성공 기준

### 생년월일 저장
- 1900년 미만 birthYear로 저장하면 400으로 거절한다
- 올해보다 큰 birthYear로 저장하면 400으로 거절한다
- 1900년 이상 올해 이하 birthYear는 그대로 저장된다

## 6. 제약과 경계

- 기존 저장 호출부의 시그니처를 바꾸지 않는다

## 7. 미해결 사항

없음
EOF
cat > build.gradle <<'EOF'
plugins { id 'java' }
repositories { mavenCentral() }
dependencies {
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'
}
test { useJUnitPlatform() }
EOF
cat > src/main/java/com/example/profile/ProfileRequest.java <<'EOF'
package com.example.profile;

public record ProfileRequest(String nickname, int birthYear) {}
EOF
cat > src/main/java/com/example/profile/InvalidRequestException.java <<'EOF'
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
EOF
cat > src/main/java/com/example/profile/BirthYearValidator.java <<'EOF'
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
EOF
cat > src/main/java/com/example/profile/ProfileService.java <<'EOF'
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
EOF
cat > src/test/java/com/example/profile/ProfileServiceTest.java <<'EOF'
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
EOF
git add -A && git commit -qm "생년월일 저장 검증 구현"
