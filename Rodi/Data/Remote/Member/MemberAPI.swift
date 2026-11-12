//
//  MemberAPI.swift
//  Rodi
//

import Alamofire
import Foundation

enum MemberAPI: TargetType {
    case myProfile
    case updateDrivingGoal(MemberDrivingGoalUpdateRequestDTO)
    case updateNickname(MemberNicknameUpdateRequestDTO)
    case withdraw
    case hardWithdraw
    case block(memberID: Int)
    case blockedMembers(query: BlockedMemberListQueryDTO)
    case unblock(memberID: Int)
    case submitOnboarding(MemberOnboardingRequestDTO)
    case completeCourseTutorial
    case onboardingForm
    case nicknameAvailability(MemberNicknameAvailabilityQueryDTO)
    case updateSortTags(MemberSortTagsUpdateRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .myProfile, .onboardingForm, .nicknameAvailability:
            .get
            
        case .updateDrivingGoal, .updateNickname:
            .patch
            
        case .updateSortTags:
            .put
            
        case .withdraw, .hardWithdraw:
            .delete

        case .block:
            .post

        case .blockedMembers:
            .get

        case .unblock:
            .delete
            
        case .submitOnboarding:
            .post
        case .completeCourseTutorial:
            .patch
        }
    }

    var path: String {
        switch self {
        case .myProfile, .updateDrivingGoal, .updateNickname, .withdraw:
            "/api/v1/members/me"

        case .hardWithdraw:
            "/api/v1/members/me/hard"

        case .block(let memberID):
            "/api/v1/members/\(memberID)/block"

        case .blockedMembers:
            "/api/v1/members/me/blocks"

        case .unblock(let memberID):
            "/api/v1/members/\(memberID)/block"
            
        case .submitOnboarding:
            "/api/v1/members/me/onboarding"
        case .completeCourseTutorial:
            "/api/v1/members/me/course-tutorial"
        case .onboardingForm:
            "/api/v1/members/me/onboarding-form"
        case .nicknameAvailability:
            "/api/v1/members/nickname/availability"
        case .updateSortTags:
            "/api/v1/members/me/sort-tags"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? {
        switch self {
        case .blockedMembers(let query):
            var parameters: Parameters = ["size": query.size]
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters
        case .nicknameAvailability(let query):
            return ["nickname": query.nickname]
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .myProfile, .withdraw, .hardWithdraw, .block, .blockedMembers, .unblock, .completeCourseTutorial, .onboardingForm, .nicknameAvailability:
            nil
            
        case .updateDrivingGoal(let request):
            requestToBody(request)
        case .updateNickname(let request):
            requestToBody(request)
            
        case .submitOnboarding(let request):
            requestToBody(request)
        case .updateSortTags(let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .blockedMembers, .onboardingForm, .nicknameAvailability:
            .url
        case .myProfile, .updateDrivingGoal, .updateNickname, .withdraw, .hardWithdraw, .block, .unblock, .submitOnboarding, .completeCourseTutorial, .updateSortTags:
            .json
        }
    }

    var requiresAuthentication: Bool { true }

    var timeoutInterval: TimeInterval? {
        switch self {
        case .myProfile:
            20
        case .updateDrivingGoal, .updateNickname, .withdraw, .hardWithdraw, .block, .blockedMembers, .unblock, .submitOnboarding, .completeCourseTutorial, .onboardingForm, .nicknameAvailability, .updateSortTags:
            nil
        }
    }
}
