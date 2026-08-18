//
//  CourseRegistrationPlaceSearchModel.swift
//  Rodi
//

import Foundation

struct CourseRegistrationRegionSuggestion: Equatable, Identifiable {
    let id: String
    let displayName: String
    let searchQuery: String
}

struct CourseRegistrationPlaceSearchItem: Equatable, Identifiable {
    let id: String
    let title: String
    let address: String
    let coordinate: RodiCoordinate?
    let category: String?
    let phone: String?
}

struct CourseRegistrationPlaceSearchPage: Equatable {
    let items: [CourseRegistrationPlaceSearchItem]
    let isEnd: Bool
}
