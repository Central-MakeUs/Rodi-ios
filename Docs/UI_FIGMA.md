# RODI UI · Figma Guide

이 문서는 Figma 기반 SwiftUI 구현과 UI 리뷰에만 사용하며, 기본 컨텍스트는 `AGENTS.md`와 이 문서로 제한한다.

## 권위와 최소 컨텍스트

UI 계약의 우선순위는 다음과 같다.

1. 사용자의 현재 요구사항과 `AGENTS.md`의 제품·안전 금지사항
2. 대상 Figma frame의 screenshot과 interaction
3. 현재 인접 View·Reducer·Component와 design-system 코드
4. 이 문서
5. UI 구현·리뷰에 필요할 때만 `.agents/skills/rodi-swiftui`

- Figma 링크는 코드 생성 명령이 아니라 디자인 근거다.
- screenshot은 시각적 원본이고, design context의 React/Tailwind는 구조 참고일 뿐이다.
- 문서와 코드가 다르면 현재 코드를 따르고 같은 작업에서 문서 차이를 바로잡는다.
- 전체 `Docs`, `Presentation`, asset catalog를 먼저 읽지 않는다. `rg`로 대상 심볼과 인접 구현부터 찾는다.
- `Docs/Archive`는 과거 UI 조사 요청이 있을 때 필요한 파일만 명시적으로 읽는다.
- Reducer 구조나 foldering 판단이 작업의 핵심이면 그때만 `Docs/ARCHITECTURE.md`를 추가로 읽는다.

## Figma Dev Mode → SwiftUI

Figma URL을 받으면 다음 순서를 지킨다.

1. URL이 `node-id`를 포함한 구현 대상 frame 링크인지 확인한다.
2. 해당 node의 design context와 screenshot을 한 번씩 조회한다.
3. screenshot으로 시각적 계약을 확인하고, 생성 코드는 hierarchy·문구·asset 단서로만 사용한다.
4. 대상 feature의 인접 View·Reducer·Component와 route를 `rg`로 찾는다.
5. design token, font, asset catalog에서 재사용 가능한 항목을 찾는다.
6. 화면 구조와 loading·empty·error·success 상태, interaction과 navigation을 먼저 정리한다.
7. Figma 값을 RODI token·asset·기존 component에 매핑하고 필요한 파일만 결정한다.
8. View는 State를 렌더링하고 Action을 전달하며, Reducer는 상태 전이와 Effect를 관리한다.
9. Debug build와 시각 검증을 수행하고 Figma와 다른 점 또는 미확정 사항을 보고한다.

node가 page/canvas라 context를 얻을 수 없으면 내부의 실제 frame을 찾아 다시 조회한다.
대상 node나 디자인이 바뀌지 않았다면 같은 context와 screenshot을 반복 조회하지 않는다.
Figma의 기기 bezel, status bar, home indicator는 앱 asset이나 custom view로 옮기지 않는다.

## RODI Design System

실제 원본은 다음 경로다.

```text
Rodi/Core/Components/RodiDesignSystem.swift
Rodi/Resources/Fonts
Rodi/Resources/Assets.xcassets
```

- 색상은 먼저 `RodiColor`에서 찾고, 대응 token이 있으면 raw hex나 임의의 system color로 대체하지 않는다.
- 텍스트는 `RodiTypography`와 `.rodiTypography(...)`를 우선한다.
- token이 없는 의도적인 크기에는 `Font.pretendard(...)`를, UIKit 경계에는 `UIFont.pretendard(...)`를 사용한다.
- Pretendard Regular·Medium·SemiBold·Bold 파일은 실제 Fonts 폴더와 등록 코드를 기준으로 확인한다.
- 새 token이 필요하면 같은 의미의 기존 token이 없는지 사용처까지 검색한 뒤 추가를 제안한다.
- asset은 catalog의 실제 이름과 rendering 특성을 확인하고, 기존 항목을 우선 재사용한다.
- asset 이름 전체 목록이나 색상값 표를 문서에 복제하지 않는다. 자주 변하는 목록의 원본은 코드와 catalog다.
- 새 image가 꼭 필요하면 안정적인 의미 기반 이름을 쓰고, Figma export의 투명 여백과 scale을 확인한다.

## 기존 RODI UI 계약

Generic SwiftUI 권고보다 현재 제품 계약과 인접 구현이 우선한다.

