//
//  PlaceAPI.swift
//  Rodi
//

import Alamofire
import Foundation

enum PlaceAPI: TargetType {
    case coordinates
    case clusters(PlaceClusterQueryDTO)
    
    case list(PlaceListQueryDTO)
    
    case authenticatedList(PlaceListQueryDTO)
    
    case search(PlaceSearchQueryDTO)
    
    case relatedSearch(PlaceRelatedSearchQueryDTO)
    
    case bookmarks(PlaceBookmarkListQueryDTO)
    
    case detail(id: Int)
    
    case bookmark(id: Int)
    
    case unbookmark(id: Int)

    var method: HTTPMethod {
        switch self {
        case .coordinates, .clusters, .list, .authenticatedList, .search, .relatedSearch, .bookmarks, .detail:
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
        case .clusters:
            "/api/v1/places/clusters"
        case .list, .authenticatedList:
            "/api/v1/places"
        case .search:
            "/api/v1/places/search"
        case .relatedSearch:
            "/api/v1/places/related-search"
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
        case .clusters(let query):
            var parameters: Parameters = [
                "swLat": query.swLat,
                "swLng": query.swLng,
                "neLat": query.neLat,
                "neLng": query.neLng
            ]
            if let types = query.practiceTypes, !types.isEmpty {
                parameters["practiceTypes"] = types.joined(separator: ",")
            }
            return parameters
        case .list(let query), .authenticatedList(let query):
            var parameters: Parameters = [
                "swLat": query.southWestLatitude,
                "swLng": query.southWestLongitude,
                "neLat": query.northEastLatitude,
                "neLng": query.northEastLongitude,
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
        case .relatedSearch(let query):
            var parameters: Parameters = ["keyword": query.keyword, "size": query.size]
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
        case .clusters, .list, .authenticatedList, .search, .relatedSearch, .bookmarks:
            .url
        default:
            .json
        }
    }

    var requiresAuthentication: Bool {
        switch self {
        case .authenticatedList, .search, .relatedSearch, .bookmarks, .detail, .bookmark, .unbookmark:
            true
        case .coordinates, .clusters, .list:
            false
        }
    }
}
