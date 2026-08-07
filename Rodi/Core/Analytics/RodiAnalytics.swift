//
//  RodiAnalytics.swift
//  Rodi
//

import FirebaseAnalytics
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
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    static func setUserContext(
        userMode: String,
        loginProvider: String?,
        memberLevel: String?,
        hasDrivingGoal: Bool?
    ) {
        Analytics.setUserProperty(userMode, forName: "user_mode")
        Analytics.setUserProperty(loginProvider, forName: "login_provider")
        Analytics.setUserProperty(memberLevel, forName: "member_level")
        Analytics.setUserProperty(hasDrivingGoal.map { $0 ? "true" : "false" }, forName: "has_driving_goal")
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
