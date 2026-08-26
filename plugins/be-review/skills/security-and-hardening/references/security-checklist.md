# 보안 체크리스트

웹 애플리케이션 보안을 위한 빠른 참조 자료. `security-and-hardening` 스킬과 함께 사용한다.

코드 예시는 Node/Express·TypeScript 기준이다 — 다른 스택(Spring/Java, Django/Python 등)이면 같은 개념의 그 생태계 표준 수단으로 치환해 점검한다. 괄호 안 수치(시도 횟수, 만료 시간 등)는 공식 표준이 아니라 프로젝트 기본값 예시다 — 프로젝트에 정해진 값이 있으면 그 값이 기준이다.

## 출처 메타데이터

- 공식 출처: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- 확인일: 2026-08-27
- 출처 버전: OWASP/CheatSheetSeries `cheatsheets/Password_Storage_Cheat_Sheet.md` commit `a6eb0c6a95f5b056d057d3b6e4e6a3c6b20b8597` (2026-06-24)
- 추적하는 기준: 알고리즘 우선순위(Argon2id → scrypt → bcrypt 레거시 → PBKDF2/FIPS), Argon2id 최소 파라미터(19MiB / t=2 / p=1), bcrypt 최소 work factor 10·72바이트 제한
- 상태: current    <!-- current | needs_review -->

**신선도 확인 규칙**: 이 파일을 읽는 실행 주체는 `확인일`이 작업일 기준 30일 이내면 위 기록값을 쓴다. 30일을 넘었으면 OWASP/CheatSheetSeries 원본 파일의 최신 commit SHA가 기록과 같은지만 확인한다. 같으면 현재 작업에 기록값을 쓰고 확인 결과를 보고한다. 다르면 수치를 자동 수정하지 말고 `needs_review`와 변경 검토 필요를 보고한다. 현재 작업이 이 스킬 저장소의 유지보수라면 같은 결과를 두 참고자료 사본의 `확인일`·`출처 버전`·`상태`와 `CUSTOMIZATIONS.md`에 함께 반영한다. 공식 출처를 확인할 수 없으면 검증 공백을 보고하고, 새 운영 기본값을 현행 공식 기준으로 단정하지 않는다.

## 목차

