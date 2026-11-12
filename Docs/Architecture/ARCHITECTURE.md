# RODI Architecture

이 문서는 RODI의 레이어, MVI, feature 배치와 책임 경계를 설명하며, 구체적인 화면 수치나 일시적인 구현 상태는 현재 코드에서 확인한다.
현재 동작은 live code로 확인한다. 이 문서가 정의한 의도와 코드가 다르면 구현 결함인지 문서 drift인지 먼저 판정하고, 코드를 현재 설계의 근거로 자동 승격하지 않는다.

## Layer Structure

현재 top-level은 `App`, `Core`, `Presentation`, `Data`, `Domain`, `Resources`이며 세부 경로는 live filesystem에서 확인한다.

레이어별 고유 계약도 이 문서에서 관리한다. 세부 경로와 현재 구현은 live filesystem에서 확인한다.

| Layer | 목적 |
| --- | --- |
| App | 앱 조립과 시작 수명 관리 |
| Core | 여러 feature가 공유하는 기술 기반 |
| Data | 외부·로컬 데이터를 Domain 계약으로 변환 |
| Domain | 제품 언어와 비즈니스 계약 유지 |
| Presentation | 화면 렌더링·사용자 상호작용·상태 전이 |
| Resources | 실행 리소스 관리 |

### Global Dependency Direction

```text
App ────────────────┐
                    ├── Presentation ──> Domain
                    └── Data ─────────> Domain
Core <──────────── Presentation, Data, App
Resources <──────── App and feature rendering
```

- MUST keep `Domain` independent of `Data`, `Presentation`, `App`, SDK runtime, DTO, and storage implementation.
- MUST let `Data` implement Domain repository protocols and convert external models before returning them.
- MUST let `Presentation` depend on Domain contracts instead of Data implementation types.
- MUST keep `AppDependencies` as the one composition point that knows both Data implementations and Domain contracts.
- MUST NOT create a dependency cycle between top-level layers.
- SHOULD move cross-feature code to Core only after at least two top-level features have a real shared need.

## Layer Contracts

### App

- MUST `RodiApp`, AppDelegate, Root, scene lifecycle과 `AppDependencies` 조립을 App에 둔다.
- MUST SDK·폰트·logging 초기화 순서와 환경 분기를 App에서 명시하고, 동일 dependency graph를 feature에 생성자로 전달한다.
- MUST Root가 인증·온보딩·메인 route와 feature root 조립만 소유하게 한다.
- SHOULD lifecycle event를 typed Action으로 전달하고, feature async work·취소·재시도는 해당 Reducer 또는 Service가 소유하게 한다.
- MUST NOT Feature UI·세부 상태 전이·DTO·Mapper·제품 I/O를 App에 둔다.
- MUST NOT lifecycle callback에 임의의 `Task`를 추가해 feature I/O를 직접 실행하거나 feature마다 전역 graph를 만든다.

### Core

- MUST `MVICore`, 공통 Network·Logger·Coordinator·design-system Component와 여러 Feature가 관찰하는 system monitor만 Core에 둔다.
- MUST 공통 Component를 두 개 이상의 top-level Feature가 실제로 사용하는지 확인한다.
- MUST Core API가 제품 Feature의 구체 타입 대신 일반 typed value 또는 protocol을 사용하게 한다.
- MUST NOT 코스·후기·회원·연습기록 정책, Feature route 또는 단일 Feature 전용 Component·Service를 Core에 둔다.
- MUST NOT Core가 Presentation·Data의 구체 Feature 타입을 import하거나 App lifecycle 설정을 소유하게 한다.
- MUST `Rodi/Core/Architecture/MVICore`, `Rodi/Core/Coordinator`, `Rodi/Core/Network` 변경에 [AGENTS.md](../../AGENTS.md)의 보호 영역 승인을 적용한다.

### Data

