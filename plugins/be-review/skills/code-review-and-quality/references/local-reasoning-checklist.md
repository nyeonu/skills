# 국소 추론 체크리스트

`code-review-and-quality` 스킬의 조건부 참고자료다. 결정 로직 변경, 새 애노테이션·AOP·리플렉션·설정 기반 동작 도입, 도메인 간 import 추가나 새 모듈·레이어 도입이 diff에 있으면 발견 사항 분류 전에 읽는다.

국소 추론(local reasoning)이란 코드 한 조각의 동작을 이해하기 위해 다른 파일을 얼마나 적게 열어야 하는가를 뜻한다. 이 코드를 다음에 고치는 것은 파일 몇 개만 컨텍스트에 올린 에이전트일 가능성이 높으므로, "나는 이해된다"가 아니라 "이 파일만 보고 이해되고, 이 파일만 고쳐서 검증되는가"로 판정한다. 이것은 가독성·아키텍처 축의 판정 기준이지 별도의 축이 아니다.

이 문서의 문턱 수치(목 3개)는 프로젝트 기본값 예시다 — 업계에 합의된 수치는 없고(관련 문헌은 개수가 아니라 "무엇을 목으로 세웠는가"로 판단한다), 생성자 의존성 3~4개를 과주입의 신호로 보는 휴리스틱과 겹치는 수준이다. 프로젝트에 정해진 값이 있으면 그 값이 기준이다. 판정 기준은 전부 코드만 보고 답할 수 있는 질문으로 쓴다 — "훈련 데이터에 흔한가" 같은 확인 불가능한 기준은 쓰지 않는다.

## 적용 강도 — 레포가 정한다

이 체크리스트의 심각도는 **대상 저장소의 `CLAUDE.md`(또는 `ARCHITECTURE.md`)에 "국소 추론 판정 기준 합의"라는 선언이 있을 때**만 아래 표대로 적용한다. 선언 문구는 이 글자 그대로 쓴다 — 리뷰어가 grep으로 확인한다. 선언이 없으면 렌즈 ①~⑤의 모든 발견은 **`Suggestion`을 상한**으로 하고, 코멘트는 요구가 아니라 질문형으로 쓴다("이 판정을 같은 파일의 static 메서드로 빼면 목 없이 테스트될 것 같은데 어떻게 보시나요"). 발동 조건과 관찰은 선언 여부와 무관하게 똑같이 수행한다 — 보고하되 막지 않는다.

이유: 이 기준은 합의되지 않은 팀에서는 리뷰어 개인의 설계 취향으로 읽히고, 렌즈 ⑤가 지키려는 "이 레포의 관례를 존중한다"와 충돌한다. 자기 코드와 에이전트 산출물(plan-executor의 서브에이전트가 만든 코드)에는 선언 없이도 표대로 적용해도 된다 — 이 기준의 원래 목적이 그것이다. 리뷰 요청자가 "내 코드다"라고 밝히면 그렇게 한다.

단, 렌즈가 가리킨 지점에서 **테스트가 없거나 분기 하나만 덮는 것**은 국소 추론 기준이 아니라 2단계(테스트 리뷰)의 결함이므로 선언과 무관하게 `Important`다.

## 용어

- **결정 로직**: 값을 보고 판단하는 코드. 접근 판정(권한·멤버십), 상태 전이, 정렬·필터 규칙, 요금·할인 계산.
- **셸(shell)**: 바깥 세계와 닿는 코드. HTTP 라우팅, 보안 필터 체인, 트랜잭션 경계, Repository·외부 API 호출, 메시징, 캐시 적중. 셸이 DB를 여러 번 부르는 것은 정상이다.
- **매직**: 코드에 직접 적혀 있지 않은데 프레임워크나 애스펙트가 뒤에서 해주는 동작. 애노테이션 기반 AOP, 리플렉션 주입, SpEL 키, 데코레이터, ORM 지연 로딩. 매직 자체는 문제가 아니다 — 아래 세 질문으로 판정한다.
- **세레모니**: 로직과 무관한 형식적 반복. 구현체가 하나뿐인 인터페이스, 필드 하나에 따라오는 Mapper·Assembler·Config 한 벌.
- **관례 기준선**: 이 코드베이스의 다른 도메인들이 같은 종류의 변경에 손대는 파일 집합. 세레모니는 절대 파일 수가 아니라 이 기준선 대비 추가분으로 잰다.
- **지식의 중복과 모양의 중복**: 같은 규칙(요금 계산식, 접근 조건)이 두 곳에 적혀 있으면 지식의 중복이고 나쁘다. 모양만 비슷한 코드 두 벌은 모양의 중복이고 그대로 둔다. 공통화는 같은 지식이 세 번 반복되고 안정된 뒤에 한다 — 두 번째에 합치면 세 번째가 플래그를 요구한다.

