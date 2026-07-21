//
//  MemberTarget.swift
//  Rodi
//

import Alamofire
import Foundation

enum MemberTarget: TargetType {
    case myProfile
    case updateDrivingGoal(MemberDrivingGoalUpdateRequestDTO)
    case withdraw
    case submitOnboarding(MemberOnboardingRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .myProfile:
            .get
        case .updateDrivingGoal:
            .patch
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
        case .submitOnboarding:
            "/api/v1/members/me/onboarding"
        }
    }

    var optionalHeaders: HTTPHeaders? {
        nil
    }

    var parameters: Parameters? {
        nil
    }

    var body: Data? {
        switch self {
        case .myProfile, .withdraw:
            nil
        case .updateDrivingGoal(let request):
            requestToBody(request)
        case .submitOnboarding(let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        .json
    }

    var requiresAuthentication: Bool {
        true
    }
}
