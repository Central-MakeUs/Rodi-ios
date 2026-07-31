# RODI Analytics And Observability Plan

이 문서는 Firebase Analytics(GA4), Firebase Crashlytics, Firebase Performance
Monitoring, Microsoft Clarity의 설계·구현 기준이다. Firebase 초기화와 P0 이벤트
전송은 적용되어 있으며, 신규 이벤트도 이 문서의 개인정보 경계를 따라 추가한다.

## Goals

Rodi가 확인하려는 핵심 질문은 다음과 같다.

1. 사용자가 온보딩 또는 로그인 이후 홈 지도까지 도달하는가.
2. 사용자가 코스 또는 주차장을 발견하고 상세를 확인하는가.
3. 발견한 장소가 외부 길안내 실행과 실제 연습 기록으로 이어지는가.
4. 검색, 필터, 지도, 바텀싯에서 사용자가 막히거나 이탈하는 지점은 어디인가.
5. 지도, 인증, 네트워크, 외부 길안내에서 발생하는 안정성·성능 문제는 무엇인가.

## Platform Decision

| Platform | Purpose | Decision |
| --- | --- | --- |
| Firebase Analytics (GA4) | 퍼널, 전환, 재방문, 기능 사용량의 정량 분석 | 도입 |
| Firebase Crashlytics | 크래시와 예상하지 못한 non-fatal 오류 분석 | 도입 |
| Firebase Performance Monitoring | 앱 시작, 화면 렌더링, HTTP 요청, 핵심 흐름의 성능 분석 | 도입 |
| Microsoft Clarity | dead tap, rage tap, 지도·바텀싯·검색 UX의 정성 분석 | 도입 |

- Firebase는 Debug/Staging과 Release를 **별도 Firebase 프로젝트**로 운영한다.
- `RODI_ANALYTICS_ENABLED`가 `YES`인 환경에서만 앱 시작 시 Firebase Analytics
  collection을 명시적으로 활성화한다. Firebase Console에서도 각 Firebase 프로젝트의
  Google Analytics 연결·수집 상태를 별도로 확인한다.
