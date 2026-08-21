# 코드 주석 및 문서화 가이드

## 목적

이 문서는 모든 코드에 설명을 추가하는 규칙이 아니다. 리팩터링 이후에도 타입의 책임, 계층 경계, 상태 소유, 화면 전환, 외부 의존성 및 비동기 처리의 이유가 명확히 유지되도록 필요한 곳에만 최소한의 한국어 주석을 작성하는 기준이다.

주석은 코드가 무엇을 하는지 반복하기보다 코드만으로 파악하기 어려운 왜 이 구조와 처리가 필요한지를 설명해야 한다.

## 적용 범위

이 문서는 `Presentation`, `Domain`, `Data` 리팩터링과 새 feature 구현에 적용한다.

- MUST 현재 구현 코드와 실제 프로젝트 구조를 기준으로 문서화한다.
- MUST 프로젝트에 실제로 존재하는 타입과 패턴만 규칙에 포함한다.
- MUST NOT 일반적인 Clean Architecture, MVVM, TCA 개념을 프로젝트에 없는 구조로 강제한다.
- MUST NOT 자동 생성 코드, 외부 패키지 또는 SDK 소스를 문서화·수정 대상으로 삼는다.
- SHOULD 새 feature를 만들거나 기존 feature를 책임 단위로 분리할 때 이 문서를 적용한다.
- SHOULD 코드 변경과 함께 관련 주석이 현재 구현과 일치하는지 검토한다.

## 규칙 우선순위

적용 우선순위는 다음과 같다.

1. 현재 사용자 요청
2. `AGENTS.md`
3. `Docs/Architecture/ARCHITECTURE.md`
4. 실제 구현 코드와 인접 feature의 관례
5. 이 문서

- MUST 상위 규칙과 충돌하는 일반론을 적용하지 않는다.
- MUST 문서와 실제 코드가 다르면 현재 동작의 기준으로 실제 코드를 사용한다.
- SHOULD 문서와 코드의 차이가 반복되는 구조 문제라면 별도 리팩터링 후보로 기록한다.

## 주석 언어와 기본 원칙

- MUST 새 코드 주석과 문서화 주석을 한국어로 작성한다.
- MUST 주석을 간결하게 유지하고 현재 구현을 기준으로 사실만 작성한다.
- MUST NOT 한국어와 영어를 섞은 문장형 주석을 작성한다.
- SHOULD 코드 식별자, API endpoint, 타입명, SDK 이름은 필요한 경우 원문 표기를 유지한다.
- MUST NOT 책임자·기한·맥락이 없는 `TODO`, 추측성 표현 또는 임시 메모를 남긴다.
- MUST NOT 코드 한 줄의 동작을 단순 번역한 주석을 작성한다.

## `///` 문서화 주석 기준

`///`는 외부 계약, 계층 경계 또는 feature 간 전달 책임처럼 다른 코드가 안전하게 사용하려면 설명이 필요한 대상에만 작성한다.

다음 대상은 문서화 주석 필요성을 검토한다.

- Repository Protocol과 앱 기능 관점의 계약
- API, RemoteDataSource, Service의 외부 통신 또는 SDK 연동 책임
- 상위 flow 또는 다른 feature가 알아야 하는 Reducer, State, Action의 책임
- Route, Delegate처럼 feature 간에 전달되는 계약
- 역할, 단위 또는 서버 계약이 이름만으로 불명확한 Domain Model과 DTO
- 부작용, 실패 조건, 호출 순서 또는 단위가 중요한 외부 호출 메서드

- MUST `public` 접근 제어 여부만으로 모든 타입에 `///`를 추가하지 않는다.
- MUST 타입의 책임, 입력·출력 의미 및 유지해야 할 제약만 작성한다.
- SHOULD API 계층에 인증 필요 여부, DTO 변환 의미 및 외부 시스템 의존성을 작성한다.
- SHOULD Reducer Delegate에 부모가 해석해야 하는 결과를 작성한다.
- MUST NOT DTO의 모든 프로퍼티를 단순 번역한 문서화 주석으로 채운다.
- MUST NOT 쉽게 바뀌는 UI 수치, 화면 문구 또는 구현 순서를 `///`에 작성한다.

## `//` 내부 구현 주석 기준

`//`는 구현 이유가 코드만으로 불명확한 지점에만 작성한다.

다음 경우에만 내부 주석을 검토한다.

- 상태 전환 순서와 그 이유
- Effect 취소, 중복 요청 방지, 재시도, 화면 이탈 처리
- 좌표, 거리, 시간, 글자 수 등 단위 변환과 제품 정책 수치
- SwiftUI와 UIKit, Kakao Map, ActivityKit 등 외부 프레임워크 연동 이유
- 배터리, 성능 또는 메모리 사용량을 고려한 처리
- 권한 거부, 외부 앱 미설치, 서버 응답 누락 등 예외 처리 이유
- 임시 선택값과 확정값을 분리한 이유

