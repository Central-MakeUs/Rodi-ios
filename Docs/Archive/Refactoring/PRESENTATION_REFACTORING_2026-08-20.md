# Presentation 리팩터링 백로그

> Archive: 2026-08-19~20에 완료한 감사·리팩터링 기록이다. 현재 후보는 [TODO](../../TODO.md)에서 관리한다.

## 목적

이 문서는 `Presentation`의 실제 코드 감사를 바탕으로, 사용자 기능·문구·Figma UI·API 계약을 바꾸지 않는 구조 리팩터링 범위를 관리했다. 현재 장기 규칙의 원본은 [ARCHITECTURE.md](../../Architecture/ARCHITECTURE.md)다.

## 운영 규칙

- MUST 실제 리팩터링 전 대상 항목의 근거·영향·검증을 확인한다.
- MUST 구조 리팩터링과 기능 변경을 같은 커밋에 섞지 않는다.
- MUST 완료한 항목을 활성 우선순위 표에서 제거하고 이 문서 하단 완료 표로 이동한다.
- MUST `Core/Architecture/MVICore`, `Core/Coordinator`, `Core/Network`, `Data/Local` 수정이 필요한 경우 별도 사용자 승인을 받는다.
- SHOULD 파일 줄 수만으로 분리하지 않고 독립 State·Action·Effect 또는 독립 UI 계약을 먼저 확인한다.

## 우선순위 기준

| 우선순위 | 판정 기준 |
| --- | --- |
| P0 | Presentation 경계 위반, 직접 I/O·SDK 호출, lifecycle·cancellation 누락, 중복 요청·stale response 위험 |
| P1 | root 과밀, child ownership 불명확, sibling 결합, 반복된 조립·route payload, 책임이 섞인 Service·Adapter |
| P2 | 실제 분리 가능한 장문 파일, TODO/FIXME, naming, Geometry·화면 크기 의존성 검토 |

## 활성 항목

## 감사 범위·판정

- 감사 범위는 `Presentation/Debug`를 제외한 `Home`, `CourseRegistration`, `Login`, `MainTab`, `My`, `Onboarding`, `DrivePractice`, `Review` 전체다.
- 2026-08-20 기준 Swift 파일은 33,201줄이다. 장문 파일은 단독 분리 사유가 아니며, State·Action·Effect 또는 독립 UI 계약이 확인된 경우에만 활성 항목으로 둔다.
- `현 구조 유지` 항목은 이번 감사에서 명확한 Presentation 규칙 위반을 찾지 못한 영역이다. 이후 기능 변경이나 재현 가능한 문제 발생 시 다시 판정한다.
- `보류` 항목은 `Data/Local` 변경 승인이 필요한 저장소 이전, 또는 UI QA·측정 결과가 필요한 레이아웃 변경이다.

| Feature | 감사 결론 | 관련 완료 항목 |
| --- | --- | --- |
| Home | root의 외부 입력과 길안내 overlay, BottomSheet route 콘텐츠 조립을 분리했다. Map Adapter와 위치·marker rendering은 유지한다. | P2-1 ~ P2-4, P1-12, P1-13, P2-11 |
| CourseRegistration | root/child 흐름은 유지하고, 외부 Kakao adapter 중복과 최근 검색 저장 경계를 정리했다. | P2-5, P2-7 |
| My | root 조립, 내 활동 목록 child ownership, 설정 파일 분리, 레벨업 저장 경계를 정리했다. | P2-8, P2-10 |
| Onboarding | route/session host와 법적 문서 화면의 navigation ownership 및 화면 크기 의존을 감사 완료했다. | P2-9 |
| Login | SDK bridge의 timeout·continuation lifecycle과 화면 폭 계산을 정리했다. | P2-6, P2-9 |
| MainTab | 상위 Feature callback·refresh intent 전달을 축소했다. | 완료 항목 |
| DrivePractice | 위치 runtime·인증 재시도·Live Activity lifetime과 session 저장 경계를 검토한다. | P1-10, P2-10 |
| Review | Flow refresh의 결과 소비 정책을 검토한다. Prompt·Writing·SkipReason child 구조는 유지한다. | P1-11 |

### P0 — 기능 안정성

