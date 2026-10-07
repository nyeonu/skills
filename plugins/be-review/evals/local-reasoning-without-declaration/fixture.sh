#!/usr/bin/env bash
# 평가용 픽스처. 빈 작업 공간에 git 저장소를 만들고, 기준 커밋 위에 리뷰 대상 변경을 올린다.
# 리뷰 세션에는 Bash가 없으므로 변경 내용을 CHANGES.diff 파일로도 남긴다.
set -euo pipefail
export GIT_AUTHOR_NAME=eval GIT_AUTHOR_EMAIL=eval@example.com GIT_COMMITTER_NAME=eval GIT_COMMITTER_EMAIL=eval@example.com
git init -q -b main .

mkdir -p src/main/java/com/example/post src/test/java/com/example/post
cat > build.gradle <<'EOF'
plugins { id 'java' }
repositories { mavenCentral() }
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webflux:3.3.4'
    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'
    testImplementation 'org.mockito:mockito-core:5.12.0'
    testImplementation 'io.projectreactor:reactor-test:3.6.10'
}
test { useJUnitPlatform() }
EOF
cat > src/main/java/com/example/post/PostDTO.java <<'EOF'
package com.example.post;

import java.util.UUID;

public record PostDTO(UUID id, UUID boardId, boolean membersOnly, String title, String body) {}
EOF
cat > src/main/java/com/example/post/BoardDTO.java <<'EOF'
package com.example.post;

import java.util.UUID;

public record BoardDTO(UUID id, UUID artistId, boolean hidden) {}
EOF
cat > src/main/java/com/example/post/UserDTO.java <<'EOF'
package com.example.post;

import java.util.Set;
import java.util.UUID;

public record UserDTO(UUID id, Set<String> roles) {
    public boolean hasAdminRole() {
        return roles.contains("ADMIN");
    }
}
EOF
cat > src/main/java/com/example/post/PostRepository.java <<'EOF'
package com.example.post;

import java.util.UUID;
import reactor.core.publisher.Mono;

public interface PostRepository {
    Mono<PostDTO> findById(UUID id);
}
EOF
cat > src/main/java/com/example/post/BoardRepository.java <<'EOF'
package com.example.post;

import java.util.UUID;
import reactor.core.publisher.Mono;

public interface BoardRepository {
    Mono<BoardDTO> findById(UUID id);
}
EOF
cat > src/main/java/com/example/post/MembershipClient.java <<'EOF'
package com.example.post;

import java.util.UUID;
import reactor.core.publisher.Mono;

/** 외부 멤버십 서비스 HTTP 클라이언트 */
public interface MembershipClient {
    Mono<Boolean> isMember(UUID userId, UUID artistId);
}
EOF
cat > src/main/java/com/example/post/PostNotFoundException.java <<'EOF'
package com.example.post;

import java.util.UUID;

public class PostNotFoundException extends RuntimeException {
    public PostNotFoundException(UUID postId) {
        super("post not found: " + postId);
    }
}
EOF
cat > src/main/java/com/example/post/AccessDeniedException.java <<'EOF'
package com.example.post;

import java.util.UUID;

public class AccessDeniedException extends RuntimeException {
    public AccessDeniedException(UUID postId) {
        super("access denied: " + postId);
    }
}
EOF
cat > src/main/java/com/example/post/PostService.java <<'EOF'
package com.example.post;

