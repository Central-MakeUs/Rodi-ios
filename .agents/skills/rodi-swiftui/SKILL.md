---
name: rodi-swiftui
description: Implement and review Rodi SwiftUI views, layouts, components, and Figma-to-SwiftUI UI work under the project's iOS 16.1, ObservableObject, MVICore, design-system, performance, and accessibility constraints. Use only for tasks that create, change, or review SwiftUI UI code; do not use for reducer-only, API or DTO, Git, release, or documentation tasks.
---

# Rodi SwiftUI

## 목적과 적용 범위

이 Skill은 SwiftUI UI를 구현하거나 검토할 때 RODI 고유의 design system과 화면 계약을 적용한다.

- MUST repository의 `AGENTS.md`와 Figma 작업의 [UI_FIGMA.md](../../../Docs/Guides/UI_FIGMA.md)를 우선한다.
- MUST State·Action·의존성·foldering을 변경할 때만 [ARCHITECTURE.md](../../../Docs/Architecture/ARCHITECTURE.md)를 추가로 읽는다.
- MUST API 도입·교체 또는 iOS 호환성 판단이 필요할 때만 [availability.md](references/availability.md)를 읽는다.
- MUST 목록 identity, 렌더링 비용, 접근성 또는 전체 상태 리뷰가 실제 범위일 때만 [swiftui-review.md](references/swiftui-review.md)를 읽는다.

## RODI 구현 계약

- MUST 색상과 서체를 `Rodi/Core/Components/RodiDesignSystem.swift`, `Rodi/Resources/Fonts`의 실제 token에 먼저 매핑한다.
- MUST image와 icon을 `Rodi/Resources/Assets.xcassets`에서 확인하고, 이름이 같아도 glyph·여백·rendering이 다르면 같은 asset으로 판단하지 않는다.
- MUST 기존 Feature Component, `RodiBottomTabBar`, Home custom bottom sheet, Kakao UIKit adapter의 interaction·safe-area·gesture 계약을 유지한다.
- MUST 현재 `ObservableObject`와 MVICore의 View → Action → Reducer → Effect 흐름을 유지한다.
- MUST generic SwiftUI나 최신 iOS 권고를 이유로 RODI UI를 system `TabView`, system sheet, `Form`, 새 navigation API로 교체하지 않는다.
- MUST 단순 UI 변경에서 캐싱·성능 최적화·상태 구조 변경·공통 Component 승격을 함께 수행하지 않는다.
- SHOULD 같은 의미의 기존 token·Component가 없고 실제 공유 책임이 확인될 때만 새 공통 항목을 제안한다.

## 구현과 검토

- MUST View가 State를 렌더링하고 사용자 입력을 Action으로 전달하게 한다. I/O와 비즈니스 판단은 기존 Reducer·Service·Adapter 경계에 둔다.
- MUST iOS 16.1 이후 API에 동등한 fallback을 둔다.
- MUST 선택 가능한 row·tile·card의 전체 visible rectangle과 icon 단독 control에 적절한 tap target·접근성 label을 제공한다.
- SHOULD stack, grid, scroll, alignment, flexible frame과 기존 safe-area abstraction으로 적응형 layout을 구성한다.
- MUST 리뷰에서는 재현 가능한 결함과 실제 위험만 영향·위치·최소 수정안으로 보고한다.

## Provenance

Adapted from [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/swiftui-agent-skill), reviewed at commit `be297ff80dddec529af1f9b1f1f114aab6c9d11c`. Preserve the bundled MIT license. Do not auto-update; review the upstream diff and iOS 16.1 compatibility before adopting changes.
