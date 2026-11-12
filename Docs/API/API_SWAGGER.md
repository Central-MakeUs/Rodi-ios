# RODI API · Swagger

RODI backend API 작업의 계약과 Data 흐름을 정의한다. 현재 코드는 사실의 원본이고 API 계약은 작업 대상 환경의 Swagger를 원본으로 삼는다.

API를 추가·변경·제거하는 작업은 이 문서의 최근 검증 기록과 [TODO.md](../TODO.md)의 대상 계약만 함께 갱신한다. 과거 전체 인벤토리는 기본 컨텍스트로 읽지 않는다.

## Source Of Truth

1. Swagger에서 environment, path, version, method와 실제 요청·응답 예시를 확인한다.
2. 인증, parameter 위치, wrapper, nullable 여부를 확인한다.
3. 인접한 `Data/Remote`, `Data/RepositoryImpl`, `Domain` 구현을 검색한다.
4. Swagger와 DTO가 다르면 환경·version을 먼저 확인하고, 실제 불일치라면 DTO부터 Presentation까지 전파한다.

optional, 기본값, enum, cursor를 추정하지 않는다. Swagger와 실제 응답이 다르면 차이를 기록해 서버 계약을 확인한다.

## Standard Flow

```text
Swagger resource
  -> Data/Remote/<Resource>/<Resource>API
  -> Data/Remote/<Resource>/DTO/Request|Response
  -> <Resource>RemoteDataSource
  -> Data/RepositoryImpl/<Concept>/<Concept>RepositoryImpl + Mapper
  -> Domain/<Concept> entity + repository protocol
  -> Presentation reducer/service
```

현재 `Auth`, `Member`, `Place`, `RecentSearch`를 `AppDependencies`가 조립해 feature에 주입한다.

## Layer Contracts

### API Target

- `<Resource>API`는 method, path, query/body, encoding, 인증 여부, timeout을 선언한다.
- query parameter는 `parameters`와 `.url`, JSON body는 Request DTO와 `.json`을 사용한다.
- endpoint가 요구하지 않는 header나 인증은 추가하지 않고 path와 version은 Swagger에 맞춘다.
- 민감한 token이나 정확한 사용자 좌표를 로그에 남기지 않는다.

### DTO

- Request/Response DTO는 `Data/Remote/<Resource>/DTO` 아래에 둔다.
- key 이름, 중첩 구조, 배열, enum raw value, 숫자 타입은 Swagger 응답 그대로 모델링한다.
- nullable 또는 누락 가능한 field만 optional로 선언한다.
- 서버 필수값을 디코딩 편의를 위해 optional로 바꾸거나 임의 기본값으로 숨기지 않는다.
- 화면 상태·SDK 타입을 넣거나 DTO를 Domain entity처럼 재사용하지 않는다.

### RemoteDataSource

- RemoteDataSource만 `NetworkManager`로 API target을 실행하고 DTO를 반환한다.
- RemoteDataSource와 API Target은 Request DTO·query DTO·원시 path 식별자만 받고, Domain query·submission을 직접 받지 않는다.
- 공통 `ServerResponse`의 payload·빈 응답 검증은 `Data/Remote/Support/ServerResponseHandler`를 사용한다. endpoint별 wrapper가 다르면 이 helper를 강제 적용하지 않는다.
- public endpoint는 unauthenticated manager, JWT endpoint는 authenticated manager를 사용한다.
- HTTP/decoding/transport 오류는 공통 `NetworkError` 흐름을 유지한다.

### Repository And Mapper

- `RepositoryImpl`은 RemoteDataSource를 호출하고 Mapper로 DTO를 Domain 값으로 변환한다.
- RepositoryImpl 또는 리소스 Mapper는 Domain 입력을 Request DTO·query DTO로 변환한 뒤 RemoteDataSource에 전달한다.
- Mapper는 서버 enum 검증, nullable 값의 제품 의미, DTO-to-Domain 변환을 한곳에 모은다.
- 서버 문자열 날짜를 Domain `Date`로 바꾸는 Mapper는 `Data/RepositoryImpl/Support/ServerDateParser`의 지원 포맷만 사용하고, 해석 실패를 임의 기본값으로 바꾸지 않는다.
- 기본값이 제품 정책이면 Mapper에서 명시하고, Swagger의 누락을 무조건 정상값으로 만들지 않는다.

### Domain

- Domain은 제품 entity, query/value model, repository protocol과 순수 policy를 소유한다.
- Domain은 DTO, RemoteDataSource, RepositoryImpl, NetworkManager를 import하거나 노출하지 않는다.
- Domain은 SwiftUI, UIKit, KakaoMapsSDK 같은 UI·외부 SDK 타입을 알지 않는다.

