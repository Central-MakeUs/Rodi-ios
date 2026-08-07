# RODI API and Swagger

RODI backend API 작업의 계약과 Data 흐름을 정의한다. 현재 코드는 사실의 원본이고 API 계약은 작업 대상 환경의 Swagger를 원본으로 삼는다.

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
- public endpoint는 unauthenticated manager, JWT endpoint는 authenticated manager를 사용한다.
- HTTP/decoding/transport 오류는 공통 `NetworkError` 흐름을 유지한다.

### Repository And Mapper

- `RepositoryImpl`은 RemoteDataSource를 호출하고 Mapper로 DTO를 Domain 값으로 변환한다.
- Mapper는 서버 enum 검증, nullable 값의 제품 의미, DTO-to-Domain 변환을 한곳에 모은다.
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

- base URL은 `RODI_API_BASE_URL`을 통해 현재 build environment에 주입된다.
- `Rodi Dev`/Debug와 `Rodi`/Release 각각에서 Swagger 환경과 앱 endpoint가 같은지 확인한다.
- URL 누락 시 다른 환경이나 운영 URL로 자동 fallback한다고 가정하지 않는다.
- secret, OAuth token, local xcconfig 값은 문서, diff, 로그에 복사하지 않는다.

## Non-Swagger SDK Boundary

Kakao Map과 Kakao Directions는 RODI backend Swagger resource가 아니다.
이런 SDK 호출은 해당 feature의 `Service` 또는 `Adapter`에 두고 Data/Domain API 계층으로 위장하지 않는다.
