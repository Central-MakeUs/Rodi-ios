# 외부 SwiftUI 가이드 반영 기준

## 목적

이 참고 자료는 `ui-ux-pro-max-skill`의 SwiftUI guideline dataset에서 RODI의 iOS 16.1·MVICore·Figma 구현에 유효한 항목만 추린 보조 기준이다. 원본 CSV를 작업마다 전부 읽지 않는다.

원본: <https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/blob/main/cli/assets/data/stacks/swiftui.csv> (검토 commit: `8a1a6d857332da32252d77365da90c3f6293b47b`)

## 적용 기준

- MUST 작은 책임의 `struct View`와 안정적인 `ForEach` identity를 사용한다.
- MUST View가 소유한 참조 상태에는 `@StateObject`, 주입받은 `ObservableObject`에는 `@ObservedObject`를 사용한다.
- MUST iOS 17 `@Observable` 권고를 RODI의 iOS 16.1 지원보다 우선하지 않는다.
- MUST loading·empty·error·success 상태가 실제 Reducer State에서 도달 가능하게 한다.
- MUST 아이콘 action에 접근성 label을 제공하고, 색상만으로 상태를 구분하지 않는다.
- MUST iOS 16.1에서 지원하지 않는 API에 `#available` fallback을 둔다.
- SHOULD 긴 목록에 lazy container와 안정적인 identity를 사용한다.
- SHOULD expensive 계산과 정렬을 `body` 밖에서 수행한다.
- SHOULD `@FocusState`, keyboard dismiss, Dynamic Type, Reduce Motion을 입력·animation 작업에서 검토한다.
- SHOULD 재사용되는 modifier 조합은 실제 중복이 확인된 뒤에만 Component 또는 modifier로 분리한다.

## RODI 우선 규칙

- MUST 현재 MVICore의 View → Action → Reducer → Effect 흐름을 유지한다. 원본의 MVVM 권고는 구조 변경 근거가 아니다.
- MUST Figma, `RodiColor`, `RodiTypography`, custom tab·bottom sheet 계약을 generic `List`, `Form`, system sheet 권고보다 우선한다.
- MUST NOT `GeometryReader`, 직접 `UIScreen.main`, device width 고정 frame을 일반 layout 해법으로 사용한다.
- MUST 측정 기반의 성능 문제는 추측으로 최적화하지 않고 Instruments 또는 재현 가능한 관찰로 확인한다.