| ID | 상태 | 대상 | 관찰 근거 | 목표 ownership | 검증 시나리오 |
| --- | --- | --- | --- | --- | --- |
| P0-1 | 완료 | `Home/Map/Service/MapService.swift` | typed `NetworkError` 경로에서 `CancellationError` 캐스팅을 시도해 항상 실패한다는 Swift 경고가 발생했다. | Effect 취소 상태는 호출 Task가 소유하므로 `catch`에서 `Task.isCancelled`를 확인해 취소를 오류 UI로 전환하지 않는다. | 지도 좌표 조회 중 화면 이탈·새 요청, 취소 뒤 오류 UI 미표시 |
| P0-2 | 완료 | `HomeBottomSheetReducer`, `ReviewReducer`, `CourseRegistrationReducer` | 상위 흐름이 child State를 직접 초기화하거나 비활성화해, 길안내·후기·코스 등록 요청이 화면 종료 뒤 남을 수 있었다. | 상위 reducer가 child reset/deactivate Action을 먼저 전달하고, child가 자기 Effect ID를 취소한다. | 상세 전환·검색 선택 해제, 후기 종료·재진입, 코스 등록 화면 이탈 |

### P1 — 책임·조립 구조

| ID | 상태 | 대상 | 관찰 근거 | 목표 ownership | 검증 시나리오 |
| --- | --- | --- | --- | --- |
| P1-10 | 완료 | `DrivePractice/Service/DrivePracticeService.swift`, `DrivePracticeCertificationService.swift`, `DrivePractice/Adapter/DrivePracticeLocationAdapter.swift` | session 정책, 인증 재시도 Task, Core Location·background lifecycle이 한 service에 섞여 있었다. | 인증 재시도 Task·request ID는 Certification Service가, Core Location delegate·background session은 Location Adapter가 소유하도록 분리했다. | 앱 복귀, 측정 취소·완료, 인증 재시도, Live Activity start/sync/end, 늦은 응답 |
| P1-11 | 완료 | `Review/Flow/ReviewFlowRefreshService.swift`, `ReviewFlowCoordinatorReducer.swift` | refresh service가 조회 결과를 버리며, coordinator가 완료 refresh ID와 화면별 갱신 request ID를 중재한다. | 결과를 소비하지 않는 prefetch를 제거하고 기존 완료 request ID 갱신으로 최신화를 요청한다. | 홈·마이·내 게시글·코스 상세의 후기 완료/취소 후 최신화 |

### P2 — 레이아웃·유지보수

| ID | 상태 | 대상 | 관찰 근거 | 목표 ownership | 검증 시나리오 |
| --- | --- | --- | --- | --- |
| P2-1 | 완료 | `MyPostsView.swift` | dropdown anchor 위치를 `GeometryReader`로 계산한다. | iOS 16.1에서 anchor preference의 전역 overlay 좌표를 읽기 위한 측정 책임이 있으므로 유지한다. | 긴 닉네임, 메뉴 문구, 스크롤, 빈 영역 tap |
| P2-2 | 완료 | `CourseDetailExpandedPage.swift` | dropdown anchor와 상세·전체보기·신고 page 조립이 함께 있다. | overlay 최상단 표시를 보존하는 anchor preference 측정은 유지하고, page 조립은 별도 P1 CourseReview 항목에서 다룬다. | 후기 menu·level dropdown, safe area, compact/large 기기 |
| P2-3 | 완료 | `CourseRegistrationTutorialView.swift` | tutorial reference image 폭을 컨테이너 폭의 72%로 유지한다. | iOS 16.1에서 화면 전역값 없이 컨테이너 비율을 계산하는 유일한 측정 책임이므로 유지한다. | Dynamic Type, compact/large layout |
| P2-4 | 완료 | `Home/HomeView.swift`, `BottomSheetPanGestureView.swift` | 구현 위치에 남아 있던 모호한 TODO가 실제 owner·완료 조건을 설명하지 않았다. | TODO를 제거하고 snackbar·drag의 후속 책임은 각각 P1-1·P1-2 및 수동 QA 항목으로 추적한다. | snackbar 연속 표시, drag·dismiss, 화면 이탈 |
| P2-7 | 완료 | `CourseRegistrationRecentSearchStore.swift`, `HomePracticeFilterStore.swift`, `RouteGuidanceService.swift` | 최근 검색어·필터·선호 길안내 앱 선택을 Presentation에서 UserDefaults로 저장한다. | 저장 key·payload를 유지한 채 `Data/Local/Support/UserDefaultsStores` 표현으로 이동했다. | 앱 재시작, 기존 값 복원, 검색 순서, 필터·길안내 앱 유지 |
| P2-8 | 완료 | `MySettingsViews.swift` | 설정, 계정 관리, 문의, 약관, 라이선스, 권한 화면이 하나의 파일에 있다. | account, information, permission SubPage 파일로 분리하고 route·문구를 유지했다. | 모든 설정 route의 back·logout·탈퇴·문서 표시 |
| P2-10 | 완료 | `LevelUpPresentationStore.swift`, `DrivePracticeSessionStore.swift` | 계정별 레벨업 상태와 연습 세션을 Presentation에서 UserDefaults로 저장한다. | 저장 key·Codable payload를 유지한 채 `Data/Local` persistence 표현을 사용하도록 정리했다. | 계정 전환, 앱 재시작, 측정 복구, 기존 저장값 호환 |

