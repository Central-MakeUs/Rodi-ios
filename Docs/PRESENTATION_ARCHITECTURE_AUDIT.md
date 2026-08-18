# Presentation 아키텍처·폴더링 점검

> 기준일: 2026-08-18
> 범위: `Rodi/Presentation`의 실제 Swift 코드와 `Docs/ARCHITECTURE.md`
> 목적: 기능 동작을 바꾸지 않고, 이후 기능 추가 시 안전하게 분리할 우선순위와 기준을 관리한다.

## 현재 인벤토리

| 항목 | 개수 |
| --- | ---: |
| Presentation Swift 파일 | 193 |
| 최상위 feature | 8 (`Home`, `My`, `CourseRegistration`, `Review`, `Onboarding`, `Login`, `MainTab`, `PracticeTracking`) |
| Reducer | 27 |
| View | 50 |
| feature Service | 21 |
| UIKit·외부 SDK Adapter | 17 |
| Presentation 하위 디렉터리 | 79 |

파일 수만으로는 리팩토링 여부를 결정하지 않는다. 현재 `Home` 96개, `Onboarding` 27개, `Review` 25개, `My` 19개, `CourseRegistration` 11개이며, 최근 큰 flow가 추가된 `CourseRegistration`과 Home의 하위 bottom sheet가 우선 점검 대상이다.

## 현재 설계에서 유지할 점

- Presentation에서 `NetworkManager`, API Target, RemoteDataSource, RepositoryImpl, DTO를 직접 참조하는 사례는 이번 점검에서 발견되지 않았다.
- `Review`는 `Section/Prompt`, `Section/Writing`, `Section/SkipReason`으로 단계 책임을 분리하고, `ReviewReducer`가 flow를 중재한다. 이는 현재 문서의 child reducer 원칙과 맞으므로 유지한다.
- Kakao 지도 구현은 `Home/Map/Adapter`, `Home/Map/Service`와 `CourseRegistration/Service`에 남아 있어 SDK 경계가 Presentation 안에서 분리되어 있다. 이를 Core 또는 Domain으로 옮기지 않는다.
- Home의 지도·바텀시트·검색, My의 `SubPage`, Onboarding의 단계별 `SubPage` 구조는 기능 경계를 드러내므로 폴더를 평탄화하지 않는다.

## 리팩토링 판단 기준

### 반드시 처리 (P1)

다음 중 하나라도 해당하면 기능 변경과 별개로 같은 작업 또는 직후 작은 리팩토링 작업을 만든다.

| 기준 | 이유 | 최소 조치 |
| --- | --- | --- |
| View/Reducer가 DTO·RemoteDataSource·RepositoryImpl·NetworkManager에 직접 의존 | 레이어 경계가 깨지고 테스트·변경 영향이 커짐 | Domain protocol 주입으로 교체 |
| feature root가 서로 독립적인 화면 단계의 State·Action·Effect를 3개 이상 함께 소유 | 하나의 기능 수정이 다른 단계 회귀로 이어짐 | child State/Action/Reducer로 합성하고 Delegate로 결과만 전달 |
| AppDependencies 전체가 feature reducer에 들어가고 실제 사용 의존성이 일부뿐 | composition root가 service locator처럼 변질됨 | 필요한 protocol/store만 생성자 인자로 축소 |
| Debug 전용 화면·테스트 API가 제품 Component/목록 렌더링 파일에 섞임 | Release 코드 이해와 제품 UI 책임이 오염됨 | `Presentation/Debug`로 분리하고 `#if DEBUG` 진입점만 남김 |
| 같은 화면을 열기 위한 feature 생성 코드가 두 곳 이상 복제됨 | 의존성·완료 callback·환경 분기가 쉽게 달라짐 | 상위 coordinator/factory 한 곳으로 모음 |

### 계획적으로 처리 (P2)

| 기준 | 이유 | 권장 조치 |
| --- | --- | --- |
| View 또는 Reducer가 500줄 이상이며 서로 다른 UI 책임/Effect 군을 가짐 | 읽기·리뷰·충돌 비용 증가 | `SubPage`, `Section`, `Component`, `Service`로 실제 책임 단위만 추출 |
| root View initializer가 10개 이상의 callback/state를 받음 | 상위 flow 결합도가 높고 호출 누락 위험 | typed route/delegate payload 또는 상위 flow state로 묶음 |
| 목록 Component가 행·empty·error·menu·dialog를 모두 포함 | 재사용 범위와 상태별 수정이 불명확 | 행/empty/dialog을 `Component`로, 상태 선택은 parent에 유지 |
| SDK gesture·height observation이 일반 SwiftUI 화면 조립과 섞임 | lifecycle·gesture 회귀 가능성 | UIKit observer/gesture policy를 Adapter 또는 전용 controller로 추출 |

### 보류 또는 예외 허용 (P3)

