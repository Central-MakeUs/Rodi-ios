# RODI API 연결 현황

> Archive: 2026-08-20 시점의 전체 점검 기록이다. 현재 API 계약은 Swagger와 활성 [API 가이드](../../API/API_SWAGGER.md)에서 다시 확인한다.

> 마지막 전체 점검: 2026-08-20
> Swagger: `https://api.stillstar.store/v3/api-docs`
> 기준 환경: 현재 Swagger가 가리키는 API 환경 / 앱 구현: `Rodi/Data/Remote`
> 이력 범위: Swagger endpoint 45개와 iOS API Target·DataSource·Repository·DTO 파일 인벤토리를 대조했다. endpoint별 field schema와 실제 실행은 해당 API 변경 작업에서 다시 확인한다.

이 문서는 API Target → RemoteDataSource → Repository → Domain/Presentation의 코드 연결 상태를 관리한다. 이 문서의 표는 마지막 점검 시점의 기록이며, 현재 Swagger schema 또는 실제 서버 실행을 자동으로 보증하지 않는다.

## 관리 규칙

- API를 추가·변경·삭제할 때 이 문서의 해당 행을 **같은 PR/커밋에서** 갱신한다.
- 확인 전에는 상태를 `확인 필요`로 두고, Swagger의 환경·버전·method·path를 확인한 뒤 `연결됨`으로 바꾼다.
- DTO에 Swagger 응답 field가 추가되면 DTO뿐 아니라 Mapper와 Domain 전달 여부까지 점검한다.
- 관리자·운영 전용 API는 일반 앱 연결 대상에서 제외하되, 제외 사유를 남긴다.
- Swagger가 실제 응답과 다르거나 request schema가 없으면 앱에서 추정하지 않고 `서버 문서 보완 필요`에 기록한다.

## 상태 범례

| 상태 | 의미 |
| --- | --- |
| 연결됨 | 마지막 점검 시 앱에서 사용 가능한 API Target·DTO·Repository 경로가 있었음 |
| 제외 | 관리자/운영 전용이거나 일반 iOS 앱 범위 밖 |
| 확인 필요 | Swagger 또는 실제 응답 변경 뒤 재점검 필요 |

`연결됨`은 다음을 뜻하지 않는다.

- 최신 Swagger의 모든 field가 DTO·Mapper·Domain까지 검증됐다는 보장
- 실제 서버 응답, 인증, 오류 처리, UI 흐름을 실행 검증했다는 보장

API 변경 작업에서는 해당 endpoint 행에 method·path 확인, field 전달 확인, 실행 검증 여부와 기준일을 함께 기록한다.

## 2026-08-20 인벤토리 기록

| 항목 | 당시 개수 | 기준 |
| --- | ---: | --- |
| Swagger endpoint | 45 | 일반 사용자 44개 + 관리자 전용 1개 |
| Remote API Target | 7 | `Auth`, `Course`, `Member`, `Place`, `Practice`, `RecentSearch`, `Review` |
| RemoteDataSource | 7 | API Target과 리소스별 1:1 |
| RepositoryImpl | 7 | 도메인 Repository와 리소스별 1:1 |
| Domain Repository protocol | 7 | Presentation은 이 계약만 사용 |
| DTO Swift 파일 | 44 | Request 17개 + Response 27개 |
| 전체 Swift 파일 | 435 | `Rodi/` 하위 기준 |

### 리소스별 DTO 수

| 리소스 | Request | Response | 합계 |
| --- | ---: | ---: | ---: |
| Auth | 3 | 3 | 6 |
| Course | 2 | 3 | 5 |
| Member | 4 | 3 | 7 |
| Place | 1 | 9 | 10 |
| Practice | 3 | 4 | 7 |
| RecentSearch | 1 | 1 | 2 |
| Review | 3 | 4 | 7 |
| **합계** | **17** | **27** | **44** |

## DTO 리팩토링 판단 기준