## 실행 순서

1. `Presentation/Debug` 내부 항목은 이 문서 범위에 넣지 않는다.
2. 이후 기능 변경으로 독립 State·Effect 책임 또는 실기기 결함이 재현될 때만 새 활성 항목을 추가한다.

## 현 구조 유지

| 대상 | 유지 근거 | 재감사 조건 |
| --- | --- | --- |
| `Home/Map/Adapter` | Kakao map delegate와 SwiftUI bridge가 Adapter에 분리돼 있다. | 지도 SDK lifecycle 또는 marker rendering 회귀 |
| `Home/Map/Service/MapLocationService.swift` | request ID, timeout task, stream 종료 처리가 있어 정적 감사만으로 lifecycle 위반을 확정할 수 없다. | 위치 권한·복귀·취소 뒤 stale callback 재현 |
| `Home/Map/Service/MapMarkerRenderingService.swift` | rendering task가 stream termination과 함께 취소된다. | marker 갱신 성능 측정 또는 메모리 문제 |
| `CourseRegistrationMapSelectionReducer`, `CourseRegistrationDetailsReducer` | 각각 지도 선택·등록 form이라는 응집된 State·Effect 책임이 있다. | 서로 독립된 flow가 추가되거나 stale response 재현 |
| `Review/Prompt`, `Review/Writing`, `Review/SkipReason` | named child reducer와 typed Delegate로 이미 분리돼 있다. | sibling state 직접 접근 또는 완료 흐름 회귀 |
| `DrivePractice` | 후기 권유·방문 기록 흐름을 root reducer가 직접 소유한다. | Review와 직접 state 결합이 다시 생길 때 |
| My의 독립 destination Store | 각 화면은 Navigation destination root이므로 자체 Store 생성만으로 위반이 아니다. | 부모 state를 직접 공유하거나 refresh가 누락될 때 |

## 완료 항목

