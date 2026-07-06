---
name: performance-optimization
description: 애플리케이션 성능을 최적화한다. 성능 요구사항이 존재할 때, 성능 회귀(regression)가 의심될 때, 또는 Core Web Vitals나 로드 시간 개선이 필요할 때 사용한다. 프로파일링 결과 수정이 필요한 병목이 드러났을 때 사용한다.
---

# 성능 최적화

## 개요

최적화하기 전에 먼저 측정하라. 측정 없는 성능 작업은 추측일 뿐이다 — 그리고 추측은 정작 중요한 것은 개선하지 못한 채 복잡성만 더하는 성급한 최적화(premature optimization)로 이어진다. 먼저 프로파일링하고, 실제 병목을 찾아내고, 수정한 뒤, 다시 측정하라. 측정으로 중요하다고 입증된 것만 최적화하라.

## 사용 시점

- 스펙에 성능 요구사항이 존재할 때 (로드 시간 예산, 응답 시간 SLA)
- 사용자 또는 모니터링에서 느린 동작이 보고될 때
- Core Web Vitals 점수가 기준치 미만일 때
- 어떤 변경이 회귀를 유발했다고 의심될 때
- 대용량 데이터셋이나 높은 트래픽을 처리하는 기능을 구현할 때

**사용하지 말아야 할 때:** 문제의 증거가 확보되기 전에는 최적화하지 마라. 성급한 최적화는 얻는 성능보다 더 큰 비용의 복잡성을 더한다.

## Core Web Vitals 목표치

| 지표 | 좋음 | 개선 필요 | 나쁨 |
|--------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## 최적화 워크플로

```
1. MEASURE  → 실제 데이터로 기준선(baseline) 수립
2. IDENTIFY → (가정이 아닌) 실제 병목 식별
3. FIX      → 특정된 병목을 해결
4. VERIFY   → 다시 측정하여 개선 확인
5. GUARD    → 회귀 방지를 위한 모니터링 또는 테스트 추가
```

### 1단계: 측정

상호 보완적인 두 가지 접근 방식 — 둘 다 사용하라:

- **합성 측정(Synthetic) (Lighthouse, DevTools Performance 탭):** 통제된 조건, 재현 가능. CI에서의 회귀 감지와 특정 이슈 격리에 최적.
- **RUM (web-vitals 라이브러리, CrUX):** 실제 환경에서의 실사용자 데이터. 수정이 실제로 사용자 경험을 개선했는지 검증하려면 필수.

**프론트엔드:**
```bash
# Synthetic: Lighthouse in Chrome DevTools (or CI)
# Chrome DevTools → Performance tab → Record
# Chrome DevTools MCP → Performance trace

# RUM: Web Vitals library in code
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

**백엔드:**
```bash
# Response time logging
# Application Performance Monitoring (APM)
# Database query logging with timing

# Simple timing
console.time('db-query');
const result = await db.query(...);
console.timeEnd('db-query');
```

### 어디서부터 측정을 시작할까

증상을 기준으로 무엇을 먼저 측정할지 결정하라:

```
무엇이 느린가?
├── 첫 페이지 로드
│   ├── 큰 번들? --> 번들 크기 측정, 코드 분할(code splitting) 확인
│   ├── 느린 서버 응답? --> DevTools Network 워터폴에서 TTFB 측정
│   │   ├── DNS가 오래 걸림? --> 알려진 오리진에 dns-prefetch / preconnect 추가
│   │   ├── TCP/TLS가 오래 걸림? --> HTTP/2 활성화, 엣지 배포 확인, keep-alive
│   │   └── 대기(서버)가 오래 걸림? --> 백엔드 프로파일링, 쿼리와 캐싱 확인
│   └── 렌더링 차단 리소스? --> Network 워터폴에서 CSS/JS 차단 여부 확인
├── 인터랙션이 굼뜨게 느껴짐
│   ├── 클릭 시 UI가 멈춤? --> 메인 스레드 프로파일링, 긴 작업(>50ms) 탐색
│   ├── 폼 입력 지연? --> 리렌더링, 제어 컴포넌트(controlled component) 오버헤드 확인
│   └── 애니메이션 버벅임(jank)? --> 레이아웃 스래싱, 강제 리플로우 확인
├── 내비게이션 후 페이지
│   ├── 데이터 로딩? --> API 응답 시간 측정, 워터폴 여부 확인
│   └── 클라이언트 렌더링? --> 컴포넌트 렌더링 시간 프로파일링, N+1 페치 확인
└── 백엔드 / API
    ├── 단일 엔드포인트만 느림? --> 데이터베이스 쿼리 프로파일링, 인덱스 확인
    ├── 모든 엔드포인트가 느림? --> 커넥션 풀, 메모리, CPU 확인
    └── 간헐적으로 느림? --> 락 경합, GC 일시 정지, 외부 의존성 확인
