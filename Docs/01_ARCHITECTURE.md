# RODI Architecture

This document is the source of truth for the current RODI folder structure and architecture boundaries.

## Current Structure

```text
Rodi/
  App/
  Core/
  Data/
    Local/
    Remote/
    RepositoryImpl/
  Domain/
    Auth/
    Home/Search/
    Member/
    Onboarding/
    Place/
  Presentation/
    Home/
    Login/
    MainTab/
    My/
    Onboarding/
  Resources/
```

## Layer Responsibilities

### App

Owns app startup, root routing, and app-level setup.

Key files:
- `Rodi/App/RodiApp.swift`
- `Rodi/App/RootView.swift`

### Core

Owns shared infrastructure and app-wide utilities.

Examples:
- design system
- legal WebView and legal document registry
- logging
- network primitives
- app preferences store
- haptic manager
- shared transient feedback (`RodiSnackbar`)
- app-wide network connection monitoring and unavailable-state UI
- extensions
- MVI core primitives

Core can be used by Presentation, Data, and App, but should avoid feature-specific business rules.

### Presentation

Owns feature UI and UI-facing logic.

Current features:
- `Presentation/Home`
- `Presentation/Login`
- `Presentation/MainTab`
- `Presentation/My`
- `Presentation/Onboarding`

Presentation may use Core and, when introduced, Domain protocols/entities. Presentation should not contain reusable infrastructure that belongs in Core.

### Data

Reserved for local/remote data sources and repository implementations.

Current status:
- intentionally light
- not the source of truth for Home dummy JSON yet
- do not introduce local persistence changes unless explicitly requested

`Data/Remote` owns Swagger-facing DTOs, APIs, and remote data sources. `Data/RepositoryImpl`
owns DTO-to-Domain mapping and concrete repository implementations.

Current server-backed features:
- `Data/Remote/Auth` + `Domain/Auth`
- `Data/Remote/Member` + `Domain/Member`
- `Data/Remote/Place` + `Domain/Place`

Current local features:
- `Data/Local/Onboarding` stores an in-progress authenticated new-member onboarding draft in UserDefaults.
- `Data/Local/Auth` uses `UserDefaults` to store only the device's most recently successful social login provider for entry-screen ordering. It never stores OAuth credentials or tokens.

`Place` keeps public marker/list requests and authenticated detail/bookmark requests behind one
repository. Presentation must receive `PlaceRepository` through dependency injection rather than
call `NetworkManager` directly.

### Domain

Owns app-facing entities, repository interfaces, and business policies. Each top-level Domain
concept keeps its own `Entity`, `Repository`, and, where needed, `Policy` folders.

Domain must not import:
- SwiftUI
- UIKit
- KakaoMapsSDK
- UserDefaults
- URLSession
- Bundle

Do not move `RodiCourseItem` into Domain as-is. It currently mixes DTO decoding, display formatting, map marker generation, and route overlay calculation.

### Resources

Owns bundled assets, fonts, data, and privacy manifest.

Examples:
- `Assets.xcassets`
- `Fonts`
- bundled JSON
- `PrivacyInfo.xcprivacy`

## Routing And Composition

`AppDependencies` is the composition root. It constructs network infrastructure, repositories,
and stores once, then injects them through `RootView` into Feature roots. Reducers and Views do
not construct or look up dependencies directly.

```text
  RootView
  AppRouter: onboarding <-> main tabs, login-required presentation
  RootReducer: version check and session restore lifecycle
  MainTabView / MainTabReducer: selected tab and cross-tab intent
    HomeView / HomeReducer: active Home flow
    MyRouter: typed NavigationStack path
    OnboardingRouter: typed NavigationStack path
```

Home and My roots stay mounted while the selected tab changes. Only the inactive tab's rendering, hit testing, and accessibility are disabled so map, bottom sheet, filter, and navigation state survive tab changes.

`RootView` owns `NetworkConnectionMonitor`, which observes the system network path. When the path is unavailable, Root replaces the active route with the shared `NetworkUnavailableView`; its retry action restarts path monitoring and the normal route returns automatically after the connection is restored.

Home map state and Home-specific map decisions belong to `HomeReducer`. `MapService` is a stateless worker for current-location and place-coordinate requests; it returns typed results but never owns Home state or presentation policy.

Authentication tokens are written as one Keychain session record. Legacy separate access/refresh entries migrate on first read, and writes use update-or-add so a transient write failure does not first delete an active session.

## Home Structure

`Presentation/Home` is intentionally self-contained because it combines a UIKit-backed Kakao map, location policy, marker rendering, search, bottom sheets, and MVI.

