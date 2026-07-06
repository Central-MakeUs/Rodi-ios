//
//  HomeRadiusFilter.swift
//  Rodi
//

import Foundation

enum HomeRadiusFilter: CaseIterable, Hashable {
    case all
    case three
    case five
    case ten

    var title: String {
        switch self {
        case .all:
            "전체"
        case .three:
            "3km"
        case .five:
            "5km"
        case .ten:
            "10km"
        }
    }

    var radiusKilometers: Double? {
        switch self {
        case .all:
            nil
        case .three:
            3
        case .five:
            5
        case .ten:
            10
        }
    }
}
