#!/usr/bin/env bash
# 평가용 픽스처. 빈 작업 공간에 git 저장소를 만들고, 기준 커밋 위에 리뷰 대상 변경을 올린다.
# 리뷰 세션에는 Bash가 없으므로 변경 내용을 CHANGES.diff 파일로도 남긴다.
set -euo pipefail
export GIT_AUTHOR_NAME=eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main .

mkdir -p src/main/java/com/example/auth
cat > build.gradle <<'EOF'
plugins { id 'java' }
repositories { mavenCentral() }
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web:3.3.4'
    implementation 'org.springframework.boot:spring-boot-starter-jdbc:3.3.4'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'
}
test { useJUnitPlatform() }
EOF
cat > src/main/java/com/example/auth/UserRepository.java <<'EOF'
package com.example.auth;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository {
    Optional<UUID> findIdByEmail(String email);
    void updatePasswordHash(UUID userId, String passwordHash);
}
EOF
cat > src/main/java/com/example/auth/PasswordHasher.java <<'EOF'
package com.example.auth;

/** Argon2id 기반 해시. 구현은 설정에서 주입된다. */
public interface PasswordHasher {
    String hash(String rawPassword);
}
EOF
cat > src/main/java/com/example/auth/MailService.java <<'EOF'
package com.example.auth;

public interface MailService {
    void send(String to, String subject, String body);
}
EOF

git add -A && git commit -qm "기준 코드"

cat > src/main/java/com/example/auth/PasswordResetController.java <<'EOF'
package com.example.auth;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth/password-reset")
public class PasswordResetController {

    private static final Logger log = LoggerFactory.getLogger(PasswordResetController.class);

    private final JdbcTemplate jdbcTemplate;
    private final UserRepository userRepository;
    private final MailService mailService;
    private final Map<String, UUID> tokens = new ConcurrentHashMap<>();

    public PasswordResetController(JdbcTemplate jdbcTemplate,
                                   UserRepository userRepository,
                                   MailService mailService) {
        this.jdbcTemplate = jdbcTemplate;
        this.userRepository = userRepository;
        this.mailService = mailService;
    }

    @PostMapping("/request")
    public void request(@RequestParam String email) {
        UUID userId = jdbcTemplate.queryForObject(
            "SELECT id FROM users WHERE email = '" + email + "'", UUID.class);
        String token = UUID.randomUUID().toString();
        tokens.put(token, userId);
        log.info("password reset requested for {} token={}", email, token);
        mailService.send(email, "비밀번호 재설정", "https://example.com/reset?token=" + token);
    }

    @PostMapping("/confirm")
    public void confirm(@RequestParam String token, @RequestParam String newPassword) {
        UUID userId = tokens.get(token);
        if (userId == null) {
            throw new IllegalArgumentException("invalid token: " + token);
        }
        userRepository.updatePasswordHash(userId, newPassword);
    }
}
EOF

git add -A && git diff --cached > CHANGES.diff && git commit -qm "비밀번호 재설정 엔드포인트 추가"