- [커밋 전 점검](#커밋-전-점검)
- [인증](#인증)
- [인가](#인가)
- [입력 검증](#입력-검증)
- [보안 헤더](#보안-헤더)
- [CORS 설정](#cors-설정)
- [레이트 리미팅](#레이트-리미팅)
- [데이터 보호](#데이터-보호)
- [의존성 보안](#의존성-보안)
- [오류 처리](#오류-처리)
- [OWASP Top 10 빠른 참조](#owasp-top-10-빠른-참조)

## 커밋 전 점검

- [ ] 코드에 시크릿 없음 (`git diff --cached | grep -i "password\|secret\|api_key\|token"`)
- [ ] `.gitignore`가 다음을 포함: `.env`, `.env.local`, `*.pem`, `*.key`
- [ ] `.env.example`은 플레이스홀더 값 사용 (실제 시크릿 금지)

## 인증

- [ ] 비밀번호 해시: **신규 시스템은 Argon2id 우선** (OWASP 최소: 메모리 19MiB, 반복 2, 병렬화 1). Argon2id 불가 시 scrypt. bcrypt는 레거시 호환용 — OWASP 공식 최소 work factor 10 이상 + 서버 응답 시간 측정으로 값 결정, 72바이트 입력 제한 인지. FIPS-140 요구 시 PBKDF2. 기준: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- [ ] 세션 쿠키: `httpOnly`, `secure`, `sameSite: 'lax'`
- [ ] 세션 만료 설정 (합리적인 max-age)
- [ ] 로그인 엔드포인트에 레이트 리미팅 (예시 기본값: 15분당 10회 이하 시도)
- [ ] 비밀번호 재설정 토큰: 시간 제한(예시 기본값: 1시간 이하), 1회용
- [ ] 반복 실패 시 계정 잠금 (선택 사항, 알림과 함께)
- [ ] 민감한 작업에 다단계 인증(MFA) 지원 (선택 사항이지만 권장)

세션 설정 예시:

```typescript
app.use(session({
  secret: process.env.SESSION_SECRET,  // 환경 변수에서, 코드에 넣지 않는다
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,     // JavaScript로 접근 불가
    secure: true,       // HTTPS 전용
    sameSite: 'lax',    // CSRF 완화
    maxAge: 24 * 60 * 60 * 1000,  // 프로젝트 기본값 예시: 24시간
  },
}));
```

## 인가

- [ ] 보호된 모든 엔드포인트가 인증을 확인
- [ ] 모든 리소스 접근 시 소유권/역할을 확인 (IDOR 방지)
- [ ] 관리자 엔드포인트는 관리자 역할 검증을 요구
- [ ] API 키는 필요 최소한의 권한으로 범위 제한
- [ ] JWT 토큰 검증 (서명, 만료, 발급자)

소유권 확인 예시 (인증만으로 끝내지 않는다):

```typescript
app.patch('/api/tasks/:id', authenticate, async (req, res) => {
  const task = await taskService.findById(req.params.id);
  if (task.ownerId !== req.user.id) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Not authorized to modify this task' }
    });
  }
  const updated = await taskService.update(req.params.id, req.body);
  return res.json(updated);
});
```

## 입력 검증

- [ ] 모든 사용자 입력을 시스템 경계에서 검증 (API 라우트, 폼 핸들러)
- [ ] 검증은 허용 목록(allowlist) 사용 (거부 목록 아님)
- [ ] 문자열 길이 제한 (최소/최대), 숫자 범위 검증
- [ ] 이메일, URL, 날짜 형식은 적절한 라이브러리로 검증
- [ ] 파일 업로드: 유형 제한, 크기 제한, 내용 검증 (확장자를 신뢰하지 않는다 — 중요하면 매직 바이트 확인)
- [ ] SQL 쿼리는 파라미터화 (문자열 이어붙이기 금지)
- [ ] HTML 출력은 인코딩 (프레임워크 자동 이스케이프 사용)
- [ ] 리다이렉트 전 URL 검증 (오픈 리다이렉트 방지)

경계에서의 스키마 검증 예시:

```typescript
import { z } from 'zod';

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
});

app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: { code: 'VALIDATION_ERROR', details: result.error.flatten() },
    });
  }
  const task = await taskService.create(result.data);  // 검증·타입 확정된 데이터
  return res.status(201).json(task);
});
```

## 보안 헤더

```
Content-Security-Policy: default-src 'self'; script-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (비활성 — CSP에 의존)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## CORS 설정

```typescript
// 제한적 설정 (권장)
cors({
  origin: ['https://yourdomain.com', 'https://app.yourdomain.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
})

// 프로덕션 금지:
cors({ origin: '*' })  // 모든 오리진 허용
```

## 레이트 리미팅

아래 수치(창 크기, 허용 횟수)는 공식 표준이 아니라 프로젝트 기본값 예시다. 트래픽 특성에 맞게 조정하고, 조정한 값은 근거와 함께 기록한다.

```typescript
import rateLimit from 'express-rate-limit';

app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000,  // 15분
  max: 100,                  // 창당 100회
  standardHeaders: true,
  legacyHeaders: false,
}));

// 인증 엔드포인트는 더 엄격하게
app.use('/api/auth/', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
}));
```

## 데이터 보호

- [ ] API 응답에서 민감한 필드 제외 (`passwordHash`, `resetToken` 등)
- [ ] 민감한 데이터를 로깅하지 않음 (비밀번호, 토큰, 전체 신용카드 번호)
- [ ] PII는 저장 시 암호화 (규제상 요구되는 경우)
- [ ] 모든 외부 통신에 HTTPS 사용
- [ ] 데이터베이스 백업 암호화

## 의존성 보안

저장소의 패키지 생태계에 맞는 감사 도구를 쓴다. CI에 이미 감사 단계가 있으면 그 기준을 따른다.

| 생태계 | 도구 예시 |
|---|---|
| Node | `npm audit` / `pnpm audit` |
| JVM (Gradle/Maven) | OWASP Dependency-Check, 조직 표준 SCA 도구 |
| Python | `pip-audit` |

결과 트리아지 — 심각도만으로 판단하지 않는다:

```
취약점 보고됨
├── critical/high
│   ├── 취약한 코드가 실제 코드 경로에서 도달 가능한가?
│   │   ├── YES → 즉시 수정 (업데이트·패치·의존성 교체)
│   │   └── NO (dev 전용, 미사용 경로) → 곧 수정하되 차단 사유는 아님
│   └── 패치가 없으면 → 우회책 검토, 의존성 교체 검토, 또는 재검토 날짜와 함께 허용 목록에 기록
├── moderate → 프로덕션 도달 가능하면 다음 릴리스 주기에 수정, dev 전용이면 백로그
└── low → 정기 의존성 업데이트 때 수정
```

수정을 미룰 때는 이유를 문서화하고 재검토 날짜를 정한다.

## 오류 처리

```typescript
// 프로덕션: 일반적인 오류, 내부 정보 없음
res.status(500).json({
  error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' }
});

// 프로덕션 금지:
res.status(500).json({
  error: err.message,
  stack: err.stack,   // 내부 구조 노출
  query: err.sql,     // 데이터베이스 세부 노출
});
```

## OWASP Top 10 빠른 참조

| # | 취약점 | 예방 방법 |
|---|---|---|
| 1 | 취약한 접근 제어 (Broken Access Control) | 모든 엔드포인트에서 인증/인가 검사, 소유권 확인 |
| 2 | 암호화 실패 (Cryptographic Failures) | HTTPS, 강력한 해싱(Argon2id 우선), 코드에 시크릿 금지 |
| 3 | 인젝션 (Injection) | 파라미터화된 쿼리, 입력 검증 |
| 4 | 안전하지 않은 설계 (Insecure Design) | 위협 모델링, 스펙 기반 개발 |
| 5 | 보안 설정 오류 (Security Misconfiguration) | 보안 헤더, 최소 권한, 의존성 감사 |
| 6 | 취약한 컴포넌트 (Vulnerable Components) | 생태계 표준 감사 도구, 의존성 최신 유지·최소화 |
| 7 | 인증 실패 (Auth Failures) | 강력한 비밀번호 저장, 레이트 리미팅, 세션 관리 |
| 8 | 데이터 무결성 실패 (Data Integrity Failures) | 업데이트/의존성 검증, 서명된 아티팩트 |
| 9 | 로깅 실패 (Logging Failures) | 보안 이벤트 로깅, 시크릿은 로깅 금지 |
| 10 | SSRF | URL 검증/허용 목록, 아웃바운드 요청 제한 |
