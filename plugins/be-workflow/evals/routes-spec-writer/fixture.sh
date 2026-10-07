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
