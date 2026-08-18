---
name: rodi-swiftui
description: Implement and review Rodi SwiftUI views, layouts, components, and Figma-to-SwiftUI UI work under the project's iOS 16.1, ObservableObject, MVICore, design-system, performance, and accessibility constraints. Use only for tasks that create, change, or review SwiftUI UI code; do not use for reducer-only, API or DTO, Git, release, or documentation tasks.
---

# Rodi SwiftUI

## Load Context

1. Read repository `AGENTS.md` and [Docs/UI_FIGMA.md](../../../Docs/UI_FIGMA.md).
2. Read [Docs/ARCHITECTURE.md](../../../Docs/ARCHITECTURE.md) only for state, action, boundary, or foldering changes.
3. Load only relevant detail:
   - [availability.md](references/availability.md) for API selection and compatibility.
   - [swiftui-review.md](references/swiftui-review.md) for identity, performance, and accessibility.
   - [figma-layout.md](references/figma-layout.md) for Figma, screenshots, and adaptive layout.

## Workflow

1. Inspect the View, adjacent Reducer and components, design-system code, and assets.
2. Identify hierarchy, interactions, navigation, and loading, empty, error, and success states.
3. Reuse Rodi tokens, assets, components, custom tab bar, and bottom sheet.
4. Preserve ObservableObject and MVICore; reject upstream Observation, view-model, and foldering advice.
5. Use adaptive stacks, grids, scrolling, alignment, and flexible frames. Preserve identity and keep expensive work out of `body`.
6. Verify device sizes, safe areas, Dynamic Type, long text, accessibility, and all states.
7. Gate post-iOS 16.1 APIs with equivalent fallbacks, then run required build and visual checks.

## Guardrails

- Follow live code, Figma node and screenshot, `AGENTS.md`, and active Docs over this skill.
- Avoid new `GeometryReader`, measurement `PreferenceKey`, direct `UIScreen.main`, device-sized frames, `.position`, and repeated `.offset`.
- Before unavoidable measurement, report failed alternatives and affected screens.
- Do not replace Rodi UI with generic system UI, fonts, or newer API merely because upstream prefers them.
- For reviews, report only genuine issues by impact with file, line, consequence, and the smallest compatible fix.

## Provenance

Adapted from [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/swiftui-agent-skill), reviewed at commit `be297ff80dddec529af1f9b1f1f114aab6c9d11c`. Preserve the bundled MIT license. Do not auto-update; review the upstream diff and iOS 16.1 compatibility before adopting changes.
