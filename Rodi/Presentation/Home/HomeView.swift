//
//  HomeView.swift
//  Rodi
//

import SwiftUI
import UIKit

/// Home feature의 진입점. Store와 Router를 만들고 화면 조합 View에 전달만 한다.
struct HomeView: View {
    @StateObject private var homeStore: StoreOf<HomeReducer>
    @ObservedObject private var router: HomeRouter
    private let isHomeTabSelected: () -> Bool
    private let onAuthenticationRequired: () -> Void
    private let placeRepository: PlaceRepository

    init(
        router: HomeRouter,
        isHomeTabSelected: @escaping () -> Bool,
        onAuthenticationRequired: @escaping () -> Void,
        placeRepository: PlaceRepository = AuthDependencyContainer.shared.placeRepository
    ) {
        self.router = router
        self.isHomeTabSelected = isHomeTabSelected
        self.onAuthenticationRequired = onAuthenticationRequired
        self.placeRepository = placeRepository
        _homeStore = StateObject(
            wrappedValue: Store(
                state: HomeReducer.State(),
                reducer: HomeReducer(placeRepository: placeRepository)
            )
        )
    }

    var body: some View {
        NavigationStack {
            HomeBottomSheetView(
                homeStore: homeStore,
                router: router,
                isHomeTabSelected: isHomeTabSelected,
                placeRepository: placeRepository
            )
        }
        .homeInteractions(
            homeStore: homeStore,
            openSettingsAction: openAppSettings
        )
        .onChange(of: homeStore.state.presentation.authenticationRequestID) { requestID in
            guard requestID > 0 else { return }
            onAuthenticationRequired()
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:]) { didOpen in
            RodiLogger.info("Open system app settings requested url=\(url.absoluteString), didOpen=\(didOpen)")
        }
    }

}
