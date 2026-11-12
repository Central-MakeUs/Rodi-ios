//
//  RodiAnalytics.swift
//  Rodi
//

import Foundation

/// Firebase Analytics에 전달할 Rodi의 제품 행동 이벤트다.
/// 원문 검색어, 좌표, 장소 식별자, 토큰 등 개인·고카디널리티 값은 정의하지 않는다.
enum RodiAnalytics {

    enum Event {
        case onboardingStarted(entryMode: String)
        case onboardingStepCompleted(step: String, entryMode: String)
        case onboardingCompleted(entryMode: String, memberLevel: String)
        case browseStarted
        case loginAttempted(provider: String)
        case loginSucceeded(provider: String, isNewMember: Bool)
        case loginFailed(provider: String, failureCategory: String)
        case loginCancelled(provider: String)
        case homeMapReady(entrySource: String, hasLocationPermission: Bool)
        case placeDetailOpened(source: String, placeType: String)
        case searchOpened
        case searchSubmitted(inputSource: String, queryLengthBucket: String)
        case searchResultsLoaded(resultCountBucket: String, hasRegionCandidates: Bool)
        case searchResultSelected(resultType: String, source: String)
        case practiceFilterOpened(presentation: String)
        case practiceFilterApplied(category: String, selectedTagCount: Int, isAll: Bool)
        case practiceFilterReset
        case bookmarkUpdated(isBookmarked: Bool, source: String, placeType: String)
        case routeGuidanceOpened(navigationProvider: String, placeType: String, source: String)
        case routeGuidanceLaunchFailed(navigationProvider: String, placeType: String)
        case courseRegistrationOpened
        case courseRegistrationWaypointChanged(action: String, waypointCount: Int)
        case courseRegistrationPointSelected(inputType: String, source: String)
        case courseRegistrationRoutePrepared(waypointCount: Int)
        case courseRegistrationDetailsOpened
        case courseRegistrationSubmitted(
            waypointCount: Int,
            practiceTypeCount: Int,
            hasCaution: Bool
        )
        case courseRegistrationCompleted(waypointCount: Int)
        case courseRegistrationFailed(stage: String)
        case myActivityOpened(tab: String)
        case myCourseFilterChanged(status: String)
        case myCourseDeleted
        case reviewWritingOpened(mode: String)
        case reviewSubmitted(mode: String, hasContent: Bool)
        case reviewCompleted(mode: String)
        case reviewSubmissionFailed(mode: String)
        case drivePracticeStarted(placeType: String)
        case drivePracticeEnteredCourse(placeType: String)
        case drivePracticeCompleted(placeType: String)
        case drivePracticeCancelled(placeType: String)
        case myOpened
        case savedPlacesOpened
        case savedPlaceSelected
        case drivingGoalSaved(goalLengthBucket: String)
        case locationPermissionPrompted
        case locationPermissionResult(status: String)
        case logoutCompleted
        case withdrawalRequested
        case withdrawalRestored

        fileprivate var name: String {
            switch self {
            case .onboardingStarted: "onboarding_started"
            case .onboardingStepCompleted: "onboarding_step_completed"
            case .onboardingCompleted: "onboarding_completed"
            case .browseStarted: "browse_started"
            case .loginAttempted: "login_attempted"
            case .loginSucceeded: "login_succeeded"
            case .loginFailed: "login_failed"
            case .loginCancelled: "login_cancelled"
            case .homeMapReady: "home_map_ready"
            case .placeDetailOpened: "place_detail_opened"
            case .searchOpened: "search_opened"
            case .searchSubmitted: "search_submitted"
            case .searchResultsLoaded: "search_results_loaded"
            case .searchResultSelected: "search_result_selected"
            case .practiceFilterOpened: "practice_filter_opened"
            case .practiceFilterApplied: "practice_filter_applied"
            case .practiceFilterReset: "practice_filter_reset"
            case .bookmarkUpdated: "bookmark_updated"
            case .routeGuidanceOpened: "route_guidance_opened"
            case .routeGuidanceLaunchFailed: "external_navigation_launch_failed"
            case .courseRegistrationOpened: "course_registration_opened"
            case .courseRegistrationWaypointChanged: "course_registration_waypoint_changed"
            case .courseRegistrationPointSelected: "course_registration_point_selected"
            case .courseRegistrationRoutePrepared: "course_registration_route_prepared"
            case .courseRegistrationDetailsOpened: "course_registration_details_opened"
            case .courseRegistrationSubmitted: "course_registration_submitted"
            case .courseRegistrationCompleted: "course_registration_completed"
            case .courseRegistrationFailed: "course_registration_failed"
            case .myActivityOpened: "my_activity_opened"
            case .myCourseFilterChanged: "my_course_filter_changed"
            case .myCourseDeleted: "my_course_deleted"
            case .reviewWritingOpened: "review_writing_opened"
            case .reviewSubmitted: "review_submitted"
            case .reviewCompleted: "review_completed"
            case .reviewSubmissionFailed: "review_submission_failed"
            case .drivePracticeStarted: "practice_tracking_started"
            case .drivePracticeEnteredCourse: "practice_tracking_entered_course"
            case .drivePracticeCompleted: "practice_tracking_completed"
            case .drivePracticeCancelled: "practice_tracking_cancelled"
            case .myOpened: "my_opened"
            case .savedPlacesOpened: "saved_places_opened"
            case .savedPlaceSelected: "saved_place_selected"
            case .drivingGoalSaved: "driving_goal_saved"
            case .locationPermissionPrompted: "location_permission_prompted"
            case .locationPermissionResult: "location_permission_result"
            case .logoutCompleted: "logout_completed"
            case .withdrawalRequested: "withdrawal_requested"
            case .withdrawalRestored: "withdrawal_restored"
            }
        }