- Firebase Analytics를 Crashlytics와 함께 사용해 크래시 전 사용자 행동 breadcrumb을
  확인한다. [Firebase Crashlytics iOS guide](https://firebase.google.com/docs/crashlytics/ios/get-started)
- Performance Monitoring은 자동 trace를 먼저 확인하고, 부족한 핵심 흐름에만 custom
  trace를 추가한다. [Firebase Performance guide](https://firebase.google.com/docs/perf-mon/get-started-ios)
- Clarity는 Dev와 Prod에 별도 프로젝트로 적용한다. Dev에서 초기화·마스킹·제스처 회귀를
  먼저 검증한 뒤 Prod 사용을 유지한다.
  Clarity는 SwiftUI를 지원하지만 공식 지원 표에 iOS 15~18이 명시되어 있으므로,
  Rodi의 iOS 26 환경은 별도 실기기 검증 대상이다.
  [Clarity mobile overview](https://learn.microsoft.com/en-us/clarity/mobile-sdk/mobile-sdk-overview)

## Measurement Model

### Core Conversion

현재 핵심 전환은 `route_guidance_opened`이다. 사용자가 장소를 발견한 뒤 실제로
카카오맵 또는 카카오내비 길안내를 실행했다는 가장 강한 의도 신호이기 때문이다.

연습 기록 기능이 안정화되면 `practice_tracking_completed`를 더 깊은 가치 행동으로
본다. 이는 코스 위 실제 주행 조건을 만족한 세션만 의미하며, GPS 원본 경로는
Analytics에 보내지 않는다.

### Primary Funnel

```text
app_open
  -> onboarding_completed or browse_started
  -> home_map_ready
  -> place_detail_opened
  -> route_guidance_opened
  -> practice_tracking_started
  -> practice_tracking_completed
```

별도 분석 퍼널:

```text
search_opened -> search_submitted -> search_results_loaded -> search_result_selected
practice_filter_opened -> practice_filter_applied -> place_detail_opened
login_attempted -> login_succeeded -> onboarding_completed
```

## Event Catalog

### P0: Initial Release Events

| Event | Trigger | Allowed parameters |
| --- | --- | --- |
| `onboarding_started` | 온보딩 진입 | `entry_mode` |
| `onboarding_step_completed` | 각 온보딩 단계의 유효한 완료 | `step`, `entry_mode` |
| `onboarding_completed` | 회원 온보딩 제출 완료 또는 둘러보기 완료 | `entry_mode`, `member_level` |
| `browse_started` | 둘러보기 선택 완료 | none |
| `login_attempted` | Apple/Kakao 로그인 시도 | `provider` |
| `login_succeeded` | 토큰 저장까지 성공 | `provider`, `is_new_member` |
| `login_failed` | 취소가 아닌 로그인 실패 | `provider`, `failure_category` |
| `login_cancelled` | Apple/Kakao 로그인 취소 | `provider` |
| `home_map_ready` | 지도 엔진과 최초 렌더 준비 완료 | `entry_source`, `has_location_permission` |
| `place_detail_opened` | 코스·주차장 상세 노출 | `source`, `place_type` |
| `search_opened` | 홈 검색 화면 노출 | none |
| `search_submitted` | 키보드 제출 또는 최근검색어 선택 | `input_source`, `query_length_bucket` |
| `search_results_loaded` | 서버 검색 완료 | `result_count_bucket`, `has_local_area_candidates` |
| `search_result_selected` | 코스·주차장 결과 선택 | `result_type`, `source` |
| `administrative_area_selected` | 로컬 시도·시군구 후보 선택 | `area_level`, `candidate_count_bucket` |
| `practice_filter_opened` | 추천 목록 필터 열기 | `presentation` |
| `practice_filter_applied` | 서버 저장 성공 후 재조회 시작 | `category`, `selected_tag_count`, `is_all` |
| `practice_filter_reset` | 필터 초기화 의도 | none |
| `bookmark_updated` | 북마크 저장·해제 성공 | `is_bookmarked`, `source`, `place_type` |
| `route_guidance_opened` | 외부 길안내 앱 실행 성공 | `navigation_provider`, `place_type`, `source` |
| `practice_tracking_started` | 위치 기록과 Live Activity 시작 성공 | `location_accuracy_state` |
| `practice_tracking_state_changed` | 이동 중/주행 중/완료 상태 전환 | `state` |
| `practice_tracking_completed` | 코스 주행 완료 조건 충족 | `completion_reason`, `duration_bucket`, `progress_bucket` |
| `practice_tracking_cancelled` | 사용자 취소·권한·외부 실행 실패 등으로 종료 | `reason` |

### P1: Retention And Account Events

- `saved_places_opened`, `saved_place_selected`
- `my_opened`, `driving_goal_saved` (`goal_length_bucket`만 기록)
- `location_permission_prompted`, `location_permission_result`
- `logout_completed`, `withdrawal_requested`, `withdrawal_restored`
- `external_navigation_launch_failed`, `token_refresh_failed`, `map_render_recovered`

## Instrumentation Rules

- 이벤트는 SwiftUI `body` 렌더나 `onAppear` 중복 호출이 아니라, Reducer의 확정된
  성공 action 또는 Router의 실제 화면 전환 완료 시점에 기록한다.
- 입력 문자마다, 지도 드래그 프레임마다, 바텀싯 drag translation마다 이벤트를 보내지
  않는다.
- 공용 `AnalyticsTracking` 추상화를 Core에 두고 Presentation은 의미 있는 event만
  요청한다. Firebase SDK를 개별 View/Reducer에 직접 import하지 않는다.
- 화면 조회는 Router의 route 전환에 한정해 `home`, `home_search`, `onboarding_*`,
  `my_*` 이름으로 기록한다.
- 사용자 속성은 `user_mode`(guest/member), `login_provider`, `member_level`,
  `has_driving_goal`처럼 low-cardinality 값으로 제한한다.

## Firebase Console Setup

- Firebase Analytics의 Events 화면은 앱이 `Analytics.logEvent`로 보낸 custom event를
  수집한다. 이벤트마다 별도 SDK 또는 별도 Firebase 연결은 필요하지 않다.
- Debug 빌드는 Xcode Scheme의 Run Arguments에 `-FIRDebugEnabled`를 넣고 Firebase
  DebugView에서 즉시 검증한다. Release 이벤트는 일반 보고서 반영까지 시간이 걸릴 수 있다.
- 퍼널·탐색 보고서에서 파라미터별 분해가 필요하면 GA4 Custom Definitions에 다음
  low-cardinality 파라미터만 등록한다: `entry_mode`, `step`, `provider`,
  `failure_category`, `place_type`, `source`, `result_type`, `area_level`,
  `category`, `navigation_provider`, `status`.
- `query_length_bucket`, `result_count_bucket`, `candidate_count_bucket`,
  `goal_length_bucket`, `selected_tag_count`는 숫자 또는 문자열 구간으로만 사용한다.
  검색어 원문·좌표·장소 ID는 Custom Definition에도 등록하지 않는다.

## Privacy And Data Boundaries

다음 값은 Analytics event parameter, user property, Crashlytics key/log, Clarity custom
event에 절대 넣지 않는다.

- 검색어 원문, 닉네임, 운전 목표 원문
- OAuth credential, access/refresh token, 이메일, 전화번호
- 위도·경도, 지도 viewport, GPS 원본 경로
- place ID, place 이름, 행정구역 이름처럼 과도한 cardinality 또는 위치 식별 가능 값

대신 `place_type`, `source`, `result_count_bucket`, `duration_bucket`,
`selected_tag_count`처럼 범주화된 값을 사용한다.

Clarity는 화면과 탭을 재현하므로 다음을 마스킹한다.

- Kakao 지도 컨테이너와 현재 위치 표현
- 검색 TextField, 닉네임, 운전 목표, 운전 경험 입력 영역
- 마이 프로필, 계정 삭제·복구·로그인 관련 화면

SwiftUI는 `clarityMask()`를, UIKit 지도 adapter는 UIKit masking API를 사용한다.
입력 필드는 개별 마스킹이 필요하다.
[Clarity masking guide](https://learn.microsoft.com/en-us/clarity/mobile-sdk/clarity-sdk-masking)

Clarity 활성화 전 개인정보처리방침, 위치기반서비스 이용약관, App Store Privacy Label에
분석·세션 리플레이 처리와 제3자 처리 관계를 반영한다.

## Crashlytics And Performance

### Crashlytics

Non-fatal 대상:

- Kakao 지도 초기화·렌더 회복 실패
- 외부 길안내 실행 실패
- 토큰 갱신 실패
- 온보딩 제출의 5xx·네트워크 오류
- 예상하지 못한 응답 디코딩 오류

정상 사용자 흐름인 4xx, 로그인 취소, 위치 권한 거부는 Crashlytics가 아닌 Analytics
이벤트로만 기록한다.

허용 key: `screen`, `selected_tab`, `bottom_sheet_state`, `map_ready`, `auth_state`,
`endpoint_category`, `http_status_family`.

### Performance Monitoring

자동 수집 확인 대상:

- 앱 시작과 foreground/background lifecycle
- 화면 렌더링
- Alamofire 기반 HTTP/S 요청

필요 시 custom trace:

- `home_map_ready`
- `home_place_coordinates_load`
- `administrative_area_search_all_pages`
- `place_detail_load`
- `practice_tracking_startup`

custom trace는 프레임 단위 또는 고빈도 호출에 사용하지 않는다.

## Validation And Rollout

1. Debug와 Release가 서로 다른 Firebase 프로젝트로 전송되는지 확인한다.
2. P0 이벤트가 사용자 의도 한 번당 한 번만 기록되는지 Firebase DebugView로 검증한다.
3. 디버거 없이 테스트 크래시와 non-fatal 오류 한 건을 전송해 Crashlytics를 검증한다.
4. Performance 자동 network trace에 Alamofire 요청이 나타나는지 확인한다.
5. Dev 환경의 iOS 18과 iOS 26 실기기에서 Clarity의 지도 드래그, 바텀싯, 검색, 키보드 동작을
   회귀 검증하고, 모든 민감 영역이 마스킹되는지 확인한다.
6. 출시 후 첫 2주 동안은 P0의 누락·중복·카디널리티를 검토한 뒤 P1을 추가한다.

## Explicit Non-Goals

- 광고 리타게팅 또는 개인화 광고 목적의 추적
- 원문 검색어·위치·운전 기록의 분석 전송
- Firebase User ID 또는 Clarity 식별자에 서버 회원 ID, 닉네임, 이메일을 넣는 작업
- 이 문서 작성과 동시에 SDK, 프로젝트 설정, Privacy Manifest, 앱 코드 변경
