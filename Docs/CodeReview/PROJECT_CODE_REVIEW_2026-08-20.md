# 전체 프로젝트 코드리뷰 결과

## 목적과 범위

이 문서는 2026년 8월 20일 기준 정적 코드리뷰와 후속 리팩터링 검증 결과다.

- 대상: `Rodi/App`, `Rodi/Core`, `Rodi/Data`, `Rodi/Domain`, `Rodi/Presentation`, `Rodi/Resources`, `RodiPracticeLiveActivity`, `RodiTests`, Xcode 프로젝트 설정
- 확인 방법: 레이어 의존성 검색, 대형 파일·금지 패턴 검색, 저장소·비동기 구현 대조, `Rodi Dev` 빌드와 테스트 타깃 컴파일
- 제외: 실제 서버 응답, GPS·백그라운드 위치, Kakao 앱 전환, Live Activity의 실기기 수명주기, VoiceOver·동적 글자 크기 수동 검증

## 결론

앱 타깃과 `RodiTests`는 iOS 16.1 simulator 대상으로 빌드·실행된다. Domain의 SDK/DTO 누수와 Presentation의 `NetworkManager` 직접 호출도 확인하지 못했다. 연습 측정 복구 모델·저장 구현은 각각 Domain·Data/Local로 분리했고, 기존 payload의 schema migration과 로그아웃·탈퇴 정리 경로를 보완했다.

| 등급 | 건수 | 의미 |
| --- | ---: | --- |
| P0 | 1 | 측정 세션 복구 데이터가 조용히 유실될 수 있는 저장 경계 |
| P1 | 4 | 테스트 신뢰성 또는 Core 책임 경계 |
| P2 | 4 | 안전한 정리·문서 정합성·측정 후 최적화 |

## 검증 결과

| 항목 | 결과 | 근거 |
| --- | --- | --- |
| 앱 빌드 | 통과 | `xcodebuild -project Rodi.xcodeproj -scheme "Rodi Dev" -destination "generic/platform=iOS Simulator" build` |
| 테스트 타깃 | 통과 | iPhone 15 simulator에서 `xcodebuild ... -scheme "Rodi Dev" ... test` 10건 통과 |
| Domain 경계 | 확인 | `Rodi/Domain`에서 SwiftUI, UIKit, Alamofire, Kakao, Firebase, ActivityKit import를 찾지 못함 |
| Presentation 네트워크 경계 | 확인 | `Rodi/Presentation`에서 `NetworkManager`, RemoteDataSource, RepositoryImpl 직접 참조를 찾지 못함. Kakao Local 전용 private DTO는 feature Service 내부에 한정됨 |
| 위험 패턴 | 확인 | `try!`, `as!`, `Task.detached`, `@unchecked Sendable`을 찾지 못함. `fatalError` 3건은 UIKit `init(coder:)` 필수 stub임 |
| 비밀정보 제외 | 확인 | `.gitignore`에 local xcconfig, Firebase plist, `.p8`가 제외돼 있음. 좌표 logger는 `(coordinate hidden)`만 반환함 |

## 조치 권장 항목

### P0-CR-1 — 연습 측정 복구 저장소의 데이터 보존 경계

상태: 완료 — `PracticeMeasurement` 계약은 `Domain/Practice`, UserDefaults schema·migration 구현은 `Data/Local/Practice`로 이동했다.

