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
mkdir -p docs/plan
SPEC_REV=$(git log -1 --format=%H -- docs/spec/2026-10-07-feature-profile-bio.md)
cat > docs/plan/2026-10-07-feature-profile-bio.md <<MD
---
plan_id: 2026-10-07-feature-profile-bio
title: 프로필 자기소개(bio) 필드 추가
status: approved
author: task-breakdown
created: 2026-10-07
target: profile-api
spec: docs/spec/2026-10-07-feature-profile-bio.md
spec_rev: ${SPEC_REV}
tasks:
  - id: T1
    title: ProfileRequest에 bio 필드와 BioValidator 추가 (테스트 먼저)
    depends_on: []
    status: pending
    tier: standard
  - id: T2
    title: ProfileService.save에서 bio 검증 호출, 조회 응답에 bio 포함
    depends_on: [T1]
    status: pending
    tier: light
---

# 프로필 자기소개(bio) 필드 추가

## 1. 목표

프로필 저장에 bio(선택, 최대 200자)를 받고 조회에 함께 내려준다. 기존 호출부는 깨지지 않아야 한다.

## 2. 실행에 필요한 현재 상태

- \`src/main/java/com/example/profile/ProfileRequest.java\`: record(nickname, birthYear)
- \`src/main/java/com/example/profile/BirthYearValidator.java\`: static validate, 범위 밖이면 InvalidRequestException(-3)
- \`src/main/java/com/example/profile/ProfileService.java\`: save가 validator를 호출하고 메모리 리스트에 추가
- 테스트는 JUnit 5, \`@DisplayName\` 한글 서술

## 3. 선택한 방식과 이유

bio 길이 검증은 BirthYearValidator와 같은 모양의 \`BioValidator.validate(String)\` static 메서드로 둔다. 서비스 메서드 안에 if를 끼우는 대안은 테스트가 ProfileService 전체를 세워야 해서 버렸다.

**되돌리기 비싼 결정**: bio는 프로필 본 테이블의 컬럼이 아니라 별도 \`profile_bio\` 테이블(profile_id PK, bio TEXT, updated_at)에 둔다. 조회 빈도가 낮고 길이가 커서 본 테이블 행 크기를 키우지 않기 위해서다. 대안으로 본 테이블에 VARCHAR(200) 컬럼을 추가하는 방식을 검토했고, 조인 비용 대신 단순함을 얻지만 이후 bio를 리치 텍스트로 늘릴 때 마이그레이션이 커진다고 보아 버렸다. 이 결정은 승인 직후 ADR Proposed 작성 대상이다.

## 4. 범위

**포함:**
- ProfileRequest에 bio(nullable) 추가, BioValidator, ProfileService 연결

**제외 (하지 말 것):**
- 기존 생성자 시그니처 제거 금지
- 영속화 계층 도입 금지 (스키마 결정만 기록)

## 5. 추적성

| 스펙 성공 기준 | 테스트 이름 | 작업 |
|---|---|---|
| bio가 없는 저장 요청은 기존처럼 저장된다 | bio 없이 저장하면 기존처럼 저장된다 | T2 |
| 200자 이하 bio는 그대로 저장된다 | 200자 bio는 그대로 저장된다 | T1 |
| 201자 이상 bio로 저장하면 400으로 거절한다 | 201자 bio로 저장하면 코드 -3으로 거절한다 | T1 |
| 저장된 프로필을 조회하면 bio가 함께 내려간다 | 저장한 프로필을 조회하면 bio가 함께 내려간다 | T2 |

## 6. 작업

### T1. ProfileRequest에 bio 필드와 BioValidator 추가 (테스트 먼저)

- 대상 파일: ProfileRequest.java, BioValidator.java(신규), BioValidatorTest.java(신규)
- 작업 내용: record에 \`String bio\` 추가, 기존 2인자 생성자 유지. BioValidator.validate는 null 허용, 201자 이상이면 InvalidRequestException(-3).
- 완료 기준: 위 추적성 표의 T1 테스트 두 개 통과
- verify: ./gradlew test --tests 'com.example.profile.BioValidatorTest'

### T2. ProfileService.save에서 bio 검증 호출, 조회 응답에 bio 포함

- 대상 파일: ProfileService.java, ProfileServiceTest.java
- 작업 내용: save에서 BioValidator.validate(request.bio()) 호출. saved()가 bio를 포함한 record를 그대로 반환하는지 테스트 추가.
- 완료 기준: 추적성 표의 T2 테스트 두 개 통과
- verify: ./gradlew test

## 7. 전체 검증

- ./gradlew test 전체 통과

## 8. 위험과 롤백

- 위험: 기존 호출부가 2인자 생성자를 쓰므로 record 변경 시 컴파일 깨짐. 완화: 2인자 보조 생성자 유지.
- 롤백: 커밋 되돌리기
MD
mkdir -p docs/decisions
cat > docs/decisions/ADR-001-2026-09-20-main-birth-year-validation-location.md <<'MD'
# ADR-001: 생년 검증을 서비스가 아닌 static 검증기에 둔다

## 상태
Accepted

## 날짜
2026-09-20

## 배경
생년 범위 검증을 ProfileService.save 안에 두면 테스트가 서비스 전체를 세워야 했다.

## 결정
IO 없는 static 메서드 BirthYearValidator.validate로 분리한다.

## 검토한 대안
### 서비스 메서드 안의 if
단순하지만 테스트가 무거워진다.

## 결과와 비용
검증기 파일 하나가 늘었다.

## 참고 자료
없음
MD
git add -A && git commit -qm "bio 계획 승인, 기존 ADR"
