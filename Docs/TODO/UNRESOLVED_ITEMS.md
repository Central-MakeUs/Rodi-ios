# 미해결 항목

## 목적

이 문서는 현재 코드에서 확인된 장기 개선·리팩터링 항목을 한곳에 기록한다. 기능 작업 중 새로 발견한 구조 문제는 이 문서에 추가하고, 재현 가능한 QA 결함은 별도 QA 이슈 로그에서 관리한다.

## 사용 규칙

- MUST 항목을 해결하기 전에 현재 코드·사용자 흐름·관련 활성 문서를 다시 확인한다.
- MUST 해결한 항목에는 해결 커밋, 검증 결과, 남은 위험을 기록한 뒤 완료로 변경한다.
- MUST NOT 서버 계약, 저장 key·payload, 사용자 UI를 이 문서만 근거로 임의 변경한다.
- SHOULD 한 항목을 독립된 리팩터링 또는 버그 수정 커밋으로 분리한다.
- SHOULD QA에서 발견한 재현 가능한 결함은 [QA 이슈 로그](QA_ISSUES.md)에 기록하고, 구조 개선이 필요할 때만 이 문서의 해당 항목과 연결한다.

## P0 — 안전성·데이터 보존

### UserDefaults의 Codable 구조체 저장 위치와 복구 정책

상태: 부분 완료 · 우선순위: P0

`UserDefaults`에 구조체를 `JSONEncoder`로 `Data`로 변환해 저장하는 행위 자체는 iOS에서 허용되는 방식이다. 현재 문제는 “구조체라서 저장하면 안 된다”가 아니라, 제품 상태 저장 구현이 `Presentation`, `Core`, `Data/Local`에 흩어져 있고 schema version·decode 실패·migration·보존 기간의 정책이 일관되지 않은 점이다.

현재 확인된 `Codable → Data → UserDefaults` 저장소:

- `Data/Local/Onboarding/OnboardingDraftStore.swift`
- `Presentation/PracticeTracking/Service/PracticeTrackingSessionStore.swift`
- `Data/Local/Practice/PracticeMeasurementStore.swift` — schema v1, legacy payload lazy migration, 손상 payload 제거를 적용했다.
- `Presentation/CourseRegistration/Service/CourseRegistrationRecentSearchStore.swift`
- `Presentation/Home/BottomSheet/Filter/Service/HomePracticeFilterStore.swift`
- `Presentation/My/Service/LevelUpPresentationStore.swift`

완료 조건:

- MUST 남은 저장 데이터별 소유 Feature, 민감도, 유지 기간, schema version·migration·decode 실패 정책을 표로 확정한다.
- MUST 장기 제품 데이터와 화면 임시 상태를 구분한다.
- MUST `Data/Local` 변경 전 사용자 승인을 받고, 기존 key·payload 호환성과 앱 업데이트 복구를 검증한다.
- SHOULD 공통 encode/decode 실패 처리와 key namespace 정책을 정리한다.

### SnackbarService의 전역 상태·렌더링 비용 검토

상태: 미해결 · 우선순위: P0

현재 `SnackbarService`는 `@Published message`와 3초 `Task`를 사용하며, `HomeView`가 이를 관찰해 overlay를 다시 렌더링한다. 동시에 Review flow는 자체 snackbar State를 사용한다. 성능 저하가 측정으로 확정된 상태는 아니지만, 전역 singleton성 presentation state와 중복 snackbar 경로가 수명주기·중첩 overlay·불필요한 View invalidation 위험을 만든다.

완료 조건:

- MUST 실제 재현 또는 Instruments/SwiftUI update 측정으로 문제를 확인한 뒤 변경한다.
- MUST 표시 owner를 Root 또는 feature 중 하나로 명확히 하고, 중복 표시·빠른 연속 요청·dismiss 뒤 늦은 Task를 검증한다.
- MUST `Task` 취소와 최신 메시지 정책을 유지하며 iOS 16.1에서 동작하게 한다.
- SHOULD `ToastStruct.state`를 실제 시각·접근성 표현에 사용할지, 제거할지 결정한다.

## P1 — Design System·구조

### Core Components의 DesignSystem 분리

상태: 미해결 · 우선순위: P1

`Core/Components`는 공통 UI와 design token이 함께 있어 이름과 책임이 섞여 있다. `RodiDesignSystem.swift`의 color·typography·font 성격 API도 분리 대상이다.

목표 구조:

```text
Core/
  DesignSystem/
    RodiColor.swift
    RodiTypography.swift
    RodiFont.swift
  Components/
    # 실제 공통 UI Component만 유지
```

완료 조건:

- MUST token·font 등록·공통 UI의 사용처를 먼저 분류한다.
- MUST color·typography·font의 public API와 기존 화면 표현을 유지한다.
- MUST Core 보호 영역인 `Architecture/MVICore`, `Coordinator`, `Network`은 수정하지 않는다.
- SHOULD DesignSystem과 Component 이동을 별도 커밋으로 분리한다.

### TODO 주석 정리

상태: 완료

2026-08-20 기준 Swift source에서 TODO/FIXME/HACK/XXX 주석을 찾지 못했다. 모호한 주석은 Presentation 리팩터링 백로그 또는 QA 이슈 로그로 이관했다.

완료 조건:

