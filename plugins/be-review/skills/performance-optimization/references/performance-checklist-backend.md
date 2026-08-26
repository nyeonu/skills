# 성능 체크리스트 — 백엔드

`performance-optimization` 스킬의 백엔드 필수 참고자료다. 백엔드 성능 작업을 시작하기 전에 반드시 읽는다. UI·웹 렌더링이 대상이면 `performance-checklist-frontend.md`를 읽는다.

이 문서의 수치(응답 시간, TTL 등)는 전부 프로젝트 기본값 예시다 — 추적하는 외부 공식 기준이 없다. 스펙·SLA·기존 측정값이 있으면 그 값이 기준이다.

## 데이터베이스

- [ ] N+1 쿼리 패턴이 없다 (즉시 로딩(eager loading) / 조인 사용)
- [ ] 쿼리에 적절한 인덱스가 있다 (실행 계획으로 확인)
- [ ] 목록 엔드포인트는 페이지네이션되어 있다 (`SELECT * FROM table` 금지)
- [ ] 커넥션 풀링이 구성되어 있고 포화 지표를 모니터링한다
- [ ] 느린 쿼리 로깅이 활성화되어 있다

## API

- [ ] 응답 시간 목표가 백분위 기준으로 정의되어 있다 (예시 기본값: p95 < 200ms — 스펙·SLA 우선)
- [ ] 요청 핸들러에 동기식 무거운 연산이 없다
- [ ] 개별 호출을 반복하는 대신 벌크(bulk) 연산 사용
- [ ] 외부 호출에 타임아웃과 실패 처리(재시도·서킷 브레이커 등 프로젝트 표준)가 있다
- [ ] 응답 압축 (gzip/brotli)
- [ ] 적절한 캐싱 (인메모리, Redis, CDN) — 무효화 시점과 스테일 허용 범위가 정의되어 있다

## 캐싱 예시

```typescript
// 자주 읽고 드물게 바뀌는 데이터 캐시 (TTL은 프로젝트 기본값 예시)
const CACHE_TTL = 5 * 60 * 1000; // 5분
let cachedConfig: AppConfig | null = null;
let cacheExpiry = 0;

async function getAppConfig(): Promise<AppConfig> {
  if (cachedConfig && Date.now() < cacheExpiry) return cachedConfig;
  cachedConfig = await db.config.findFirst();
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedConfig;
}

// API 응답 캐싱 헤더
res.set('Cache-Control', 'public, max-age=300');
```

## 인프라

- [ ] 정적 자산에 CDN 사용
- [ ] 서버가 사용자 가까이에 위치 (또는 엣지 배포)
- [ ] 수평 확장(horizontal scaling) 구성 (필요한 경우)
- [ ] 로드 밸런서용 헬스 체크 엔드포인트

## 흔한 안티패턴

| 안티패턴 | 영향 | 해결 |
|---|---|---|
| N+1 쿼리 | DB 부하의 선형 증가 | 조인, include, 또는 배치 로딩 사용 |
| 무제한 쿼리 | 메모리 고갈, 타임아웃 | 항상 페이지네이션, LIMIT 추가 |
| 누락된 인덱스 | 데이터 증가에 따라 느려지는 읽기 | 필터/정렬되는 컬럼에 인덱스 추가 |
| 핸들러 안의 동기 무거운 연산 | 처리량 하락, 지연 스파이크 | 비동기화, 워커·큐로 오프로드 |
| 무효화 계획 없는 캐시 | 스테일 데이터 버그 | 무효화 시점·스테일 허용 범위를 먼저 정의 |
| 메모리 누수 | 메모리 증가, 결국 크래시 | 리스너, 인터벌, 참조(ref) 정리 |
