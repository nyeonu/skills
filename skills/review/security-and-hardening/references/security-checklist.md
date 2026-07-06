# 보안 체크리스트 (Security Checklist)

웹 애플리케이션 보안을 위한 빠른 참조 자료. `security-and-hardening` 스킬과 함께 사용한다.

## 목차

- [커밋 전 점검](#커밋-전-점검)
- [인증](#인증)
- [인가](#인가)
- [입력 검증](#입력-검증)
- [보안 헤더](#보안-헤더)
- [CORS 설정](#cors-설정)
- [데이터 보호](#데이터-보호)
- [의존성 보안](#의존성-보안)
- [오류 처리](#오류-처리)
- [OWASP Top 10 빠른 참조](#owasp-top-10-빠른-참조)

## 커밋 전 점검

- [ ] 코드에 시크릿 없음 (`git diff --cached | grep -i "password\|secret\|api_key\|token"`)
- [ ] `.gitignore`가 다음을 포함: `.env`, `.env.local`, `*.pem`, `*.key`
- [ ] `.env.example`은 플레이스홀더 값 사용 (실제 시크릿 금지)

## 인증

- [ ] 비밀번호는 bcrypt(라운드 12 이상), scrypt 또는 argon2로 해시
- [ ] 세션 쿠키: `httpOnly`, `secure`, `sameSite: 'lax'`
- [ ] 세션 만료 설정 (합리적인 max-age)
- [ ] 로그인 엔드포인트에 레이트 리미팅 (15분당 10회 이하 시도)
- [ ] 비밀번호 재설정 토큰: 시간 제한(1시간 이하), 1회용
- [ ] 반복 실패 시 계정 잠금 (선택 사항, 알림과 함께)
- [ ] 민감한 작업에 다단계 인증(MFA) 지원 (선택 사항이지만 권장)

## 인가

- [ ] 보호된 모든 엔드포인트가 인증을 확인
- [ ] 모든 리소스 접근 시 소유권/역할을 확인 (IDOR 방지)
- [ ] 관리자 엔드포인트는 관리자 역할 검증을 요구
- [ ] API 키는 필요 최소한의 권한으로 범위 제한
- [ ] JWT 토큰 검증 (서명, 만료, 발급자)

## 입력 검증

- [ ] 모든 사용자 입력을 시스템 경계에서 검증 (API 라우트, 폼 핸들러)
- [ ] 검증은 허용 목록(allowlist) 사용 (거부 목록 아님)
- [ ] 문자열 길이 제한 (최소/최대)
- [ ] 숫자 범위 검증
- [ ] 이메일, URL, 날짜 형식은 적절한 라이브러리로 검증
- [ ] 파일 업로드: 유형 제한, 크기 제한, 내용 검증
- [ ] SQL 쿼리는 파라미터화 (문자열 이어붙이기 금지)
- [ ] HTML 출력은 인코딩 (프레임워크 자동 이스케이프 사용)
- [ ] 리다이렉트 전 URL 검증 (오픈 리다이렉트 방지)

## 보안 헤더

```
Content-Security-Policy: default-src 'self'; script-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (disabled, rely on CSP)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

## CORS 설정

```typescript
// Restrictive (recommended)
cors({
  origin: ['https://yourdomain.com', 'https://app.yourdomain.com'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
})

// NEVER use in production:
cors({ origin: '*' })  // Allows any origin
```

## 데이터 보호

- [ ] API 응답에서 민감한 필드 제외 (`passwordHash`, `resetToken` 등)
- [ ] 민감한 데이터를 로깅하지 않음 (비밀번호, 토큰, 전체 신용카드 번호)
- [ ] PII는 저장 시 암호화 (규제상 요구되는 경우)
- [ ] 모든 외부 통신에 HTTPS 사용
- [ ] 데이터베이스 백업 암호화

## 의존성 보안

```bash
# Audit dependencies
npm audit

# Fix automatically where possible
npm audit fix

# Check for critical vulnerabilities
npm audit --audit-level=critical

# Keep dependencies updated
npx npm-check-updates
```

## 오류 처리

```typescript
// Production: generic error, no internals
res.status(500).json({
  error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' }
});

// NEVER in production:
res.status(500).json({
  error: err.message,
  stack: err.stack,         // Exposes internals
  query: err.sql,           // Exposes database details
});
```

## OWASP Top 10 빠른 참조

| # | 취약점 | 예방 방법 |
|---|---|---|
| 1 | 취약한 접근 제어 (Broken Access Control) | 모든 엔드포인트에서 인증/인가 검사, 소유권 확인 |
| 2 | 암호화 실패 (Cryptographic Failures) | HTTPS, 강력한 해싱, 코드에 시크릿 금지 |
| 3 | 인젝션 (Injection) | 파라미터화된 쿼리, 입력 검증 |
| 4 | 안전하지 않은 설계 (Insecure Design) | 위협 모델링, 명세 주도 개발 |
| 5 | 보안 설정 오류 (Security Misconfiguration) | 보안 헤더, 최소 권한, 의존성 감사 |
| 6 | 취약한 컴포넌트 (Vulnerable Components) | `npm audit`, 의존성 최신 유지, 의존성 최소화 |
| 7 | 인증 실패 (Auth Failures) | 강력한 비밀번호, 레이트 리미팅, 세션 관리 |
| 8 | 데이터 무결성 실패 (Data Integrity Failures) | 업데이트/의존성 검증, 서명된 아티팩트 |
| 9 | 로깅 실패 (Logging Failures) | 보안 이벤트 로깅, 시크릿은 로깅 금지 |
| 10 | SSRF | URL 검증/허용 목록, 아웃바운드 요청 제한 |