```text
Presentation/Home/
  HomeView.swift                 # Active feature entry and injected dependencies
  HomeReducer.swift              # Active Map, BottomSheet, Search, presentation orchestration
  Model/                         # Map과 BottomSheet가 공유하는 Home 값 모델
  Map/
    Adapter/Kakao/               # SwiftUI bridge와 UIKit Kakao adapter
    Component/                   # 지도 UI
    Enum/ Model/ Service/        # 지도 전용 값과 외부 작업·계산
  BottomSheet/
    RecommendList/ Filter/ CourseDetail/ ParkingDetail/
    Shared/                      # 코스·주차장 공통 길안내
  Search/
    Component/                   # 검색 입력·결과·최근 검색 UI
```

`HomeView` is a thin shell: it creates one `HomeReducer` Store and renders Map, BottomSheet, Search full-screen cover, alert, and snackbar feedback. Map, BottomSheet, and Search views receive explicit `State` and `send(Action)` closures; they neither create nor receive separate feature Stores.

`HomeReducer` is the active cross-feature mediator. Its State owns `MapState`, `HomeBottomSheetReducer.State`, `HomeSearchReducer.State`, and `PresentationState`. `HomeBottomSheetReducer` owns its route host plus recommendation-list, filter, course-detail, and parking-detail child states/reducers. A child reducer never reads another child's state and never sends it an action. It emits a minimal final delegate; its parent interprets that output and updates only Map or presentation state.

`HomeBottomSheetReducer` owns the current route (`recommendList`, `filter`, `resolvingPlace`, `courseDetail`, `parkingDetail`). It resolves a bare place ID and switches to the typed detail section. The actual sheet features own their own state and layout rules:

- `RecommendListBottomSheetReducer`: viewport list query, pagination, research, and collapsed/medium/expanded presentation. Only its collapsed state exposes the bottom tab bar.
- `FilterBottomSheetReducer`: draft/applied filter selection, save request, fixed middle height, and downward dismissal back to the recommendation list.
- `CourseDetailBottomSheetReducer`: course detail bookmark/road-route state and content-measured height with downward dismissal.
- `ParkingDetailBottomSheetReducer`: parking bookmark state, fixed middle height, map-focus event, and downward dismissal.

`HomeBottomSheetView` renders every route as a Home ZStack overlay. The recommendation list has collapsed/50%/full-height presentation; its drag settle value is View-local and the reducer changes presentation only after that settle completes. Its expanded state is not a system `.large` sheet: it is a white, edge-to-edge Home overlay with the header content inset below the window top safe area. The expanded recommendation header owns the back-to-medium action and filter action, matching the full-screen list flow. Recommendation and filter backgrounds extend to the bottom edge, while their scrollable/action content has the window bottom safe inset applied. `BottomSheetPanGestureView` is a UIKit adapter that reports `UIPanGestureRecognizer` translation in the stable `UIWindow` coordinate system, so a moving sheet header never becomes its own gesture coordinate origin. Filter, course detail, parking detail, and resolving-place retain their distinct overlay heights and dismissal rules. There is intentionally no shared detent manager or custom drag layout policy.

`SnackbarService` in Core owns Home-wide transient feedback and its dismissal lifetime. Home reducers expose a one-time snackbar request in State; `HomeView` bridges that request to `SnackbarService` and acknowledges it immediately. Login requests are an explicit parent-reducer callback to App/Root. The location settings alert is owned by `HomeReducer.PresentationState` and rendered by `HomeView`.

`EnvironmentValues.screenBounds` and `screenSafeAreaInsets` expose the active window scene's screen metrics to SwiftUI layout. `screenBounds` falls back to the active scene and then `UIScreen.main` before a key window exists, so Home's first overlay layout cannot collapse to zero height. Home BottomSheet uses those bounds for overlay heights, while `RodiBottomTabBar` keeps a fixed 56pt content layout and adds the actual bottom safe area. Neither flow uses `GeometryReader` or a height PreferenceKey.

For a selected course/parking marker or the current-location marker, `HomeView` passes `screenBounds.height * 0.1` as the Kakao camera bottom inset. The adapter converts half of that inset into a camera-target offset, leaving the focus target at the screen's upper 45% / lower 55% point.

`HomeView` composes the Kakao adapter from `Map/Adapter/Kakao`. Coordinate loading belongs to `HomeReducer.MapAction` Effects so it can be cancelled and revision-checked outside the View lifecycle.

`HomeView` owns one `HomeReducer` Store and translates SwiftUI/Kakao map events into reducer actions. `HomeReducer.State` separates `MapState`, `HomeBottomSheetReducer.State`, and `PresentationState`: map owns lifecycle, camera, location, heading, markers, clustering, and route overlay; presentation owns snackbar, alerts, and tab-bar visibility. `MapServiceInAction` and `MapServiceOutAction` are the typed request/result contract for location and place-coordinate I/O. `MapMarkerRenderingService` creates progressive marker snapshot streams, while cancellation and latest-result handling remain in the reducer. `MapMarkerTierResolver` and `MapMarkerInteractionResolver` are stateless calculations only.