- MUST API Target, Request·Response DTO, RemoteDataSource, Mapper와 RepositoryImpl을 resource 경계에 둔다.
- MUST DTO의 optional, wrapper, raw value, 숫자 타입, cursor와 인증 요구를 Swagger·실제 응답에 맞춘다.
- MUST RepositoryImpl이 Domain 입력을 wire DTO로 바꾸고, 외부 결과를 Domain 값 또는 typed error로 변환해 반환하게 한다.
- MUST 공통 응답 wrapper와 서버 날짜 parsing을 기존 `Data/Remote/Support`, `Data/RepositoryImpl/Support` 경계에서 일관되게 처리한다.
- MUST `Data/Local`에는 payload·key·encoding 같은 저장 표현만 두고, 화면 session·route·복원 정책은 Feature가 소유하게 한다.
- MUST NOT DTO·DataSource·NetworkManager·SDK 타입을 Domain 또는 Presentation에 노출한다.
- MUST NOT Swagger가 제공하지 않은 화면 문구·색상·layout을 DTO에 추가한다. 서버 제공 label·placeholder·form metadata는 wire format과 제품 의미의 경계를 명시한다.
- MUST API 변경 기록과 미해결 계약을 [API_SWAGGER.md](../API/API_SWAGGER.md)와 [TODO.md](../TODO.md)의 해당 ID에 반영한다.

### Domain

- MUST 앱에서 사용하는 제품 entity, value·query·submission, repository protocol과 순수 policy를 Domain에 둔다.
- MUST Repository protocol을 endpoint가 아니라 앱 기능 관점의 계약으로 정의한다.
- SHOULD 서버 field 이름과 제품 의미가 다르면 Mapper에서 바꾸고 Domain 이름을 raw field에 맞추지 않는다.
- SHOULD 독립적으로 재사용되는 제품 규칙이 확인된 경우에만 UseCase 또는 Policy를 추가한다.
- MUST NOT DTO, HTTP status·wrapper, DataSource·RepositoryImpl, SwiftUI·UIKit·외부 SDK를 Domain에 노출한다.
- MUST NOT 화면 문구·색상·padding·loading·navigation route를 Domain에 둔다. 서버 form metadata가 제품 입력 계약에 필요하면 wire field와 제품 정책의 소유 경계를 명시한다.

### Presentation

- MUST View가 State를 렌더링하고 사용자·runtime event를 Action으로 전달하게 한다.
- MUST Reducer가 상태 전이, Effect orchestration, 취소·중복 요청·stale response 판단을 소유하게 한다.
- MUST Feature Service·Adapter가 Store·Reducer State·SwiftUI View를 소유하지 않게 한다.
- MUST child가 typed Delegate로 필요한 결과만 부모에 전달하고 sibling State·Action에 직접 접근하지 않게 한다.
- MUST selectable row·tile·card·container의 전체 영역을 같은 primary action에 연결한다.
- MUST NOT DTO·NetworkManager·API Target·DataSource·RepositoryImpl을 View 또는 Reducer에서 직접 사용한다.
- MUST NOT View `body`나 View-local `Task`에 lifecycle-bound I/O와 business decision을 숨긴다.
- MUST NOT 파일 길이만 줄이기 위한 폴더·Service·child Reducer를 만든다.

### 서버 연결 전 UI 구현