## 매직 판정 세 질문 (렌즈 ①)

"셸이면 괜찮다"는 셸과 코어를 아는 사람에게만 작동하는 기준이다. 대신 코드만 보고 답할 수 있는 세 질문을 쓴다.

| 질문 | 확인 방법 | 결과 |
|---|---|---|
| 출처: 프레임워크가 주는 것인가, 이 레포가 만든 것인가 | import 경로를 본다 (`org.springframework…` vs 이 레포 패키지) | 레포가 만든 것이면 그 동작이 `CLAUDE.md`/`ARCHITECTURE.md`에 적혀 있어야 한다 |
| 가시성: 호출 지점에서 적용된다는 사실이 보이는가 | 메서드 위에 애노테이션이 있는가, 아니면 URL 패턴·설정 파일·전역 인터셉터로 적용되는가 | 호출부에서 안 보이면 문서 요구 |
| 결정 관여: 그 설정값이 사용자가 보는 결과를 바꾸는가, 성능·횡단 관심사만 바꾸는가 | 설정값(SpEL 키, 조건식, 플래그)에 권한·상태·시간 조건이 들어 있는가 | 결과를 바꾸면 `Important` — 그 조건은 결정 로직과 같은 곳에서 관리되어야 한다 |

원칙은 **메커니즘은 모으고, 판단은 호출부에 둔다**이다. 캐시를 읽고 쓰는 방법은 애스펙트 한 곳에 모으는 것이 맞다(세레모니 감소). 하지만 "이 호출에서 누구끼리 결과를 공유해도 되는가"는 호출부의 판단이고, 그것이 애스펙트의 설정 문자열 안에 들어가면 접근 판정과 같은 지식이 두 곳에 생긴다. 모은 메커니즘에는 세 가지가 따라온다: 한 파일에 있을 것, 호출부에서 적용 사실이 보일 것, 호출자가 알아야 할 규칙이 문서 한 단락으로 적혀 있을 것.

## 렌즈 ①~⑤

| 렌즈 | 리뷰 질문 | 판정 |
|---|---|---|
| ① 매직 | 새 애노테이션·AOP·리플렉션·SpEL 키·전역 상태를 도입하거나, 기존 것의 설정값에 **결정 조건**을 넣는가 | 위 세 질문으로 판정한다. 레포가 만든 것이면서 결과를 바꾸면 `Important` — 판정을 코드로 드러내거나 결정 로직과 같은 곳에서 관리하게 하고, 동작을 `CLAUDE.md`에 적게 한다. 프레임워크 것이거나 성능만 바꾸면 지적하지 않는다 |
| ② 결정과 IO 분리 | 접근 판정·상태 전이·정렬·필터 규칙이 Repository 호출, HTTP 클라이언트, `Mono`/`Flux` 체인 사이에 끼어 있고, **그 판정을 검증해야 하는가** | 발동 조건은 "체인 안에 `if`가 있다"가 아니라 **결정 하나를 검증하려면 그 판정과 무관한 Repository·HTTP 목을 세워야 한다**이다(목이 3개 이상이면 신호가 강하다). 심각도는 목 개수가 아니라 테스트가 정한다: 목 비용 때문에 **그 결정에 테스트가 없거나 분기 하나만 덮고 있으면** `Important`(테스트 품질 결함, ②는 그 원인 설명), 목이 많더라도 테스트가 결정의 분기를 덮고 있으면 `Suggestion`(다음 변경을 싸게 만드는 개선). 권고는 판정을 IO 호출 없는 함수로 빼는 것이고 형태는 아래 "분리의 단계"를 따른다. 테스트 대상이 아닌 두세 줄 분기는 지적하지 않는다 |
| ③ 세레모니 | 이 변경이 **관례 기준선에 없는** 형식 파일을 새로 들여왔는가 — 구현체 하나뿐인 인터페이스, 필드 하나에 따라붙은 Mapper·Assembler·Config | 관례 기준선이 요구하는 파일(entity·DTO·repository·service 등)은 세지 않는다. 기준선 밖의 추가 파일이 있으면 `Suggestion`. 기준선 자체가 무거운 것은 이 변경의 책임이 아니므로 지적하지 않는다 |
| ④ 경계와 의존 방향 | 도메인 A가 도메인 B의 `repository`·`entity`를 직접 import하는가. 결정 로직이 `org.springframework`·`reactor`를 import하는가 | 레포에 **같은 모양의 선례가 없으면** `Important`(이 변경이 경계를 처음 깨는 것). 선례가 이미 있으면 `Suggestion` — 이 변경의 책임이 아니므로 되돌리기보다 강제 수단(ArchUnit·린터·구조 테스트) 추가를 요구한다. 규칙이 문서에만 있는 것도 `Suggestion`으로 강제 수단을 요구한다 — 문서는 에이전트가 안 읽어도 아무 일이 없지만, 구조 테스트는 어긴 순간 빌드가 실패하고 그 오류가 에이전트에게 돌아간다 |
| ⑤ 관례 이탈 | "에이전트가 읽기 좋게"를 이유로 파일 통합, 레이어 제거, 프레임워크 우회처럼 코드베이스 관례에서 벗어난 구조를 도입했는가 | 기준은 하나다: **이 레포의 다른 도메인이 같은 모양인가.** 다르면 에이전트는 관례 하나와 예외 하나를 동시에 배워야 한다. ①~④를 해결하지 않는 이탈은 `Suggestion`으로 되돌리기를 제안한다 |

