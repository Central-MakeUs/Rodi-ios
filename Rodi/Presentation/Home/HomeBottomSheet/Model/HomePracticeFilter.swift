//
//  HomePracticeFilter.swift
//  Rodi
//

import Foundation

enum HomePracticeCategory: String, CaseIterable, Codable, Equatable {
    case basicDriving
    case urbanBasics
    case parking
    case trafficFlow
    case complexSituations

    var title: String {
        switch self {
        case .basicDriving: "기초 주행"
        case .urbanBasics: "도심 기본"
        case .parking: "주차"
        case .trafficFlow: "도로 흐름"
        case .complexSituations: "복합 상황"
        }
    }

    var options: [HomePracticeFilterOption] {
        switch self {
        case .basicDriving:
            [
                .init(type: .straight, title: "직선주행"),
                .init(type: .leftRightTurn, title: "좌우회전"),
                .init(type: .laneChange, title: "차선변경")
            ]
        case .urbanBasics:
            [
                .init(type: .intersection, title: "교차로"),
                .init(type: .uTurn, title: "유턴")
            ]
        case .parking:
            []
        case .trafficFlow:
            [
                .init(type: .multilane, title: "다차로주행"),
                .init(type: .merging, title: "합류"),
                .init(type: .highwayEntry, title: "고속진입")
            ]
        case .complexSituations:
            [
                .init(type: .roundabout, title: "회전교차로"),
                .init(type: .unprotectedLeftTurn, title: "비보호좌회전"),
                .init(type: .narrowRoad, title: "좁은도로"),
                .init(type: .cornering, title: "코너링")
            ]
        }
    }
}

struct HomePracticeFilterOption: Identifiable, Equatable {
    let type: PlacePracticeType
    let title: String

    var id: PlacePracticeType { type }
}

struct HomePracticeFilterSelection: Codable, Equatable {
    var category: HomePracticeCategory = .basicDriving
    var selectedTypes: [PlacePracticeType] = []
    var isAllSelected = false

    static let `default` = Self()

    var filterTags: [PlacePracticeType] {
        if category == .parking { return [.parking] }
        return selectedTypes
    }

    var showsPracticeTypeOptions: Bool {
        category != .parking
    }

    mutating func selectCategory(_ category: HomePracticeCategory) {
        self.category = category
        selectedTypes = []
        isAllSelected = false
    }

    mutating func toggleType(_ type: PlacePracticeType) {
        guard category != .parking else { return }
        if let index = selectedTypes.firstIndex(of: type) {
            selectedTypes.remove(at: index)
        } else {
            selectedTypes.append(type)
        }
        isAllSelected = selectedTypes.count == category.options.count
    }

    mutating func selectAll() {
        guard category != .parking else { return }
        selectedTypes = category.options.map(\.type)
        isAllSelected = true
    }
}
