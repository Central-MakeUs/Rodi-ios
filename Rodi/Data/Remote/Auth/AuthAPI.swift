//
//  AuthAPI.swift
//  Rodi
//

import Alamofire
import Foundation

enum AuthAPI: TargetType {
    case login(providerRawValue: String, request: SocialLoginRequestDTO)
    
    case restore(providerRawValue: String, request: SocialLoginRequestDTO)
    
    case refresh(request: TokenRefreshRequestDTO)
    
    case logout(request: LogoutRequestDTO)

    var method: HTTPMethod {
        .post
    }

    var path: String {
        switch self {
        case .login(let providerRawValue, _):
            "/api/v1/auth/oauth/\(providerRawValue)"
        case .restore(let providerRawValue, _):
            "/api/v1/auth/oauth/\(providerRawValue)/restore"
        case .refresh:
            "/api/v1/auth/token/refresh"
        case .logout:
            "/api/v1/auth/logout"
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
        case .login(_, let request):
            requestToBody(request)
        case .restore(_, let request):
            requestToBody(request)
        case .refresh(let request):
            requestToBody(request)
        case .logout(let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        .json
    }
}