- 대상: `Rodi/Domain/Practice/PracticeMeasurement.swift`, `Rodi/Data/Local/Practice/PracticeMeasurementStore.swift`, `Rodi/Presentation/PracticeTracking/Service/PracticeTrackingService.swift`
- 근거: `PracticeMeasurement`는 코스·주차장·GPS 인증·방문 기록 상태라는 제품 모델이고, 동일 파일이 `UserDefaults` key, JSON encode/decode, legacy key 제거까지 소유한다. `load()`과 `save()`가 `try?`로 실패를 숨기므로 앱 업데이트·손상 payload·schema 변경 때 활성 측정이 조용히 사라질 수 있다.
- 영향: 외부 길안내/앱 재시작 뒤 인증 재시도와 Live Activity 완료 전환에 필요한 상태를 복구하지 못할 수 있다. 현재 문제는 `Codable` 저장 자체가 아니라, schema·migration·decode 실패·보존 기간 정책이 불명확한 점이다.
- 권장 조치: 먼저 저장 계약 표(소유 Feature, 민감도, retention, schema version, migration, decode 실패 처리)를 확정한다. 이후 사용자 승인을 받은 Data/Local 작업에서 persistence 표현만 `Data/Local`로 이동하고, `PracticeTracking`은 session 정책만 유지한다. 기존 key와 payload 호환 검증이 완료되기 전에는 삭제·형식 변경을 하지 않는다.
- 검증: 기존 저장값으로 업데이트 설치, decode 실패 payload, 인증 대기 상태 앱 종료·재실행, 계정 전환을 각각 확인한다.

### P1-CR-1 — 테스트 타깃이 현재 계약과 불일치

상태: 완료 — Repository·Service stub과 주의사항 선택 입력 정책을 현재 contract에 맞췄다.

- 대상: `RodiTests/CourseReviewReducerTests.swift`, `RodiTests/ReviewReducerTests.swift`
- 근거: 실제 테스트 명령이 실패했다. `ReviewRepositoryStub`에는 `fetchDetail`, `update`가 없고, `MemberRepositoryStub`에는 `hardWithdraw`, `completeCourseTutorial`이 없다. `WritingServiceStub`도 `fetchReviewDetail`, `createReview`, `updateReview`을 구현하지 않는다. 또한 `testWritingRequiresAllFirstPageSelectionsAndCaution`은 현재 주의사항을 선택 사항으로 바꾼 작성 정책과 반대다.
- 영향: reducer 리팩터링 뒤 회귀를 잡을 최소 자동 검증이 동작하지 않는다. 앱 빌드 통과는 테스트 타깃의 신뢰성을 대체하지 못한다.
- 권장 조치: protocol stub을 현재 요구사항에 맞춘 뒤, 주의사항 없는 후기의 다음 단계 전환을 기대하는 테스트로 바꾼다. 새 테스트 프레임워크·fixture 계층은 추가하지 않는다.
- 검증: `Rodi Dev` scheme의 `xcodebuild test`가 컴파일과 두 reducer 시나리오를 모두 통과해야 한다.

### P1-CR-2 — Core 프로필 이미지가 회원·후기 제품 타입을 직접 안다

상태: 완료 — `RodiLevelProfileImage`와 nested `Config`를 `Presentation/Shared/Component`로 이동했다.

- 대상: `Rodi/Presentation/Shared/Component/RodiLevelProfileImage.swift`
- 근거: Core Component가 `MemberProfile.Level`, `MemberOnboardingSubmission.DrivingLevel`, `ReviewLevel` 각각을 받고 rabbit asset 이름을 직접 매핑한다.
- 영향: Core의 재사용 UI가 회원·온보딩·후기 Domain 변화에 동시에 수정돼야 한다. 이는 Core가 제품 Feature 타입을 직접 알지 않아야 한다는 레이어 규칙과 맞지 않는다.
- 권장 조치: asset name 또는 Presentation 전용 표시 모델을 입력으로 받는 순수 이미지 Component만 유지하고, 세 level → asset mapping은 `Presentation/Shared` 또는 가장 가까운 Feature에서 관리한다. 실제 두 Feature 이상에서 재사용되는 UI 자체는 유지한다.
- 검증: My, Onboarding, Course Review의 rabbit 이미지·크기·접근성 표현이 변하지 않는지 확인한다.

### P1-CR-3 — 제품 행동 Analytics catalog가 Core에 위치

상태: 완료 — 제품 event catalog는 `Presentation/Shared/Analytics`로 이동했고 Firebase 전송 adapter는 Core에 유지했다.