다음 기준을 만족할 때만 DTO 구조를 바꾼다. 단순히 파일 수를 줄이기 위해 서로 다른 endpoint 계약을 하나의 DTO로 합치지 않는다.

| 우선순위 | 기준 | 조치 |
| --- | --- | --- |
| 높음 | Swagger field가 DTO·Mapper·Domain 중 한 단계에서 유실됨 | 같은 작업에서 전파·연결 |
| 높음 | DTO가 SwiftUI·Presentation 상태·제품 기본값을 가짐 | DTO는 wire format으로 되돌리고 정책은 Mapper/Domain으로 이동 |
| 높음 | API Target/DTO/Repository 중 하나가 없어 endpoint를 실제 호출할 수 없음 | 표준 Data 경로를 추가 |
| 중간 | 파일명과 주 타입명이 다르거나 `Read`·`List`·`CursorPage` 의미가 실제 schema와 다름 | 실제 payload 형태에 맞춰 파일·타입명을 정렬 |
| 중간 | 한 DTO가 100줄을 넘기거나 서로 무관한 schema 3개 이상을 포함 | endpoint/중첩 모델 책임 단위로 분리 |
| 중간 | 같은 wire schema가 2개 이상 중복되고 Swagger 변경 시 함께 수정돼야 함 | 공통 nested DTO로 추출. endpoint wrapper는 유지 |
| 낮음 | 선택값·페이지·form metadata처럼 화면이 아직 쓰지 않는 응답 field | DTO→Domain까지 보존하고 UI 반영은 별도 기능 작업에서 결정 |

### 현재 판단과 반영

- 최대 DTO 파일은 54줄이므로 크기만으로 분할할 대상은 없다.
- 타입명과 파일명이 달랐던 아래 3개는 이번 점검에서 실제 응답 의미로 파일명을 정리했다.
  - `TokenRefreshResponseDTO.swift`
  - `MyPracticeCursorPageResponseDTO.swift`
  - `MyReviewCursorPageResponseDTO.swift`
- 따라서 현재 남은 구조 개선은 **Swagger schema 변경 시의 재점검**이 우선이며, DTO를 억지로 합치거나 대규모 폴더 재구성할 필요는 없다.

## 인증·회원

