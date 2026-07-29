//
//  RecentSearchTarget.swift
//  Rodi
//

import Alamofire
import Foundation

enum RecentSearchTarget: TargetType {
    case list
    case delete(id: Int)
    case deleteAll

    var method: HTTPMethod {
        switch self {
        case .list:
            .get
        case .delete, .deleteAll:
            .delete
        }
    }

    var path: String {
        switch self {
        case .list, .deleteAll:
            "/api/v1/members/me/recent-searches"
        case .delete(let id):
            "/api/v1/members/me/recent-searches/\(id)"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }
    var parameters: Parameters? { nil }
    var body: Data? { nil }
    var encodingType: EncodingType { .json }
    var requiresAuthentication: Bool { true }
}
