//
//  PlaceTarget.swift
//  Rodi
//

import Alamofire
import Foundation

enum PlaceTarget: TargetType {
    case coordinates
    case list(PlaceListQuery)
    case authenticatedList(PlaceListQuery)
    case search(PlaceSearchQuery)
    case bookmarks(PlaceBookmarkListQuery)
    case detail(id: Int)
    case bookmark(id: Int)
    case unbookmark(id: Int)

    var method: HTTPMethod {
        switch self {
        case .coordinates, .list, .authenticatedList, .search, .bookmarks, .detail:
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
        case .list, .authenticatedList:
            "/api/v1/places"
        case .search:
            "/api/v1/places/search"
        case .bookmarks:
            "/api/v1/places/bookmarks"
        case .detail(let id):
            "/api/v1/places/\(id)"
        case .bookmark(let id), .unbookmark(let id):
            "/api/v1/places/\(id)/bookmark"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? {
        switch self {
        case .list(let query), .authenticatedList(let query):
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
        case .search(let query):
            var parameters: Parameters = [
                "keyword": query.keyword,
                "lat": query.currentLatitude,
                "lng": query.currentLongitude,
                "size": query.size
            ]
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters
        case .bookmarks(let query):
            var parameters: Parameters = ["size": query.size]
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters
        default:
            return nil
        }
    }

    var body: Data? { nil }

    var encodingType: EncodingType {
        switch self {
        case .list, .authenticatedList, .search, .bookmarks:
            .url
        default:
            .json
        }
    }

    var requiresAuthentication: Bool {
        switch self {
        case .authenticatedList, .search, .bookmarks, .detail, .bookmark, .unbookmark:
            true
        case .coordinates, .list:
            false
        }
    }
}