- MUST 모호한 TODO를 재현 조건·owner·완료 조건이 있는 이슈로 바꾸거나 해결한다.
- MUST NOT 코드 위치만 표시한 TODO를 장기 backlog의 유일한 근거로 남긴다.

### 500줄 초과 파일 분리 검토

상태: 미해결 · 우선순위: P1

2026-08-20 기준 500줄 초과 Swift 파일:

| 줄 수 | 파일 | 우선 분리 후보 |
| ---: | --- | --- |
| 906 | `Presentation/Home/HomeReducer.swift` | Map·Search·BottomSheet child reducer의 최종 delegate 중재만 root에 남기는지 재검토 |
| 766 | `Presentation/Home/HomeView.swift` | root composition, map controls, sheet·dialog presentation, full-screen route 분리 |
| 533 | `Presentation/Home/Search/HomeSearchReducer.swift` | 입력 debounce, region/place 결과, recent search effect owner 분리 |
| 532 | `Presentation/Home/BottomSheet/HomeBottomSheetView.swift` | drag/settle gesture adapter, route별 sheet rendering, dialog overlay 책임 분리 |
| 532 | `Presentation/CourseRegistration/SubPage/MapSelection/CourseRegistrationMapSelectionReducer.swift` | 지도 candidate·주소 조회·route effect ownership을 재검토 |
| 519 | `Presentation/Home/BottomSheet/HomeBottomSheetReducer.swift` | route·상세 child teardown과 delegate 중재를 재검토 |

완료 조건:

- MUST 줄 수만을 이유로 파일을 나누지 않고 State·Action·Effect·UI 책임을 기준으로 분리한다.
- MUST child 간 전달은 typed Delegate로 하고 sibling State를 직접 읽지 않는다.
- MUST 구조 이동과 사용자 동작 변경을 같은 커밋에 섞지 않는다.

## P2 — 레이아웃 측정 제거 또는 제한

### GeometryReader 사용처 검토

상태: 미해결 · 우선순위: P2

2026-08-19 기준 사용처는 3개다.

| 위치 | 현재 목적 | 우선 검토 대안 |
| --- | --- | --- |
| `Presentation/My/SubPage/MyPosts/MyPostsView.swift:359` | more menu anchor frame·overlay 위치 | anchor preference·overlay alignment를 유지하되 geometry scope 최소화, 가능하면 menu 전용 Component로 격리 |
| `Presentation/CourseRegistration/SubPage/Tutorial/CourseRegistrationTutorialView.swift:103` | tutorial image 크기 계산 | flexible frame, aspect ratio, `ViewThatFits` 또는 iOS 16 `Layout` |
| `Presentation/Home/BottomSheet/CourseDetail/SubPage/CourseDetailExpandedPage.swift:311` | review dropdown anchor frame·overlay 위치 | dropdown Component의 anchor/overlay 책임으로 격리하고 화면 전체 측정을 피함 |

완료 조건:

- MUST GeometryReader를 제거하기 전에 현재 UI·safe area·SE/Max 화면·dropdown hit testing을 비교한다.
- MUST 새 GeometryReader, `UIScreen.main`, 기기 전체 고정 frame을 추가하지 않는다.
- SHOULD 제거할 수 없는 anchor positioning은 가장 작은 Component 범위에 제한하고 이유를 코드에 기록한다.

## QA 결함 기록 방식

QA 중 발견한 “어떤 화면에서, 어떤 행동 후, 무엇이 잘못됐다”는 관찰은 이 장기 개선 문서에 바로 섞지 않는다. [QA 이슈 로그](QA_ISSUES.md)에 다음 형식으로 기록한다.

```md
## QA-YYYYMMDD-번호 — 짧은 제목

- 상태: Open / Investigating / Fixed / Verified
- 환경: branch, build, device, iOS, 로그인·권한·네트워크 상태
- 재현: 1. … 2. … 3. …
- 기대 결과:
- 실제 결과:
- 증거: screenshot, 안전하게 정리한 로그, API endpoint
- 원인 가설 / 확정 원인:
- 수정 PR·커밋:
- 검증:
```

그 QA 이슈가 반복되거나 공통 구조 개선을 요구할 때만 이 문서의 P0~P2 항목에 링크한다. 이 분리는 즉시 고쳐야 할 결함과 장기 리팩터링을 서로 묻히지 않게 한다.

## 실기기 검증 대기

- [ ] 이동 중 위치 버튼을 여러 번 탭해 새 위치로 카메라가 갱신되는지 확인한다.
- [ ] 지하철·터널 등에서 위치를 20초 안에 받지 못할 때 위치 확인 불가 snackbar가 노출되는지 확인한다.
- [ ] 출발지 확정 후 도착지 선택 단계에서 시작 핀을 탭해 `핀 수정하기`로 진입하고, 완료 뒤 도착지 선택 상태가 유지되는지 확인한다.

## 실기기 확인 후 해결 대기

- [ ] Dev > 외부 길안내 복귀 — `GPS 측정 코스 → 외부 앱 10초 이상 이탈 → 복귀 → 측정 종료`에서 `register → recordVisit`와 후기 권유 팝업이 실제 기기에서 실행되지 않는다. 다음 작업에서는 `PracticeReturnReducer.activeMeasurementEnded` action 도달 여부, 저장된 측정의 모드·장소 유형·외부 이탈 시각, Debug 조건, POST 결과를 비식별 로그로 확인한 뒤 원인을 확정한다.
