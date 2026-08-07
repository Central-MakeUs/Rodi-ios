# Coordinator Core

`Coordinator Core`는 iOS 16 이상 SwiftUI `NavigationStack`의 typed path를 관리하기 위한 작은 공통 계층입니다.

이 모듈은 화면의 destination을 만들지 않고, 비즈니스 state를 갖지도 않으며, MVI Reducer도 아닙니다. route path 변경과 전환 중 입력 정책만 일관되게 관리합니다.

```text
View ── 요청 ──> Router<Route>
                       │
                       ▼
                Coordinator<Route>
                       │
                       ▼
           NavigationStack(path: Binding<[Route]>)
```

## 구성 요소

| 타입 | 책임 |
| --- | --- |
| `Route` | path에 저장할 destination 식별자의 공통 계약 |
| `NavigationStep` | path를 한 번 변환하는 원자 명령 |
| `NavigationPlan` | 여러 명령을 최종 path로 계산하는 순수 값 타입 |
| `Router` | View가 path를 직접 알지 않고 전환을 요청하는 façade |
| `Coordinator` | path 소유, 전환 잠금, system path 동기화 |

## Route

`Route`는 `Hashable`이며 앱 또는 navigation scope 안에서 안정적인 `id`를 제공해야 합니다.

```swift
enum AppRoute: Route {
    case profile(userID: String)
    case settings

    var id: String {
        switch self {
        case let .profile(userID):
            "profile.\(userID)"
        case .settings:
            "settings"
        }
    }
}
```

같은 화면 종류여도 전달받은 데이터가 다르면 `id`도 달라야 합니다. 예를 들어 `profile.1`과 `profile.2`는 서로 다른 path 요소입니다.

`Route`는 destination View를 요구하지 않습니다. 어느 route가 어떤 View를 만드는지는 route를 합성하는 앱 또는 feature 계층의 책임입니다.

## Coordinator와 NavigationStack 연결

Coordinator는 해당 `NavigationStack`을 소유하는 composition root에서 한 번 생성합니다.

```swift
struct AppNavigationView: View {
    @StateObject private var coordinator = Coordinator<AppRoute>()

    var body: some View {
        NavigationStack(path: coordinator.pathBinding) {
            HomeView(router: coordinator.router)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case let .profile(userID):
                        ProfileView(userID: userID, router: coordinator.router)
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}
```

`NavigationStack`을 실제로 호스팅하는 View만 주입된 `Coordinator`의 `pathBinding`을 사용합니다. 그 하위 View는 `Router`만 받고 `[Route]`나 `Coordinator`를 새로 만들지 않습니다.

```swift
struct HomeView: View {
    let router: Router<AppRoute>

    var body: some View {
        Button("프로필") {
            router.push(.profile(userID: "42"))
        }
    }
}
```

Environment 주입, 생성자 주입 등 Router를 View에 전달하는 방식은 앱 composition 규칙에 따릅니다. Coordinator Core는 그 방식을 강제하지 않습니다.

## Router

`Router`는 전환 요청만 노출합니다. 현재 path를 조회·변경하는 API는 제공하지 않습니다.

| 메서드 | 동작 |
| --- | --- |
| `push(_:)` | route 하나를 최상단에 추가 |
| `pop(count:)` | 최상단부터 지정한 수만큼 제거 |
| `popToRoot()` | path 전체 제거 |
| `replace(with:)` | path 전체 교체 |
| `perform(_:)` | `NavigationPlan`의 최종 path를 한 번에 적용 |

```swift
router.push(.settings)
router.pop()
router.pop(count: 2)
router.popToRoot()
router.replace(with: [.profile(userID: "42")])
```

Preview처럼 Coordinator가 없는 환경에는 `Router.empty`를 사용합니다. 빈 Router는 요청을 무시하며 화면 전환을 시도하지 않습니다.

## NavigationStep과 NavigationPlan

`NavigationStep`은 path 변환 한 건을 표현합니다.

```swift
let steps: [NavigationStep<AppRoute>] = [
    .push(.profile(userID: "42")),
    .push(.settings),
    .pop(count: 1),
]
```

`NavigationPlan`은 step을 왼쪽부터 적용해 최종 path만 계산합니다.

```swift
router.perform(
    NavigationPlan(steps: [
        .push(.profile(userID: "42")),
        .push(.settings),
    ])
)
```

위 요청은 두 화면을 순서대로 애니메이션하지 않습니다. 현재 path에 두 step을 적용한 뒤, 결과 path를 `NavigationStack`에 한 번만 반영합니다. 다단계 deep link, 완료 후 특정 화면으로 이동, 여러 화면을 즉시 pop해야 할 때 사용합니다.