- 앱 하단 탐색은 `RodiBottomTabBar`와 `MainTabView`의 custom 동작을 유지한다.
- Home의 sheet는 `Presentation/Home/BottomSheet` 아래 custom 상태·gesture·safe-area 동작을 유지한다.
- Figma가 tab bar나 sheet처럼 보여도 곧바로 `TabView`나 system `.sheet`로 교체하지 않는다.
- 기존 feature component가 있으면 화면별 복제품을 만들지 말고 현재 API와 책임을 확인해 재사용한다.
- Kakao map은 기존 UIKit-backed adapter 경계를 유지하며 순수 SwiftUI map으로 대체하지 않는다.
- Figma 문구가 안전·사고 방지를 보장하는 표현이면 구현 전에 `AGENTS.md` 기준으로 바로잡거나 보고한다.

## SwiftUI와 MVI 책임

- View는 State 렌더링, 사용자 입력 수집, Action 전달만 담당한다.
- Reducer는 사용자 의도, 상태 전이, Effect 시작·취소, 최신 응답 판단을 담당한다.
- SDK·UIKit delegate·외부 I/O는 기존 Service/Adapter 경계를 따른다.
- `body` 안에 비동기 업무나 비즈니스 결정을 넣지 않는다.
- 탭 가능한 요소는 `Button`을 우선하고, 아이콘 단독 버튼에는 접근성 label을 제공한다.
- 동적 목록은 안정적인 identity를 사용하고 `.indices`를 데이터 identity로 삼지 않는다.
- 큰 View를 나눌 때 먼저 같은 파일의 작은 private subview/extension이 충분한지 판단한다.

## Layout과 Geometry

새 코드에서는 기본적으로 다음을 사용하지 않는다.

- `GeometryReader`
- size 측정용 `PreferenceKey`
- 직접 `UIScreen.main`
- 기기 전체 크기를 고정한 `.frame`
- Figma 좌표를 복제한 `.position`
- 흐르는 content를 맞추기 위한 반복적인 `.offset`

대안은 다음 순서로 검토한다.

1. `VStack`, `HStack`, `ZStack`, `Grid`, `ScrollView`
2. alignment, `Spacer`, flexible `.frame(maxWidth:maxHeight:)`
3. `fixedSize`, `layoutPriority`
4. `safeAreaInset`, alignment 기반 `overlay`
5. `ViewThatFits` 또는 iOS 16의 `Layout`
6. 기존 `screenBounds`, `screenSafeAreaInsets`
7. SDK나 gesture 특성상 필요한 UIKit adapter

측정이 불가피하면 도입 전에 필요한 이유, 위 대안이 실패한 근거, 영향 화면을 보고한다.
작은 icon이나 명확한 component 자체 크기까지 금지하는 규칙은 아니며, 화면 전체를 Figma pixel frame으로 고정하지 않는 것이 목적이다.
현재 `LoginView`와 `OnboardingAnalysisDialog`의 직접 `UIScreen.main` 사용은 별도 UI 리팩터링 대상이며 새 코드가 따라 하지 않는다.

## Compatibility와 적응형 검증

최소 지원은 iOS 16.1이다.
iOS 17+ API를 쓰려면 `#available` 분기와 iOS 16.1 fallback을 함께 구현한다.
custom tab, bottom sheet, keyboard가 top·bottom safe area와 충돌하지 않는지 확인한다.

구현 후 최소한 다음을 확인한다.

- compact device와 large device에서 clipping, overflow, 과도한 빈 공간이 없는가
- 긴 한국어 문구와 큰 Dynamic Type에서 핵심 정보와 action이 유지되는가
- VoiceOver label·trait·reading order와 충분한 tap target이 있는가
- 색상만으로 selected·disabled·error 상태를 구분하지 않는가
- Reduce Motion 등 접근성 설정에서도 interaction 의미가 유지되는가
- loading·empty·error·success가 실제 State에서 각각 도달 가능하고 전환이 자연스러운가
- keyboard, scroll, safe area, modal·navigation dismiss 동작이 기존 흐름과 맞는가

코드 또는 프로젝트 구조를 바꿨다면 `AGENTS.md`의 `Rodi Dev` Debug 기준으로 build한다.
가능하면 동일 상태의 simulator screenshot을 Figma와 나란히 비교하고 hierarchy, spacing, typography, asset, interaction 순으로 차이를 확인한다.
자동 테스트 target이 없다면 “테스트 통과”라고 쓰지 말고, 수행한 build와 수동·시각 검증만 정확히 기록한다.
