# RODI Architecture

이 문서는 RODI의 레이어, MVI, feature 배치와 책임 경계를 설명하며, 구체적인 화면 수치나 일시적인 구현 상태는 현재 코드에서 확인한다.
문서와 코드가 다르면 현재 코드를 기준으로 판단하고 같은 작업에서 문서를 바로잡는다.

## Layer Structure

현재 top-level은 `App`, `Core`, `Presentation`, `Data`, `Domain`, `Resources`이며 세부 경로는 live filesystem에서 확인한다.

각 레이어의 상세 MUST/MUST NOT과 감사 기준은 아래 Layer 문서를 원본으로 사용한다. 이 문서는 전체 의존성 방향과 공통 원칙만 유지하며, 같은 규칙을 Layer 문서에 반복하지 않는다.

| Layer | 목적 | 상세 규칙 |
| --- | --- | --- |
| App | 앱 조립과 시작 수명 관리 | [Layers/APP.md](Layers/APP.md) |
| Core | 여러 feature가 공유하는 기술 기반 | [Layers/CORE.md](Layers/CORE.md) |
| Data | 외부·로컬 데이터를 Domain 계약으로 변환 | [Layers/DATA.md](Layers/DATA.md) |
| Domain | 제품 언어와 비즈니스 계약 유지 | [Layers/DOMAIN.md](Layers/DOMAIN.md) |
| Presentation | 화면 렌더링·사용자 상호작용·상태 전이 | [Layers/PRESENTATION.md](Layers/PRESENTATION.md) |
| Resources | 실행 리소스 관리 | [Layers/RESOURCES.md](Layers/RESOURCES.md) |

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

다단계 Review flow는 `Flow/ReviewFlowFactory`가 Review 전용 reducer·service를 조립하고, `Flow/ReviewFlowCoordinatorReducer`가 전역 진입 출처·완료 갱신·Snackbar를 중재한다. `ReviewReducer`는 `Prompt`·`Writing`·`SkipReason` named child feature 전환과 최종 Delegate를 중재하고, `ReviewView`는 현재 child State만 전달해 조립한다. 앱 복귀 뒤 측정 continuation·방문 기록·후기 권유는 `PracticeTrackingReducer`의 child인 `PracticeReturnReducer`가 소유한다. Review와 PracticeTracking은 서로의 State를 읽지 않고 typed Delegate를 Root가 중계한다. Review root에는 `ReviewView`와 `ReviewReducer`만 둔다. 각 단계 화면은 named child feature의 `SubPage`, 공통 dialog·header·scaffold는 Review 또는 PracticeTracking `Component`, 표시 모델은 해당 named feature의 `Model`, repository를 사용하는 요청은 해당 named feature의 `Service`에 둔다. 빈 폴더를 미리 만들지 않는다. 한 feature 내부 공유는 가장 가까운 공통 부모의 `Shared`에 두고, 최소 두 top-level feature에서 재사용되는 것이 확인된 뒤 Core로 올린다.

## UIKit And Kakao Boundary

- SHOULD SwiftUI로 직접 표현할 수 없는 SDK view와 delegate lifecycle에서만 adapter 사용을 검토한다.
- MUST feature 전용 Kakao Map·Directions 구현을 해당 feature의 `Adapter` 또는 `Service`에 둔다.
- MUST adapter가 Reducer State를 렌더링하고 SDK event를 typed Action으로 돌려준다.
- MUST NOT bridge용 transient runtime state를 제품 정책의 원본으로 사용한다.
- MUST NOT Domain에 SDK 타입을 노출한다. 앱 전역에서 재사용되는 UIKit bridge만 Core 후보로 검토한다.

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
