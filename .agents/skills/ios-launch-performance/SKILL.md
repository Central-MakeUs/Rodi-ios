---
name: ios-launch-performance
description: Use this skill when diagnosing iOS app launch performance, startup regressions, first-frame readiness, or early responsiveness. Covers pre-main/dyld work, AppDelegate/SceneDelegate, SwiftUI App startup, launch orchestration, SDK initialization, and launch measurement. Do not use for general performance unless the code runs on the launch path.
---

# iOS Launch Performance

## 목적과 적용 범위

이 Skill은 앱 실행 요청부터 첫 화면·첫 상호작용까지의 지연을 진단한다.

- MUST 실행 경로에 있는 pre-main, 앱·scene 초기화, 의존성 구성, SDK 시작, 첫 렌더링과 직후 응답성에 적용한다.
- MUST NOT 일반 스크롤·메모리 누수·네트워크·아키텍처 문제만으로 적용한다. 실행 중인 앱의 복귀는 새 process 실행과 구분한다.
- MUST [AGENTS.md](../../../AGENTS.md)의 변경 권한·지원 OS·보호 영역을 유지한다. 원본 라이선스는 [LICENSE](LICENSE)에 보존한다.

## 진단 순서

1. MUST cold·warm·prewarmed·resume·최초 설치/실행·업데이트·불명 중 시나리오를 분류한다. 서로 다른 시나리오의 측정값을 합치지 않는다.
2. MUST App/SceneDelegate, SwiftUI App·root, DI 구성, global/static과 SDK 호출 중 실제 실행 경로만 좁혀 읽는다. 숨은 초기화는 실행 시점·비용을 확인하기 전까지 가설로 둔다.
3. MUST pre-main·runtime/static·app/scene·DI·첫 렌더링·직후 응답성 중 비싼 구간을 근거로 판별한다. 불명확하면 먼저 측정 경로를 제시한다.
4. MUST 각 작업을 첫 화면 필수, 첫 상호작용 필수, 직후 필요, 인증 이후, 후속 feature, 유지보수로 분류한다.
5. MUST 순서가 있는 경우 실제 선행 조건, main-thread 제약, 공유 상태, 실패 시 진입 차단, 가장 긴 필수 의존 경로를 확인한다.
6. SHOULD 근거가 있는 구간 하나에 제거·지연·lazy 초기화 등 가장 작은 변경을 제안하고, 같은 조건으로 재측정한다.

## 유지할 판단 기준

- MUST NOT dyld를 기본 원인으로 지목하거나 측정 없이 framework 개수 제한·전체 static linking을 권한다. linking은 build 시간·binary 크기·중복 symbol·resource·SDK 배포·debugging·mergeable library 조건을 함께 검토한다.
- MUST NOT 400ms를 watchdog 한계나 pre-main 예산으로 해석한다. 첫 화면 UX 목표를 논의할 때만 taxonomy 참고자료의 맥락을 확인한다.
- MUST NOT `+initialize`를 `+load`의 보편적 대안으로 삼는다. 부작용 있는 constructor·global/static·eager singleton은 실제 비용을 확인하고 명시적 초기화를 검토한다.
- MUST 병렬화 전에 의존 순서·actor isolation·공유 상태·main-thread 요구·실패 전파를 확인한다. 근거 없는 main-thread 동기 대기나 전체 재설계로 확대하지 않는다.
- MUST NOT main queue 비동기 예약이나 SwiftUI `.task`가 첫 프레임 이후 실행을 보장한다고 가정한다.
- MUST SDK별 시작 시점과 정확성 요구를 확인한다. crash reporting·보안·deep link·attribution·push·remote config·feature flag를 일괄 지연하지 않는다.
- MUST 첫 화면이 빨라졌어도 첫 상호작용 지연·필수 초기화 누락·중복 실행으로 비용이 이동했는지 확인한다.

## 필요한 참고자료 선택

- MUST 현재 판단에 필요한 행만 선택하고 참고자료 전체를 읽지 않는다. 근거와 다음 조치가 정해지면 탐색을 종료한다.

| 판단할 문제 | 참고자료 |
| --- | --- |
| cold/warm/prewarm/resume 구분, 최초 실행·업데이트, 목표 시간 | [launch-taxonomy-and-targets.md](references/launch-taxonomy-and-targets.md) |
| dyld, `+load`, constructor, global/static, runtime 등록 | [pre-main-dyld-and-static-initializers.md](references/pre-main-dyld-and-static-initializers.md) |
| framework·static/dynamic·mergeable·binary layout | [linking-strategy.md](references/linking-strategy.md) |
| 초기화 순서·실패 전파·병렬화·필수 의존 경로 | [launch-orchestration-and-dependency-graph.md](references/launch-orchestration-and-dependency-graph.md) |
| App/SceneDelegate, storage·keychain·migration, 첫 frame | [appdelegate-scenedelegate-and-first-frame.md](references/appdelegate-scenedelegate-and-first-frame.md) |
| App.init·WindowGroup·root model·환경 주입·task·scenePhase | [swiftui-app-launch.md](references/swiftui-app-launch.md) |
| SDK 필요 시점·lazy 시작·초기화 정확성 | [third-party-sdks-at-launch.md](references/third-party-sdks-at-launch.md) |
| Instruments·signpost·XCTest·MetricKit·Organizer·측정 편차 | [metrics-instruments-xctest-metrickit.md](references/metrics-instruments-xctest-metrickit.md) |

## 검증과 보고

- MUST 기기·OS·build 설정·실행 유형·계정/권한/네트워크·데이터·반복 횟수와 편차를 기록한다. SHOULD 실기기와 Release에 가까운 조건, 구형 지원 기기를 우선한다.
- MUST NOT Debug·Simulator·단일 최신 기기의 한 번 결과를 제품 성능으로 일반화한다. 운영 histogram은 추세 근거이며 로컬 병목을 단독으로 증명하지 않는다.
- SHOULD 구간 진단은 App Launch, CPU는 Time Profiler, 앱 고유 단계는 signpost, 회귀는 XCTest, 운영 분포는 MetricKit/Organizer에서 필요한 도구만 선택한다.
- MUST 결과에 실행 유형, 확인된 구간·필수 의존 경로, 근거와 가설, 우선 변경 또는 다음 측정, 재측정 결과·미검증을 포함한다. 짧은 요청에 고정된 긴 보고 양식을 강제하지 않는다.
- MUST NOT 실제 전후 측정이 없는데 실행 성능 개선을 완료로 보고한다.