| Method | Endpoint | API Target | DTO | 상태 |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/auth/oauth/{provider}` | `AuthAPI.login` | `SocialLoginRequestDTO` / `SocialLoginResponseDTO` | 연결됨 |
| POST | `/api/v1/auth/oauth/{provider}/restore` | `AuthAPI.restore` | `SocialLoginRequestDTO` / `SocialLoginResponseDTO` | 연결됨 |
| POST | `/api/v1/auth/token/refresh` | `AuthAPI.refresh` | `TokenRefreshRequestDTO` / `TokenRefreshResponseDTO` | 연결됨 |
| POST | `/api/v1/auth/logout` | `AuthAPI.logout` | `LogoutRequestDTO` | 연결됨 |
| GET | `/api/v1/members/me` | `MemberAPI.myProfile` | `MemberProfileResponseDTO` | 연결됨 |
| PATCH | `/api/v1/members/me` | `MemberAPI.updateDrivingGoal` | `MemberDrivingGoalUpdateRequestDTO` / `MemberProfileResponseDTO` | 연결됨 |
| PUT | `/api/v1/members/me/filter-tags` | `MemberAPI.updatePlaceFilterTags` | `MemberPlaceFilterTagsUpdateRequestDTO` | 연결됨 |
| POST | `/api/v1/members/me/onboarding` | `MemberAPI.submitOnboarding` | `MemberOnboardingRequestDTO` | 연결됨 |
| PATCH | `/api/v1/members/me/course-tutorial` | `MemberAPI.completeCourseTutorial` | `CourseTutorialCompletionResponseDTO` | 연결됨 |
| DELETE | `/api/v1/members/me` | `MemberAPI.withdraw` | 없음 | 연결됨 |
| DELETE | `/api/v1/members/me/hard` | `MemberAPI.hardWithdraw` | 없음 | 연결됨 (Debug 테스트 진입점) |
| POST | `/api/v1/members/{memberId}/block` | `MemberAPI.block` | 없음 | 연결됨 |
| GET | `/api/v1/members/me/blocks` | `MemberAPI.blockedMembers` | `BlockedMemberCursorPageResponseDTO` | 연결됨 |
| DELETE | `/api/v1/members/{memberId}/block` | `MemberAPI.unblock` | 없음 | 연결됨 |

## 장소·북마크·검색

| Method | Endpoint | API Target | DTO | 상태 |
| --- | --- | --- | --- | --- |
| GET | `/api/v1/places/coordinates` | `PlaceAPI.coordinates` | `[PlaceCoordinateDTO]` | 연결됨 |
| GET | `/api/v1/places` | `PlaceAPI.list` / `authenticatedList` | `PlaceCursorPageDTO` | 연결됨 |
| GET | `/api/v1/places/search` | `PlaceAPI.search` | `PlaceCursorPageDTO` | 연결됨 |
| GET | `/api/v1/places/related-search` | `PlaceAPI.relatedSearch` | `PlaceRelatedSearchDTO` | 연결됨 |
| GET | `/api/v1/places/{placeId}` | `PlaceAPI.detail` | `PlaceDetailDTO` | 연결됨 |
| GET | `/api/v1/places/bookmarks` | `PlaceAPI.bookmarks` | `PlaceCursorPageDTO` | 연결됨 |
| POST | `/api/v1/places/{placeId}/bookmark` | `PlaceAPI.bookmark` | 없음 | 연결됨 |
| DELETE | `/api/v1/places/{placeId}/bookmark` | `PlaceAPI.unbookmark` | 없음 | 연결됨 |
| GET | `/api/v1/members/me/recent-searches` | `RecentSearchAPI.list` | `[RecentSearchDTO]` | 연결됨 |
| POST | `/api/v1/members/me/recent-searches` | `RecentSearchAPI.register` | `RecentSearchRegisterRequestDTO` | 연결됨 |
| DELETE | `/api/v1/members/me/recent-searches/{id}` | `RecentSearchAPI.delete` | 없음 | 연결됨 |
| DELETE | `/api/v1/members/me/recent-searches` | `RecentSearchAPI.deleteAll` | 없음 | 연결됨 |

## 연습·방문 인증

| Method | Endpoint | API Target | DTO | 상태 |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/places/{placeId}/practices` | `PracticeAPI.register` | `PracticeRegisterResponseDTO` | 연결됨 |
| POST | `/api/v1/practices/{practiceId}/visits` | `PracticeAPI.recordVisit` | `PracticeVisitRequestDTO` / `PracticeVisitResponseDTO` | 연결됨 |
| GET | `/api/v1/members/me/practices` | `PracticeAPI.myPractices` | `MyPracticeCursorPageResponseDTO` | 연결됨 |
| GET | `/api/v1/practices/skip-reason-form` | `PracticeAPI.skipReasonForm` | `PracticeSkipReasonFormResponseDTO` | 연결됨 |
| POST | `/api/v1/practices/{practiceId}/skip-reason` | `PracticeAPI.submitSkipReason` | `PracticeSkipReasonRequestDTO` | 연결됨 |

## 후기·신고

