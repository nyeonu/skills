# 성능 체크리스트 — 프런트엔드

`performance-optimization` 스킬의 프런트엔드 필수 참고자료다. UI·웹 렌더링 성능 작업을 시작하기 전에 반드시 읽는다. 백엔드가 대상이면 `performance-checklist-backend.md`를 읽는다.

## 출처 메타데이터

- 공식 출처: https://web.dev/articles/vitals
- 확인일: 2026-08-27
- 출처 버전: Last updated 2024-10-31 UTC · 기준값 LCP ≤ 2.5s / INP ≤ 200ms / CLS ≤ 0.1 (필드 데이터 75번째 백분위)
- 추적하는 기준: Core Web Vitals 지표 구성(LCP·INP·CLS)과 good/needs improvement/poor 임계값
- 상태: current    <!-- current | needs_review -->

**신선도 확인 규칙**: 이 파일을 읽는 실행 주체는 `확인일`이 작업일 기준 30일 이내면 아래 기록값을 쓴다. 30일을 넘었으면 web.dev 문서의 `Last updated`와 Core Web Vitals 기준값 영역이 기록과 같은지만 확인한다. 같으면 현재 작업에 기록값을 쓰고 확인 결과를 보고한다. 다르면 수치를 자동 수정하지 말고 `needs_review`와 변경 검토 필요를 보고한다. 현재 작업이 이 스킬 저장소의 유지보수라면 같은 결과를 두 참고자료 사본의 `확인일`·`출처 버전`·`상태`와 `CUSTOMIZATIONS.md`에 함께 반영한다. 공식 출처를 확인할 수 없으면 검증 공백을 보고하고, 새 스펙·SLA·성능 예산·CI 기준을 현행 공식 기준으로 단정하지 않는다.

## Core Web Vitals

아래 구간은 Google 공식 기준이다. 판정 조건: **필드 데이터(실사용자)의 75번째 백분위**가 모바일·데스크톱 각각에서 기준을 충족해야 한다. 랩 측정(Lighthouse) 점수는 공식 판정이 아니라 진단 보조다. 프로젝트 자체 성능 예산은 이 공식 기준과 구분해 표기한다.

| 지표 | 좋음 | 개선 필요 | 나쁨 |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | > 2.5s, ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | > 200ms, ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | > 0.1, ≤ 0.25 | > 0.25 |

## 측정

