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
    case submitOnboarding(MemberOnboardingRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .myProfile:
            .get
            
        case .updateDrivingGoal:
            .patch
            
        case .updatePlaceFilterTags:
            .put
            
        case .withdraw:
            .delete
            
        case .submitOnboarding:
            .post
        }
    }

    var path: String {
        switch self {
        case .myProfile, .updateDrivingGoal, .withdraw:
            "/api/v1/members/me"
            
        case .updatePlaceFilterTags:
            "/api/v1/members/me/filter-tags"
            
        case .submitOnboarding:
            "/api/v1/members/me/onboarding"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? { nil }

    var body: Data? {
        switch self {
        case .myProfile, .withdraw:
            nil
            
        case .updateDrivingGoal(let request):
            requestToBody(request)
            
        case .updatePlaceFilterTags(let request):
            requestToBody(request)
            
        case .submitOnboarding(let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType { .json }

    var requiresAuthentication: Bool { true }

    var timeoutInterval: TimeInterval? {
        switch self {
        case .myProfile:
            20
        case .updateDrivingGoal, .updatePlaceFilterTags, .withdraw, .submitOnboarding:
            nil
        }
    }
}
