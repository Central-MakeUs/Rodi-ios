//
//  MemberAPI.swift
//  Rodi
//

import Alamofire
import Foundation

enum MemberAPI: TargetType {
    case myProfile
    case updateDrivingGoal(MemberDrivingGoalUpdateRequestDTO)
    case updatePlaceFilterTags(MemberPlaceFilterTagsUpdateRequestDTO)
    case withdraw
    case hardWithdraw
    case block(memberID: Int)
    case blockedMembers(query: BlockedMemberQuery)
    case unblock(memberID: Int)
    case submitOnboarding(MemberOnboardingRequestDTO)
    case completeCourseTutorial

    var method: HTTPMethod {
        switch self {
        case .myProfile:
            .get
            
        case .updateDrivingGoal:
            .patch
            
        case .updatePlaceFilterTags:
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
        case .myProfile, .updateDrivingGoal, .withdraw:
            "/api/v1/members/me"

        case .hardWithdraw:
            "/api/v1/members/me/hard"

        case .block(let memberID):
            "/api/v1/members/\(memberID)/block"

        case .blockedMembers:
            "/api/v1/members/me/blocks"

        case .unblock(let memberID):
            "/api/v1/members/\(memberID)/block"
            
        case .updatePlaceFilterTags:
            "/api/v1/members/me/filter-tags"
            
        case .submitOnboarding:
            "/api/v1/members/me/onboarding"
        case .completeCourseTutorial:
            "/api/v1/members/me/course-tutorial"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? {
        guard case .blockedMembers(let query) = self else { return nil }

        var parameters: Parameters = ["size": query.size]
        if let cursor = query.cursor, !cursor.isEmpty {
            parameters["cursor"] = cursor
        }
        return parameters
    }

    var body: Data? {
        switch self {
        case .myProfile, .withdraw, .hardWithdraw, .block, .blockedMembers, .unblock, .completeCourseTutorial:
            nil
            
        case .updateDrivingGoal(let request):
            requestToBody(request)
            
        case .updatePlaceFilterTags(let request):
            requestToBody(request)
            
        case .submitOnboarding(let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .blockedMembers:
            .url
        case .myProfile, .updateDrivingGoal, .updatePlaceFilterTags, .withdraw, .hardWithdraw, .block, .unblock, .submitOnboarding, .completeCourseTutorial:
            .json
        }
    }

    var requiresAuthentication: Bool { true }

    var timeoutInterval: TimeInterval? {
        switch self {
        case .myProfile:
            20
        case .updateDrivingGoal, .updatePlaceFilterTags, .withdraw, .hardWithdraw, .block, .blockedMembers, .unblock, .submitOnboarding, .completeCourseTutorial:
            nil
        }
    }
}
