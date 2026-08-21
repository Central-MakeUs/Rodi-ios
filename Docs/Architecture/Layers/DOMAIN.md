# Domain 레이어 규칙

## 목적

`Domain`은 RODI 제품이 사용하는 언어와 계약을 표현한다. 모바일 화면이나 Swagger의 구조가 아니라 코스, 장소, 후기, 연습, 회원 같은 제품 개념을 소유한다.

## MUST

- MUST Entity를 제품 의미와 단위가 드러나는 이름으로 작성한다.
- MUST Repository protocol을 앱 기능 관점의 계약으로 정의하고 Data 구현체는 그 계약을 따르게 한다.
- MUST 순수 제품 policy와 계산이 외부 I/O나 UI 상태를 알지 않게 한다.
- MUST pagination·filter·submission처럼 제품이 필요로 하는 입력·출력만 Domain에 노출한다.
- SHOULD 독립적으로 재사용되는 제품 규칙이 생길 때만 UseCase 또는 Policy 타입을 추가한다.
- SHOULD 서버 필드 이름과 제품 의미가 다를 때 Mapper에서 변환하고 Domain 이름을 서버 raw field에 맞추지 않는다.

## MUST NOT

- MUST NOT Alamofire, Firebase, Kakao SDK, SwiftUI, UIKit, DTO, API endpoint를 import하거나 노출한다.
- MUST NOT `ServerResponse`, HTTP status code, request body, response wrapper를 Domain Entity에 포함한다.
- MUST NOT 화면 문구, 색상, padding, loading flag, navigation route를 Domain에 둔다.
- MUST NOT Repository protocol이 RepositoryImpl, DataSource, DTO의 구체 타입을 요구하게 한다.

## 검토 기준

- Domain 파일을 읽을 때 서버 path나 SwiftUI 화면을 알아야 한다면 경계 누수를 찾는다.
- Entity 변경 뒤에는 Data Mapper와 Presentation 변환이 각각 제품 의미를 유지하는지 확인한다.
- Domain 리팩터링은 리소스 단위로 진행하고, 사용자 동작·API 계약 변경 커밋과 섞지 않는다.