## 분리의 단계 (렌즈 ②)

분리는 공짜가 아니다. 파일이 하나 늘면 **읽을 때** 열어야 할 파일이 하나 늘어 국소 추론이 그만큼 나빠진다. 이득은 **고치고 검증할 때** 난다. 그래서 가장 가벼운 형태부터 쓰고, 조건이 맞을 때만 올린다.

| 단계 | 형태 | 쓰는 때 |
|---|---|---|
| 0 | 그대로 둔다 | 판정이 테스트 대상이 아니고 두세 줄이다 |
| 1 | **같은 파일 안의 `static` 메서드**. IO 호출 없이 값만 받아 결과(예외 또는 `null`, 또는 enum)를 돌려준다 | 판정을 목 없이 테스트해야 한다. 결과가 허용/거부 둘이다. **기본 형태** |
| 2 | 별도 파일 + `sealed` 결과 타입 + 전 분기 `switch` | 결과가 셋 이상이거나(허용 / 거부 / 허용하되 가공), 호출부가 `boolean`을 받아 다시 판단하고 있다 |

2단계는 다음 조건이 **모두** 맞을 때만 이득이 난다. 하나라도 빠지면 `if`보다 긴 코드만 남는다.

- 결과를 소비하는 `switch`에 `default`를 붙이지 않는다. `default`가 있거나 `instanceof` 체인으로 쓰면 전 분기 검사가 사라져 "결과 추가 시 컴파일러가 알려준다"는 유일한 이득이 없어진다.
- Java 21 이상이다. `sealed`는 17부터지만 `case Allow a ->` 같은 타입 패턴 `switch`는 21부터 정식이다.
- 결정 타입은 셸 안에서 소비하고 끝낸다. DTO에 실어 직렬화하면 다형 타입 처리를 위한 애노테이션이 필요해져 렌즈 ①의 매직이 생긴다.
- 결정 결과를 소비하는 곳은 한 곳이다. 열 곳에서 `switch`하면 결과 하나 추가에 열 곳을 고쳐야 한다.
- 레포에 `sealed`가 처음이면 새 패턴이다(렌즈 ⑤). 계획의 "선택한 방식과 이유"에 적고 `CLAUDE.md`에 한 줄 두며, 그 작업은 `light`가 아니라 `standard` 등급으로 배정한다.

리뷰어가 두세 줄짜리 `if`에 2단계를 요구하면 그것이 세레모니다.

## 이 체크리스트가 요구하지 않는 것

프레임워크 제거를 요구하지 않는다. Spring Security 필터 체인, `@Transactional`, WebFlux 라우팅, Bean 구성, 셸의 다중 DB 호출, 횡단 관심사를 모은 애스펙트는 그대로 두는 것이 맞다. 잡아야 할 것은 **셸의 설정값이 결정 로직과 뒤섞이는 지점**이다. "Spring을 걷어내라", "순수 자바로 가라", "파일을 합쳐라"는 이 체크리스트의 결론이 아니다.

## 전/후 예시 1 — 렌즈 ②, 1단계 분리

전: 멤버십 접근 판정이 리액티브 체인 안에서 Repository 호출과 첨부파일 조회 사이에 끼어 있다. "멤버십 만료 유저는 MembershipRequiredException"을 검증하려면 `postRepository`, `attachmentService.getAttachments`, `getVodAttachments` 목이 셋 필요하다.