### Presentation

- Reducer와 feature Service는 Domain repository protocol과 Domain 값만 사용한다.
- Presentation에서 DTO, API target, RemoteDataSource, NetworkManager를 직접 사용하지 않는다.
- Reducer가 loading/error/success, 취소, 최신 응답 여부와 pagination 상태를 소유한다.

## Response Wrapper And Errors

RODI backend의 현재 공통 성공 응답은 `ServerResponse<T>`다.

```text
isSuccess: Bool
code: String
message: String
data: T?
traceId: String?
```

- payload 응답은 `isSuccess == true`이고 `data`가 있을 때만 성공으로 반환한다.
- payload 없는 성공은 `ServerResponse<EmptyResponse>`로 받고 `isSuccess`를 확인한다.
- 실패는 `code`와 `message`를 보존한 `NetworkError.apiError`로 변환한다.
- endpoint별 wrapper가 다르면 공통 wrapper에 억지로 맞추지 말고 Swagger 계약대로 모델링한다.

## Authentication, Encoding, And Cursor

- 구현 전 public/JWT 여부와 token refresh 적용 여부를 endpoint별로 확인한다.
- GET query와 JSON body를 혼동하지 말고 Swagger의 parameter 위치를 그대로 따른다.
- cursor의 optional·빈 문자열·`size`와 items, `hasNext`, `nextCursor`, `totalCount` 계약을 확인한다.
- 다음 page는 현재 query·bounds와 같은 요청일 때만 append하고, stale 응답은 reducer에서 버린다.

## Environment Verification

