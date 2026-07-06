# 성능 체크리스트 (Performance Checklist)

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

TTFB가 느릴 때(> 800ms), DevTools의 네트워크 워터폴에서 각 구성 요소를 확인하라:

- [ ] **DNS 해석(DNS resolution)**이 느림 → 알려진 오리진에 `<link rel="dns-prefetch">` 또는 `<link rel="preconnect">` 추가
- [ ] **TCP/TLS 핸드셰이크**가 느림 → HTTP/2 활성화, 엣지 배포 고려, keep-alive 확인
- [ ] **서버 처리**가 느림 → 백엔드 프로파일링, 느린 쿼리 확인, 캐싱 추가

## 프론트엔드 체크리스트

### 이미지
- [ ] 이미지는 최신 포맷 사용 (WebP, AVIF)
- [ ] 이미지는 반응형 크기 조정 (`srcset`과 `sizes`)
- [ ] 이미지와 `<source>` 요소에 명시적 `width`와 `height` 지정 (아트 디렉션에서 CLS 방지)
- [ ] 폴드 아래(below-the-fold) 이미지는 `loading="lazy"`와 `decoding="async"` 사용
- [ ] 히어로/LCP 이미지는 `fetchpriority="high"` 사용, 지연 로딩 금지

### JavaScript
- [ ] 번들 크기 gzip 기준 200KB 이하 (초기 로드)
- [ ] 라우트와 무거운 기능에 동적 `import()`를 활용한 코드 분할(code splitting)
- [ ] 트리 셰이킹(tree shaking) 활성화 (의존성이 ESM을 제공하고 `sideEffects: false`를 명시하는지 확인)
- [ ] `<head>`에 블로킹 JavaScript 없음 (`defer` 또는 `async` 사용)
- [ ] 무거운 연산은 Web Worker로 오프로드 (해당하는 경우)
- [ ] 같은 props로 리렌더링되는 비싼 컴포넌트에 `React.memo()` 적용
- [ ] `useMemo()` / `useCallback()`은 프로파일링으로 이득이 확인된 곳에만 사용
- [ ] 긴 태스크(> 50ms)를 분할하여 메인 스레드 가용성 유지 — INP의 주요 지렛대
- [ ] 장시간 실행 루프 내부에 `yieldToMain` 패턴을 사용해 청크 사이에 입력 이벤트가 실행되도록 함
- [ ] 가능한 곳에서 최신 스케줄링 API 사용: `scheduler.yield()`(선호), 우선순위를 지정한 `scheduler.postTask()`, 필요할 때만 양보하기 위한 `isInputPending()`
- [ ] 미룰 수 있는 비긴급 작업에 `requestIdleCallback` 사용 (분석 데이터 전송, 프리페치, 워밍업)
- [ ] 비필수 작업은 이벤트 핸들러 밖으로 연기 (예: 분석, 로깅) — 상호작용에 대한 응답이 지연되지 않도록
- [ ] 서드파티 스크립트는 `async` / `defer`로 로드하고, 크기를 감사하며, 무거운 경우 퍼사드(facade)로 대체 (채팅 위젯, 임베드)

### CSS
- [ ] 크리티컬 CSS는 인라인 또는 프리로드
- [ ] 비필수 스타일에 렌더 블로킹 CSS 없음
- [ ] 프로덕션에서 CSS-in-JS 런타임 비용 없음 (추출 방식 사용)

### 폰트
- [ ] 폰트 패밀리 2–3개, 각 2–3개 굵기(weight)로 제한 (굵기 하나 추가마다 요청이 하나 더 발생)
- [ ] WOFF2 포맷만 사용 (가장 작고 보편적 지원 — WOFF/TTF/EOT 생략)
- [ ] 가능하면 셀프 호스팅 (서드파티 폰트 CDN은 DNS + TCP + TLS 왕복을 추가)
- [ ] LCP에 중요한 폰트는 프리로드: `<link rel="preload" as="font" type="font/woff2" crossorigin>`
- [ ] `font-display: swap` (비필수 폰트는 `optional`)으로 렌더를 막는 FOIT 방지
- [ ] `unicode-range`로 서브셋하여 페이지별로 필요한 글리프만 제공
- [ ] 여러 굵기/스타일이 필요할 때는 가변 폰트(variable font) 고려 (파일 하나가 여러 개를 대체)
- [ ] 폰트 교체 시 CLS를 줄이기 위해 폴백 폰트 메트릭을 `size-adjust`, `ascent-override`, `descent-override`로 조정
- [ ] 커스텀 폰트 도입 전에 시스템 폰트 스택 먼저 고려