- 대상: `Rodi/Presentation/Shared/Analytics/RodiAnalytics.swift`, `Rodi/Core/Analytics/FirebaseAnalyticsTracker.swift`
- 근거: 하나의 `Event` enum이 로그인, 온보딩, 지도 검색, 코스 등록, 후기, 연습 추적, 마이페이지의 제품 행동과 parameter bucket을 모두 소유한다.
- 영향: Firebase 전송 adapter와 제품 이벤트 catalog가 결합돼 이벤트 변경이 Core 변경이 된다.
- 권장 조치: Firebase Analytics/Crashlytics 전송 adapter는 Core에 유지하고, event name·parameter catalog와 user context는 `Presentation/Shared/Analytics`로 이동한다. event name 및 parameter key는 바꾸지 않는다.
- 검증: 기존 event name·parameter key의 before/after diff와 Firebase DebugView 또는 안전한 개발 로그를 비교한다. 원문 검색어·좌표·토큰을 이벤트에 추가하지 않는다.

### P1-CR-4 — LegalDocument와 KakaoConfiguration의 책임 위치

상태: 완료 — 약관 표시 모델은 `Presentation/Shared/Model`, Bundle 기반 Kakao 설정은 `App/Configuration`으로 이동했다.

- 대상: `Rodi/Presentation/Shared/Model/LegalDocument.swift`, `Rodi/App/Configuration/KakaoConfiguration.swift`
- 근거: 전자는 RODI의 약관 제목·공개 URL을, 후자는 앱 bundle의 Kakao key 설정을 직접 소유한다. 둘 다 제품 UI 또는 앱 조립 설정이며 Core 기술 기반이 아니다.
- 영향: Core 변경 없이 약관·SDK 설정을 교체하기 어렵고, 레이어 책임 설명과 실제 코드가 어긋난다.
- 권장 조치: 약관 표시 모델은 `Presentation/Shared/Model`로, bundle 기반 SDK 설정은 `App/Configuration`으로 옮긴다. URL·설정 key·실행 결과는 변경하지 않는다.
- 검증: Onboarding·My 약관 화면, Kakao 로그인·지도·길안내의 Dev/Prod 설정을 각각 확인한다.

### P2-CR-1 — 사용되지 않는 launch loading View

상태: 완료 — inline launch UI를 유지하고 미사용 `RootLaunchLoadingView`를 삭제했다.

- 대상: `Rodi/App/RootView.swift`
- 근거: `rootContent`의 `.launching` case가 loading UI를 inline으로 렌더링하며, 같은 구현의 `RootLaunchLoadingView`는 선언 외 사용처가 없다.
- 권장 조치: inline 구현을 유지하고 private unused View 한 개만 삭제한다.
- 검증: launch route에서 세션 확인 화면이 기존과 동일한지 확인한다.

### P2-CR-2 — LicenseList Swift Package reference 중복

상태: 완료 — 사용 중인 package product는 유지하고 중복 reference만 제거했다.

- 대상: `Rodi.xcodeproj/project.pbxproj`
- 근거: Rodi target의 `packageProductDependencies`와 project `packageReferences`에 같은 `LicenseList` identifier가 각각 두 번 등록돼 있다. 실제 import 사용처는 `MySettingsInformationViews.swift` 한 곳이다.
- 권장 조치: 동일 identifier의 중복 reference만 한 개 제거한다. 패키지 자체는 사용 중이므로 삭제하지 않는다.
- 검증: `Rodi Dev` Debug build, My > 설정 > 오픈소스 라이선스 화면을 확인한다.

### P2-CR-3 — 활성 문서의 코드 기준선 불일치

상태: 완료 — 활성 backlog, 미해결 항목, API 현황의 기준선과 테스트 상태를 현재 심볼로 갱신했다.

- 대상: `Docs/Refactoring/PRESENTATION_REFACTORING.md`, `Docs/TODO/UNRESOLVED_ITEMS.md`, `Docs/API/API_CONNECTION_STATUS.md`
- 근거: Presentation backlog는 존재하지 않는 P1-8/P1-9/P2-5를 참조하고 Presentation Swift 줄 수를 30,639로 기록하지만 현재는 32,701줄이다. 미해결 항목은 TODO 3개와 이전 파일 줄 수를 기록하지만 현재 source 검색에서는 TODO/FIXME/HACK/XXX가 없다. API 현황의 구성 설명도 현재 AppDependencies의 repository 조립 범위와 일부 다르다.
- 권장 조치: 다음 해당 Feature/API 리팩터링 커밋에서 현재 심볼·줄 수·상태로 갱신한다. 단순 날짜만 바꾸지 말고 완료/보류/미착수를 현재 증거로 재분류한다.
- 검증: 문서가 가리키는 path·symbol이 `rg`에서 확인되고, 완료 표와 활성 표가 중복되지 않는지 확인한다.