| 완료일 | 대상 | 정리 결과 | 검증 |
| --- | --- | --- | --- |
| 2026-08-20 | Home Map child ownership | `HomeMapReducer`가 지도 카메라·권한·위치 갱신·마커·Kakao 결과와 request revision·Effect ID를 소유하게 하고, Home root는 Map/Search/BottomSheet의 typed Delegate 중재만 남겼다. | Dev Debug build, RodiTests 8건 통과, 수동 지도 lifecycle QA 대기 |
| 2026-08-20 | 장소 길안내 child ownership | 코스·주차장 상세가 공통 `RouteGuidanceReducer`만 통해 앱 선택·설치·외부 앱 실행·취소·stale result를 처리하게 하고, 부모의 미사용 request proxy를 제거했다. | Dev Debug build, RodiTests 8건 통과, 수동 외부 앱 전환 QA 대기 |
| 2026-08-20 | Login·Onboarding 화면 크기 의존 | `LoginView` tooltip은 parent 폭 안의 최대 폭 제약으로, 분석 dialog는 content intrinsic height로 전환해 직접 `UIScreen.main` 의존을 제거했다. | Dev Debug build, RodiTests 8건 통과, SE·대형 기기 시각 QA 대기 |
| 2026-08-20 | 장문 파일 재감사 | Home root는 219줄로 축소했고, 남은 HomeMap·HomeView·BottomSheet·Search·MapSelection·DrivePractice 장문 파일은 각각 단일 State/Effect 또는 화면 조립 책임임을 확인했다. | 정적 책임 감사, 기능 변경 시 재감사 |
| 2026-08-20 | Home 상위 delegate | 인증·후기 작성·수정 closure를 `HomeReducer.Delegate`로 통합하고 MainTab이 기존 로그인·Review flow로 중계하게 했다. | Dev Debug build, Release build, 수동 QA 대기 |
| 2026-08-20 | Home Debug 계약 | Debug 후기 요청을 `#if DEBUG` Home action·delegate로 한정해 Release `HomePresentation`에서 제거했다. | Dev Debug build, Release build, 수동 QA 대기 |
| 2026-08-20 | My 권한·조립 | 권한 시스템 접근을 Adapter/Reducer로 이동하고 destination 의존성·social session 조립을 feature dependency로 축소했다. | Dev Debug build, 수동 QA 대기 |
| 2026-08-20 | 코스 등록 진입 | MainTab/My가 `CourseRegistrationPresentation`·feature dependency로 같은 등록 entry contract를 사용하게 했다. | Dev Debug build, Release build, 수동 QA 대기 |
| 2026-08-19 | `Home/BottomSheet/CourseDetail`, `ParkingDetail` 길안내 | View의 `RouteGuidanceService.shared`·View 내부 `Task`를 제거하고, BottomSheet reducer와 `RouteGuidanceFlowService`가 dialog·측정 준비·외부 앱 실행·stale result를 소유하게 했다. | Dev Debug build, 정적 검색, 수동 QA 대기 |
| 2026-08-19 | `My` 로그아웃 SDK 호출 | `MyReducer`의 Kakao SDK 직접 callback을 `Login/Service/SocialSessionService` contract로 이동했다. | Dev Debug build, 수동 로그아웃 QA 대기 |
| 2026-08-19 | Login SDK bridge | Apple authorization continuation과 Kakao callback·timeout을 `Login/Adapter`로 이동하고, `SocialLoginService`는 provider fallback·credential orchestration만 소유하도록 축소했다. | Dev Debug build, 수동 Kakao/Apple 취소·fallback QA 대기 |
| 2026-08-19 | MainTab presentation 계약 | Root→MainTab의 로그인·후기·refresh·튜토리얼 입력을 `MainTabPresentation` 하나로 묶어 다수 callback·request ID 전달을 축소했다. | Dev Debug build, 수동 탭·후기 refresh QA 대기 |
| 2026-08-19 | Kakao REST transport | 코스 등록 지도·장소 검색·코스 길찾기의 공통 인증 header·URLSession·HTTP 응답 처리를 `KakaoRESTClient`로 통일하고, 각 Feature service는 endpoint·DTO mapping만 유지했다. | Dev Debug build, 수동 Kakao API 오류·취소 QA 대기 |
| 2026-08-19 | Home BottomSheet chrome | 공통 rounded sheet chrome과 UIKit pan bridge를 포함한 drag handle을 `Home/BottomSheet/Component`로 분리해 화면 조립 중복을 줄였다. | Dev Debug build, 수동 drag·safe area QA 대기 |
| 2026-08-19 | `DrivePractice` 인증 재시도 | 인증 API Task를 service가 소유하고 취소·request ID 최신성 검증을 추가했다. | Dev Debug build, 수동 인증 재시도 QA 대기 |
| 2026-08-19 | Home 지도 좌표 취소 | typed error의 무효한 cancellation cast를 제거하고, 취소 Task가 좌표 조회 실패 UI를 만들지 않게 했다. | Dev Debug build, 수동 지도 이탈 QA 대기 |
| 2026-08-19 | Onboarding 법적 설정 화면 | Coordinator를 소유하던 설정 화면을 Component에서 `SubPage/LegalSettings`로 이동했다. | Dev Debug build, 수동 문서·문의 이동 QA 대기 |
| 2026-08-19 | MainTab 의존성 | `MainTabFeatureDependencies`로 AppDependencies 전체의 Presentation 전파를 제거했다. | Dev Debug build, 수동 탭·등록 진입 QA 대기 |
| 2026-08-19 | GeometryReader 재판정 | My Posts·코스 후기 dropdown의 anchor 좌표와 코스 등록 튜토리얼의 컨테이너 비율 계산은 iOS 16.1에서 실제 측정 책임이 있어 유지했다. | 정적 검토, UI 수동 QA 대기 |
| 2026-08-19 | Home TODO 정리 | 모호한 TODO를 제거하고 해당 owner·검증 조건을 활성 백로그로 단일화했다. | Dev Debug build, 수동 snackbar·drag QA 대기 |
| 2026-08-19 | 후기 완료 prefetch | 반환값을 소비하지 않던 `ReviewFlowRefreshService`를 제거하고 기존 완료 request ID 갱신 흐름을 유지했다. | Dev Debug build, 수동 후기 완료 갱신 QA 대기 |
| 2026-08-19 | My 설정 화면 | 단일 settings 파일을 account, information, permission SubPage 파일로 분리했다. | Dev Debug build, 수동 설정 route QA 대기 |
| 2026-08-19 | Home Search state | 최근 검색과 검색 결과의 loading·cursor·request ID를 `HomeSearchState.recent`/`.results`로 분리해, debounce·최근 검색·페이지네이션 최신성 owner를 명시했다. | Dev Debug build, 수동 검색·최근 검색·연속 입력 QA 대기 |
| 2026-08-19 | CourseDetail Review menu ownership | 레벨·카드 dropdown overlay와 메뉴 행동 해석을 `CourseReview` Component로 이동하고, Review Component가 상위 CourseDetail reducer의 page/summary alias를 참조하지 않게 했다. | Dev Debug build, 수동 레벨 선택·카드 메뉴·신고·차단·삭제 QA 대기 |
| 2026-08-19 | Home BottomSheet layout policy | drag 중 높이 clamp, opacity, 추천/코스 settle 목적지를 상태 없는 `HomeBottomSheetLayout` Model로 분리했다. View-local pan·animation task와 reducer presentation은 유지했다. | Dev Debug build, 수동 drag·settle·safe area QA 대기 |
| 2026-08-19 | Onboarding 복원 path 정책 | guest/member별 onboarding route stack 복원 정책을 `OnboardingNavigationPath` Model로 이동해 Router View의 제품 route 해석을 축소했다. | Dev Debug build, 수동 신규 설치·자동 로그인·재진입 QA 대기 |
| 2026-08-19 | My Posts child ownership | 후기·코스 목록의 pagination·삭제·request revision을 각각 `MyReviewPostsReducer`, `MyCoursePostsReducer`로 분리하고, 부모는 탭·수정 진입·Snackbar·최종 갱신 delegate만 중재하게 했다. | Dev Debug build, 수동 탭·필터·cursor·삭제·수정 QA 대기 |
| 2026-08-19 | Home presentation·길안내 overlay | MainTab→Home의 외부 입력을 `HomePresentation`으로 묶고, 길안내 dialog 조립을 `HomeRouteGuidanceOverlay`로 이동했다. | Dev Debug build, 수동 길안내·설정 복귀·후기 overlay QA 대기 |
| 2026-08-19 | Home/Review/CourseRegistration child teardown | 상세 전환과 흐름 종료가 child reset/deactivate Action을 거치게 하고, 도로 경로·길안내·후기 작성/미방문 사유·코스 등록 작업의 취소 owner를 child reducer에 유지했다. | Dev Debug build, 수동 이탈·재진입 QA 대기 |
| 2026-08-19 | Home presentation host | 검색·코스 확장·코스 후기 full-screen cover 조립을 `HomePresentationHost`로 이동해 Home root가 지도·BottomSheet·lifecycle 조립에 집중하게 했다. | Dev Debug build, 수동 검색·확장·후기 overlay QA 대기 |
| 2026-08-19 | Home BottomSheet route 콘텐츠 | 추천·필터·코스·주차장 route별 콘텐츠 렌더링을 `HomeBottomSheetRouteContent`로 분리하고, root에는 drag·settle·높이 계산만 남겼다. | Dev Debug build, 수동 drag·settle·safe area QA 대기 |
| 2026-08-19 | My root·Onboarding ownership 재감사 | 독립 Navigation destination Store와 onboarding route host는 현재 책임 경계에 맞으며, 추가 child layer는 회귀 위험만 높인다고 판정했다. | 정적 감사, 수동 My·Onboarding 회귀 QA 대기 |
| 이전 완료 | `Home` 경로 이동 | `Map`, `Search`, `BottomSheet`의 직접 기능 경로로 정리하고 filesystem-synchronized group의 참조를 확인했다. | Dev Debug build, `git diff --check` |
| 이전 완료 | `CourseRegistration` root·하위 흐름 | root route 조립, 지도 선택·핀 편집 SubPage, 검색 State ownership, snackbar·비동기 최신성 방어를 정리했다. | Dev Debug build, 수동 QA 대기 |
| 이전 완료 | `Review`, `DrivePractice` root 구조 | root View·Reducer와 child flow, Adapter·Service·Live Activity target 경계를 정리했다. | Dev Debug build, 수동 QA 대기 |
| 이전 완료 | Live Activity target 경계 | Widget UI·공유 ActivityAttributes·app-only runtime service를 `RodiPracticeLiveActivity/` target 경계로 이동했다. | Dev Debug build, `git diff --check` |

## 공통 검증

- MUST 코드 구조 변경 뒤 `Rodi Dev` Debug build와 `git diff --check`를 실행한다.
- MUST 각 항목의 표에 적힌 수동 시나리오를 해당 변경 단위에서 확인한다.
- MUST 테스트 target 변경 뒤에는 실제 실행한 `xcodebuild test` 명령과 결과를 기록한다.
- SHOULD 구조 이동 전후 `rg`로 이전 경로·심볼 참조가 남지 않았는지 확인한다.