import java.util.UUID;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class PostService {

    private final PostRepository postRepository;

    public PostService(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    public Mono<PostDTO> getPost(UUID postId, UserDTO user) {
        return postRepository.findById(postId)
            .switchIfEmpty(Mono.error(new PostNotFoundException(postId)));
    }
}
EOF
cat > src/test/java/com/example/post/PostServiceTest.java <<'EOF'
package com.example.post;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class PostServiceTest {

    private final PostRepository postRepository = mock(PostRepository.class);
    private final PostService service = new PostService(postRepository);

    @Test
    @DisplayName("존재하는 글 id로 조회하면 그 글을 돌려준다")
    void returnsPostWhenFound() {
        UUID postId = UUID.randomUUID();
        PostDTO post = new PostDTO(postId, UUID.randomUUID(), false, "제목", "본문");
        when(postRepository.findById(postId)).thenReturn(Mono.just(post));

        StepVerifier.create(service.getPost(postId, new UserDTO(UUID.randomUUID(), Set.of("USER"))))
            .expectNext(post)
            .verifyComplete();
    }

    @Test
    @DisplayName("없는 글 id로 조회하면 PostNotFoundException으로 실패한다")
    void failsWhenMissing() {
        UUID postId = UUID.randomUUID();
        when(postRepository.findById(postId)).thenReturn(Mono.empty());

        StepVerifier.create(service.getPost(postId, new UserDTO(UUID.randomUUID(), Set.of("USER"))))
            .expectError(PostNotFoundException.class)
            .verify();
    }
}
EOF

git add -A && git commit -qm "기준 코드"

cat > src/main/java/com/example/post/PostService.java <<'EOF'
package com.example.post;

import java.util.UUID;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Mono;

@Service
public class PostService {

    private final PostRepository postRepository;
    private final BoardRepository boardRepository;
    private final MembershipClient membershipClient;

    public PostService(PostRepository postRepository,
                       BoardRepository boardRepository,
                       MembershipClient membershipClient) {
        this.postRepository = postRepository;
        this.boardRepository = boardRepository;
        this.membershipClient = membershipClient;
    }

    public Mono<PostDTO> getPost(UUID postId, UserDTO user) {
        return postRepository.findById(postId)
            .switchIfEmpty(Mono.error(new PostNotFoundException(postId)))
            .flatMap(post -> boardRepository.findById(post.boardId())
                .flatMap(board -> membershipClient.isMember(user.id(), board.artistId())
                    .flatMap(member -> {
                        if (board.hidden() && !user.hasAdminRole()) {
                            return Mono.error(new AccessDeniedException(postId));
                        }
                        if (post.membersOnly() && !member && !user.hasAdminRole()) {
                            return Mono.error(new AccessDeniedException(postId));
                        }
                        return Mono.just(post);
                    })));
    }
}
EOF

cat > src/test/java/com/example/post/PostServiceTest.java <<'EOF'
package com.example.post;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;

class PostServiceTest {

    private final PostRepository postRepository = mock(PostRepository.class);
    private final BoardRepository boardRepository = mock(BoardRepository.class);
    private final MembershipClient membershipClient = mock(MembershipClient.class);
    private final PostService service = new PostService(postRepository, boardRepository, membershipClient);

    @Test
    @DisplayName("존재하는 글 id로 조회하면 그 글을 돌려준다")
    void returnsPostWhenFound() {
        UUID postId = UUID.randomUUID();
        UUID boardId = UUID.randomUUID();
        PostDTO post = new PostDTO(postId, boardId, false, "제목", "본문");
        when(postRepository.findById(postId)).thenReturn(Mono.just(post));
        when(boardRepository.findById(boardId)).thenReturn(Mono.just(new BoardDTO(boardId, UUID.randomUUID(), false)));
        when(membershipClient.isMember(any(), any())).thenReturn(Mono.just(false));

        StepVerifier.create(service.getPost(postId, new UserDTO(UUID.randomUUID(), Set.of("USER"))))
            .expectNext(post)
            .verifyComplete();
    }

    @Test
    @DisplayName("없는 글 id로 조회하면 PostNotFoundException으로 실패한다")
    void failsWhenMissing() {
        UUID postId = UUID.randomUUID();
        when(postRepository.findById(postId)).thenReturn(Mono.empty());

        StepVerifier.create(service.getPost(postId, new UserDTO(UUID.randomUUID(), Set.of("USER"))))
            .expectError(PostNotFoundException.class)
            .verify();
    }
}
EOF

git add -A && git diff --cached > CHANGES.diff && git commit -qm "숨김 게시판·멤버십 전용 글 접근 제한"