1. **필드 데이터 먼저** — CrUX Vis(https://developer.chrome.com/docs/crux/vis) 또는 사용 중인 RUM 도구에서 실사용자 지표 확인. 필드 데이터가 없으면 합성 기준선으로 작업하되 실사용자 개선을 단정하지 않는다.
2. **느린 인터랙션 식별** — DevTools Performance 패널 녹화로 긴 작업(long task, > 50ms) 탐색
3. **중급 사양 기기에서 테스트** — INP 문제는 느린 하드웨어에서만 드러나는 경우가 많다. 실제 기기 또는 DevTools CPU 스로틀링(4×–6×) 사용

```bash
# Lighthouse CLI (합성 측정 — 재현·회귀 확인용)
npx lighthouse https://localhost:3000 --output json --output-path ./report.json

# 번들 분석
npx webpack-bundle-analyzer stats.json
# Vite: npx vite-bundle-visualizer
```

```typescript
// RUM: web-vitals 라이브러리
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(console.log); onINP(console.log); onCLS(console.log);

// INP 원인 분해 (attribution 빌드)
import { onINP } from 'web-vitals/attribution';
onINP(({ value, attribution }) => {
  const { interactionTarget, inputDelay, processingDuration, presentationDelay } = attribution;
  console.log({ value, interactionTarget, inputDelay, processingDuration, presentationDelay });
});
```

### TTFB 진단

TTFB가 느릴 때 DevTools Network 워터폴에서 구성 요소별 확인:

- [ ] **DNS 조회** 느림 → 알려진 오리진에 `<link rel="dns-prefetch">` / `<link rel="preconnect">`
- [ ] **TCP/TLS 핸드셰이크** 느림 → HTTP/2 활성화, 엣지 배포 검토, keep-alive
- [ ] **서버 처리** 느림 → `performance-checklist-backend.md`로 이동 (쿼리·캐싱)

## 체크리스트

### 이미지
- [ ] 최신 포맷(WebP, AVIF) 사용, 반응형 크기 조정 (`srcset`과 `sizes`)
- [ ] 이미지와 `<source>` 요소에 명시적인 `width`/`height` (CLS 방지)
- [ ] 폴드 아래(below-the-fold) 이미지는 `loading="lazy"`와 `decoding="async"`
- [ ] 히어로/LCP 이미지는 `fetchpriority="high"`, 지연 로딩 금지

### JavaScript
- [ ] 초기 로드 번들 크기가 프로젝트 예산 이내 (예시 기본값: gzip 200KB — 예산은 사용자와 확정)
- [ ] 라우트와 무거운 기능에 동적 `import()` 코드 분할(code splitting)
- [ ] 트리 셰이킹 활성화 (의존성이 ESM 제공, `sideEffects: false`)
- [ ] `<head>`에 차단 JavaScript 없음 (`defer`/`async`)
- [ ] 긴 작업(> 50ms)을 잘게 나눠 메인 스레드 확보 — INP 개선의 핵심
- [ ] 양보(yield)에는 지원 여부를 확인하고 `scheduler.yield()` 사용 — **기능 탐지 필수, 미지원 환경 대체 경로 제공** (아래 코드 예시). 특정 브라우저 기능을 범용 규칙처럼 강제하지 않는다
- [ ] 비긴급 작업(분석 전송, 프리페치)에 `requestIdleCallback`
- [ ] `React.memo()`/`useMemo()`는 프로파일링에서 이점이 확인된 곳에만 (과용은 미사용만큼 나쁘다)
- [ ] 서드파티 스크립트는 `async`/`defer`, 무거우면(채팅 위젯, 임베드) 파사드(facade)를 앞단에

### CSS·폰트
- [ ] 크리티컬 CSS 인라인 또는 preload, 비핵심 스타일의 렌더링 차단 없음
- [ ] 폰트는 WOFF2만, 가능하면 셀프 호스팅, LCP에 결정적인 폰트는 preload
- [ ] `font-display: swap` (비핵심 폰트는 `optional`), `unicode-range` 서브셋
- [ ] 폴백 폰트 메트릭 조정(`size-adjust` 등)으로 폰트 교체 시 CLS 감소
- [ ] 커스텀 폰트에 앞서 시스템 폰트 스택 우선 검토

### 네트워크·렌더링
- [ ] 정적 자산을 긴 `max-age` + 콘텐츠 해싱으로 캐싱
- [ ] HTTP/2 또는 HTTP/3, 알려진 오리진에 `preconnect`, 불필요한 리다이렉트 없음
- [ ] 레이아웃 스래싱 없음 (DOM 읽기 일괄 후 쓰기 일괄)
- [ ] 애니메이션은 `transform`/`opacity` (GPU 가속)
- [ ] 긴 목록은 가상화(virtualization), 화면 밖 섹션은 `content-visibility: auto`
- [ ] `unload` 핸들러와 `Cache-Control: no-store` 없음 — bfcache 적격성 유지

## 코드 예시

### scheduler.yield() — 기능 탐지와 대체 경로

```typescript
// 지원 여부를 확인하고 사용한다. 미지원 환경은 setTimeout 폴백.
async function yieldToMain(): Promise<void> {
  if ('scheduler' in globalThis && 'yield' in (globalThis as any).scheduler) {
    return (globalThis as any).scheduler.yield();
  }
  return new Promise((resolve) => setTimeout(resolve, 0));
}

async function processChunks(items: Item[]) {
  for (const chunk of toChunks(items, 50)) {
    processChunk(chunk);
    await yieldToMain(); // 청크 사이에 입력 이벤트가 실행될 수 있게 양보
  }
}
```

지원 현황과 스펙: https://developer.mozilla.org/en-US/docs/Web/API/Scheduler/yield

### LCP 이미지 — 아트 디렉션 + 해상도 전환

```html
<picture>
  <!-- 모바일: 세로 크롭 -->
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.avif 400w, /hero-mobile-800.avif 800w"
    sizes="100vw" width="800" height="1000" type="image/avif" />
  <!-- 데스크톱: 가로 크롭 -->
  <source
    srcset="/hero-800.avif 800w, /hero-1200.avif 1200w, /hero-1600.avif 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200" height="600" type="image/avif" />
  <img src="/hero-desktop.jpg" width="1200" height="600"
       fetchpriority="high" alt="Hero image description" />
</picture>

<!-- 폴드 아래 이미지 -->
<img src="/content.webp" width="800" height="400"
     loading="lazy" decoding="async" alt="Content image description" />
```

### React 리렌더링

```tsx
// BAD: 렌더마다 새 객체 생성 → 자식이 매번 리렌더링
function TaskList() {
  return <TaskFilters options={{ sortBy: 'date', order: 'desc' }} />;
}

// GOOD: 안정된 참조
const DEFAULT_OPTIONS = { sortBy: 'date', order: 'desc' } as const;
function TaskList() {
  return <TaskFilters options={DEFAULT_OPTIONS} />;
}

// 비싼 연산은 useMemo (프로파일링으로 확인된 곳에만)
function TaskStats({ tasks }: Props) {
  const stats = useMemo(() => calculateStats(tasks), [tasks]);
  return <div>{stats.completed} / {stats.total}</div>;
}
```

### 코드 분할

```typescript
// 무겁고 드물게 쓰는 기능은 동적 import
const ChartLibrary = lazy(() => import('./ChartLibrary'));

// 라우트 수준 분할 + Suspense
const SettingsPage = lazy(() => import('./pages/Settings'));
function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <SettingsPage />
    </Suspense>
  );
}
```
