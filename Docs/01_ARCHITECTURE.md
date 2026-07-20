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
  Domain/
    Entity/
    Repository/
  Presentation/
    Home/
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
- extensions
- MVI core primitives

Core can be used by Presentation, Data, and App, but should avoid feature-specific business rules.

### Presentation

Owns feature UI and UI-facing logic.

Current features:
- `Presentation/Home`
- `Presentation/Onboarding`

Presentation may use Core and, when introduced, Domain protocols/entities. Presentation should not contain reusable infrastructure that belongs in Core.

### Data

Reserved for local/remote data sources and repository implementations.

Current status:
- intentionally light
- not the source of truth for Home dummy JSON yet
- do not introduce local persistence changes unless explicitly requested

Server-backed DTO, mapper, API, and repository implementation should move here once the API contract is stable.

Current server-backed features:
- `Data/Remote/Auth` + `Domain/Auth`
- `Data/Remote/Member` + `Domain/Member`
- `Data/Remote/Place` + `Domain/Place`

Current local features:
- `Data/Local/Onboarding` stores an in-progress authenticated new-member onboarding draft in Realm.

`Place` keeps public marker/list requests and authenticated detail/bookmark requests behind one
repository. Presentation must receive `PlaceRepository` through dependency injection rather than
call `NetworkManager` directly.

### Domain

Reserved for pure entities and repository interfaces.

Domain must not import:
- SwiftUI
- UIKit
- KakaoMapsSDK
- RealmSwift
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

## Home Structure

`Presentation/Home` is intentionally self-contained because it combines Kakao SDK lifecycle, location policy, route overlays, marker rendering, bottom sheets, and MVI.

```text
Presentation/Home/
  Map/
  Models/
  Reducers/
  Services/
  States/
  Views/
```

Rules:
- `Map/` is a Kakao UIKit adapter area, not a regular SwiftUI subview folder.
- `Views/` owns SwiftUI composition and Home-only components.
- `Services/` owns Home runtime side effects and Home-specific external integrations.
- `Models/` is temporary for Home display, DTO-like, and map models until server/Data/Domain separation is requested.
- `States/` and `Reducers/` own Home MVI decomposition.

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

`Presentation/Onboarding` owns onboarding flow state, entry/social login UI, legal agreement UI, nickname/driving preference screens, safety confirmation, and location permission prompt UI.

Onboarding UI models are Presentation models, not Domain entities. `Data/Local/Onboarding/OnboardingDraftStore` stores the authenticated new-member's current step and selections after every state change so an interrupted onboarding session can resume. It is cleared only after final onboarding completion or logout/withdrawal. `Core/Setting/AppPreferencesStore` continues to own the separate final `hasSeenOnboarding` flag.

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

1. Define server DTOs in `Data/Remote/<Feature>`.
2. Define pure app entities in `Domain/Entity`.
3. Define repository interfaces in `Domain/Repository`.
4. Add mapper functions from DTO to Domain entity.
5. Add Data repository implementation.
6. Update Presentation to depend on Domain-facing models/interfaces.

Until then, Home dummy JSON can stay inside `Presentation/Home`.

## Structural Change Rule

After moving files or changing project structure, run:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme Rodi -destination 'generic/platform=iOS Simulator' build
```
