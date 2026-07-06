# RODI AI Workflow

This document is the main operating guide for AI agents working in this repository. It also replaces project-local skill and handoff files for day-to-day work.

## How To Start

1. Read `AGENTS.md`.
2. Read only the relevant document from `Docs`.
3. Inspect the live files before planning or editing.
4. Keep changes scoped to the requested layer or feature.
5. Run the build command after code or project-structure changes.

## Where To Look

| Task | First Location | Notes |
| --- | --- | --- |
| App startup/root flow | `Rodi/App/` | `RodiApp.swift`, `RootView.swift` own app entry and root routing. |
| Home feature | `Rodi/Presentation/Home/` | Map, location, bottom sheet, marker, route, and Home MVI live here. |
| Onboarding | `Rodi/Presentation/Onboarding/` | Onboarding MVI, legal agreements, and permission screen live here. |
| Design tokens | `Rodi/Core/RodiDesignSystem.swift` | Use `RodiColor`, `RodiTypography`, and Pretendard helpers. |
| Assets/fonts/data | `Rodi/Resources/` | Asset catalog, bundled JSON, fonts, privacy manifest. |
| Legal pages | `Rodi/Core/LegalDocument.swift`, `Rodi/Core/LegalWebView.swift` | In-app legal document routing and WebView. |
| Local onboarding flag | `Rodi/Core/AppPreferencesStore.swift` | Realm-backed onboarding completion flag. Do not move unless persistence refactor is requested. |
| Logging | `Rodi/Core/RodiLogger.swift` | Release logs must not expose keys or precise coordinates. |
| Networking primitives | `Rodi/Core/Network/` | Generic network layer foundation, not yet full server integration. |
| Fastlane/release | `fastlane/`, `Docs/03_RELEASE_APPSTORE_LEGAL.md` | Local Mac fastlane only; no GitHub Actions. |

## Code Map

| Symbol/File | Role |
| --- | --- |
| `RodiApp` | App entry point and global setup. |
| `RootView` | Chooses onboarding or home based on app preferences. |
| `HomeView` | Home screen composition; should render state and send actions. |
| `HomeState` | Single render-state source for Home. |
| `HomeAction` | User intents, runtime events, route events, and presentation actions. |
| `HomeReducer` | Home state transitions and effect orchestration. |
| `HomeRuntimeService` | Location, heading, fallback, and marker runtime side effects. |
| `KakaoMapContainerView` | SwiftUI wrapper around the Kakao UIKit map adapter. |
| `RodiKakaoMapView` | UIKit Kakao map lifecycle and rendering control. |
| `KakaoDirectionsService` | Kakao Mobility route API integration for route overlay. |
| `RouteGuidanceService` | External KakaoMap/KakaoNavi handoff. |
| `OnboardingView` | Onboarding MVI entry view. |
| `OnboardingReducer` | Onboarding state transitions. |
| `SocialLoginService` | Apple/Kakao onboarding login side effects. |
| `RodiDesignSystem` | Colors, typography, fonts, and design token helpers. |

## Commands

