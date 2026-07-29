//
//  KoreanAdministrativeArea.swift
//  Rodi
//

import Foundation

enum KoreanAdministrativeAreaLevel: String, Codable, Equatable {
    case sido
    case sigungu
    case municipalCity
}

struct KoreanAdministrativeArea: Codable, Equatable, Identifiable {
    let id: String
    let level: KoreanAdministrativeAreaLevel
    let displayName: String
    let parentName: String?
    let aliases: [String]
    let latitude: Double
    let longitude: Double
    let zoomLevel: Int
    let southWestLatitude: Double
    let southWestLongitude: Double
    let northEastLatitude: Double
    let northEastLongitude: Double

    var coordinate: RodiCoordinate {
        RodiCoordinate(latitude: latitude, longitude: longitude)
    }

    var bounds: RodiMapBounds {
        RodiMapBounds(
            southWestLatitude: southWestLatitude,
            southWestLongitude: southWestLongitude,
            northEastLatitude: northEastLatitude,
            northEastLongitude: northEastLongitude
        )
    }

    var searchDisplayName: String {
        guard let parentName,
              level == .sigungu,
              parentName.hasSuffix("시")
        else {
            return displayName
        }

        let districtName = displayName
            .replacingOccurrences(of: "\(parentName) ", with: "")

        return "\(parentName.dropLast()) \(districtName)"
    }
}

struct KoreanAdministrativeAreaCatalog: Decodable {
    let areas: [KoreanAdministrativeArea]
}
