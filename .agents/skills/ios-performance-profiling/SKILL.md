---
name: ios-performance-profiling
description: Use this skill when choosing, running, or interpreting iOS performance profiling workflows, including Instruments traces, signposts, XCTest metrics, MetricKit, Xcode Organizer, hangs, hitches, CPU, allocations, memory graphs, disk I/O, networking, power, or production performance signals. Do not use it as the deep domain skill for launch, SwiftUI, concurrency, perceived performance, or runtime issues unless the task is specifically about measurement, tool selection, trace interpretation, or verification.
---

# iOS Performance Profiling

## 목적과 적용 범위

이 Skill은 iOS 성능 증상에 맞는 측정 도구를 선택하고 trace·지표를 해석한다.

- MUST 측정 계획, 도구 선택, 기존 trace 해석 또는 전후 검증이 필요한 요청에 적용한다.
- MUST NOT 구체적 원인이 알려진 launch·SwiftUI·동시성·체감 속도·runtime 수정에서 기본으로 함께 읽는다. 추가 측정 문제가 있을 때만 적용한다.
- MUST [AGENTS.md](../../../AGENTS.md)의 변경 권한·지원 OS·보호 영역을 유지한다. 원본 라이선스는 [LICENSE](LICENSE)에 보존한다.

## 측정과 해석 순서

1. MUST 계획·코드 리뷰·실제 측정·기존 증거 해석 중 요청을 구분하고, 사용자 증상과 재현 경로를 정한다.
2. MUST 실제 project·scheme·build 설정, 연결 기기·OS, 사용할 수 있는 도구·trace·로그를 확인한다. 도구가 없으면 측정 계획과 미확인 사항을 제시한다.
3. MUST 아래 표에서 가장 직접적인 도구를 고르고 기기·OS·build·데이터·계정/네트워크·반복 횟수를 기록한다.
4. MUST stack, hitch, allocation·retained graph, I/O, waterfall, wakeup 또는 운영 분포 중 가장 강한 신호를 먼저 해석한다.
5. MUST 증명된 사실과 가설을 분리하고, 우선 가설 한두 개에 연결되는 최소 변경 또는 다음 조사를 제시한다.
6. MUST 개선을 주장하려면 같은 시나리오의 전후 재측정 근거를 제시한다. SHOULD 중요 경로에는 XCTest·CI·운영 지표 중 적합한 회귀 감시를 둔다.

## 도구·참고자료 선택

- MUST 현재 시나리오에서 실제 사용할 수 있는 도구를 확인한다. 아래 이름만 보고 설치·OS 지원을 가정하지 않는다.
- MUST 참고자료 전체를 읽지 않고 필요한 행만 선택한다. 도구 선택 자체가 불명확할 때만 [tool-selection.md](references/tool-selection.md)를 추가한다.

| 증상·목적 | 우선 도구·신호 | 상세 참고자료 |
| --- | --- | --- |
| 실행·첫 frame·첫 상호작용 | App Launch, Time Profiler, XCTest launch metric | [tool-selection.md](references/tool-selection.md) |
| hang·CPU·느린 연산 | Hangs, Time Profiler; 필요 시 Counters·Main Thread Checker | [time-profiler-and-hangs.md](references/time-profiler-and-hangs.md) |
| animation·scroll hitch, 반복 SwiftUI 갱신 | Animation Hitches·Core Animation·SwiftUI Instrument·Time Profiler | [animation-hitches-and-swiftui.md](references/animation-hitches-and-swiftui.md) |
| 메모리 증가·allocation churn | Allocations·VM Tracker; 소유 관계는 Memory Graph·Leaks | [memory-leaks-and-allocations.md](references/memory-leaks-and-allocations.md) |
| disk 지연·쓰기 증폭 | File Activity·System Trace·disk 진단 지표 | [network-disk-power.md](references/network-disk-power.md) |
| 느린 네트워크·중복 요청 | Network instrument·URLSession metrics·서버 timing | [network-disk-power.md](references/network-disk-power.md) |
| 배터리·발열·wakeups | Energy Log·Power Profiler·운영 지표 | [network-disk-power.md](references/network-disk-power.md) |
| 운영에서만 재현·회귀 감시·p95/p99 | MetricKit·Organizer·XCTest·CI 이력 | [xctest-metrickit-organizer.md](references/xctest-metrickit-organizer.md) |
| 시스템 trace에서 구분 안 되는 앱 고유 작업 | `os_signpost`·`OSSignposter`, 안정적인 재현 시나리오 | [signposts-and-scenarios.md](references/signposts-and-scenarios.md) |

## 오판 방지

- MUST CPU 실행, lock·actor 대기, I/O·network 대기, memory pressure를 구분한다. wall-clock 지연만으로 CPU 병목을 단정하지 않는다.
- MUST 비용이 사용자 경로를 실제로 지연하는지 확인한다. background로 옮겨도 UI가 그 결과를 기다리면 지연이 남을 수 있다.
- MUST 메모리 증가·allocation spike만으로 retain cycle을 단정하지 않고 generation·참조 경로를 확인한다. `weak` 일괄 추가를 해결책으로 삼지 않는다.
- MUST 로컬 trace의 원인 분석, 운영 MetricKit/Organizer의 분포, XCTest 회귀 측정의 역할을 구분한다. 평균만으로 긴 지연을 숨기지 않고 필요한 percentile과 편차를 확인한다.
- MUST NOT CPU trace가 깨끗하다는 이유로 network 지연을 배제한다. 전력 문제는 timer·polling·sensor·위치·background·offscreen 반복 작업도 확인한다.
- MUST 변경은 관찰된 근거에 연결한다. 반복 작업·중복 요청 축소, 소유권·취소, disk batching 등을 검토하되 근거 없는 전체 재설계·의존성 미확인 병렬화는 하지 않는다.

## 관련 Skill로 확장하는 조건

- SHOULD 원인이 드러난 뒤 깊은 구현 판단이 필요할 때만 해당 Skill을 추가한다: 실행 필수 의존 경로는 `ios-launch-performance`, invalidation·identity·layout은 `swiftui-performance`, actor·Task·취소는 `swift-concurrency-performance`, 피드백·loading 경험은 `ios-perceived-performance`, ARC·boxing·dispatch·COW는 `swift-runtime-performance`.
- MUST NOT 관련 Skill을 모두 읽거나 전문 규칙을 이 문서에 복제한다.

## 검증과 보고

- SHOULD 실기기·Release에 가까운 build·안정적인 데이터·반복 측정을 우선한다. Simulator는 상대적 로컬 조사에 사용할 수 있으나 기기 전력·발열·메모리 압박·출시 성능의 증거로 일반화하지 않는다.
- MUST NOT Debug 결과나 깨끗한 한 번의 실행을 개선 완료로 판단한다.
- MUST 보고에 증상·측정 조건, 선택한 도구와 이유, 실제 관찰과 가설, 다음 변경/조사, 재측정 결과·미검증을 포함한다. 코드 리뷰는 위험과 검증 방법을, trace 해석은 가장 강한 신호와 증거의 한계를 중심으로 쓴다.
- MUST NOT 도구·trace가 없는데 프로파일링을 수행했다고 하거나, 측정하지 않은 성능 향상을 보고한다.