        fileprivate var parameters: [String: Any] {
            switch self {
            case .onboardingStarted(let entryMode):
                ["entry_mode": entryMode]
            case .onboardingStepCompleted(let step, let entryMode):
                ["step": step, "entry_mode": entryMode]
            case .onboardingCompleted(let entryMode, let memberLevel):
                ["entry_mode": entryMode, "member_level": memberLevel]
            case .browseStarted:
                [:]
            case .loginAttempted(let provider):
                ["provider": provider]
            case .loginSucceeded(let provider, let isNewMember):
                ["provider": provider, "is_new_member": isNewMember ? 1 : 0]
            case .loginFailed(let provider, let failureCategory):
                ["provider": provider, "failure_category": failureCategory]
            case .loginCancelled(let provider):
                ["provider": provider]
            case .homeMapReady(let entrySource, let hasLocationPermission):
                ["entry_source": entrySource, "has_location_permission": hasLocationPermission ? 1 : 0]
            case .placeDetailOpened(let source, let placeType):
                ["source": source, "place_type": placeType]
            case .searchOpened:
                [:]
            case .searchSubmitted(let inputSource, let queryLengthBucket):
                ["input_source": inputSource, "query_length_bucket": queryLengthBucket]
            case .searchResultsLoaded(let resultCountBucket, let hasRegionCandidates):
                ["result_count_bucket": resultCountBucket, "has_region_candidates": hasRegionCandidates ? 1 : 0]
            case .searchResultSelected(let resultType, let source):
                ["result_type": resultType, "source": source]
            case .practiceFilterOpened(let presentation):
                ["presentation": presentation]
            case .practiceFilterApplied(let category, let selectedTagCount, let isAll):
                ["category": category, "selected_tag_count": selectedTagCount, "is_all": isAll ? 1 : 0]
            case .practiceFilterReset:
                [:]
            case .bookmarkUpdated(let isBookmarked, let source, let placeType):
                ["is_bookmarked": isBookmarked ? 1 : 0, "source": source, "place_type": placeType]
            case .routeGuidanceOpened(let navigationProvider, let placeType, let source):
                ["navigation_provider": navigationProvider, "place_type": placeType, "source": source]
            case .routeGuidanceLaunchFailed(let navigationProvider, let placeType):
                ["navigation_provider": navigationProvider, "place_type": placeType]
            case .courseRegistrationOpened:
                [:]
            case .courseRegistrationWaypointChanged(let action, let waypointCount):
                ["action": action, "waypoint_count": waypointCount]
            case .courseRegistrationPointSelected(let inputType, let source):
                ["input_type": inputType, "source": source]
            case .courseRegistrationRoutePrepared(let waypointCount):
                ["waypoint_count": waypointCount]
            case .courseRegistrationDetailsOpened:
                [:]
            case let .courseRegistrationSubmitted(waypointCount, practiceTypeCount, hasCaution):
                [
                    "waypoint_count": waypointCount,
                    "practice_type_count": practiceTypeCount,
                    "has_caution": hasCaution ? 1 : 0
                ]
            case .courseRegistrationCompleted(let waypointCount):
                ["waypoint_count": waypointCount]
            case .courseRegistrationFailed(let stage):
                ["stage": stage]
            case .myActivityOpened(let tab):
                ["tab": tab]
            case .myCourseFilterChanged(let status):
                ["status": status]
            case .myCourseDeleted:
                [:]
            case .reviewWritingOpened(let mode):
                ["mode": mode]
            case .reviewSubmitted(let mode, let hasContent):
                ["mode": mode, "has_content": hasContent ? 1 : 0]
            case .reviewCompleted(let mode):
                ["mode": mode]
            case .reviewSubmissionFailed(let mode):
                ["mode": mode]
            case .drivePracticeStarted(let placeType),
                 .drivePracticeEnteredCourse(let placeType),
                 .drivePracticeCompleted(let placeType),
                 .drivePracticeCancelled(let placeType):
                ["place_type": placeType]
            case .myOpened, .savedPlacesOpened, .savedPlaceSelected, .logoutCompleted, .withdrawalRequested, .withdrawalRestored:
                [:]
            case .drivingGoalSaved(let goalLengthBucket):
                ["goal_length_bucket": goalLengthBucket]
            case .locationPermissionPrompted:
                [:]
            case .locationPermissionResult(let status):
                ["status": status]
            }
        }
    }

    static func track(_ event: Event) {
        FirebaseAnalyticsTracker.track(name: event.name, parameters: event.parameters)
    }

    static func setUserContext(
        userMode: String,
        loginProvider: String?,
        memberLevel: String?,
        hasDrivingGoal: Bool?
    ) {
        FirebaseAnalyticsTracker.setUserProperty(userMode, forName: "user_mode")
        FirebaseAnalyticsTracker.setUserProperty(loginProvider, forName: "login_provider")
        FirebaseAnalyticsTracker.setUserProperty(memberLevel, forName: "member_level")
        FirebaseAnalyticsTracker.setUserProperty(
            hasDrivingGoal.map { $0 ? "true" : "false" },
            forName: "has_driving_goal"
        )
    }

    static func lengthBucket(for value: String) -> String {
        switch value.count {
        case 0: "empty"
        case 1...2: "1_2"
        case 3...5: "3_5"
        case 6...10: "6_10"
        default: "11_plus"
        }
    }

    static func countBucket(for count: Int) -> String {
        switch count {
        case 0: "0"
        case 1...4: "1_4"
        case 5...9: "5_9"
        case 10...19: "10_19"
        default: "20_plus"
        }
    }
}