```

### 2단계: 병목 식별

카테고리별 흔한 병목:

**프론트엔드:**

| 증상 | 유력한 원인 | 조사 방법 |
|---------|-------------|---------------|
| 느린 LCP | 큰 이미지, 렌더링 차단 리소스, 느린 서버 | Network 워터폴, 이미지 크기 확인 |
| 높은 CLS | 크기(dimension) 미지정 이미지, 늦게 로드되는 콘텐츠, 폰트 전환에 따른 밀림 | 레이아웃 이동(layout shift) 어트리뷰션 확인 |
| 나쁜 INP | 메인 스레드의 무거운 JavaScript, 대규모 DOM 업데이트 | Performance 트레이스에서 긴 작업(long task) 확인 |
| 느린 초기 로드 | 큰 번들, 과다한 네트워크 요청 | 번들 크기, 코드 분할 확인 |

**백엔드:**

| 증상 | 유력한 원인 | 조사 방법 |
|---------|-------------|---------------|
| 느린 API 응답 | N+1 쿼리, 누락된 인덱스, 최적화되지 않은 쿼리 | 데이터베이스 쿼리 로그 확인 |
| 메모리 증가 | 누수된 참조, 무제한 캐시, 큰 페이로드 | 힙 스냅샷 분석 |
| CPU 스파이크 | 동기식 무거운 연산, 정규식 백트래킹 | CPU 프로파일링 |
| 높은 지연 시간(latency) | 캐싱 누락, 중복 연산, 네트워크 홉 | 스택 전반에 걸친 요청 트레이싱 |

### 3단계: 흔한 안티패턴 수정

#### N+1 쿼리 (백엔드)

```typescript
// BAD: N+1 — one query per task for the owner
const tasks = await db.tasks.findMany();
for (const task of tasks) {
  task.owner = await db.users.findUnique({ where: { id: task.ownerId } });
}

// GOOD: Single query with join/include
const tasks = await db.tasks.findMany({
  include: { owner: true },
});
```

#### 무제한 데이터 페칭

```typescript
// BAD: Fetching all records
const allTasks = await db.tasks.findMany();

// GOOD: Paginated with limits
const tasks = await db.tasks.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' },
});
```

#### 이미지 최적화 누락 (프론트엔드)

```html
<!-- BAD: No dimensions, no format optimization -->
<img src="/hero.jpg" />

<!-- GOOD: Hero / LCP image — art direction + resolution switching, high priority -->
<!--
  Two techniques combined:
  - Art direction (media): different crop/composition per breakpoint
  - Resolution switching (srcset + sizes): right file size per screen density
-->
<picture>
  <!-- Mobile: portrait crop (8:10) -->
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.avif 400w, /hero-mobile-800.avif 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/avif"
  />
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.webp 400w, /hero-mobile-800.webp 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/webp"
  />
  <!-- Desktop: landscape crop (2:1) -->
  <source
    srcset="/hero-800.avif 800w, /hero-1200.avif 1200w, /hero-1600.avif 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/avif"
  />
  <source
    srcset="/hero-800.webp 800w, /hero-1200.webp 1200w, /hero-1600.webp 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/webp"
  />
  <img
    src="/hero-desktop.jpg"
    width="1200"
    height="600"
    fetchpriority="high"
    alt="Hero image description"
  />
</picture>

<!-- GOOD: Below-the-fold image — lazy loaded + async decoding -->
<img
  src="/content.webp"
  width="800"
  height="400"
  loading="lazy"
  decoding="async"
  alt="Content image description"
/>
```

#### 불필요한 리렌더링 (React)

```tsx
// BAD: Creates new object on every render, causing children to re-render
function TaskList() {
  return <TaskFilters options={{ sortBy: 'date', order: 'desc' }} />;
}

// GOOD: Stable reference
const DEFAULT_OPTIONS = { sortBy: 'date', order: 'desc' } as const;
function TaskList() {
  return <TaskFilters options={DEFAULT_OPTIONS} />;
}

// Use React.memo for expensive components
const TaskItem = React.memo(function TaskItem({ task }: Props) {
  return <div>{/* expensive render */}</div>;
});

