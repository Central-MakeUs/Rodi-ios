---
name: swiftui-expert-skill
description: Review or change SwiftUI state ownership, identity, navigation, accessibility, API availability, animation, or Instruments traces when those concerns are central to the task. Do not load it as a second default skill for ordinary RODI UI styling or Figma implementation.
---

# SwiftUI Expert

## 역할

이 skill은 일반 SwiftUI 구현에 추가 전문 판단이 필요한 경우에 사용한다. RODI에서는 `AGENTS.md`, 활성 프로젝트 문서, live code와 `rodi-swiftui`가 우선한다. 프로젝트의 iOS 16.1, `ObservableObject`, MVICore, design system과 navigation 계약을 generic 현대화 권고보다 먼저 지킨다.

## 적용 조건

- 상태 소유, identity, binding, broad invalidation 또는 View 수명 문제
- sheet·navigation·scroll·focus·animation의 동작 계약
- Dynamic Type, VoiceOver, localization 같은 접근성 검토
- API modernization, deprecation 또는 availability 진단
- 사용자가 제공하거나 수집을 요청한 Instruments `.trace` 분석

MUST 일반 padding·색상·폰트·asset·Figma 구현만으로 이 skill을 추가 활성화하지 않는다. MUST 성능 최적화는 측정 가능한 증상이나 명시적인 검토 범위가 있을 때만 제안한다.

## 작업 방식

1. 대상 View와 직접 소유 State, 인접 Reducer·Component만 먼저 확인한다.
2. 아래 router에서 현재 판단에 필요한 reference만 읽는다.
3. 현재 동작, 확인된 결함, 가능한 위험과 측정 결과를 구분한다.
4. iOS 16.1 이후 API에는 동등한 fallback을 둔다.
5. 변경 범위에 맞는 build·수동 상태·접근성 또는 trace 검증을 수행한다.

MUST 필요한 결정과 검증 경로가 정해지면 다른 reference를 연쇄적으로 읽지 않는다. MUST 같은 작업에서 이미 확인했고 변경되지 않은 reference를 반복해서 읽지 않는다.

## Reference Router

| 실제 작업 | 읽을 reference |
| --- | --- |
| State와 property wrapper | `references/state-management.md` |
| View 책임·구조 분리 | `references/view-structure.md` |
| Identity·목록 | `references/list-patterns.md` |
| Layout | `references/layout-best-practices.md` |
| Sheet·navigation | `references/sheet-navigation-patterns.md` |
| Scroll | `references/scroll-patterns.md` |
| Focus·keyboard | `references/focus-patterns.md` |
| Animation | `references/animation-basics.md`, 필요 시 transitions 또는 advanced |
| 접근성 | `references/accessibility-patterns.md` |
| Text·localization | `references/text-patterns.md` 또는 `references/localization.md` |
| 이미지 decode·downsampling | `references/image-optimization.md` |
| API modernization·deprecation | `references/latest-apis.md`, 필요 시 `references/soft-deprecation.md` |
| Preview | `references/previews.md` |
| SwiftUI 성능 가설 | `references/performance-patterns.md` |
| 기존 trace 분석 | `references/trace-analysis.md` |
| 새 trace 수집 | `references/trace-recording.md` |
| Chart | `references/charts.md`, 접근성 검토 시 `references/charts-accessibility.md` |
| 명시적으로 요청된 Liquid Glass | `references/liquid-glass.md` |

macOS 전용 reference는 macOS 화면 요청에서만 읽는다.

## 필수 검토

- 전달받은 값을 `@State`나 `@StateObject`로 잘못 소유하지 않는지 확인한다.
- 변경 가능한 목록은 안정적인 identity를 사용하고 index를 identity로 삼지 않는다.
- I/O, 정렬, 파싱과 무거운 변환을 `body`에서 반복하지 않는다.
- `Button`과 접근성 label·trait·reading order를 확인한다.
- 애니메이션은 상태값에 연결하고 Reduce Motion에서도 의미를 유지한다.
- Preview는 live service나 network에 의존하지 않는다.

## Trace

실제 `.trace`가 있으면 사용자 증상이 발생한 구간을 먼저 정하고 `references/trace-analysis.md`의 script로 근거를 추출한다. 새 기록 요청에서는 기기·Simulator와 template 차이를 `references/trace-recording.md`에서 확인한다. MUST trace나 측정 없이 성능 개선을 완료로 표현하지 않는다.