`HomeReducer` composes BottomSheet through `State.bottomSheet` and `Action.bottomSheet(HomeBottomSheetReducer.Action)`. `HomeBottomSheetView` is stateless and receives explicit state and action closures. The parent may render the child state and run its reducer, but must not inspect nested BottomSheet state to decide Map, Search, or sibling behavior. Cross-feature behavior is driven only by `HomeBottomSheetReducer.Delegate`.

`HomeBottomSheetReducer` owns the recommendation-list, filter, course-detail, and parking-detail child states. It consumes child delegates internally for route transitions, filter recovery, and detail presentation, then emits only final typed delegates to `HomeReducer`: map focus, route overlay, detail dismissal, recommendation presentation, authentication, and snackbar. `CourseDetailBottomSheetReducer` is the sole owner of course route loading and fallback rendering.

`HomeSearchReducer` owns search query/result state, real-time related search, region search, recent searches, and pagination. It emits only `placeSelected`, `dismissed`, and `showSnackbar` delegates. `HomeReducer` closes the full-screen cover, resets map selection/route when needed, and passes the selected place ID to `HomeBottomSheetReducer` for typed detail resolution; it never reads nested Search state to make that decision.

### Map marker clustering

Home marker clustering is client-rendered in `Presentation/Home/Map`.

- `RodiHomeMarkerClusterIndex` groups the complete `/api/v1/places/coordinates` response by address, never by the current viewport origin.
- Tiers are `province` (map zoom `<= 8`, first address token such as `인천광역시`), `district` (`9...11`, first two tokens such as `인천광역시 강화군`), and `individual` (`>= 12`, course/parking markers).
- Camera movement does not call the Places API again. On KakaoMap `cameraStopped` (the practical idle event), the current zoom tier is rendered from the coordinates already held in Home state.
- Viewport-aware cache/paged coordinate requests are deferred until the coordinate endpoint becomes too large to keep in memory or is replaced by a bounds-based API.

### Viewport place list

Home deliberately uses two public Place APIs for different jobs.

- `/api/v1/places/coordinates` supplies the complete lightweight coordinate set for map markers and client-side clusters.
- `/api/v1/places` supplies bottom-sheet cards only. It is queried with KakaoMap's full drawable south-west/north-east bounds, an origin coordinate, `size=20`, and a cursor.
- `RecommendListBottomSheetReducer.State` owns list items, cursor metadata, query revision, loading/error state, and whether the user must tap `재검색`.
- Initial loading occurs once after the first stable camera event. A user pan or zoom only marks the list as stale; it never starts a request automatically.
- A programmatic camera move such as current-location focus, marker selection, or cluster drill-down must not mark the list as stale.
- A late response is ignored when its query revision is no longer current. Cursor pages append only while the current bounds remain active.

## Onboarding Structure

`Presentation/Login` owns social login, browse entry, authentication failures, and withdrawal recovery. `Presentation/Onboarding` owns the authenticated/guest onboarding routes after login.

`OnboardingRouterView` hosts the stack and forwards `OnboardingTransition` values. Individual Terms, Profile, and Permission reducers own their input, validation, presentation, and effects. `OnboardingSession` is the accumulated value model for draft persistence and submission; it does not depend on reducer-owned nested types. Browse users follow `terms -> safety -> location permission` and never create a member draft or submit member onboarding data.

## My Structure

`Presentation/My` owns the profile screen and settings navigation. `MyReducer` owns profile loading, logout, withdrawal, and transient feedback. `MyRouter` owns the typed `NavigationStack` path and keeps system edge-swipe state synchronized.

## MVI Rules

Use `Core/MVICore` for interactive features.

- `State` is the single render-state source.
- `Action` represents user intents, runtime events, and effect results.
- `Reducer` owns state transitions and effect orchestration.
- Views render state and send actions.
- Subviews receive explicit values and callbacks.
- Runtime services handle UIKit, SDK, location, network monitor, and other side effects.

## Data/Domain Migration Rule

Do not add mapper/repository layers just to make folders look used.

Use this order when server work begins:

1. Define server DTOs, APIs, and remote data sources in `Data/Remote/<Resource>`.
2. Define app entities and repository interfaces in their `Domain/<Concept>` folders.
3. Add mapper functions in `Data/RepositoryImpl/<Concept>`.
4. Add the concrete repository implementation beside its mapper.
5. Update Presentation to depend on Domain-facing models/interfaces.

Until then, Home dummy JSON can stay inside `Presentation/Home`.

## Structural Change Rule

After moving files or changing project structure, run:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme Rodi -destination 'generic/platform=iOS Simulator' build
```
