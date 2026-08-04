//
//  HomeBottomSheetManager.swift
//  Rodi
//

import Foundation

struct HomeBottomSheetManager: Reducer {
    enum Content: Equatable {
        // 추천 목록
        case placeList
        
        // 필터
        case filter
        
        //
        case placeDetail
    }

    struct State: Equatable {
        var content: Content = .placeList
        var detent: HomeBottomSheetState = .collapsed
        var height: CGFloat = 0
        var containerHeight: CGFloat = 0
        var selectedContentHeight: CGFloat = 0

        var isFilterPresented: Bool {
            content == .filter
        }
    }

    enum Action {
        case presentList(mediumHeight: CGFloat)
        case presentFilter(mediumHeight: CGFloat)
        case dismissFilter(mediumHeight: CGFloat)
        case presentDetail(mediumHeight: CGFloat)
        case dismissDetail
        case dismissSheet
        case expand(availableHeight: CGFloat)
        case collapse(mediumHeight: CGFloat)
        case resetToMedium(mediumHeight: CGFloat)
        case containerHeightChanged(CGFloat)
        case selectedContentHeightChanged(CGFloat)
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .presentList(let mediumHeight):
            state.content = .placeList
            state.detent = .medium
            state.height = mediumHeight

        case .presentFilter(let mediumHeight):
            state.content = .filter
            state.detent = .medium
            state.height = mediumHeight

        case .dismissFilter(let mediumHeight):
            state.content = .placeList
            state.detent = .medium
            state.height = mediumHeight

        case .presentDetail(let mediumHeight):
            state.content = .placeDetail
            state.detent = .medium
            state.height = mediumHeight
            state.selectedContentHeight = 0

        case .dismissDetail:
            state.content = .placeList
            state.selectedContentHeight = 0

        case .dismissSheet:
            state.content = .placeList
            state.detent = .collapsed
            state.height = 0
            state.selectedContentHeight = 0

        case .expand(let availableHeight):
            guard state.content == .placeList else { return .none }
            state.detent = .expanded
            state.height = availableHeight

        case .collapse(let mediumHeight), .resetToMedium(let mediumHeight):
            guard state.content != .filter else { return .none }
            state.detent = .medium
            state.height = mediumHeight

        case .containerHeightChanged(let height):
            state.containerHeight = max(height, 0)

        case .selectedContentHeightChanged(let height):
            state.selectedContentHeight = max(height, 0)
        }

        return .none
    }
}