Build after code or structure changes:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme Rodi -destination 'generic/platform=iOS Simulator' build
```

Fastlane local commands:

```sh
bundle exec fastlane build
bundle exec fastlane archive
bundle exec fastlane beta
bundle exec fastlane version
```

Useful static checks:

```sh
rg "<stale path or boilerplate keyword>" AGENTS.md Docs Rodi
rg "SwiftUI|UIKit|KakaoMapsSDK|RealmSwift|URLSession|Bundle" Rodi/Domain
rg "KAKAO_NATIVE_APP_KEY|KAKAO_REST_API_KEY|AuthKey_.*\\.p8" .
```

## Platform Notes

- Minimum deployment target is iOS 16.
- Do not introduce iOS 17+ only APIs without availability checks and fallback.
- Kakao Maps SDK is UIKit-based in this app; do not rewrite it as a pure SwiftUI map.
- Do not remove or hide Kakao logo/copyright visibility.
- The app is Korea-focused. Simulator or foreign coordinates may need fallback handling.
- Keep Bundle ID and Kakao console implications in mind before changing identifiers.

## SwiftUI Refactor Playbook

Use when splitting views, reducing view responsibility, or improving UI structure.

1. Read the target view and nearby subviews.
2. Identify sections with clear visual or behavioral responsibility.
3. Extract dedicated subview types for non-trivial sections.
4. Keep `body` declarative; move actions into named methods or MVI actions.
5. Pass explicit values, bindings, and callbacks.
6. Preserve behavior and layout unless the task asks for UI change.
7. Build after code changes.

Do not create abstractions just to reduce line count. Do not move feature-only UI into Core. Preserve iOS 16 compatibility.

## MVI Change Playbook

Use when changing Home or Onboarding state/action/reducer flow.

1. Inspect current `State`, `Action`, `Reducer`, and view bindings.
2. Add or adjust meaningful actions, not generic setter actions unless needed.
3. Keep render state in `State`.
4. Keep UIKit, location, network monitor, and external app side effects in services.
5. Let Reducer own state transitions and effect orchestration.
6. Keep subviews store-agnostic when reasonable.
7. Build and test the affected user flow.

Do not duplicate state between Store and services. Do not put business logic in SwiftUI `body`.

## Figma Implementation Playbook

Use when the user provides a Figma link, screenshot, or dev mode context.

1. Inspect the design source and identify purpose, hierarchy, actions, and states.
2. Check current `Presentation` and `Core` components before creating new ones.
3. Map colors and typography to `RodiColor` and `RodiTypography`.
4. Build with SwiftUI by default.
5. Avoid direct Figma coordinates, excessive offsets, and device-sized fixed frames.
6. Save required image/vector assets into `Rodi/Resources/Assets.xcassets`.
7. If a design implies legal/safety guarantees, flag it before implementation.

Implementation checklist:
- Treat Figma Dev Mode and screenshots as design references, not exported source code.
- Identify background, header, content blocks, cards, lists, forms, primary/secondary actions, chips, status, empty, loading, and error states before coding.
- If one design input is missing but the screen is otherwise unambiguous, proceed with an explicit assumption instead of blocking.
- Preserve visual hierarchy before pixel-level polish.
- Keep reusable layout in feature subviews; do not move Home-only or Onboarding-only UI into `Core`.

## UIKit Playbook

Use UIKit only when the user explicitly asks for UIKit or when working inside existing UIKit-backed code such as the Kakao map adapter.

When UIKit is explicitly requested:
- Use programmatic Auto Layout.
- Prefer SnapKit for constraints if the package is available in the project.
- Use Then for concise UIKit object configuration if the package is available.
- Use RxSwift, RxCocoa, RxRelay, and NSObject-Rx only for reactive flows that are already Rx-based or explicitly requested.
- Prefer `DisposeBag` or `rx.disposeBag` for subscription lifetime management.
- Keep UIKit lifecycle and delegate handling out of SwiftUI `body`.
- Wrap UIKit in `UIViewRepresentable`/`UIViewControllerRepresentable` when exposing it to SwiftUI.

Avoid:
- choosing UIKit over SwiftUI without user instruction
- mixing large UIKit lifecycle code directly into SwiftUI views
- frame-based layout when Auto Layout is appropriate
- unmanaged Rx subscriptions; always dispose subscriptions predictably
- using RxRelay as hidden global mutable state
- using Then for complex construction where a named factory or builder is clearer

Reference sources:
- Apple UIKit documentation: https://developer.apple.com/documentation/uikit
- Apple Auto Layout Guide: https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html
- SnapKit: https://github.com/SnapKit/SnapKit
- RxSwift: https://github.com/ReactiveX/RxSwift
- NSObject-Rx: https://github.com/RxSwiftCommunity/NSObject-Rx
- Then: https://github.com/devxoul/Then

## Kakao Map And Location Debugging

First check:
- Kakao Native App Key and REST API Key are present locally.
- Bundle ID matches Kakao console settings.
- Network is available.
- Location permission state is known.
- Simulator coordinates may be outside Kakao map service coverage.

Important files:
- `Presentation/Home/Map/`
- `Presentation/Home/Services/Runtime/`
- `Presentation/Home/Services/KakaoDirectionsService.swift`
- `Presentation/Home/Services/RouteGuidanceService.swift`

Rules:
- Do not remove or hide Kakao logo/copyright.
- Do not force a custom current-location marker unless requested.
- Do not block map rendering solely because location permission is denied.
- Keep location-denied behavior explicit and user-facing.
- Keep Release logs free of precise coordinates.

## Concurrency And Async Work

Use when touching async/await, `Task`, actors, location callbacks, network calls, or cancellation.

1. Check Xcode Swift settings if the issue is compiler/concurrency-related.
2. Identify the isolation boundary: main actor, runtime service, SDK callback, or background work.
3. Keep UI state mutation on the main actor.
4. Avoid blanket `@MainActor` fixes when only a small hop is needed.
5. Prefer structured cancellation for long-running or repeatable tasks.
6. Match a `Task` entry's isolation to its synchronous prefix before the first `await`.
7. Avoid `@unchecked Sendable`, `nonisolated(unsafe)`, semaphores, and ad hoc locking unless the safety invariant is documented.
8. Build after the smallest safe change.

If a concurrency warning depends on project settings, inspect the `.pbxproj` settings first:
- Swift language version
- strict concurrency
- default actor isolation
- upcoming Swift feature flags

## Release/App Store Work

Use when changing versioning, TestFlight, App Store metadata, legal links, privacy, or permissions.

1. Read `Docs/03_RELEASE_APPSTORE_LEGAL.md`.
2. Verify `Config/Info.plist`.
3. Verify secrets are local-only.
4. Verify Privacy Label and app behavior alignment.
5. Use fastlane only from the local Mac.
6. Do not invent support email or legal contact information.

## Documentation Rules

- `Docs` is the only project documentation home.
- Do not create separate handoff or skill docs unless explicitly requested.
- If multiple developers or long-running parallel work begins, add `Docs/HANDOFF.md` or `Docs/Handoff/{Owner}.md` at that time.
- If a reusable rule emerges, place it in the most relevant `Docs/*.md` file.
- If a document conflicts with live code, trust live code first and update the document.
- Docs are not automatically updated by Codex or by the build system.
- When a task changes architecture, foldering, package usage, release flow, privacy/legal behavior, UI conventions, or public app wording, update the relevant doc in the same task.
- If the user explicitly asks for code-only work and a doc becomes stale, mention the doc drift in the final response instead of silently leaving it as truth.
- Keep docs short enough to route decisions quickly; merge documents when their responsibilities overlap.
