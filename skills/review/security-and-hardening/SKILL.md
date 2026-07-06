---
name: security-and-hardening
description: 코드를 보안 취약점으로부터 강화(hardening)한다. 사용자 입력 처리, 인증(authentication), 데이터 저장, 외부 연동을 다룰 때 사용한다. 신뢰할 수 없는 데이터를 받거나, 사용자 세션을 관리하거나, 서드파티 서비스와 상호작용하는 기능을 만들 때 입력 검증과 OWASP 기준의 보안 점검을 위해 사용한다.
---

# 보안 및 하드닝 (Security and Hardening)

## 개요

웹 애플리케이션을 위한 보안 우선(security-first) 개발 관행이다. 모든 외부 입력은 적대적인 것으로, 모든 시크릿(secret)은 신성한 것으로, 모든 인가(authorization) 검사는 필수적인 것으로 취급하라. 보안은 하나의 단계가 아니다 — 사용자 데이터, 인증, 외부 시스템을 다루는 모든 코드 라인에 적용되는 제약 조건이다.

## 사용 시점

- 사용자 입력을 받는 모든 것을 만들 때
- 인증(authentication) 또는 인가(authorization)를 구현할 때
- 민감한 데이터를 저장하거나 전송할 때
- 외부 API나 서비스와 연동할 때
- 파일 업로드, 웹훅(webhook), 콜백을 추가할 때
- 결제 또는 개인식별정보(PII) 데이터를 처리할 때

## 3단계 경계 시스템 (The Three-Tier Boundary System)

### 항상 할 것 (예외 없음)