- MUST 실제 제품 화면에서 기존 Domain Entity와 기능 계약을 먼저 확인하고, 새 Entity에는 확정된 제품 개념만 표현한다.
- MUST NOT 미확정 서버 응답을 추측해 Entity, DTO 또는 endpoint를 미리 만든다.
- SHOULD 단순 화면에는 mock Entity를 직접 주입하고, 조회·로딩·실패·재시도 상태가 필요하면 기존 Repository 계약의 mock 구현을 주입한다.
- MUST 날짜 표시, 상대 시간, badge 색상, image 이름 같은 표시 변환을 Presentation에서 처리한다.
- MUST Entity와 화면 모델 사이에 실제 변환 책임이 있을 때만 Presentation Mapper를 둔다.
- MUST NOT 변환할 값이 없는데 형식적으로 Mapper를 추가한다.
- MUST 실제 API 연결 시 Data의 DTO→Entity Mapper와 Repository 구현을 연결하고, 서버 연결 여부와 무관한 화면 계약을 유지한다.
- MUST 임시 디자인 실험에는 Presentation 표시 모델을 사용할 수 있으며, 실험만을 위해 제품 Domain Entity를 추가하지 않는다.
- MUST 서버 연결 요청이 없는 구현 결과에 mock data 사용 여부를 명시하고, 이미 연결된 API를 임의로 mock으로 교체하지 않는다.

기본 데이터 흐름은 `mock Entity → 필요한 표시 변환 → 화면`이다. 서버가 연결되면 앞단에 `DTO → Data Mapper → Entity`가 추가된다. Domain은 서버 표현과 독립적인 제품 계약이며, 제품 요구가 바뀌면 함께 변경될 수 있다.

### Resources

- MUST asset catalog, font, plist와 localization을 실제 target membership과 함께 관리한다.
- MUST asset 이름을 화면 위치가 아닌 안정적인 의미로 짓고, Figma export의 scale·투명 여백·rendering mode를 확인한다.
- MUST app과 extension에 필요한 resource의 target 경계를 명확히 유지한다.
- SHOULD 미사용·중복·과도한 image·font·framework를 release 전에 점검한다.
- MUST NOT 제품 로직·Swift·Markdown·임시 screenshot·key·token을 Resources에 둔다.
- MUST NOT Figma 임시 URL, 기기 bezel·status bar·home indicator를 앱 resource로 추가한다.

## Composition Root

`AppDependencies`는 token store, 인증·비인증 네트워크, remote data source와 repository를 조립한다. `RootView`가 만든 동일한 graph를 내려보내고 Reducer는 생성자로 의존성을 받는다.

- MUST NOT View나 Reducer에서 repository 구현 또는 `NetworkManager`를 새로 만든다.
- SHOULD feature 전용 Service가 주입된 계약을 사용해 해당 feature 안에서 조합하게 한다.
- MUST NOT 전역 service locator나 숨은 singleton lookup을 의존성 전달 수단으로 추가한다.

## MVICore Flow

```text
View -> Action -> Reducer(State mutation) -> Effect
     <- Store publishes State <- Action
```

- MUST `State`를 화면이 렌더링하는 제품 상태의 단일 원본으로 유지한다.
- MUST `Action`이 사용자 의도, lifecycle·SDK event, Effect 결과를 표현하게 한다.
- MUST `Reducer`가 상태 전이, 의도 해석, Effect 시작·취소를 담당하게 한다.
- MUST `Effect`가 `.none`, `.send`, `.run`, `.cancel`을 제공하고 child Action으로 `map`할 수 있게 유지한다.
- MUST `Store`가 `@MainActor`에서 Reducer를 실행하고 state를 publish하며 Effect task를 관리하게 한다.
- MUST Reducer가 취소 ID, request revision과 최신 응답 판단을 소유하게 한다.
- MUST NOT View lifecycle에 비동기 제품 로직을 숨긴다. Action과 Effect로 표현한다.

독립 feature root는 하나의 Store를 소유할 수 있다. 부모 Reducer에 합성된 child는 별도 Store를 만들지 않고 부모 State의 child State와 명시적인 `send(Action)`을 전달받는다.
View 전용 animation·gesture 진행값은 로컬 상태일 수 있지만 제품 상태를 복제하지 않는다.

## Concurrency · Actor Isolation

