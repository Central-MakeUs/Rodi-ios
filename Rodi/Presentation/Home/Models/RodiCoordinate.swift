//
//  RodiCoordinate.swift
//  Rodi
//

import Foundation

struct RodiCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    static let seoulCityHall = RodiCoordinate(latitude: 37.5665, longitude: 126.9780)
    static let southKoreaCenter = RodiCoordinate(latitude: 36.35, longitude: 127.85)

    func distanceKilometers(to other: RodiCoordinate) -> Double {
        let earthRadiusKilometers = 6371.0
        let latitudeDelta = (other.latitude - latitude) * .pi / 180
        let longitudeDelta = (other.longitude - longitude) * .pi / 180
        let startLatitude = latitude * .pi / 180
        let endLatitude = other.latitude * .pi / 180

        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + sin(longitudeDelta / 2) * sin(longitudeDelta / 2) * cos(startLatitude) * cos(endLatitude)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKilometers * c
    }
}