- **모든 외부 입력을 검증**하라 — 시스템 경계에서(API 라우트, 폼 핸들러)
- **모든 데이터베이스 쿼리를 파라미터화**하라 — 사용자 입력을 SQL에 절대 문자열로 이어붙이지 말 것
- **출력을 인코딩**하여 XSS를 방지하라 (프레임워크의 자동 이스케이프를 사용하고, 우회하지 말 것)
- **HTTPS를 사용**하라 — 모든 외부 통신에 대해
- **비밀번호를 해시**하라 — bcrypt/scrypt/argon2 사용 (평문 저장 절대 금지)
- **보안 헤더를 설정**하라 (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- **세션에는 httpOnly, secure, sameSite 쿠키를 사용**하라
- **`npm audit`을 실행**하라 (또는 이에 준하는 도구) — 모든 릴리스 전에

### 먼저 물어볼 것 (사람의 승인 필요)

- 새 인증 플로우 추가 또는 인증 로직 변경
- 새로운 범주의 민감 데이터(PII, 결제 정보) 저장
- 새 외부 서비스 연동 추가
- CORS 설정 변경
- 파일 업로드 핸들러 추가
- 레이트 리미팅(rate limiting) 또는 스로틀링 수정
- 상승된 권한이나 역할(role) 부여

### 절대 하지 말 것

- **시크릿을 버전 관리에 절대 커밋하지 말 것** (API 키, 비밀번호, 토큰)
- **민감한 데이터를 절대 로깅하지 말 것** (비밀번호, 토큰, 전체 신용카드 번호)
- **클라이언트 측 검증을 보안 경계로 절대 신뢰하지 말 것**
- **편의를 위해 보안 헤더를 절대 비활성화하지 말 것**
- **사용자 제공 데이터와 함께 `eval()`이나 `innerHTML`을 절대 사용하지 말 것**
- **세션을 클라이언트에서 접근 가능한 저장소에 절대 저장하지 말 것** (인증 토큰의 localStorage 저장)
- **스택 트레이스나 내부 오류 세부 정보를 사용자에게 절대 노출하지 말 것**

## OWASP Top 10 예방

### 1. 인젝션 (SQL, NoSQL, OS 커맨드)

```typescript
// BAD: SQL injection via string concatenation
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// GOOD: Parameterized query
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// GOOD: ORM with parameterized input
const user = await prisma.user.findUnique({ where: { id: userId } });
```

### 2. 취약한 인증 (Broken Authentication)

```typescript
// Password hashing
import { hash, compare } from 'bcrypt';

const SALT_ROUNDS = 12;
const hashedPassword = await hash(plaintext, SALT_ROUNDS);
const isValid = await compare(plaintext, hashedPassword);

// Session management
app.use(session({
  secret: process.env.SESSION_SECRET,  // From environment, not code
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,     // Not accessible via JavaScript
    secure: true,       // HTTPS only
    sameSite: 'lax',    // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,  // 24 hours
  },
}));
```

### 3. 크로스 사이트 스크립팅 (XSS)

```typescript
// BAD: Rendering user input as HTML
element.innerHTML = userInput;

// GOOD: Use framework auto-escaping (React does this by default)
return <div>{userInput}</div>;

// If you MUST render HTML, sanitize first
import DOMPurify from 'dompurify';
const clean = DOMPurify.sanitize(userInput);
```

### 4. 취약한 접근 제어 (Broken Access Control)

```typescript
// Always check authorization, not just authentication
app.patch('/api/tasks/:id', authenticate, async (req, res) => {
  const task = await taskService.findById(req.params.id);

  // Check that the authenticated user owns this resource
  if (task.ownerId !== req.user.id) {
    return res.status(403).json({
      error: { code: 'FORBIDDEN', message: 'Not authorized to modify this task' }
    });
  }

  // Proceed with update
  const updated = await taskService.update(req.params.id, req.body);
  return res.json(updated);
});
```

### 5. 보안 설정 오류 (Security Misconfiguration)

```typescript
// Security headers (use helmet for Express)
import helmet from 'helmet';
app.use(helmet());

// Content Security Policy
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],  // Tighten if possible
    imgSrc: ["'self'", 'data:', 'https:'],
    connectSrc: ["'self'"],
  },
}));

// CORS — restrict to known origins
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || 'http://localhost:3000',
  credentials: true,
}));
```

### 6. 민감 데이터 노출 (Sensitive Data Exposure)

```typescript
// Never return sensitive fields in API responses
function sanitizeUser(user: UserRecord): PublicUser {
  const { passwordHash, resetToken, ...publicFields } = user;
  return publicFields;
}

// Use environment variables for secrets
const API_KEY = process.env.STRIPE_API_KEY;
if (!API_KEY) throw new Error('STRIPE_API_KEY not configured');
```

## 입력 검증 패턴

### 경계에서의 스키마 검증

```typescript
import { z } from 'zod';

const CreateTaskSchema = z.object({
  title: z.string().min(1).max(200).trim(),
  description: z.string().max(2000).optional(),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
  dueDate: z.string().datetime().optional(),
});

// Validate at the route handler
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: result.error.flatten(),
      },
    });
  }
  // result.data is now typed and validated
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

### 파일 업로드 안전성

```typescript
// Restrict file types and sizes
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_SIZE = 5 * 1024 * 1024; // 5MB

function validateUpload(file: UploadedFile) {
  if (!ALLOWED_TYPES.includes(file.mimetype)) {
    throw new ValidationError('File type not allowed');
  }
  if (file.size > MAX_SIZE) {
    throw new ValidationError('File too large (max 5MB)');
  }
  // Don't trust the file extension — check magic bytes if critical
}
```

## npm audit 결과 트리아지(triage)

모든 감사(audit) 결과가 즉각적인 조치를 요구하는 것은 아니다. 다음 의사결정 트리를 사용하라:

```
npm audit reports a vulnerability
├── Severity: critical or high
│   ├── Is the vulnerable code reachable in your app?
│   │   ├── YES --> Fix immediately (update, patch, or replace the dependency)
│   │   └── NO (dev-only dep, unused code path) --> Fix soon, but not a blocker
│   └── Is a fix available?
│       ├── YES --> Update to the patched version
│       └── NO --> Check for workarounds, consider replacing the dependency, or add to allowlist with a review date
├── Severity: moderate
│   ├── Reachable in production? --> Fix in the next release cycle
│   └── Dev-only? --> Fix when convenient, track in backlog
└── Severity: low
    └── Track and fix during regular dependency updates
```

**핵심 질문:**
- 취약한 함수가 실제로 코드 경로에서 호출되는가?
- 해당 의존성이 런타임 의존성인가, 개발 전용(dev-only)인가?
- 배포 컨텍스트를 고려할 때 해당 취약점이 실제로 악용 가능한가? (예: 클라이언트 전용 앱에서의 서버 사이드 취약점)

수정을 미룰 때는 그 이유를 문서화하고 재검토 날짜를 정하라.

## 레이트 리미팅 (Rate Limiting)

```typescript
import rateLimit from 'express-rate-limit';

// General API rate limit
app.use('/api/', rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,                   // 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
}));