| 기준 | 판단 |
| --- | --- |
| 단일 파일이 300줄 안팎이지만 한 화면의 응집된 표현만 가짐 | 같은 파일의 `private extension`, `MARK`를 우선 사용. 무조건 파일 분할하지 않음 |
| custom dropdown anchor, Kakao 지도, bottom sheet 크기 측정처럼 UIKit/SwiftUI 제약상 `GeometryReader`·Preference가 필요한 경우 | 이유와 영향 화면을 남기고 feature Adapter/Component 경계 안에서 제한적으로 유지 |
| iOS 16.1에서 비율 기반 tutorial 이미지 크기를 표현하기 위한 제한적 GeometryReader | 단독·고정 높이 계산으로 대체 가능한지 UI 변경 작업 때 재검토. 지금은 기능 회귀 위험 때문에 즉시 교체하지 않음 |

## 발견 사항과 권장 순서

### P1 — 코스 등록 flow 분리

대상: [CourseRegistrationReducer.swift](../Rodi/Presentation/CourseRegistration/CourseRegistrationReducer.swift), [CourseRegistrationView.swift](../Rodi/Presentation/CourseRegistration/CourseRegistrationView.swift)

- Reducer가 1,141줄이며 튜토리얼, 지도 최초 선택, 장소 검색 전환, 핀 수정, 경로 계산, 상세 폼 조회·제출, 이탈 확인, 토스트를 함께 소유한다.
- View도 877줄이며 튜토리얼, 지도 선택 화면, 핀 수정 화면, 하단바, 입력 행을 한 파일에서 조립한다.
- 이는 `CourseRegistration`이 실제로 독립 단계 4개 이상을 갖는 flow라는 뜻이다. 현재 root가 모든 Action을 직접 해석해 이후 핀 수정·등록 폼 변경이 서로 영향을 줄 가능성이 크다.

권장 구조:

```text
CourseRegistration/
  CourseRegistrationReducer.swift      // route·최종 Delegate만 중재
  Tutorial/                            // TutorialReducer, TutorialPageView
  MapSelection/                        // MapSelectionReducer, EntryView, SelectionBar
  PinEditing/                          // PinEditReducer, PinEditView
  Details/                             // DetailsReducer, DetailsView
  Component/                           // Header, LocationInputs, 공통 하단 버튼
  Model/                               // Waypoint, SelectedPlace, route payload
  Service/                             // 현재 지도·역지오코딩·directions service 유지
```

각 child는 필요한 결과만 `delegate`로 올린다. 예를 들어 지도 선택은 `selected(target, place)`만, 핀 수정은 `completed(target, replacement, routePath)`만 부모에 전달한다. route 전환과 최종 등록 성공 후 닫기만 부모가 소유한다.

### P1 — Debug 테스트 화면을 제품 목록 Component에서 분리