- MUST 상태 변수명 또는 함수명을 그대로 설명하지 않는다.
- MUST 제품 정책 수치에 해당 수치가 필요한 이유를 함께 작성한다.
- SHOULD 비동기 취소 또는 중복 방지 처리에 방어하려는 사용자 행동이나 화면 전환을 작성한다.
- SHOULD 외부 SDK bridge에 SwiftUI만으로 처리하지 않은 이유를 작성한다.
- MUST NOT 단순 View 배치, padding, `VStack`/`HStack`, 색상 또는 폰트에 과도한 내부 주석을 작성한다.

## 계층별 문서화 기준

### Presentation

- MUST View를 상태 표시와 사용자·runtime 이벤트 전달에 집중시킨다.
- SHOULD child Reducer, Delegate, Route 전환, Effect 취소 경계에만 주석을 둔다.
- SHOULD `@State`, `@Binding`, `@Observable`, `@MainActor`, UIKit bridge의 선택 이유가 불명확할 때만 주석을 작성한다.
- MUST NOT View의 단순 UI 구조를 주석으로 설명한다.
- MUST NOT View가 네트워크, 영속성 또는 복잡한 상태 전환의 이유를 직접 소유하도록 문서화한다.

### Domain

- MUST Repository Protocol에 endpoint가 아니라 앱 기능 관점의 책임을 설명한다.
- SHOULD Domain Model이 표현하는 앱의 의미와 단위를 설명한다.
- MUST 현재 Domain Model이 DTO 또는 Swagger 구조에 의존한다면 이를 숨기거나 절대적인 Domain 규칙처럼 설명하지 않는다.
- SHOULD DTO·Swagger 의존을 별도 아키텍처 리팩터링 후보로 기록한다.
- MUST NOT 서버 필드 구조를 Domain의 영구 계약처럼 문서화한다.

### Data

- MUST API, RemoteDataSource, DTO 매핑 및 외부 SDK 변환처럼 외부 계약 경계에만 주석을 둔다.
- SHOULD 인증 필요 여부, 데이터 손실 가능성 및 서버 값 변환 이유를 설명한다.
- MUST NOT DTO 프로퍼티 전체에 반복 설명을 추가한다.
- MUST NOT Data DTO를 Presentation까지 직접 전달하는 구조를 새로 만들거나 정당화한다.

## 문서화 검토 기준

리팩터링 완료 전 다음 항목을 검토한다.

- MUST 책임 단위로 타입과 폴더가 분리되었는지 확인한다.
- MUST NOT 단순 `extension` 또는 파일 분할만으로 책임 분리가 완료됐다고 판단한다.
- MUST View, Reducer, Domain, Data의 책임 소유가 현재 아키텍처와 일치하는지 확인한다.
- MUST child Reducer의 Delegate와 Route 전환 책임이 명확한지 확인한다.
- SHOULD Domain이 DTO 또는 Swagger 명명·구조에 종속된 부분을 식별한다.
- SHOULD Data DTO가 Presentation까지 직접 전달되는지 확인한다.
- MUST 주석이 무엇을 하는가가 아니라 왜 이 경계와 처리가 필요한지를 설명하는지 확인한다.
- MUST 변경한 코드와 주석이 같은 기준으로 최신 상태인지 확인한다.

## 금지 기준

- MUST NOT 코드 내용을 그대로 반복하는 주석을 작성한다.
- MUST NOT 구현 변경 시 쉽게 낡는 주석을 작성한다.
- MUST NOT 자동 생성 파일이나 외부 패키지 코드에 주석을 추가한다.
- MUST NOT View의 단순 UI 배치를 과도하게 주석 처리한다.
- MUST NOT Swagger DTO 필드를 한국어로 단순 번역하는 주석을 작성한다.
- MUST NOT 근거 없는 TODO, 추측성 메모 또는 책임자 없는 임시 문구를 남긴다.

## 리팩터링 우선 검토 대상

### 즉시 주석 추가 검토 대상

- `Rodi/Presentation/CourseRegistration/CourseRegistrationReducer.swift`: 상위 flow와 child feature 사이의 Route·Delegate 책임을 검토한다.
- `Rodi/Presentation/CourseRegistration/Details/CourseRegistrationDetailsReducer.swift`: 등록 요청 컨텍스트, 폼 검증 및 완료 Delegate의 경계를 검토한다.
- `Rodi/Data/Remote`: 인증이 필요한 API와 외부 SDK 변환 경계를 검토한다.

### 별도 아키텍처 리팩터링 검토 대상

- `Rodi/Domain`: Domain Model과 Repository 계약이 DTO·Swagger 명명 또는 구조에 불필요하게 종속됐는지 검토한다.
- `Rodi/Data/RepositoryImpl`: DTO에서 Domain으로 변환하는 Mapper 책임이 명시적으로 분리됐는지 검토한다.
- `Rodi/Presentation/CourseRegistration`: `Tutorial`, `MapSelection`, `PinEditing`을 child Reducer 책임으로 분리할 수 있는지 검토한다.