| Method | Endpoint | API Target | DTO | 상태 |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/places/{placeId}/reviews` | `ReviewAPI.create` | `ReviewRequestDTO` / `ReviewCreateResponseDTO` | 연결됨 |
| GET | `/api/v1/reviews/{reviewId}` | `ReviewAPI.detail` | `ReviewDetailResponseDTO` | 연결됨 |
| PUT | `/api/v1/reviews/{reviewId}` | `ReviewAPI.update` | `ReviewRequestDTO` / `ReviewResponseDTO` | 연결됨 |
| DELETE | `/api/v1/reviews/{reviewId}` | `ReviewAPI.delete` | 없음 | 연결됨 |
| GET | `/api/v1/places/{placeId}/reviews/summary` | `ReviewAPI.summary` | `ReviewSummaryResponseDTO` | 연결됨 |
| GET | `/api/v1/places/{placeId}/reviews` | `ReviewAPI.list` | `ReviewCursorPageResponseDTO` | 연결됨 |
| GET | `/api/v1/members/me/reviews` | `ReviewAPI.myReviews` | `MyReviewCursorPageResponseDTO` | 연결됨 |
| GET | `/api/v1/reviews/report-form` | `ReviewAPI.reportForm` | `ReviewReportFormResponseDTO` | 연결됨 |
| POST | `/api/v1/reviews/{reviewId}/report` | `ReviewAPI.report` | `ReviewReportRequestDTO` | 연결됨 |

## 코스 등록·내 코스

| Method | Endpoint | API Target | DTO | 상태 |
| --- | --- | --- | --- | --- |
| GET | `/api/v1/courses/registration-form` | `CourseAPI.registrationForm` | `CourseRegistrationFormResponseDTO` | 연결됨 |
| POST | `/api/v1/courses` | `CourseAPI.register` | `CourseRegisterRequestDTO` / `CourseRegisterResponseDTO` | 연결됨 |
| GET | `/api/v1/members/me/courses` | `CourseAPI.myCourses` | `MyCourseCursorPageResponseDTO` | 연결됨 |
| DELETE | `/api/v1/courses/{courseId}` | `CourseAPI.deleteMyCourse` | 없음 | 연결됨 |
| PATCH | `/api/v1/admin/courses/{courseId}/approval` | 없음 | 없음 | 제외 (관리자 전용) |

## 이번 DTO 점검 반영 사항

- RemoteDataSource와 API Target이 Domain query·submission을 직접 받던 혼재를 제거했다. RepositoryImpl/Mapper에서 Domain 입력을 Request·query DTO로 변환하고, RemoteDataSource는 DTO·원시 path 식별자만 실행한다.
- 공통 `ServerResponse`의 payload·빈 응답 검증을 `Data/Remote/Support/ServerResponseHandler`로 통일했다. API Target별 인증·path·DTO·response wrapper 계약은 각 리소스에 그대로 둔다.
- Member·Practice·Review·Auth의 Domain `Date` 변환은 `Data/RepositoryImpl/Support/ServerDateParser`로 통일했다. ISO-8601, fractional seconds, timezone 없는 서버 날짜 형식을 처리하며, 실제 서버 응답 수동 검증은 별도 QA에서 수행한다.
- `MemberRemoteDataSource`와 `MemberRepositoryImpl`의 프로필 원문 Debug 로그를 제거했다. 회원 닉네임·운전 목표 등 개인정보는 Data 로그에 기록하지 않는다.
- `PracticeRegisterResponseDTO`: `status`, `visitCount`, `requiredDistanceMeters` 전달 추가
- `MyPracticeItemResponseDTO`, `PlaceListItemResponseDTO`: `isDeleted` 추가 및 목록 노출 제외
- `PracticeSkipReasonFormResponseDTO`: 질문 ID·유형·제목·설명·필수 여부 전달 추가
- `CourseTutorialCompletionResponseDTO`: 튜토리얼 완료 시각 응답 전달 추가

## 서버 문서 보완 필요

- Swagger의 전역 Bearer 보안 표기는 소셜 로그인·토큰 갱신·로그아웃 API의 실제 인증 요구와 구분되어 있지 않다. endpoint별 보안 요구사항을 명확히 표기해야 한다.
- `POST /api/v1/courses`는 예시만 제공하고 machine-readable request schema를 제공하지 않는다. 필수/nullable/최대 길이·배열 제약을 포함한 schema가 필요하다.