### 네트워크
- [ ] 정적 자산은 긴 `max-age` + 콘텐츠 해싱으로 캐싱
- [ ] API 응답은 적절한 곳에서 캐싱 (`Cache-Control`)
- [ ] HTTP/2 또는 HTTP/3 활성화
- [ ] 알려진 오리진에 리소스 사전 연결 (`<link rel="preconnect">`)
- [ ] `fetchpriority`를 중요한 비이미지 리소스에도 사용 (예: 핵심 `<link rel="preload">`, 폴드 위 `<script>`) — `<img>`에만 쓰지 말 것
- [ ] 불필요한 리디렉트 없음

### 렌더링
- [ ] 레이아웃 스래싱(layout thrashing) 없음 (강제 동기 레이아웃)
- [ ] 애니메이션은 `transform`과 `opacity` 사용 (GPU 가속)
- [ ] 긴 목록은 가상화(virtualization) 사용 (예: `react-window`)
- [ ] 불필요한 전체 페이지 리렌더링 없음
- [ ] 화면 밖 섹션은 `content-visibility: auto`와 `contain-intrinsic-size`를 사용해 비가시 영역의 레이아웃/페인트 생략
- [ ] `unload` 이벤트 핸들러 없음, HTML 응답에 `Cache-Control: no-store` 없음 — 뒤로/앞으로 캐시(bfcache) 적격성 유지

## 백엔드 체크리스트

### 데이터베이스
- [ ] N+1 쿼리 패턴 없음 (이거 로딩(eager loading) / 조인 사용)
- [ ] 쿼리에 적절한 인덱스 존재
- [ ] 목록 엔드포인트는 페이지네이션 (`SELECT * FROM table` 절대 금지)
- [ ] 커넥션 풀링 설정
- [ ] 느린 쿼리 로깅 활성화

### API
- [ ] 응답 시간 < 200ms (p95)
- [ ] 요청 핸들러에서 동기식 무거운 연산 없음
- [ ] 개별 호출 반복 대신 벌크 연산
- [ ] 응답 압축 (gzip/brotli)
- [ ] 적절한 캐싱 (인메모리, Redis, CDN)

### 인프라
- [ ] 정적 자산에 CDN
- [ ] 사용자 가까이에 서버 위치 (또는 엣지 배포)
- [ ] 수평 확장 설정 (필요한 경우)
- [ ] 로드 밸런서용 헬스 체크 엔드포인트

## 측정 명령어

### INP 필드 데이터와 DevTools 워크플로우

1. **필드 데이터 우선** — 최적화 전에 [CrUX Vis](https://developer.chrome.com/docs/crux/vis) 또는 사용 중인 RUM 도구에서 실사용자 INP 확인
2. **느린 상호작용 식별** — DevTools → Performance 패널을 열고 상호작용하며 녹화; 클릭/키 입력으로 발생하는 긴 태스크 탐색
3. **중급형 안드로이드에서 테스트** — INP 문제는 느린 하드웨어에서만 드러나는 경우가 많다; 실제 기기 또는 DevTools CPU 스로틀링(4×–6× 감속) 사용

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

| 안티패턴 | 영향 | 해결책 |
|---|---|---|
| N+1 쿼리 | DB 부하의 선형 증가 | 조인, includes, 또는 배치 로딩 사용 |
| 무제한 쿼리 | 메모리 고갈, 타임아웃 | 항상 페이지네이션, LIMIT 추가 |
| 인덱스 누락 | 데이터가 늘수록 읽기 느려짐 | 필터/정렬되는 컬럼에 인덱스 추가 |
| 레이아웃 스래싱 | 버벅임(jank), 프레임 드롭 | DOM 읽기를 배치로 처리한 뒤 쓰기를 배치로 처리 |
| 최적화되지 않은 이미지 | 느린 LCP, 대역폭 낭비 | WebP, 반응형 크기, 지연 로딩 사용 |
| 큰 번들 | 느린 Time to Interactive | 코드 분할, 트리 셰이킹, 의존성 감사 |
| 메인 스레드 블로킹 | 나쁜 INP, 반응 없는 UI | `scheduler.yield()` / `yieldToMain`으로 긴 태스크 분할, Web Worker로 오프로드 |
| 메모리 누수 | 메모리 증가, 결국 크래시 | 리스너, 인터벌, 참조 정리 |
