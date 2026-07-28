//
//  MainTabRouter.swift
//  Rodi
//
//  Created by mac on 7/28/26.
//

import Combine

enum MainTabIntent: Equatable {
    case presentHomeList
    case openHomePlace(id: Int)
    case openMyProfile
    case openMySavedPlaces
}

@MainActor
final class MainTabRouter: ObservableObject {
    @Published private(set) var selectedTab: RodiTab = .home
    @Published private(set) var navigationIntent: MainTabIntent?

    func selectHomeTab() {
        if selectedTab == .home {
            navigate(to: .presentHomeList)
        } else {
            selectedTab = .home
        }
    }

    func selectMyTab() {
        selectedTab = .my
    }

    func navigate(to intent: MainTabIntent) {
        switch intent {
        case .presentHomeList, .openHomePlace:
            selectedTab = .home
        case .openMyProfile, .openMySavedPlaces:
            selectedTab = .my
        }

        navigationIntent = intent
    }

    func consumeNavigationIntent() {
        navigationIntent = nil
    }
}