// Stricter limit for auth endpoints
app.use('/api/auth/', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,  // 10 attempts per 15 minutes
}));
```

## 시크릿 관리 (Secrets Management)

```
.env files:
  ├── .env.example  → Committed (template with placeholder values)
  ├── .env          → NOT committed (contains real secrets)
  └── .env.local    → NOT committed (local overrides)

.gitignore must include:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

**커밋 전에 항상 확인하라:**
```bash
# Check for accidentally staged secrets
git diff --cached | grep -i "password\|secret\|api_key\|token"
```

## 보안 리뷰 체크리스트

```markdown
### 인증 (Authentication)
- [ ] 비밀번호를 bcrypt/scrypt/argon2로 해시 (솔트 라운드 ≥ 12)
- [ ] 세션 토큰은 httpOnly, secure, sameSite
- [ ] 로그인에 레이트 리미팅 적용
- [ ] 비밀번호 재설정 토큰에 만료 시간 설정

### 인가 (Authorization)
- [ ] 모든 엔드포인트가 사용자 권한을 확인
- [ ] 사용자는 자신의 리소스에만 접근 가능
- [ ] 관리자 작업은 관리자 역할 검증을 요구

### 입력 (Input)
- [ ] 모든 사용자 입력을 경계에서 검증
- [ ] SQL 쿼리는 파라미터화
- [ ] HTML 출력은 인코딩/이스케이프 처리

### 데이터 (Data)
- [ ] 코드나 버전 관리에 시크릿 없음
- [ ] API 응답에서 민감한 필드 제외
- [ ] PII는 저장 시 암호화 (해당되는 경우)

### 인프라 (Infrastructure)
- [ ] 보안 헤더 설정 완료 (CSP, HSTS 등)
- [ ] CORS를 알려진 오리진으로만 제한
- [ ] 의존성 취약점 감사 완료
- [ ] 오류 메시지가 내부 정보를 노출하지 않음
```
## 참고 (See Also)

상세 보안 체크리스트와 커밋 전 검증 단계는 `references/security-checklist.md`를 참고하라.

## 흔한 합리화 (Common Rationalizations)

| 합리화 | 현실 |
|---|---|
| "이건 내부 도구라 보안은 중요하지 않아" | 내부 도구도 침해당한다. 공격자는 가장 약한 고리를 노린다. |
| "보안은 나중에 추가하자" | 보안을 나중에 덧붙이는 것은 처음부터 넣는 것보다 10배 어렵다. 지금 추가하라. |
| "아무도 이걸 악용하려 하지 않을 거야" | 자동화된 스캐너가 찾아낸다. 은폐에 의한 보안(security by obscurity)은 보안이 아니다. |
| "프레임워크가 보안을 처리해줘" | 프레임워크는 도구를 제공할 뿐, 보장을 제공하지 않는다. 여전히 올바르게 사용해야 한다. |
| "이건 그냥 프로토타입이야" | 프로토타입은 프로덕션이 된다. 보안 습관은 첫날부터. |

## 위험 신호 (Red Flags)

- 사용자 입력이 데이터베이스 쿼리, 셸 커맨드, HTML 렌더링에 직접 전달됨
- 소스 코드나 커밋 히스토리에 시크릿 존재
- 인증 또는 인가 검사가 없는 API 엔드포인트
- CORS 설정 누락 또는 와일드카드(`*`) 오리진 사용
- 인증 엔드포인트에 레이트 리미팅 없음
- 스택 트레이스나 내부 오류가 사용자에게 노출됨
- 알려진 치명적(critical) 취약점을 가진 의존성

## 검증 (Verification)

보안 관련 코드를 구현한 후:

- [ ] `npm audit`에 치명적(critical) 또는 높음(high) 취약점 없음
- [ ] 소스 코드나 git 히스토리에 시크릿 없음
- [ ] 모든 사용자 입력이 시스템 경계에서 검증됨
- [ ] 보호된 모든 엔드포인트에서 인증과 인가를 확인
- [ ] 응답에 보안 헤더 존재 (브라우저 DevTools로 확인)
- [ ] 오류 응답이 내부 세부 정보를 노출하지 않음
- [ ] 인증 엔드포인트에 레이트 리미팅 활성화
