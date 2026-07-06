# 성능 체크리스트

웹 애플리케이션 성능을 위한 빠른 참조 체크리스트. `performance-optimization` 스킬과 함께 사용한다.

## 목차

- [Core Web Vitals 목표치](#core-web-vitals-목표치)
- [TTFB 진단](#ttfb-진단)
- [프론트엔드 체크리스트](#프론트엔드-체크리스트)
- [백엔드 체크리스트](#백엔드-체크리스트)
- [측정 명령어](#측정-명령어)
- [흔한 안티패턴](#흔한-안티패턴)

## Core Web Vitals 목표치

| 지표 | 좋음 | 개선 필요 | 나쁨 |
|--------|------|------------|------|
| LCP (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| INP (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |

## TTFB 진단

TTFB가 느릴 때(> 800ms), DevTools Network 워터폴에서 각 구성 요소를 확인하라:

- [ ] **DNS 조회**가 느림 → 알려진 오리진에 `<link rel="dns-prefetch">` 또는 `<link rel="preconnect">` 추가
- [ ] **TCP/TLS 핸드셰이크**가 느림 → HTTP/2 활성화, 엣지 배포 검토, keep-alive 확인
- [ ] **서버 처리**가 느림 → 백엔드 프로파일링, 느린 쿼리 확인, 캐싱 추가

## 프론트엔드 체크리스트

### 이미지
- [ ] 이미지가 최신 포맷(WebP, AVIF)을 사용한다
- [ ] 이미지가 반응형으로 크기 조정된다 (`srcset`과 `sizes`)
- [ ] 이미지와 `<source>` 요소에 명시적인 `width`와 `height`가 있다 (아트 디렉션에서의 CLS 방지)
- [ ] 폴드 아래(below-the-fold) 이미지는 `loading="lazy"`와 `decoding="async"`를 사용한다
- [ ] 히어로/LCP 이미지는 `fetchpriority="high"`를 사용하고 지연 로딩을 하지 않는다

### JavaScript
- [ ] 번들 크기가 gzip 기준 200KB 미만이다 (초기 로드)
- [ ] 라우트와 무거운 기능에 동적 `import()`를 사용한 코드 분할(code splitting)
- [ ] 트리 셰이킹(tree shaking) 활성화 (의존성이 ESM을 제공하고 `sideEffects: false`로 표시되어 있는지 확인)
- [ ] `<head>`에 차단(blocking) JavaScript가 없다 (`defer` 또는 `async` 사용)
- [ ] 무거운 연산은 Web Worker로 오프로드했다 (해당되는 경우)
- [ ] 같은 props로 리렌더링되는 비싼 컴포넌트에 `React.memo()` 적용
- [ ] `useMemo()` / `useCallback()`은 프로파일링에서 이점이 확인된 곳에만 사용
- [ ] 긴 작업(> 50ms)을 잘게 나눠 메인 스레드를 가용 상태로 유지 — INP 개선의 핵심 수단
- [ ] 장시간 실행 루프 내부에 `yieldToMain` 패턴을 사용하여 청크 사이에 입력 이벤트가 실행될 수 있게 함
- [ ] 가능한 곳에서 최신 스케줄링 API 사용: `scheduler.yield()` (선호), 우선순위를 지정한 `scheduler.postTask()`, 필요할 때만 양보하기 위한 `isInputPending()`
- [ ] 미룰 수 있는 비긴급 작업(분석 데이터 전송, 프리페치, 워밍업)에 `requestIdleCallback` 사용
- [ ] 비핵심 작업(예: 분석, 로깅)을 이벤트 핸들러 밖으로 미뤄 인터랙션에 대한 응답이 지연되지 않게 함
- [ ] 서드파티 스크립트는 `async` / `defer`로 로드하고 크기를 감사하며, 무거운 경우(채팅 위젯, 임베드) 파사드(facade)를 앞단에 둠

### CSS
- [ ] 크리티컬 CSS를 인라인하거나 preload한다
- [ ] 비핵심 스타일에 렌더링 차단 CSS가 없다
- [ ] 프로덕션에서 CSS-in-JS 런타임 비용이 없다 (추출(extraction) 사용)

### 폰트
- [ ] 폰트 패밀리 2–3개, 각 2–3개 굵기(weight)로 제한 (굵기 하나가 늘 때마다 요청도 하나 늘어난다)
- [ ] WOFF2 포맷만 사용 (가장 작고 범용 지원 — WOFF/TTF/EOT는 생략)
- [ ] 가능하면 셀프 호스팅 (서드파티 폰트 CDN은 DNS + TCP + TLS 왕복을 추가한다)
- [ ] LCP에 결정적인 폰트는 preload: `<link rel="preload" as="font" type="font/woff2" crossorigin>`
- [ ] 렌더링을 차단하는 FOIT를 피하기 위해 `font-display: swap` (비핵심 폰트는 `optional`)
- [ ] `unicode-range`로 서브셋(subset)하여 각 페이지에 필요한 글리프만 제공
- [ ] 여러 굵기/스타일이 필요할 때 가변 폰트(variable font) 검토 (파일 하나가 여러 개를 대체)
- [ ] 폰트 교체 시 CLS를 줄이기 위해 `size-adjust`, `ascent-override`, `descent-override`로 폴백 폰트 메트릭 조정
- [ ] 커스텀 폰트에 앞서 시스템 폰트 스택 우선 검토

### 네트워크
- [ ] 정적 자산을 긴 `max-age` + 콘텐츠 해싱으로 캐싱한다
- [ ] 적절한 곳에서 API 응답을 캐싱한다 (`Cache-Control`)
- [ ] HTTP/2 또는 HTTP/3 활성화
- [ ] 알려진 오리진에 리소스 사전 연결 (`<link rel="preconnect">`)
- [ ] 크리티컬한 비이미지 리소스(예: 핵심 `<link rel="preload">`, 폴드 위 `<script>`)에도 `fetchpriority` 사용 — `<img>`에만 쓰지 않는다
- [ ] 불필요한 리다이렉트가 없다

### 렌더링
- [ ] 레이아웃 스래싱(강제 동기 레이아웃)이 없다
- [ ] 애니메이션은 `transform`과 `opacity`를 사용한다 (GPU 가속)
- [ ] 긴 목록은 가상화(virtualization)를 사용한다 (예: `react-window`)
- [ ] 불필요한 전체 페이지 리렌더링이 없다
- [ ] 화면 밖 섹션은 `content-visibility: auto`와 `contain-intrinsic-size`를 사용하여 보이지 않는 영역의 레이아웃/페인트를 건너뛴다
- [ ] HTML 응답에 `unload` 이벤트 핸들러와 `Cache-Control: no-store`가 없다 — 뒤로/앞으로 가기 캐시(bfcache) 적격성 유지

## 백엔드 체크리스트

### 데이터베이스
- [ ] N+1 쿼리 패턴이 없다 (즉시 로딩(eager loading) / 조인 사용)
- [ ] 쿼리에 적절한 인덱스가 있다
- [ ] 목록 엔드포인트는 페이지네이션되어 있다 (`SELECT * FROM table` 금지)
- [ ] 커넥션 풀링이 구성되어 있다
- [ ] 느린 쿼리 로깅이 활성화되어 있다

### API
- [ ] 응답 시간 < 200ms (p95)
- [ ] 요청 핸들러에 동기식 무거운 연산이 없다
- [ ] 개별 호출을 반복하는 대신 벌크(bulk) 연산 사용
- [ ] 응답 압축 (gzip/brotli)
- [ ] 적절한 캐싱 (인메모리, Redis, CDN)

### 인프라
- [ ] 정적 자산에 CDN 사용
- [ ] 서버가 사용자 가까이에 위치 (또는 엣지 배포)
- [ ] 수평 확장(horizontal scaling) 구성 (필요한 경우)
- [ ] 로드 밸런서용 헬스 체크 엔드포인트

## 측정 명령어

### INP 필드 데이터와 DevTools 워크플로

1. **필드 데이터 먼저** — 최적화 전에 [CrUX Vis](https://developer.chrome.com/docs/crux/vis) 또는 사용 중인 RUM 도구에서 실사용자 INP 확인
2. **느린 인터랙션 식별** — DevTools → Performance 패널을 열고 인터랙션하며 녹화; 클릭/키 입력으로 유발되는 긴 작업(long task)을 탐색
3. **중급 사양 안드로이드에서 테스트** — INP 문제는 느린 하드웨어에서만 드러나는 경우가 많다; 실제 기기 또는 DevTools CPU 스로틀링(4×–6× 감속) 사용

```bash
# Lighthouse CLI
npx lighthouse https://localhost:3000 --output json --output-path ./report.json

# Bundle analysis
npx webpack-bundle-analyzer stats.json
# or for Vite:
npx vite-bundle-visualizer

# Check bundle size
npx bundlesize

# Web Vitals in code
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(console.log);
onINP(console.log);
onCLS(console.log);

# INP with interaction-level detail (attribution build)
import { onINP } from 'web-vitals/attribution';
onINP(({ value, attribution }) => {
  const { interactionTarget, inputDelay, processingDuration, presentationDelay } = attribution;
  console.log({ value, interactionTarget, inputDelay, processingDuration, presentationDelay });
});
```

## 흔한 안티패턴

| 안티패턴 | 영향 | 해결 |
|---|---|---|
| N+1 쿼리 | DB 부하의 선형 증가 | 조인, include, 또는 배치 로딩 사용 |
| 무제한 쿼리 | 메모리 고갈, 타임아웃 | 항상 페이지네이션, LIMIT 추가 |
| 누락된 인덱스 | 데이터 증가에 따라 느려지는 읽기 | 필터/정렬되는 컬럼에 인덱스 추가 |
| 레이아웃 스래싱 | 버벅임(jank), 프레임 드롭 | DOM 읽기를 일괄 처리한 뒤 쓰기를 일괄 처리 |
| 최적화되지 않은 이미지 | 느린 LCP, 대역폭 낭비 | WebP, 반응형 크기, 지연 로딩 사용 |
| 큰 번들 | 느린 Time to Interactive | 코드 분할, 트리 셰이킹, 의존성 감사 |
| 메인 스레드 차단 | 나쁜 INP, 응답 없는 UI | `scheduler.yield()` / `yieldToMain`으로 긴 작업 분할, Web Worker로 오프로드 |
| 메모리 누수 | 메모리 증가, 결국 크래시 | 리스너, 인터벌, 참조(ref) 정리 |
