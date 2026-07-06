# RODI Agent Guide

RODI is a map-based driving practice course discovery app for beginner drivers and long-inactive license holders.

## Non-Negotiables

- Do not say or imply that RODI guarantees safety, accident prevention, road conditions, or parking availability.
- Use wording like "practice reference", "practice suitability", "difficulty", "recommended for practice", and "external navigation handoff".
- Do not commit real Kakao keys, App Store Connect private keys, `.p8` files, or local secrets.
- Do not print full API keys or precise user coordinates in Release logs.
- Do not touch `Data/Local` unless the task explicitly asks for local persistence work.

## Current Structure

```text
Rodi/
  App/
  Core/
  Data/
  Domain/
  Presentation/
    Home/
    Onboarding/
  Resources/
```

Use the live filesystem as the source of truth. This project uses Xcode filesystem-synchronized groups, so disk moves usually affect Xcode, but always verify structural changes.

## Docs Router

Read only the docs needed for the task:

- `Docs/00_AI_WORKFLOW.md`: where to look, code map, commands, platform notes.
- `Docs/01_ARCHITECTURE.md`: layer responsibilities, MVI rules, Data/Domain boundaries.
- `Docs/02_UI_IMPLEMENTATION_GUIDE.md`: Figma, SwiftUI, UIKit, colors, typography, assets, UI implementation rules.
- `Docs/03_RELEASE_APPSTORE_LEGAL.md`: fastlane, TestFlight, App Store, privacy/legal checklist.

`AGENTS.md` is intentionally short. Put detailed guidance in `Docs`, not here.

## Doc Selection Rules

- For code navigation, start with `00_AI_WORKFLOW`.
- For foldering, model boundaries, or MVI ownership, start with `01_ARCHITECTURE`.
- For UI, Figma, SwiftUI, UIKit, colors, fonts, or assets, start with `02_UI_IMPLEMENTATION_GUIDE`.
- For TestFlight, App Store Connect, privacy, terms, or support URL work, start with `03_RELEASE_APPSTORE_LEGAL`.
- For repeated task execution patterns, start with `00_AI_WORKFLOW`.
- If a doc conflicts with live code, trust live code first and update the doc.

## Build

Run this after code or project-structure changes:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme Rodi -destination 'generic/platform=iOS Simulator' build
```

Documentation-only changes do not require a build.

## Architecture Defaults

- `Presentation` owns screens, MVI state/action/reducer, SwiftUI views, Home-specific services, and UIKit/Kakao map adapters.
- `Core` owns shared infrastructure, design tokens, legal web view, logging, networking primitives, and app-wide utilities.
- `Resources` owns assets, bundled data, fonts, and privacy manifest.
- `Data` and `Domain` are intentionally light for now; do not force models into them before the server API is stable.
- `Domain` must not import SwiftUI, UIKit, KakaoMapsSDK, RealmSwift, URLSession, or Bundle.

## Design Defaults

- Minimum deployment target is iOS 16.
- Do not introduce iOS 17+ APIs without `#available` gating and fallback.
- Use `RodiColor`, `RodiTypography`, `.rodiTypography(...)`, `Font.pretendard(...)`, and `UIFont.pretendard(...)`.
- Assets live in `Rodi/Resources/Assets.xcassets`.
- Fonts live in `Rodi/Resources/Fonts`.

## Docs Over Skills

Do not rely on `.opencode/skills` as project truth. If a skill conflicts with `AGENTS.md`, `Docs`, or the live code, follow the live code and `Docs`.
Keep project-specific working agreements in `Docs`.
Do not create new skill or handoff files unless the user explicitly asks for them.
Docs do not update themselves. When a code, architecture, dependency, release, privacy, or UI convention change makes a doc stale, update the relevant `Docs/*.md` in the same task or report the drift clearly in the final response.