- MUST use `@MainActor` only for UI state, Store·Reducer coordination, main-thread-only SDK APIs, 또는 실제로 main actor가 필요한 코드에 적용한다.
- MUST NOT `@MainActor`를 isolation compiler error를 없애는 수단으로 추가한다. 적용 전 해당 상태·SDK·API가 실제로 main actor를 요구하는지 확인한다.
- MUST NOT `async` 또는 `Task`가 자동으로 background execution을 보장한다고 가정한다.
- MUST NOT `Task.detached`로 actor isolation 오류를 우회한다. detached 작업은 독립 lifetime, cancellation, priority, `Sendable` 경계를 명확히 설명할 수 있을 때만 사용한다.
- MUST keep UI state mutation on the main actor. CPU-heavy pure work는 main actor 밖에서 수행할 수 있으나, UI state와 main-thread SDK 접근을 임의로 밖으로 옮기면 안 된다.
- MUST every `await` 뒤 route, request revision, cancellation, 또는 필요한 State가 여전히 유효한지 확인한 뒤에만 비동기 결과를 반영한다.
- SHOULD treat `@MainActor`가 이미 선언된 protocol·Store·Reducer 안의 중복 annotation을 자동 제거 대상이 아니라 의도와 public isolation contract를 검토할 신호로 본다.

## Async Work Ownership

- MUST give user-initiated or lifecycle-bound asynchronous work an explicit owner, cancellation ID 또는 stale-result guard를 둔다.
- MUST let Reducer Effect 또는 lifetime이 명확한 Service가 제품 비동기 작업을 시작하게 한다. View `body`는 비동기 제품 작업을 시작하면 안 된다.
- MUST NOT swallow cancellation with a broad `catch`. cancellation 뒤에도 결과가 도착할 수 있는 legacy callback·SDK·network 작업은 revision 검증으로 화면 재등장을 막는다.
- SHOULD use structured concurrency when the parent owns the work lifetime. unstructured `Task`는 부모와 독립된 lifetime이 제품 요구사항으로 명확할 때만 사용한다.

## Parent And Child Reducers

부모는 child State와 Action을 같은 형태로 합성한다.

```swift
var child = ChildReducer.State()
case child(ChildReducer.Action)
return childReducer.reduce(&state.child, with: action).map(Action.child)
```

- MUST NOT child가 sibling State를 읽거나 sibling Action을 직접 보낸다.
- MUST child 밖으로 필요한 결과만 `Action.delegate(Delegate)`로 내보낸다.
- MUST 바로 위 부모가 child Delegate를 해석해 자신의 State를 바꾸거나 다른 child Action을 만든다.
- MUST 중첩 부모가 내부 Delegate를 소비하고 상위에 필요한 최소한의 최종 Delegate만 다시 보낸다.
- MUST NOT 상위 View가 child 내부 State를 검사해 feature 간 정책을 결정한다.
- MUST Delegate에 화면 전체 State 대신 경계에 필요한 typed value와 사용자 의도만 담는다.

## Responsibility Boundaries

- **View**: MUST State를 렌더링하고 사용자·runtime event를 Action으로 전달한다.
- **Reducer**: MUST 상태 전이, Effect orchestration, 취소와 최신 응답 여부를 결정한다.
- **Service**: MUST 외부 I/O·SDK·UIKit delegate 또는 State를 모르는 순수 계산을 수행한다.
- **Domain**: MUST 제품 개념, repository contract와 순수 policy를 표현한다.
- **Data**: MUST API DTO, data source, mapper와 repository implementation을 구현한다.

MUST NOT Service를 만들 가능성만으로 Reducer 로직을 옮긴다. Service는 Store나 UI State를 소유하지 않으며 결과를 typed value 또는 event로 Reducer에 돌려준다.

## Feature Foldering

새 top-level feature의 기본 형태는 다음과 같다.

```text
Presentation/<Feature>/
  <Feature>View.swift
  <Feature>Reducer.swift
```

Feature root는 진입 View·Reducer와 화면 조립만 담당한다. MUST NOT 여러 단계의 flow나 큰 화면에서 root View 하나에 화면·공통 UI·I/O·표시 모델을 함께 쌓는다. 필요가 생긴 폴더만 단수형으로 추가한다.

