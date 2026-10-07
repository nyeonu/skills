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
mkdir -p docs/spec
cat > docs/spec/2026-10-07-feature-profile-bio.md <<'MD'
---
spec_id: 2026-10-07-feature-profile-bio
title: 프로필 자기소개(bio) 필드 추가
status: approved
created: 2026-10-07
scope: app
---

# 프로필 자기소개(bio) 필드 추가

## 1. 한눈에 보기

회원 프로필에 자기소개 문구(bio)를 저장하고 조회에 함께 내려준다. 지금은 닉네임과 생년만 있어 팬 페이지에서 자기소개를 보여줄 수 없다.

## 2. 범위

### 포함
- 저장 요청에 bio(선택, 최대 200자)를 받는다
- 조회 응답에 bio를 포함한다

### 제외
- bio 수정 이력 보관
- 금칙어 필터링

## 3. 확인한 사실과 가정

- 저장은 `ProfileService.save(ProfileRequest)`를 거친다 (확인값).
- 거절은 400 응답과 코드 -3으로 내려간다 (확인값, 기존 규칙).
- 프로필 저장소는 아직 메모리 리스트다 (확인값). 영속화는 이번 범위가 아니다.

## 4. 계약과 배포 순서

해당 없음

## 5. 성공 기준

### 자기소개 저장
- bio가 없는 저장 요청은 기존처럼 저장된다
- 200자 이하 bio는 그대로 저장된다
- 201자 이상 bio로 저장하면 400으로 거절한다

### 자기소개 조회
- 저장된 프로필을 조회하면 bio가 함께 내려간다

## 6. 제약과 경계

- 기존 저장 호출부의 시그니처를 깨지 않는다 (bio 없는 생성자 또는 기본값 유지)

## 7. 미해결 사항

없음
MD
git add -A && git commit -qm "bio 스펙 승인"
