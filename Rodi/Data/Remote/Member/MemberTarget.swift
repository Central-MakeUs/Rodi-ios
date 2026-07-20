//
//  MemberTarget.swift
//  Rodi
//

import Alamofire
import Foundation

enum MemberTarget: TargetType {
    case withdraw
    case submitOnboarding(MemberOnboardingRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .withdraw:
            .delete
        case .submitOnboarding:
            .post
        }
    }

    var path: String {
        switch self {
        case .withdraw:
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
        case .withdraw:
            nil
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