- `Component`: feature 안의 여러 화면에서 재사용되거나 독립 interaction 계약을 가진 UI. Button, header, dialog, selector처럼 독립 화면이 아닌 단위에 사용한다.
- `Model`: Presentation 전용 표시 단계, payload, 선택값, route와 feature enum을 둔다. 제품 entity·repository protocol은 Domain에 둔다. 별도 `Enum` 폴더는 만들지 않는다.
- `Service`: 외부 I/O, SDK 호출 또는 State를 모르는 순수 계산을 둔다. Store·Reducer State·SwiftUI View를 소유하지 않는다.
- `SubPage`: Navigation destination뿐 아니라 full-screen 단계, 독립 modal, flow의 한 화면처럼 독립적으로 렌더링되는 화면.
- `Adapter`: SwiftUI와 UIKit·외부 SDK 사이의 변환, delegate와 lifecycle 연결을 둔다. `Service`에 흡수하지 않는다.
- `SubView`: 단일 상위 View의 시각 분해가 필요할 때만 가장 가까운 화면 아래에 둔다. feature 최상위 분류로 사용하지 않으며, 작은 분해는 같은 파일의 `private extension`과 `// MARK: -`를 우선한다.
- 독립 State·Action·Reducer 또는 행동 계약을 가진 영역은 `Section` 같은 범용 폴더 대신 `Review`, `Search`, `Map`처럼 실제 기능 이름의 직접 폴더로 둔다.

다단계 Review flow는 `Flow/ReviewFlowFactory`가 Review 전용 reducer·service를 조립하고, `Flow/ReviewFlowCoordinatorReducer`가 전역 진입 출처·완료 갱신·Snackbar를 중재한다. `ReviewReducer`는 `Prompt`·`Writing`·`SkipReason` named child feature 전환과 최종 Delegate를 중재하고, `ReviewView`는 현재 child State만 전달해 조립한다. 앱 복귀 뒤 측정 continuation·방문 기록·후기 권유는 `DrivePracticeReducer`가 직접 소유한다. Review와 DrivePractice는 서로의 State를 읽지 않고 typed Delegate를 Root가 중계한다. Review root에는 `ReviewView`와 `ReviewReducer`만 둔다. 각 단계 화면은 named child feature의 `SubPage`, 공통 dialog·header·scaffold는 Review 또는 DrivePractice `Component`, 표시 모델은 해당 named feature의 `Model`, repository를 사용하는 요청은 해당 named feature의 `Service`에 둔다. 빈 폴더를 미리 만들지 않는다. 한 feature 내부 공유는 가장 가까운 공통 부모의 `Shared`에 두고, 최소 두 top-level feature에서 재사용되는 것이 확인된 뒤 Core로 올린다.

## UIKit And Kakao Boundary

- SHOULD SwiftUI로 직접 표현할 수 없는 SDK view와 delegate lifecycle에서만 adapter 사용을 검토한다.
- MUST feature 전용 Kakao Map·Directions 구현을 해당 feature의 `Adapter` 또는 `Service`에 둔다.
- MUST adapter가 Reducer State를 렌더링하고 SDK event를 typed Action으로 돌려준다.
- MUST NOT bridge용 transient runtime state를 제품 정책의 원본으로 사용한다.
- MUST NOT Domain에 SDK 타입을 노출한다. 앱 전역에서 재사용되는 UIKit bridge만 Core 후보로 검토한다.

## View And Reducer File Style

하나의 책임 안에서 helper와 표시 구획만 길어진 파일은 같은 파일의 extension과 `// MARK: -`로 정리할 수 있다. 독립 State·Action·Effect·수명주기 또는 화면 계약이 확인된 책임은 extension으로 숨기지 않고 child reducer, SubPage, Component, Service 또는 Adapter로 분리한다. 파일 줄 수만으로 두 방식 중 하나를 선택하지 않는다.

