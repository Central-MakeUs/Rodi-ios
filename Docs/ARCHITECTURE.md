# RODI Architecture

이 문서는 RODI의 레이어, MVI, feature 배치와 책임 경계를 설명하며, 구체적인 화면 수치나 일시적인 구현 상태는 현재 코드에서 확인한다.
문서와 코드가 다르면 현재 코드를 기준으로 판단하고 같은 작업에서 문서를 바로잡는다.

## Layer Structure

현재 top-level은 `App`, `Core`, `Presentation`, `Data`, `Domain`, `Resources`이며 세부 경로는 live filesystem에서 확인한다.

### App

- 앱 시작, scene lifecycle, 최상위 route와 feature root 조합을 담당한다.
- `RodiApp`은 로깅, 폰트, 외부 SDK처럼 프로세스 시작 시 필요한 설정만 수행한다.
- `RootView`는 `AppDependencies`를 한 번 만들고 하위 feature root에 전달한다.
- 제품 기능의 세부 상태 전이나 서버 DTO 변환을 두지 않는다.

### Core

- 여러 feature가 사용하는 설계 토큰, 공통 UI, 네트워크 기반 요소, 로깅, 환경 설정을 둔다.
- `Core/Architecture/MVICore`는 `Reducer`, `Effect`, `Store` 실행 기반을 제공한다.
- `Core/Architecture/Dependency/AppDependencies`는 앱의 composition root이다.
- 특정 feature의 화면 정책이나 비즈니스 규칙을 공통 코드라는 이유만으로 올리지 않는다.

### Presentation

- SwiftUI View, 화면 상태와 Action, Reducer, feature 전용 Model·Service·Adapter를 둔다.
- View는 Domain 계약을 통해 데이터를 요청하며 DTO나 `NetworkManager`를 직접 사용하지 않는다.
- UIKit 또는 Kakao SDK가 필요한 구현은 이를 소유한 feature의 경계 안에 둘 수 있다.
- 두 개 이상의 top-level feature에서 실제로 재사용될 때만 공통 구현을 Core로 이동한다.

### Data

- `Remote`는 서버 API, Request·Response DTO와 RemoteDataSource를 담당한다.
- `RepositoryImpl`은 DTO를 Domain 모델로 변환하는 Mapper와 repository 구현을 담당한다.
- `Local`은 명시적으로 승인된 로컬 저장 구현만 담당한다.
- Presentation에 DTO, data source 또는 repository 구현 타입을 노출하지 않는다.
- 세부 Swagger 계약과 구현 순서는 `Docs/API_SWAGGER.md`를 따른다.

### Domain

- 제품 entity, repository protocol, 순수 policy를 담당한다.
- UI 표시 형식, SDK runtime, 저장소 구현, DTO를 알지 않는다.
- SwiftUI, UIKit, KakaoMapsSDK와 구체 네트워크·영속성 구현을 import하지 않는다.
- Data는 Domain 계약을 구현하고 Presentation은 그 계약에 의존한다.

## Composition Root

`AppDependencies`는 token store, 인증·비인증 네트워크, remote data source와 repository를 조립한다. `RootView`가 만든 동일한 graph를 내려보내고 Reducer는 생성자로 의존성을 받는다.

- View나 Reducer에서 repository 구현 또는 `NetworkManager`를 새로 만들지 않는다.
- feature 전용 Service는 주입된 계약을 사용해 해당 feature 안에서 조합할 수 있다.
- 전역 service locator나 숨은 singleton lookup을 의존성 전달 수단으로 추가하지 않는다.

## MVICore Flow

```text
View -> Action -> Reducer(State mutation) -> Effect
     <- Store publishes State <- Action
```

- `State`는 화면이 렌더링하는 제품 상태의 단일 원본이다.
- `Action`은 사용자 의도, lifecycle·SDK event, Effect 결과를 표현한다.
- `Reducer`는 상태 전이, 의도 해석, Effect 시작·취소를 담당한다.
- `Effect`는 `.none`, `.send`, `.run`, `.cancel`을 제공하고 child Action으로 `map`할 수 있다.
- `Store`는 `@MainActor`에서 Reducer를 실행하고 state를 publish하며 Effect task를 관리한다.
- 취소 ID, request revision과 최신 응답 판단은 Reducer가 소유한다.
- View lifecycle에 비동기 제품 로직을 숨기지 않고 Action과 Effect로 표현한다.