| 환경 | API / Swagger |
| --- | --- |
| Dev | `https://dev-api.stillstar.store` · [Swagger](https://dev-api.stillstar.store/swagger-ui/index.html) · [OpenAPI](https://dev-api.stillstar.store/v3/api-docs) |
| Prod | `https://api.stillstar.store` · [Swagger](https://api.stillstar.store/swagger-ui/index.html) · [OpenAPI](https://api.stillstar.store/v3/api-docs) |

- base URL은 `RODI_API_BASE_URL`을 통해 현재 build environment에 주입된다.
- `Rodi Dev`/Debug와 `Rodi`/Release 각각에서 Swagger 환경과 앱 endpoint가 같은지 확인한다.
- URL 누락 시 다른 환경이나 운영 URL로 자동 fallback한다고 가정하지 않는다.
- secret, OAuth token, local xcconfig 값은 문서, diff, 로그에 복사하지 않는다.

## Connection Status And Verification

`연결됨`은 API Target·DTO·Mapper·Domain·호출 경로가 존재한다는 뜻이다. 최신 Swagger field, 인증과 실제 실행까지 확인했다는 의미가 아니다.

`Data 준비 완료`는 API Target·DTO·RemoteDataSource만 존재한다는 뜻이다. Domain·Presentation 연결과 실제 응답 decoding·인증·실행 검증을 포함하지 않는다.

- MUST 실제 계약을 확인한 경우 검증일, 환경, Method·Endpoint와 schema·decoding·인증·실행 중 확인한 범위를 함께 기록한다.
- MUST 대상 endpoint 행만 추가하거나 갱신하고 과거 전체 개수나 파일 수를 현재 계약의 근거로 사용하지 않는다.
- MUST 관리자·운영 전용 API를 앱 연결 대상에서 제외하고 사유를 기록한다.
- MUST 해결되지 않은 서버 계약을 [TODO.md](../TODO.md)의 `API` 항목에서 관리한다.

| 검증일 | 환경 | Method·Endpoint | 코드 경로 | 검증 범위 | 상태 |
| --- | --- | --- | --- | --- | --- |
| 2026-08-20 | 당시 Swagger 환경 | 전체 45개 endpoint | API Target·DTO·Repository 인벤토리 | 경로 존재 여부 중심, field·실행 전체 검증 아님 | [과거 전체 점검](../Archive/API/API_CONNECTION_STATUS_2026-08-20.md) |
| 2026-11-02 | Dev·Prod | 전체 경로·schema 대조 | 현재 API Target·Review DTO 대조 | Dev 50개·Prod 49개 operation, 차이는 후기 폼·후기 평가 및 공유 폼 schema; 인증된 실행 미검증 | `API-004` 확인 필요 |
| 2026-11-02 | Dev | GET `/api/v1/places/coordinates` | PlaceAPI → PlaceCoordinateDTO | 공개 실행 성공, `COMMON_200`·118개; 전체 DTO decoding·앱 실행은 미검증 | 공개 연결 확인 |
| 2026-11-02 | Dev | GET `/api/v1/members/me` | MemberAPI → MemberProfileResponseDTO | token 없이 HTTP 401·`AUTH_401_6`; 로그인·refresh·회원 조회 성공은 미검증 | 인증 검증 대기 |
| 2026-11-02 | Prod | GET `/api/v1/members/me/onboarding-form` | MemberAPI → DTO·RemoteDataSource → MemberOnboardingFormMapper → MemberRepository → OnboardingProfileReducer | schema 기반 연결·합성 fixture 점검; token 없는 GET은 401·AUTH_401_6 | 연결됨 / 인증된 실제 응답·실기기 검증 대기 (`QA-050`) |
| 2026-11-02 | Dev | GET `/api/v1/members/me/onboarding-form` | MemberAPI → DTO·RemoteDataSource → MemberOnboardingFormMapper → MemberRepository → OnboardingProfileReducer | 환경별 주소·인증 경로 유지; 누락 규칙의 Prod fallback 없음, token 없는 GET은 401·AUTH_401_6 | 연결됨 / 실제 응답·누락 규칙 확인 대기 (`API-004`, `QA-050`) |
| 2026-11-02 | Dev·Prod | GET `/api/v1/members/nickname/availability` | MemberAPI → MemberNicknameAvailabilityQueryDTO·ResponseDTO → MemberRemoteDataSource | schema 대조; 30일 제한의 `nicknameChangeableAt` 포함 | Data 준비 완료 / Domain·Presentation 미연결 / 실행 미검증 |
| 2026-11-02 | Dev·Prod | PATCH `/api/v1/members/me` (닉네임) | MemberAPI → MemberNicknameUpdateRequestDTO·ResponseDTO → MemberRemoteDataSource → MemberMapper·MemberRepositoryImpl → MemberRepository → MyNicknameReducer | schema·정적 경로 대조; nickname만 전송, 확정 nickname 반환·nullable nicknameChangeableAt 수신 | 연결됨 / 실제 PATCH·인증·UI 실행 미검증 |
| 2026-11-12 | Dev·Prod | PUT `/api/v1/members/me/sort-tags` | 홈 필터 → MemberRepository → MemberRemoteDataSource → MemberAPI | 인증 JSON `sortTags`; 초기화는 빈 배열, 저장 성공 후 GET 갱신 | 연결됨 / Dev 테스트 계정 실제 저장 대기 (`QA-051`); Prod 쓰기 미실행 |
| 2026-11-11 | Dev만 | GET `/api/v1/places/{placeId}/review-form` | ReviewAPI → DTO·RemoteDataSource → ReviewMapper·ReviewRepository → ReviewWritingReducer | `showWhen`·코스 문제 선택지·직접 입력 규칙 대조; Prod에는 호출하지 않음 | 연결됨 / 인증된 실행 미검증 |
| 2026-11-11 | Dev만 | GET `/api/v1/courses/report-form` | CourseRemoteDataSource → CourseMapper·CourseRepository → CourseReportReducer | `FormResponse` 공유 schema와 복수 선택·기타 입력 계약 대조 | 연결됨 / 인증된 실행 미검증 |
| 2026-11-11 | Dev만 | POST `/api/v1/courses/{courseId}/report` | CourseReportReducer → CourseRepository → CourseReportRequestDTO·CourseRemoteDataSource | `courseIssues`·`detail` JSON 및 빈 성공 응답 schema 대조 | 연결됨 / 실제 제출 미실행 |
| 2026-11-12 | Dev·Prod | GET `/api/v1/places/clusters` | 홈 지도 → PlaceRepository → PlaceMapper·PlaceRemoteDataSource → PlaceAPI | 공개 GET; 서울 고정 범위·`PARKING`에서 두 환경 모두 장소 6개·단계 12개 | 연결됨 / 공개 GET 확인 / 지도 QA는 `API-003` |
| 2026-11-12 | Dev·Prod | GET `/api/v1/places` | Home 적용 필터 → PlaceListQuery → PlaceMapper → PlaceListQueryDTO → PlaceAPI | 지도와 같은 범위·유형 사용; 두 환경 공개 GET의 `totalCount` 6 | 연결됨 / 공개 GET 확인 / 인증 목록·페이지네이션 검증 대기 (`QA-051`) |
| 2026-11-02 | Dev·Prod | GET `/api/v1/places/search` | HomeSearchState → PlaceSearchQuery → PlaceMapper → PlaceSearchQueryDTO → PlaceAPI | `practiceTypes` 콤마 query, 빈 배열 생략; 검색 진입 시 적용 필터 snapshot 사용 | 요청 경로 반영 / 실제 검색 실행 검증 대기 (`QA-051`) |

2026-11-11 Dev 후기 작성·수정은 서버 폼을 조회하고 기존 두 페이지에 문항·선택지·입력 제약을 반영한다. 추천은 난이도·혼잡도, 비추천은 코스 문제 1개 이상과 선택에 따른 직접 입력을 검증한다. 비추천 사유는 후기 POST·PUT의 `courseIssues`·`courseIssueDetail`로만 보내며, 별도 코스 신고를 중복 제출하지 않고 공개 코스 상세에도 표시하지 않는다. 본인 후기 수정은 기존 상세 응답의 저장 값으로 초기화한다. Prod는 폼 미제공이 확인되어 기존 흐름을 유지하고, Dev의 폼 조회 실패 시 Prod 계약이나 하드코딩 폼으로 대체하지 않는다. [TODO](../TODO.md)의 `API-004` 호환성 차단은 유지한다.

Dev Debug 빌드와 후기·코스 신고 합성 DTO XCTest 4건을 통과했다. 실제 인증 응답과 제출은 검증하지 않았다.

2026-11-02 조회 당시 Dev `OnboardingFormResponse.steps`와 `ReviewFormResponse.steps`가 같은 `Step`·`Question` schema를 참조해 온보딩에 필요한 `skippable`·`maxSelect`·`exclusive` 등이 명세에서 빠져 있었다. 2026-11-11 조회한 후기 작성 폼은 별도의 `ReviewFormStep`·`ReviewFormQuestion`을 참조한다. 온보딩 실제 응답과 누락 규칙은 별도 확인 대상이다.

후속 승인으로 온보딩은 실제 응답 확보 전 Swagger 기준 연결을 구현하고, 인증된 응답 확인은 앱 로그인 뒤로 이동했다. 폼의 문구·순서·선택지·필수·조건부 노출·단독 선택·후속 생략·상한·추가 정보 건너뛰기를 연결했다. DTO는 Dev 명세에 없는 속성도 수신할 수 있지만 `skippable` 또는 순위 문항의 `maxSelect` 등 해석에 필요한 값이 실제로 없거나 코드·제출 제약이 호환되지 않으면 오류·재시도 화면을 표시한다. 기존 하드코딩 폼과 다른 환경의 값으로 대체하지 않는다. 레벨 계산·기존 제출 형식·초안 저장 형식은 유지한다. 정상 응답 fixture는 아직 없으며 합성 입력 검증을 실제 서버 검증으로 간주하지 않는다.

Dev·Prod 모두 `/places/coordinates`는 deprecated다. 홈 지도는 `/places/clusters`로 전환했으며 이전 경로로 대체하지 않는다. 유효한 첫 범위, 재검색, 지역 이동 완료, 필터 저장 성공 시 조회한다. 일반 이동·확대와 클러스터 탭은 기존 응답의 확대 단계와 범위만 사용한다.

후속 닉네임 수정 작업에서는 PATCH를 마이페이지에 연결했다. 사용 가능 여부 GET은 선행 호출하지 않으며 계속 Data 준비 상태다. 중복·금칙어·변경 주기는 PATCH 서버 응답으로 판정한다. 저장 성공 시 반환된 닉네임만 반영하고 별도 프로필 GET은 실행하지 않는다. 실제 저장·키보드·실기기 확인은 `QA-049`에 남긴다.

장소 목록·검색·클러스터의 `practiceTypes`는 조회 결과를 제한하는 query이며 회원 정렬 기준 저장과 별개다. 홈 필터는 `/sort-tags`만 호출한다. 홈 자동완성은 기존 `/related-search`를 유지하며 `/search` helper를 새로 호출하지 않는다.

새 기록은 다음 형식을 사용한다.

```md
| YYYY-MM-DD | Dev 또는 Prod | METHOD `/path` | Target → DTO → Mapper → Domain → Presentation | schema / decoding / 인증 / 실제 실행 중 확인한 범위 | 연결됨 또는 확인 필요 |
```

## Non-Swagger SDK Boundary

Kakao Map과 Kakao Directions는 RODI backend Swagger resource가 아니다.
이런 SDK 호출은 해당 feature의 `Service` 또는 `Adapter`에 두고 Data/Domain API 계층으로 위장하지 않는다.