### Path 계산 규칙

- `.push`는 현재 최상단과 같은 route면 아무 동작도 하지 않습니다.
- `.pop(count:)`의 count가 현재 path 수보다 크면 가능한 수만 제거합니다.
- 음수 또는 `0` count는 아무 동작도 하지 않습니다.
- `.popToRoot`는 빈 path를 만듭니다.
- `.replace`는 이전 step 결과를 버리고 전달받은 path를 사용합니다.
- 빈 plan 또는 결과가 현재 path와 같으면 `NavigationStack`을 다시 전환하지 않습니다.

`NavigationPlan.applying(to:)`는 순수 함수입니다. Coordinator와 SwiftUI 없이도 입력 path와 최종 path를 단위 테스트할 수 있습니다.

## 전환 정책

Coordinator는 `@MainActor`로 path를 직렬화합니다. Coordinator가 시작한 전환이 논리적으로 끝날 때까지 아래의 새 요청은 무시합니다.

- `push`
- `pop`
- `popToRoot`
- `replace`
- `perform`

이 정책은 두 번 탭했을 때 화면이 두 번 push되는 문제를 막기 위한 것입니다. 요청을 큐잉하거나 마지막 요청으로 바꾸지 않습니다. 의도적인 여러 경로 변경은 `NavigationPlan`으로 명시해야 합니다.

잠금 해제는 iOS 17 이상에서 `Transaction.addAnimationCompletion(criteria: .logicallyComplete)`를 사용합니다. iOS 16에서는 다음 run loop까지 잠금을 유지해 같은 turn의 중복 요청을 막습니다. Coordinator는 `ObservableObject`/`@Published`로 상태를 공개하므로 앱의 iOS 16.1 배포 기준과 호환됩니다.

## 시스템 뒤로가기

`Coordinator.pathBinding`은 `NavigationStack`이 사용자 뒤로가기 동작으로 변경한 path도 수신합니다.

사용자 스와이프나 시스템 뒤로가기 버튼이 path를 바꾸면 Coordinator는 자동 전환보다 그 결과를 우선합니다. 진행 중인 전환 완료 콜백은 전환 식별자로 무효화되고, 이후 Router 요청은 새 path를 기준으로 처리됩니다.

특정 feature가 시스템 path를 제한해야 하면 생성 시 `acceptsSystemPath` closure를 제공합니다. 이 closure는 system binding 변경에만 적용되며, `Router`가 요청한 정상적인 전환을 차단하지 않습니다.

`LockIsolated`, `NSLock` 등은 이 정책에 사용하지 않습니다. Coordinator path는 MainActor가 이미 직렬화하며, lock은 SwiftUI의 화면 전환 수명 전체를 보장하지 못합니다.

## 중첩 Coordinator 기준

Coordinator 하나는 정확히 하나의 `NavigationStack` path만 소유합니다.

독립된 중첩 `NavigationStack`을 실제로 만드는 feature라면 별도 `Coordinator<FeatureRoute>`를 둘 수 있습니다.

```swift
typealias ProfileCoordinator = Coordinator<ProfileRoute>
typealias ProfileRouter = Router<ProfileRoute>
```

단, 상위와 하위 Coordinator가 동일한 path를 함께 수정하면 안 됩니다. 상위 Coordinator는 상위 stack만, 하위 Coordinator는 자신이 소유한 중첩 stack만 관리합니다. 단순 상세 push를 위해 불필요하게 child Coordinator를 만들지 않습니다.

## 책임 밖의 것

Coordinator Core는 다음을 제공하지 않습니다.

- route에서 destination View를 생성하는 규칙
- 화면별 비즈니스 state와 side effect
- deep link URL 파싱
- 인증/권한에 따른 화면 접근 제어
- 전환 실패 UI 또는 에러 상태
- 여러 Coordinator 사이의 자동 route 변환

이 기능들은 앱 composition, feature route, Reducer/Effect 또는 별도 flow 계층에서 결정해야 합니다.

## 검증 항목

- 동일한 push를 빠르게 여러 번 요청해도 path가 한 번만 바뀌는가?
- 전환 중 다른 일반 Router 요청이 무시되는가?
- `NavigationPlan`이 중간 화면 없이 최종 path를 적용하는가?
- `pop(count:)`, `popToRoot`, `replace`가 경계 path에서 안전한가?
- 시스템 뒤로가기 뒤 새 Router 요청이 정상 동작하는가?
- 데이터가 있는 route의 `id`가 입력 데이터까지 포함해 안정적으로 구분되는가?