```swift
struct FeatureView: View { /* properties, body */ }
// MARK: - Core
private extension FeatureView { }
// MARK: - Layout
private extension FeatureView { }
```

```swift
struct FeatureReducer: Reducer { /* State, Action, dependencies, init */ }
// MARK: - Reduce
extension FeatureReducer { }
// MARK: - Effect
extension FeatureReducer { }
```

작은 파일에 extension이나 MARK를 억지로 추가하지 않는다. 접근 제어는 protocol requirement와 실제 호출 범위에 맞추며, 단지 convention을 맞추려고 넓히거나 좁히지 않는다.

## Refactoring Triggers

- MUST Data 구현이나 `NetworkManager`를 직접 사용하는 Presentation을 Domain contract 주입으로 바꾼다.
- MUST 독립 화면 단계 세 개 이상의 State·Action·Effect를 root가 소유하면 child Reducer와 typed Delegate를 검토한다.
- MUST 일부 의존성만 쓰는 Reducer에 전체 `AppDependencies`를 전달하지 않고 feature 범위 계약으로 줄인다.
- MUST Debug 화면·테스트 API를 제품 UI와 분리하고 Release 제외 조건을 유지한다.
- SHOULD 하나의 View 또는 Reducer가 독립 UI 책임이나 Effect 군을 함께 가진 채 500줄 이상이면 실제 책임 단위 분리를 검토한다.
- SHOULD callback·state가 많아 호출 누락 위험이 생기면 typed route·delegate payload로 묶는다.
- MUST 구조 변경과 사용자 기능·문구·Figma·Swagger 계약 변경을 같은 커밋에 섞지 않는다.
- MUST 확인된 구조 개선과 검증 대기는 [TODO.md](../TODO.md)에 기록하고, 완료되면 항목을 삭제한다.

## Korean Code Comments

주석은 코드 동작을 번역하는 대신 다른 코드가 안전하게 사용하기 위해 필요한 책임·경계와 코드만으로 알기 어려운 이유를 설명한다.

### `///` 문서화 주석

- MUST Repository protocol, 외부 통신·SDK Service, feature 간 Reducer·Route·Delegate처럼 외부 계약을 이해해야 하는 대상에만 필요성을 검토한다.
- MUST 역할·단위·실패 조건·부작용이 이름만으로 불명확한 public API의 입력과 출력을 설명한다.
- SHOULD 인증 필요 여부, DTO 변환 의미와 부모가 해석할 child Delegate 결과를 설명한다.
- MUST NOT `public`이라는 이유만으로 모든 타입에 주석을 달거나 DTO property를 한국어로 반복한다.
- MUST NOT 쉽게 바뀌는 UI 수치·문구·구현 순서를 외부 계약처럼 기록한다.

### `//` 구현 주석

- SHOULD 상태 전환 순서, Effect 취소·중복 방지·재시도, 좌표·거리·시간 단위 변환, UIKit·SDK bridge와 예외 처리의 이유가 불명확할 때만 작성한다.
- SHOULD 성능·배터리·메모리를 위한 구현 판단에는 확인한 문제와 유지할 제약을 함께 적는다.
- MUST 새 주석을 한국어로 간결하게 작성하되 타입명·endpoint·SDK 이름은 원문을 유지할 수 있다.
- MUST NOT 함수·변수 이름을 되풀이하거나 `VStack`, padding, 색상·폰트 같은 단순 배치를 설명한다.
- MUST NOT 책임자·완료 조건 없는 TODO, 추측성 메모, 구현 변경 시 쉽게 낡는 주석을 남긴다.
- MUST NOT 자동 생성 코드나 외부 package·SDK source를 주석 추가 대상으로 삼는다.

리팩터링을 마칠 때 View·Reducer·Data·Domain의 실제 책임, async owner·취소 경계와 주석의 현재성을 함께 확인한다.
