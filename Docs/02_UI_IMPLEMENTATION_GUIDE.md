# RODI UI Implementation Guide

This document explains how to translate RODI design references into SwiftUI and, only when explicitly requested, UIKit implementation.

## Figma Source

Primary Figma file:

https://www.figma.com/design/7awHdG2meTh8izvlqKWyrd

Important onboarding frames:
- `스플래시 _ 신규`
- `약관 동의-1`
- `약관 동의-2`
- `닉네임 설정`
- `경력입력`
- `경력입력 선택 완료`
- `경력입력_내용 입력 전`
- `경력입력_내용 입력 완료`
- `운전 자격 및 주의 사항`
- `위치 권한 안내`

Use Figma as a visual source, but implement with native app patterns and existing RODI components.

## Default UI Stack

Use SwiftUI by default.

UIKit is allowed only when:
- the user explicitly asks for UIKit
- the code is already inside an existing UIKit-backed integration such as Kakao Maps

Do not independently choose UIKit just because a layout looks complex.

## Design Tokens

Design tokens live in:

```text
Rodi/Core/RodiDesignSystem.swift
```

Use:
- `RodiColor`
- `RodiTypography`
- `.rodiTypography(...)`
- `Font.pretendard(...)`
- `UIFont.pretendard(...)`

Avoid:
- ad hoc `.font(...)`
- raw colors when a token exists
- one-off typography unless a new token is intentional

## Colors

| Purpose | Value | Token |
| --- | --- | --- |
| Primary | `#5640FF` | `RodiColor.primary` |
| Primary 50 | `#F0EFFF` | `RodiColor.primary50` |
| Primary 100 | `#DBD9FF` | `RodiColor.primary100` |
| Primary 200 | `#BAB6FF` | `RodiColor.primary200` |
| Course text marker | `#7062FF` | `RodiColor.primary400` |
| Gray 100 | `#F5F5F5` | `RodiColor.gray100` |
| Black text | `#222222` | `RodiColor.black` |

## Typography

Bundled Pretendard fonts:
- `Pretendard-Regular`
- `Pretendard-Medium`
- `Pretendard-SemiBold`
- `Pretendard-Bold`

Font files live in:

```text
Rodi/Resources/Fonts
```

Use `.rodiTypography(...)` on `Text` for app text styles.

Current token families include:
- `heading2`
- `headline1`
- `headline2`
- `body1SemiBold`
- `body1Medium`
- `body3Medium`
- `caption1Medium`
- `caption1Regular`
- `caption2SemiBold`
- `caption3Medium`
- `buttonMedium`

## Assets

Asset catalog:

```text
Rodi/Resources/Assets.xcassets
```

Common assets:
- `ic_check_active`
- `ic_check_inactive`
- `ic_location_permission`
- `ic_caution_round`
- `ic_caution_round_white`
- `ic_network_inactive`
- `ic_my_location_active`
- `ic_my_location_inactive`
- `ic_start_pin`
- `ic_arrival_pin`
- `ic_parking_pin`
- `ic_star`

## Figma Implementation Rules

- Use Figma Dev Mode values as reference, not as absolute code.
- Identify screen background, header, content blocks, cards, lists, forms, primary/secondary actions, chips, status, empty, loading, and error states before coding.
- If one design input is missing but the screen is otherwise unambiguous, proceed with an explicit assumption instead of blocking.
- Preserve visual hierarchy before pixel-level polish.
- Map Figma colors and text styles to `RodiColor` and `RodiTypography`.
- Do not copy Figma coordinates into `.position` or repeated `.offset`.
- Avoid device-sized fixed frames.
- Use responsive SwiftUI layout with stacks, scroll views, constraints, safe-area handling, and explicit subviews.
- Save required assets to the asset catalog and use stable asset names.
- If Figma text implies guaranteed safety or accident prevention, flag it before implementing.

## SwiftUI Rules

- Prefer stable view trees over large top-level conditional branches.
- Split large SwiftUI files into dedicated subviews.
- Keep non-trivial actions out of `body`; call named methods or send MVI actions.
- Pass explicit values, bindings, and callbacks into subviews.
- Use `Button` for tappable UI instead of gesture-only text or containers.
- Check iOS 16 compatibility before using newer SwiftUI APIs.
- Keep `@State` private.
- Use `@Binding` only when the child modifies parent-owned state.
- Do not mark injected values as `@State` or `@StateObject`; they can ignore upstream updates.
- Use `@StateObject` for view-owned observable objects and `@ObservedObject` for injected observable objects.
- Use stable identity in `ForEach`; avoid `.indices` for dynamic lists.
- Keep a constant number of views per `ForEach` element when possible.
- Use `.animation(_:value:)` with an explicit `value`.
- Add accessibility labels or grouping for icon-only actions and compact controls.
- Reduce unnecessary state updates before introducing new abstractions.
- Consider downsampling when large raw image decoding such as `UIImage(data:)` appears in a hot path.

## UIKit Rules

UIKit is not the default. Use it only when the user explicitly instructs it or when maintaining existing UIKit-backed code.

When UIKit is used:
- Prefer programmatic views.
- Use Auto Layout for sizing and positioning.
- Use SnapKit for concise constraints if installed.
- Use Then for simple object configuration if installed.
- Use RxSwift, RxCocoa, RxRelay, and NSObject-Rx only for explicitly reactive flows or existing Rx-based code.
- Prefer `DisposeBag` or `rx.disposeBag` for subscription lifetime management.
- Keep UIKit lifecycle and delegates in UIKit classes/adapters.
- Bridge UIKit into SwiftUI with `UIViewRepresentable` or `UIViewControllerRepresentable`.

Avoid:
- frame-based layout for adaptive screens
- choosing UIKit without user instruction
- mixing UIKit lifecycle code directly into SwiftUI view bodies
- unmanaged Rx subscriptions
- using RxRelay as hidden global mutable state
- overusing Then for complex setup

## Home UI Rules

- Home-specific components should stay under `Presentation/Home/Views`.
- Home map adapter code belongs under `Presentation/Home/Map`.
- Do not move Home-only chips, bottom sheets, marker UI, or controls to `Core/Components` unless reused outside Home.
- Kakao map rendering is UIKit-backed; do not replace it with a pure SwiftUI map.

## Onboarding UI Rules

- Current flow is entry/social login -> terms -> nickname -> required driving experience -> optional driving preference -> safety confirmation -> location permission.
- The entry screen owns browse, Apple login, and Kakao login actions. Browse goes directly to Home.
- Apple/Kakao login UI must send MVI actions through `OnboardingAction.EntryAction`; do not mutate `OnboardingState` directly from views.
- KakaoTalk-not-installed fallback alerts are production UX; keep the copy user-facing and avoid test-only wording.
- Use current onboarding subviews before introducing new ones.
- Keep agreement row hit areas accessible and tappable across the full row.
- Legal document titles must match user-facing legal page titles.
- Do not use dark/light mode dependent colors unless intentionally tokenized.

## References

- Apple UIKit: https://developer.apple.com/documentation/uikit
- Apple View Controller guidance: https://developer.apple.com/documentation/UIKit/UIViewController
- Apple Auto Layout Guide: https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/index.html
- SnapKit: https://github.com/SnapKit/SnapKit
- RxSwift: https://github.com/ReactiveX/RxSwift
- NSObject-Rx: https://github.com/RxSwiftCommunity/NSObject-Rx
- Then: https://github.com/devxoul/Then