### P2-CR-4 — 위치·마커 경로는 측정 후 최적화

상태: 구현 완료·실기기 계측 대기 — 대용량 경로 매칭의 XCTest metric 기준을 추가했고, marker progressive rendering은 모든 prefix snapshot을 미리 보관하지 않도록 바꿨다. 실기기 연결이 복구되면 동일 테스트와 Instruments를 다시 실행한다.

- 대상: `Rodi/Presentation/PracticeTracking/Service/PracticeTrackingService.swift`, `Rodi/Presentation/PracticeTracking/Service/PracticeRouteMatcher.swift`, `Rodi/Presentation/Home/Map/Service/MapMarkerRenderingService.swift`
- 근거: `PracticeTrackingService`는 MainActor에서 위치 update마다 전체 route segment를 선형 탐색한다. marker progressive rendering은 누적 prefix snapshot 배열을 생성한다. 두 경우 모두 정적 비용은 보이지만 hitch·메모리 문제의 실측 근거는 없다.
- 조치: 2,001개 좌표·20회 매칭을 사용하는 `PracticeRouteMatcherPerformanceTests`에 clock·memory metric을 추가했다. Simulator 기준 평균 0.006초·추가 physical memory 평균 약 262KB로, 정적 비용만으로 route index를 도입할 근거는 확인되지 않았다. marker는 기존 batch 크기·16ms cadence·최종 snapshot 계약을 유지하면서 batch 배열 전체를 사전 생성하지 않도록 바꿨다.
- 검증: Simulator에서 성능 테스트와 1,000개 marker snapshot 계약 테스트를 실행한다. 실기기 Time Profiler/SwiftUI Instruments는 기기 보안 연결 복구 후 동일 긴 route·marker viewport로 다시 확인한다.

## 유지 판정

다음은 이번 리뷰에서 변경 후보로 확정하지 않았다.

- Domain은 UI·SDK·DTO import 없이 Entity와 Repository contract를 유지한다.
- DataSource/RepositoryImpl/Mapper의 서버 변환 경계와 `ServerResponse` helper 구조는 유지한다.
- Presentation은 backend `NetworkManager`를 직접 호출하지 않는다. 코스 등록의 Kakao Local private DTO와 URLSession은 RODI backend Swagger DTO가 아닌 feature 전용 외부 API adapter라 현재 Service 내부 유지가 적절하다.
- Kakao Map Adapter, Home 위치 request ID/취소 구조, Review의 Prompt/Writing/SkipReason child 구조, PracticeTracking의 Return/Adapter/Service 분리는 정적 검토상 현 구조를 유지하는 편이 안전하다.
- `GeometryReader` 3건은 dropdown anchor 또는 튜토리얼 컨테이너 비율 계산이라는 실제 측정 책임이 있어, 재현된 SE/Max 레이아웃 결함 없이 제거하지 않는다.

## 권장 처리 순서

1. P2-CR-4는 실제 긴 경로·다수 marker 환경에서 Instruments 측정 결과가 생길 때만 다시 연다.
2. 위치·Live Activity·Kakao 외부 앱 전환·로그아웃은 실기기 수동 QA로 보완한다.

## 후속 검증 체크

- MUST 테스트 target 변경 뒤 `xcodebuild test`를 실제로 실행하고 결과를 기록한다.
- MUST persistence 변경 뒤 기존 key·payload 호환과 인증 대기 session 복구를 수동 확인한다.
- MUST 책임 이동 뒤 Dev Debug build와 `git diff --check`를 실행한다.
- SHOULD 위치·Live Activity·Kakao 외부 앱 전환은 실기기에서 별도로 수동 검증한다.
