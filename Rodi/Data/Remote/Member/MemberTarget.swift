//
//  MemberTarget.swift
//  Rodi
//

import Alamofire
import Foundation

enum MemberTarget: TargetType {
    case withdraw

    var method: HTTPMethod {
        .delete
    }

    var path: String {
        "/api/v1/members/me"
    }

    var optionalHeaders: HTTPHeaders? {
        nil
    }

    var parameters: Parameters? {
        nil
    }

    var body: Data? {
        nil
    }

    var encodingType: EncodingType {
        .json
    }

    var requiresAuthentication: Bool {
        true
    }
}