대상: [PlaceListView.swift](../Rodi/Presentation/Home/BottomSheet/RecommendList/Component/PlaceListView.swift#L266)

- 빈 추천 목록 Component 안에 triple tap 진입, Live Activity picker, 후기 팝업, 등록 코스 preview, 즉시 탈퇴 API·다이얼로그가 약 330줄 포함되어 있다.
- `#if DEBUG`라 Release 바이너리에는 들어가지 않지만, 제품 empty state가 Debug 테스트의 소유자가 되는 구조다.

권장 조치:

```text
Presentation/Debug/
  DebugFeatureTestPage.swift
  DebugMyCoursesPreviewPage.swift
  DebugHardWithdrawalConfirmationDialog.swift
```

`PlaceListEmptyResultView`에는 Debug 페이지를 열기 위한 conditional callback만 남긴다. 실제 API 호출은 상위 coordinator나 주입된 action으로 전달해 목록 Component가 회원 관리 책임을 갖지 않게 한다.

### P1 — feature reducer의 전체 AppDependencies 의존성 축소

대상: [HomeReducer.swift](../Rodi/Presentation/Home/HomeReducer.swift#L127), [HomeBottomSheetReducer.swift](../Rodi/Presentation/Home/BottomSheet/HomeBottomSheetReducer.swift#L66)

- 두 reducer가 `AppDependencies` 전체를 받아 내부에서 일부 repository/store를 골라 쓴다.
- `AppDependencies`는 App composition root로는 적절하지만, feature reducer가 전체 graph를 알면 신규 의존성이 숨겨지고 테스트용 대체 구현을 주입하기 어렵다.

권장 조치: `HomeDependencies`와 `HomeBottomSheetDependencies` 같은 feature 범위 값으로 `PlaceRepository`, `RecentSearchRepository`, `MemberRepository`, `PracticeRepository`, `ReviewRepository`, 필요한 store만 명시적으로 주입한다. `RootView`/`MainTabView`만 AppDependencies를 소유한다.

### P2 — Home flow의 입출력 계약 축소

대상: [MainTabView.swift](../Rodi/Presentation/MainTab/MainTabView.swift#L16), [HomeView.swift](../Rodi/Presentation/Home/HomeView.swift#L18)

- `MainTabView`와 `HomeView`가 리뷰 작성·수정, 로그인, 바텀 탭 노출, 목록 요청, 장소 선택, snackbar, 완료 revision 등 다수의 callback과 state를 직접 전달한다.
- 특히 `HomeView`는 상위 flow의 상태를 10개 이상 받으므로 호출 지점 변경 시 인자 누락·순서 오류를 검토하기 어렵다.

권장 조치: 홈에서 상위로 내보낼 이벤트를 `HomeDelegate`/`HomePresentationRequest`처럼 typed enum으로 묶고, 코스 상세 후기 flow는 parent child State로 합성한다. callback 개수를 줄이되, 전역 singleton 또는 `AppDependencies` 조회로 대체하지 않는다.

### P2 — 중복된 코스 등록 생성 지점 제거

대상: [MainTabView.swift](../Rodi/Presentation/MainTab/MainTabView.swift#L132), [MyView.swift](../Rodi/Presentation/My/MyView.swift#L184)

- 등록 탭과 마이페이지 route가 각각 `CourseRegistrationView`를 만들며 같은 repository·완료 처리 계약을 조립한다.
- 향후 등록 flow에 새 의존성이나 완료 상태가 추가되면 두 진입점의 동기화가 필요하다.

권장 조치: `MainTab` 또는 별도 상위 route factory가 `CourseRegistrationView` 생성을 한 번만 소유하고, My는 `.openCourseRegistration` delegate만 올린다. My의 navigation stack으로 열어야 하는 UX가 유지되어야 한다면 공통 factory 함수만 사용한다.

### P2 — 큰 화면 파일을 표현 책임별로 분리

| 대상 | 근거 | 최소 분리 단위 |
| --- | --- | --- |
| [HomeBottomSheetView.swift](../Rodi/Presentation/Home/BottomSheet/HomeBottomSheetView.swift) (842줄) | sheet chrome, 3개 gesture, 높이 측정 UIKit bridge, destination routing이 한 파일 | `BottomSheetContentHeightObserver`는 Adapter, 각 sheet gesture policy는 전용 helper/Section |
| [MyPostsView.swift](../Rodi/Presentation/My/SubPage/MyPosts/MyPostsView.swift) (779줄) | 후기/코스 행, empty state, dropdown, 삭제 dialog를 모두 소유 | `MyCourseRow`, `MyPostReviewRow`, empty/retry/dialog를 `Component`로 추출 |
| [CourseReviewSection.swift](../Rodi/Presentation/Home/BottomSheet/CourseDetail/Section/Review/Component/CourseReviewSection.swift) (694줄) | 요약, 난이도, 목록, 카드, dropdown가 동일 파일 | summary/list/card를 개별 Component로. reducer 책임은 이동하지 않음 |
| [CourseDetailExpandedPage.swift](../Rodi/Presentation/Home/BottomSheet/CourseDetail/SubPage/CourseDetailExpandedPage.swift) (535줄) | 상세 정보와 전체 후기·menu overlay를 함께 조립 | 상세 정보 Section과 후기 전체보기 SubPage/Component를 분리 |

### P3 — 기존 화면 크기 접근 재검토

| 대상 | 근거 | 방향 |
| --- | --- | --- |
| [LoginView.swift](../Rodi/Presentation/Login/LoginView.swift#L154) | `UIScreen.main.bounds.width`에 의존 | stack/flexible frame으로 대체 가능한지 로그인 UI 수정 때 확인 |
| [OnboardingAnalysisDialog.swift](../Rodi/Presentation/Onboarding/Component/OnboardingAnalysisDialog.swift#L26) | `UIScreen.main.bounds.height`에 의존 | content 기반 크기·safe area로 전환 검토 |
| [CourseRegistrationView.swift](../Rodi/Presentation/CourseRegistration/CourseRegistrationView.swift#L860) | tutorial 이미지 폭 72%를 GeometryReader로 계산 | iOS 16.1 호환 범위에서 대안 검토 후에만 변경 |

`MyPostsView`, `CourseDetailExpandedPage`, `CourseReviewSection`의 anchor preference/GeometryReader는 custom dropdown 위치 정렬에 쓰인다. 이 항목은 일반적인 화면 측정과 달리 현재 목적이 명확하므로, 대체안을 검증하기 전에는 제거하지 않는다.

## 실행 원칙

1. 사용자 기능을 추가하는 파일에서 P1 기준이 충족되면 해당 feature부터 함께 정리한다.
2. 한 번에 Home 전체 또는 Presentation 전체를 이동하지 않는다. 각 작업은 build 가능한 작은 단위로 끝낸다.
3. 파일 이동 뒤에는 filesystem-synchronized group, route 진입, child delegate 전달을 확인한다.
4. Swift 변경 뒤 `Rodi Dev` Debug build와 `git diff --check`를 실행한다.
5. 이 문서는 feature 추가·대형 파일 분할·새 top-level feature 생성 시 갱신한다.
