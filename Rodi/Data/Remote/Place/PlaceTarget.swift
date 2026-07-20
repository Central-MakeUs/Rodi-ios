//
//  PlaceTarget.swift
//  Rodi
//

import Alamofire
import Foundation

enum PlaceTarget: TargetType {
    case coordinates
    case list(PlaceListQuery)
    case detail(id: Int)
    case bookmark(id: Int)
    case unbookmark(id: Int)

    var method: HTTPMethod {
        switch self {
        case .coordinates, .list, .detail:
            .get
        case .bookmark:
            .post
        case .unbookmark:
            .delete
        }
    }

    var path: String {
        switch self {
        case .coordinates:
            "/api/v1/places/coordinates"
        case .list:
            "/api/v1/places"
        case .detail(let id):
            "/api/v1/places/\(id)"
        case .bookmark(let id), .unbookmark(let id):
            "/api/v1/places/\(id)/bookmark"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? {
        guard case .list(let query) = self else { return nil }

        var parameters: Parameters = [
            "swLat": query.viewport.southWestLatitude,
            "swLng": query.viewport.southWestLongitude,
            "neLat": query.viewport.northEastLatitude,
            "neLng": query.viewport.northEastLongitude,
            "lat": query.currentLatitude,
            "lng": query.currentLongitude,
            "size": query.size
        ]
        if let cursor = query.cursor, !cursor.isEmpty {
            parameters["cursor"] = cursor
        }
        return parameters
    }

    var body: Data? { nil }

    var encodingType: EncodingType {
        switch self {
        case .list:
            .url
        default:
            .json
        }
    }

    var requiresAuthentication: Bool {
        switch self {
        case .detail, .bookmark, .unbookmark:
            true
        case .coordinates, .list:
            false
        }
    }
}
