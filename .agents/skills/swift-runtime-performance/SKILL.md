---
name: swift-runtime-performance
description: Use this skill when reviewing Swift code for runtime-level performance costs, including heap allocation, ARC traffic, stack vs heap storage, closure capture contexts, method dispatch, protocol witness dispatch, existentials vs generics, opaque types, copy-on-write, SIL optimizer output, unsafe memory boundaries, or module-boundary optimizer visibility. Do not use it for Swift Concurrency scheduling, SwiftUI rendering, app launch, or profiling workflows unless the question is specifically about Swift runtime costs.
---

# Swift Runtime Performance

## 목적과 적용 범위

이 Skill은 Swift 코드에서 실제로 중요한 allocation·ARC·dispatch·boxing·copying·최적화 경계 비용을 검토한다.

- MUST 비용이 의심되는 hot path와 사용자 영향이 있는 요청에 적용한다. 일반 문법·폴더링·UI 스타일만으로 적용하지 않는다.
- MUST 주제가 실행·첫 frame이면 `ios-launch-performance`, SwiftUI 갱신이면 `swiftui-performance`, actor·Task·취소이면 `swift-concurrency-performance`, 측정 도구이면 `ios-performance-profiling`의 범위를 먼저 구분한다. 추가 runtime 문제가 있을 때만 함께 사용한다.
- MUST [AGENTS.md](../../../AGENTS.md)의 변경 권한·지원 OS·보호 영역을 유지한다. 원본 라이선스는 [LICENSE](LICENSE)에 보존한다.

## 검토 순서

1. MUST 지연·메모리·CPU·반복 비용 등 증상과 실행 빈도·데이터 크기·호출 위치를 확인해 hot path인지 판단한다.
2. MUST 비용을 allocation, ARC, dispatch, existential/generic, copying, compiler 최적화, unsafe 또는 module 경계로 구분한다.
3. MUST 측정·optimized SIL·benchmark 중 해당 비용을 확인할 근거를 선택하고, 실제 관찰과 이론적 가능성을 구분한다.
4. MUST 추상화의 제품 의미·수명·다형성·value semantics·동시성 계약을 확인한 뒤 가장 작은 변경을 검토한다.
5. MUST 가독성·API 유연성·testability·ABI·binary 크기·build 시간·유지보수의 trade-off를 설명하고 같은 경로에서 전후 검증한다.
6. MUST NOT hot path나 의미 있는 비용의 근거가 없는데 저수준 재작성을 수행한다. 사용자 영향이 의심될 때만 필요한 다음 측정을 제시한다.

## 유지할 판단 기준

- MUST NOT `struct`를 stack allocation 보장으로, `class`를 성능 결함으로 해석한다. value type·collection도 heap storage·ARC·bridging 비용을 가질 수 있다.
- MUST allocation 원인이 객체·escaping closure·box·type erasure·중간 collection·Foundation bridging 중 무엇인지 확인한다. reference type 전체 교체보다 실제 반복 allocation 감소를 검토한다.
- MUST ARC 변경 전에 소유권과 수명을 확인한다. `weak`·`unowned`는 수명 계약이며 일반적인 성능 해결책이 아니다.
- MUST 동적 다형성과 runtime heterogeneity가 필요한지 확인한다. `any Protocol`은 유효한 계약이며 `some`·generics·구체 타입으로 일괄 대체하지 않는다.
- MUST generics의 specialization·devirtualization이 실제 발생하는지 확인한다. public resilience·module 경계·함수 크기·type erasure가 영향을 줄 수 있다.
- MUST COW 변경 전에 uniqueness·mutation 패턴을 확인하고 value semantics·thread-safety 가정을 보존한다.
- MUST 성능 판단에 optimized SIL을 사용하고 compiler 버전을 확인한다. 한 버전의 SIL 형태에만 코드를 맞추지 않는다.
- MUST NOT `final`·`@inline(__always)`를 일괄 최적화로 적용한다. 상속 의도가 없는 app class의 `final`과 실제 성능 개선 근거를 구분하고 inlining의 코드 크기 비용을 확인한다.
- MUST `@inlinable`·`@usableFromInline`·`@frozen` 도입 시 최적화 근거와 API/ABI 약속을 확인한다.
- MUST unsafe API는 안전한 API로 충분하지 않고 비용이 측정된 경우에만 검토한다. pointer 수명·binding·alignment·aliasing·mutation을 작은 safe wrapper 경계에서 보장한다.

## 필요한 참고자료 선택

- MUST 현재 판단에 필요한 행만 읽고, 참고자료 전체를 로딩하지 않는다. 구체적인 변경과 검증 경로가 정해지면 탐색을 멈춘다.

| 판단할 문제 | 참고자료 |
| --- | --- |
| heap/stack·box·closure context·중간 collection·layout | [allocation-and-layout.md](references/allocation-and-layout.md) |
| retain/release·capture·weak/unowned·bridging 수명 | [arc-and-ownership.md](references/arc-and-ownership.md) |
| dynamic/witness/ObjC dispatch·specialization·devirtualization | [dispatch-and-specialization.md](references/dispatch-and-specialization.md) |
| any·some·generic·type erasure·이종 collection | [existentials-generics-opaque-types.md](references/existentials-generics-opaque-types.md) |
| 대형 값·반복 복사·collection mutation·custom COW | [cow-and-large-values.md](references/cow-and-large-values.md) |
| allocation·ARC·witness·inlining의 compiler 근거 | [sil-inspection.md](references/sil-inspection.md) |
| pointer·buffer·binding·alignment·unsafe wrapper | [unsafe-swift.md](references/unsafe-swift.md) |
| module 가시성·resilience·inlinable·frozen·linking | [modularization-and-linking.md](references/modularization-and-linking.md) |
| 동시성 코드의 allocation·ARC·SIL 비용만 남은 경우 | [concurrency-runtime.md](references/concurrency-runtime.md) |

## 검증과 보고

- SHOULD allocation·객체 churn은 Allocations, CPU·복사·bridging·hot call은 Time Profiler, specialization·ARC 삽입은 optimized SIL을 선택한다. 작은 benchmark와 XCTest는 재현 가능한 연산의 회귀 확인에 사용한다.
- MUST Debug 전용 개발 성능 요청 외에는 Debug build 결과를 최적화 성능의 근거로 사용하지 않는다. 실제 사용자 경로의 개선은 같은 조건의 전후 trace로 확인한다.
- MUST 결과에 실제/이론적/판단 불가 구분, 비용 분류와 hot path 근거, 최소 변경·trade-off, 필요한 증거와 검증 결과를 포함한다. 짧은 질문에 고정된 긴 보고 양식을 강제하지 않는다.
- MUST NOT 소스 모양만으로 느리다고 단정하거나 전후 근거 없이 성능 개선을 완료로 보고한다.
