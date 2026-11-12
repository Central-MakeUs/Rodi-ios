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
    var category: HomePracticeCategory?
    var selectedTypes: [PlacePracticeType] = []

    static let `default` = Self()

    var filterTags: [PlacePracticeType] {
        return selectedTypes
    }

    var showsPracticeTypeOptions: Bool {
        guard let category else { return false }
        return !category.options.isEmpty
    }

    var isAllSelected: Bool {
        guard let category, !category.options.isEmpty else { return false }
        return category.options.allSatisfy { selectedTypes.contains($0.type) }
    }

    mutating func selectCategory(_ category: HomePracticeCategory) {
        if self.category == category {
            if category == .parking {
                toggleParking()
            }
            self.category = nil
            return
        }

        self.category = category
        if category == .parking, !selectedTypes.contains(.parking) {
            selectedTypes.append(.parking)
        }
    }

    mutating func toggleType(_ type: PlacePracticeType) {
        guard let category, category != .parking else { return }
        if let index = selectedTypes.firstIndex(of: type) {
            selectedTypes.remove(at: index)
        } else {
            selectedTypes.append(type)
        }
    }

    mutating func selectAll() {
        guard let category, category != .parking else { return }
        for type in category.options.map(\.type) where !selectedTypes.contains(type) {
            selectedTypes.append(type)
        }
    }

    private mutating func toggleParking() {
        if let index = selectedTypes.firstIndex(of: .parking) {
            selectedTypes.remove(at: index)
        } else {
            selectedTypes.append(.parking)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case category
        case selectedTypes
    }

    init() {
        category = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyCategory = try container.decodeIfPresent(HomePracticeCategory.self, forKey: .category)
        selectedTypes = try container.decodeIfPresent([PlacePracticeType].self, forKey: .selectedTypes) ?? []
        if legacyCategory == .parking, !selectedTypes.contains(.parking) {
            selectedTypes.append(.parking)
        }
        category = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(selectedTypes, forKey: .selectedTypes)
    }
}
