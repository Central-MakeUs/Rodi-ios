# Data 레이어 규칙

## 목적

`Data`는 Swagger·SDK·로컬 저장소 같은 외부 표현을 Domain 계약으로 변환한다. 서버 구조가 화면과 제품 모델까지 전파되지 않게 하는 경계다.

## MUST

- MUST 리소스별 API Target, Request DTO, Response DTO, RemoteDataSource, Mapper, RepositoryImpl을 Data에 둔다.
- MUST Request와 Response DTO를 서로 다른 타입으로 작성한다. 서버가 동일 구조를 명시할 때만 같은 DTO 재사용의 근거를 남긴다.
- MUST DTO의 optional, wrapper, enum raw value, `Int64`, cursor, 인증 요구사항을 Swagger와 실제 응답 기준으로 모델링한다.
- MUST `RepositoryImpl`이 DTO·외부 SDK 값을 Domain Entity 또는 Domain query/result로 변환한 뒤 반환한다.
- MUST RemoteDataSource와 API Target은 Data DTO·원시 path 식별자만 입력으로 받는다. Domain query·submission·enum을 직접 받지 않는다.
- MUST RepositoryImpl 또는 리소스 Mapper가 Domain 입력을 Request DTO·query DTO로 변환한 뒤 RemoteDataSource에 전달한다.
- MUST Data 계층에서 API 오류, decoding 오류, 외부 SDK 오류를 앱이 처리 가능한 typed error로 보존한다.
- MUST 공통 `ServerResponse` wrapper의 payload·빈 응답 검증은 `Data/Remote/Support`에서 일관되게 처리하고, 리소스별 RemoteDataSource에 같은 guard를 복제하지 않는다.
- MUST 서버 문자열 날짜를 Domain `Date`로 변환할 때 `Data/RepositoryImpl/Support/ServerDateParser`를 사용한다. 지원하지 않는 날짜 형식은 임의 기본값 대신 Mapper에서 `NetworkError.decodingFail`로 처리한다.
- MUST Local 저장 구현은 사용자의 명시적 범위가 있을 때만 `Data/Local`에 추가·수정한다.
- MUST `Data/Local`은 payload·저장 key·encoding 같은 persistence 표현만 소유한다. Feature 화면 session, route, 화면 복원 정책은 Presentation Feature가 소유한다.
- SHOULD Mapper를 API Target 또는 RepositoryImpl과 가까운 리소스 경계에 두고, 변환 규칙을 Feature View에 흩어 놓지 않는다.
- SHOULD API 추가·변경·삭제 시 `Docs/API/API_CONNECTION_STATUS.md`를 같은 작업에서 갱신한다.

## MUST NOT

- MUST NOT SwiftUI View, Presentation State, Feature route를 Data에 둔다.
- MUST NOT DTO, `ServerResponse`, `NetworkManager`, RemoteDataSource를 Presentation에 노출한다.
- MUST NOT RemoteDataSource 또는 API Target에서 Domain query·submission의 필드를 직접 읽어 wire parameter·request body를 조립한다.
- MUST NOT Swagger의 화면용 문구·색상·layout 값을 DTO에 추가한다.
- MUST NOT API 호출 결과를 Data에서 임의의 UI 문구나 Snackbar로 변환한다.
- MUST NOT 공통 helper를 이유로 API Target별 인증, path, request DTO, endpoint별 response wrapper 차이를 숨기거나 강제로 통일한다.
- MUST NOT Domain Repository protocol을 Data 구현 세부사항에 맞추어 설계한다.

## 검토 기준

- endpoint 변경 시 `API → DTO → DataSource → Mapper → RepositoryImpl → Domain` 경로가 끊기지 않는지 확인한다.
- DTO 변경 뒤에는 성공·빈 값·nullable·decoding 실패·인증 오류를 최소한 정적으로 검토한다.
- Data 리팩터링 뒤에는 영향 endpoint의 실제 요청 조건과 Dev Debug build를 확인한다.
