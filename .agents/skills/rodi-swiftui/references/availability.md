# iOS 16.1 Availability

## Keep the Baseline

- Treat iOS 16.1 as the minimum runtime even when the installed SDK is newer.
- Preserve the project's `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, and MVICore patterns.
- Do not migrate UI state to Observation or `@Observable` as incidental modernization.
- Check the actual Xcode toolchain and Apple API availability before accepting generic "modern SwiftUI" advice.

## Select an API

1. Confirm the API's platform introduction and the target containing the call.
2. Use it directly only when it is available on iOS 16.1.
3. Wrap later APIs in `if #available` or an availability-scoped helper.
4. Implement a fallback with equivalent user-visible behavior; do not leave the older path blank or degraded without product approval.
5. Compile every conditional branch supported by the project.

## Watch Common Traps

- Keep the one-parameter `onChange(of:perform:)` form where iOS 16 support is required; the zero- and two-parameter closures are newer.
- Treat Observation, `containerRelativeFrame`, `visualEffect`, `ContentUnavailableView`, and `sensoryFeedback` as later-OS options requiring verification and fallback.
- Do not adopt the newer `Tab` API, iOS 26 `WebView`, `@Animatable`, or other upstream-default APIs without checking availability.
- Prefer iOS 16-compatible `NavigationStack`, `Grid`, `ViewThatFits`, custom `Layout`, stacks, alignment, flexible frames, overlays, and `safeAreaInset` when they fit the existing design.
- Prefer an explicit `RoundedRectangle` or another confirmed iOS 16-compatible shape spelling over syntax introduced by a newer SDK.
- Keep UIKit adapters already required by Kakao Maps, gestures, or platform delegates; do not remove them merely to make the code "pure SwiftUI."

## Review a Gated Path

- Exercise both modern and fallback paths conceptually and in code review.
- Keep state, accessibility labels, safe-area behavior, and interaction semantics equivalent.
- Flag a newer API without a reachable fallback as a compatibility defect, not a style preference.
