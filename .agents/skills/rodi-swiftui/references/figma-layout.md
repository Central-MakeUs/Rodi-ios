# Figma Layout to Rodi SwiftUI

## Establish the Contract

1. Require a frame link containing `node-id`; ask for the exact node when the link is ambiguous.
2. Fetch design context and a screenshot once for the target node.
3. Treat the screenshot and node properties as the visual contract. Use generated React or Tailwind only to infer hierarchy and repeated structure.
4. Search the target feature's adjacent View, Reducer, component, design tokens, fonts, and assets before designing the SwiftUI structure.
5. List the visible hierarchy, states, interactions, navigation, and loading, empty, error, and success behavior before implementation.

## Map into Rodi

- Map colors to `RodiColor`, text to `RodiTypography` or Pretendard helpers, and imagery to the actual asset catalog.
- Reuse existing feature components before creating a new one.
- Preserve Rodi's custom bottom tab and Home bottom sheet when they differ from generic system UI.
- Follow `Docs/ARCHITECTURE.md` for state ownership and foldering instead of copying generated web component boundaries.
- Record any missing asset, ambiguous behavior, or deliberate design deviation.

## Build Adaptive Geometry

Do not copy Figma x/y coordinates, viewport dimensions, or absolute positioning. Prefer:

1. `Stack`, `Grid`, and `ScrollView`
2. alignment and flexible `frame`
3. `fixedSize` and `layoutPriority`
4. `safeAreaInset` and aligned overlay
5. `ViewThatFits` or an iOS 16 `Layout`
6. an existing project `screenBounds` or `screenSafeAreaInsets` abstraction
7. a UIKit adapter required by SDK or gesture behavior

Avoid new `GeometryReader`, measurement `PreferenceKey`, direct `UIScreen.main`, device-sized fixed frames, `.position`, and repeated `.offset`. Before introducing measurement, report why the preceding options fail and which screens it affects.

Do not copy existing direct `UIScreen.main` usage from `LoginView` or `OnboardingAnalysisDialog`; treat it as pre-existing refactoring debt outside unrelated UI work.

## Verify Visually

- Compare hierarchy, spacing rhythm, alignment, typography, color, corner treatment, imagery, and interaction states with the screenshot.
- Check a compact and a large supported device, safe areas, Dynamic Type, long text, keyboard presentation, and accessibility labels.
- Exercise loading, empty, error, and success states.
- State what could not be matched and why; do not conceal approximations.
