//
//  RecentSearchAPI.swift
//  Rodi
//

import Alamofire
import Foundation

enum RecentSearchAPI: TargetType {
    case list
    case register(RecentSearchRegisterRequestDTO)
    case delete(id: Int)
    case deleteAll

    var method: HTTPMethod {
        switch self {
        case .list:
            .get
        case .register:
            .post
        case .delete, .deleteAll:
            .delete
        }
    }

    var path: String {
        switch self {
        case .list, .register, .deleteAll:
            "/api/v1/members/me/recent-searches"
        case .delete(let id):
            "/api/v1/members/me/recent-searches/\(id)"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }
    var parameters: Parameters? { nil }
    var body: Data? {
        guard case .register(let request) = self else { return nil }
        return requestToBody(request)
    }
    var encodingType: EncodingType { .json }
    var requiresAuthentication: Bool { true }
}
