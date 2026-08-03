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
    HomeRouter: search presentation and Home handoff
    MyRouter: typed NavigationStack path
    OnboardingRouter: typed NavigationStack path
```

Home and My roots stay mounted while the selected tab changes. Only the inactive tab's rendering, hit testing, and accessibility are disabled so map, bottom sheet, filter, and navigation state survive tab changes.

Home coordinate loading belongs to `HomeMapReducer`. Requests use a revision and cancellation ID so stale results cannot replace newer map state. `HomeNetworkMonitor` creates a fresh `NWPathMonitor` for every start because a cancelled monitor cannot be restarted.

Authentication tokens are written as one Keychain session record. Legacy separate access/refresh entries migrate on first read, and writes use update-or-add so a transient write failure does not first delete an active session.

## Home Structure

`Presentation/Home` is intentionally self-contained because it combines a UIKit-backed Kakao map, location policy, marker rendering, search, bottom sheets, and MVI.

```text
Presentation/Home/
  HomeView.swift                 # Feature entry and injected dependencies
  HomeReducer.swift              # Map / bottom sheet / presentation composition
  HomeRouter.swift               # Search presentation and cross-feature handoff
  HomeMap/                       # Map UI, reducer, Kakao adapter, runtime services
  HomeBottomSheet/               # List, details, filter, route guidance
  HomeSearch/                    # Full-screen place and administrative-area search
  Component/                     # Home-local shared UI and presentation reducer
```

`HomeMapView` owns only map SDK and location runtime lifecycle. Coordinate loading belongs to `HomeMapReducer` Effects so it can be cancelled and revision-checked outside the View lifecycle.

### Map marker clustering

Home marker clustering is client-rendered in `Presentation/Home/Map`.

- `RodiHomeMarkerClusterIndex` groups the complete `/api/v1/places/coordinates` response by address, never by the current viewport origin.
- Tiers are `province` (map zoom `<= 10`, first address token such as `인천광역시`), `district` (`11...13`, first two tokens such as `인천광역시 강화군`), and `individual` (`>= 14`, course/parking markers).
- Camera movement does not call the Places API again. On KakaoMap `cameraStopped` (the practical idle event), the current zoom tier is rendered from the coordinates already held in Home state.
- Viewport-aware cache/paged coordinate requests are deferred until the coordinate endpoint becomes too large to keep in memory or is replaced by a bounds-based API.

### Viewport place list

Home deliberately uses two public Place APIs for different jobs.

- `/api/v1/places/coordinates` supplies the complete lightweight coordinate set for map markers and client-side clusters.
- `/api/v1/places` supplies bottom-sheet cards only. It is queried with KakaoMap's full drawable south-west/north-east bounds, an origin coordinate, `size=20`, and a cursor.
- `HomePlaceListState` owns list items, cursor metadata, query revision, loading/error state, and whether the user must tap `재검색`.
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