// Use useMemo for expensive computations
function TaskStats({ tasks }: Props) {
  const stats = useMemo(() => calculateStats(tasks), [tasks]);
  return <div>{stats.completed} / {stats.total}</div>;
}
```

#### 큰 번들 크기

```typescript
// Modern bundlers (Vite, webpack 5+) handle named imports with tree-shaking automatically,
// provided the dependency ships ESM and is marked `sideEffects: false` in package.json.
// Profile before changing import styles — the real gains come from splitting and lazy loading.

// GOOD: Dynamic import for heavy, rarely-used features
const ChartLibrary = lazy(() => import('./ChartLibrary'));

// GOOD: Route-level code splitting wrapped in Suspense
const SettingsPage = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <SettingsPage />
    </Suspense>
  );
}
```

#### 캐싱 누락 (백엔드)

```typescript
// Cache frequently-read, rarely-changed data
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes
let cachedConfig: AppConfig | null = null;
let cacheExpiry = 0;

async function getAppConfig(): Promise<AppConfig> {
  if (cachedConfig && Date.now() < cacheExpiry) {
    return cachedConfig;
  }
  cachedConfig = await db.config.findFirst();
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedConfig;
}

// HTTP caching headers for static assets
app.use('/static', express.static('public', {
  maxAge: '1y',           // Cache for 1 year
  immutable: true,        // Never revalidate (use content hashing in filenames)
}));

// Cache-Control for API responses
res.set('Cache-Control', 'public, max-age=300'); // 5 minutes
```

## 성능 예산 (Performance Budget)

예산을 설정하고 강제하라:

```
JavaScript bundle: < 200KB gzipped (initial load)
CSS: < 50KB gzipped
Images: < 200KB per image (above the fold)
Fonts: < 100KB total
API response time: < 200ms (p95)
Time to Interactive: < 3.5s on 4G
Lighthouse Performance score: ≥ 90
```

**CI에서 강제:**
```bash
# Bundle size check
npx bundlesize --config bundlesize.config.json

# Lighthouse CI
npx lhci autorun
```

## 참고

상세한 성능 체크리스트, 최적화 명령어, 안티패턴 레퍼런스는 `references/performance-checklist.md`를 참고하라.


## 흔한 합리화

| 합리화 | 현실 |
|---|---|
| "나중에 최적화할게요" | 성능 부채는 복리로 불어난다. 명백한 안티패턴은 지금 고치고, 마이크로 최적화는 미뤄라. |
| "제 컴퓨터에서는 빠른데요" | 당신의 컴퓨터는 사용자의 컴퓨터가 아니다. 대표성 있는 하드웨어와 네트워크에서 프로파일링하라. |
| "이 최적화는 자명해요" | 측정하지 않았다면 모르는 것이다. 먼저 프로파일링하라. |
| "사용자는 100ms를 못 느껴요" | 연구에 따르면 100ms의 지연은 전환율(conversion rate)에 영향을 미친다. 사용자는 생각보다 많이 알아챈다. |
| "프레임워크가 성능을 알아서 처리해요" | 프레임워크는 일부 문제를 예방하지만 N+1 쿼리나 과도한 번들 크기는 해결하지 못한다. |

## 위험 신호 (Red Flags)

- 프로파일링 데이터로 정당화되지 않은 최적화
- 데이터 페칭에서의 N+1 쿼리 패턴
- 페이지네이션 없는 목록(list) 엔드포인트
- 크기(dimension), 지연 로딩(lazy loading), 반응형 크기가 없는 이미지
- 리뷰 없이 커지는 번들 크기
- 프로덕션 성능 모니터링 부재
- 모든 곳에 `React.memo`와 `useMemo` 사용 (과용은 미사용만큼 나쁘다)

## 검증

성능 관련 변경 후에는 다음을 확인하라:

- [ ] 변경 전후의 측정값이 존재한다 (구체적인 수치)
- [ ] 특정 병목이 식별되고 해결되었다
- [ ] Core Web Vitals가 "좋음(Good)" 기준치 이내이다
- [ ] 번들 크기가 유의미하게 증가하지 않았다
- [ ] 새 데이터 페칭 코드에 N+1 쿼리가 없다
- [ ] CI에서 성능 예산 검사를 통과한다 (구성된 경우)
- [ ] 기존 테스트가 여전히 통과한다 (최적화가 동작을 깨뜨리지 않았다)