```java
return postRepository.getPost(user, id)
        .flatMap(post -> {
            if (post == null)              return Mono.error(new NotExistValueException(id.toString()));
            if (post.isMembership()) {
                if (!user.isWeverseAccount())  return Mono.error(new UnAuthorizedException());
                if (!user.isMembershipValid()) return Mono.error(new MembershipRequiredException());
            }
            return attachmentService.getAttachments(user.getSiteId(), id, AttachmentType.POST)
                    .collectList()
                    .map(list -> { post.setAttachments(organize(list)); return post; });
        })
        .flatMap(post -> getVodAttachments(user.getSiteId(), post.getId())
                .collectList().map(vods -> { post.setVods(vods); return post; }));
```

후: 같은 파일 안에서 판정만 `static` 메서드로 뺀다. 새 파일 없음, 프레임워크 import 없음, 호출 순서 그대로. 테스트는 값 두 개를 넣고 반환값을 보면 끝난다.

```java
static RuntimeException accessDenial(PostDTO post, UserDTO user, UUID id) {
    if (post == null)               return new NotExistValueException(id.toString());
    if (!post.isMembership())       return null;
    if (!user.isWeverseAccount())   return new UnAuthorizedException();
    if (!user.isMembershipValid())  return new MembershipRequiredException();
    return null;
}

public Mono<PostDTO> getPost(UserDTO user, UUID id) {
    return postRepository.getPost(user, id)
            .flatMap(post -> {
                RuntimeException denied = accessDenial(post, user, id);
                if (denied != null) return Mono.error(denied);
                return loadAttachments(user, id, post);
            })
            .flatMap(post -> getVodAttachments(user.getSiteId(), post.getId())
                    .collectList().map(vods -> { post.setVods(vods); return post; }));
}
```

```java
@Test
@DisplayName("멤버십 글을 멤버십이 만료된 위버스 계정이 조회하면 MembershipRequiredException으로 거부한다")
void expiredMembershipIsDenied() {
    var denied = PostService.accessDenial(membershipPost(), expiredUser(), id);
    assertThat(denied).isInstanceOf(MembershipRequiredException.class);
}
```

세 번째 결과(예: "허용하되 썸네일을 블러 처리")가 생기면 `null` 반환으로는 표현할 수 없다. 그때 2단계로 올린다: `sealed interface Decision permits Allow, Deny, AllowBlurred`와 `default` 없는 `switch`. 결과가 하나 더 늘면 컴파일러가 빠진 분기를 알려 주므로(Java 21 이상의 `sealed` + `switch` 표현식) 에이전트가 세션 안에서 스스로 고친다.

## 전/후 예시 2 — 렌즈 ①, 설정값에 든 결정 조건

전: 레포가 만든 캐시 애노테이션의 키에 권한 조건이 들어 있다. "누구끼리 응답을 공유해도 되는가"가 접근 판정 코드와 이 문자열 두 곳에 있다. 접근 규칙에 조건이 추가될 때 키를 안 고치면 다른 계정의 캐시가 내려간다.

```java
@ReactiveCacheable(value = CacheKey.POST,
    key = "{#user.siteId, #user.hasAdminRole(), #user.isMembershipValid(), #id, #boardCode}")
public Mono<PostDTO> getPost(UserDTO user, UUID id, String boardCode) { ... }
```

세 질문: 출처는 레포(`core.common.cache`), 가시성은 메서드 위 애노테이션이라 보임, 결정 관여는 키에 권한 조건이 있으니 관여. 결론은 애스펙트 유지, 조건의 관리 위치 이동.

후: 키의 유저 부분을 접근 판정 메서드들 옆의 메서드 하나로 모은다. 지식이 한 곳이 되고, 접근 판정에 입력이 추가되면 같은 파일에서 캐시 범위도 고치게 된다.

```java
// UserDTO.java — isWeverseAccount(), isMembershipValid() 옆
public String cacheScope() {
    return siteId + ":" + hasAdminRole() + ":" + isMembershipValid();
}

@ReactiveCacheable(value = CacheKey.POST, key = "{#user.cacheScope(), #id, #boardCode}")
```

그리고 `CLAUDE.md`에 한 줄: "`@ReactiveCacheable` 키의 유저 부분은 `UserDTO.cacheScope()`만 쓴다. 접근 판정이 읽는 유저 속성이 늘면 그 메서드에 추가한다."

리뷰 코멘트도 이 수준으로 쓴다 — "구조가 나쁘다"가 아니라 "이 판정을 같은 파일의 static 메서드로 빼면 목 없이 테스트된다", "이 키의 권한 조건을 접근 판정 옆으로 옮기면 지식이 한 곳이 된다".