독립 feature root는 하나의 Store를 소유할 수 있다. 부모 Reducer에 합성된 child는 별도 Store를 만들지 않고 부모 State의 child State와 명시적인 `send(Action)`을 전달받는다.
View 전용 animation·gesture 진행값은 로컬 상태일 수 있지만 제품 상태를 복제하지 않는다.

## Parent And Child Reducers

부모는 child State와 Action을 같은 형태로 합성한다.

```swift
var child = ChildReducer.State()
case child(ChildReducer.Action)
return childReducer.reduce(&state.child, with: action).map(Action.child)
```

- child는 sibling State를 읽거나 sibling Action을 직접 보내지 않는다.
- child 밖으로 필요한 결과만 `Action.delegate(Delegate)`로 내보낸다.
- 바로 위 부모가 child Delegate를 해석해 자신의 State를 바꾸거나 다른 child Action을 만든다.
- 중첩 부모는 내부 Delegate를 소비하고 상위에 필요한 최소한의 최종 Delegate만 다시 보낸다.
- 상위 View가 child 내부 State를 검사해 feature 간 정책을 결정하지 않는다.
- Delegate에는 화면 전체 State 대신 경계에 필요한 typed value와 사용자 의도만 담는다.

## Responsibility Boundaries

- **View**: State를 렌더링하고 사용자·runtime event를 Action으로 전달한다.
- **Reducer**: 상태 전이, Effect orchestration, 취소와 최신 응답 여부를 결정한다.
- **Service**: 외부 I/O·SDK·UIKit delegate 또는 State를 모르는 순수 계산을 수행한다.
- **Domain**: 제품 개념, repository contract와 순수 policy를 표현한다.
- **Data**: API DTO, data source, mapper와 repository implementation을 구현한다.

Service를 만들 가능성만으로 Reducer 로직을 옮기지 않는다. Service는 Store나 UI State를 소유하지 않으며 결과를 typed value 또는 event로 Reducer에 돌려준다.

## Feature Foldering

새 top-level feature의 기본 형태는 다음과 같다.

```text
Presentation/<Feature>/
  <Feature>View.swift
  <Feature>Reducer.swift
```

필요가 생긴 폴더만 단수형으로 추가한다.

- `Component`: feature 안의 여러 화면이 실제로 재사용하는 UI
- `SubView`: 특정 View를 시각적으로 분해한 하위 View
- `SubPage`: navigation destination 또는 독립 하위 화면
- `Section`: 자체 State·Action·Reducer 또는 독립 행동 계약을 가진 큰 영역
- `Model`: feature 전용 값 모델
- `Service`: 외부 I/O, SDK runtime, UIKit delegate 또는 상태 없는 계산
- `Adapter`: SwiftUI와 UIKit·외부 SDK 사이의 변환 및 lifecycle 연결

빈 폴더를 미리 만들지 않는다. 한 feature 내부 공유는 가장 가까운 공통 부모의 `Shared`에 두고, 최소 두 top-level feature에서 재사용되는 것이 확인된 뒤 Core로 올린다.

## UIKit And Kakao Boundary

- SwiftUI로 직접 표현할 수 없는 SDK view와 delegate lifecycle은 adapter 사용을 허용한다.
- feature 전용 Kakao Map·Directions 구현은 해당 feature의 `Adapter` 또는 `Service`에 둔다.
- adapter는 Reducer State를 렌더링하고 SDK event를 typed Action으로 돌려준다.
- bridge용 transient runtime state는 가질 수 있지만 제품 정책의 원본은 아니다.
- 앱 전역에서 재사용되는 UIKit bridge만 Core 후보이며 Domain에는 SDK 타입을 노출하지 않는다.

## View And Reducer File Style

큰 파일은 역할별 별도 `+Map.swift`, `+BottomSheet.swift`로 쪼개기보다 같은 파일의
extension과 `// MARK: -`로 먼저 구획한다.

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
