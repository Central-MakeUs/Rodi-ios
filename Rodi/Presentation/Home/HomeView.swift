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
    
    private let onBottomSheetStateChanged: (HomeBottomSheetState) -> Void
    
    private let bottomTabBarHeight: CGFloat
    
    private let placeRepository: PlaceRepository
    
    private let memberRepository: MemberRepository
    
    private let recentSearchRepository: RecentSearchRepository
    
    private let tokenStore: TokenStoring

    init(
        router: HomeRouter,
        isHomeTabSelected: @escaping () -> Bool,
        onAuthenticationRequired: @escaping () -> Void,
        onBottomSheetStateChanged: @escaping (HomeBottomSheetState) -> Void,
        bottomTabBarHeight: CGFloat,
        dependencies: AppDependencies
    ) {
        self.router = router
        self.isHomeTabSelected = isHomeTabSelected
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onBottomSheetStateChanged = onBottomSheetStateChanged
        self.bottomTabBarHeight = bottomTabBarHeight
        placeRepository = dependencies.placeRepository
        memberRepository = dependencies.memberRepository
        recentSearchRepository = dependencies.recentSearchRepository
        tokenStore = dependencies.tokenStore
        
        _homeStore = StateObject(
            wrappedValue: Store(
                state: HomeReducer.State(),
                reducer: HomeReducer(
                    placeRepository: dependencies.placeRepository,
                    memberRepository: dependencies.memberRepository,
                    tokenStore: dependencies.tokenStore
                )
            )
        )
    }

    var body: some View {
        HomeBottomSheetView(
            homeStore: homeStore,
            router: router,
            isHomeTabSelected: isHomeTabSelected,
            onSearchRequested: presentSearch,
            bottomTabBarHeight: bottomTabBarHeight,
            placeRepository: placeRepository
        )
        .homeInteractions(
            homeStore: homeStore,
            openSettingsAction: openAppSettings
        )
        .onChange(of: homeStore.state.presentation.authenticationRequestID) { requestID in
            guard requestID > 0 else { return }
            onAuthenticationRequired()
        }
        .onAppear {
            onBottomSheetStateChanged(homeStore.state.bottomSheet.bottomSheetState)
        }
        .onChange(of: homeStore.state.bottomSheet.bottomSheetState) { state in
            onBottomSheetStateChanged(state)
        }
        .fullScreenCover(item: searchPresentationBinding) { presentation in
            switch presentation {
            case .search(let origin):
                HomeSearchView(
                    origin: origin,
                    onPlaceSelected: { placeID, placeName in
                        router.completeSearch(placeID: placeID, name: placeName)
                    },
                    onDismiss: router.dismissPresentation,
                    placeRepository: placeRepository,
                    recentSearchRepository: recentSearchRepository
                )
            }
        }
    }
}

extension HomeView {
    
    private func openAppSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }
        UIApplication.shared
            .open(
                url, options: [:]
            ) { didOpen in
                RodiLogger.info(
                    "Open system app settings requested url=\(url.absoluteString), didOpen=\(didOpen)")
        }
    }

    private func presentSearch() {
        guard [
            tokenStore.accessToken,
            tokenStore.refreshToken
        ].contains(
            where: {
                $0?.isEmpty == false
            }) else {
            onAuthenticationRequired()
            return
        }
        
        router
            .presentSearch(
                origin: homeStore.state.map.userLocationCoordinate ?? .southKoreaCenter
            )
    }

    private var searchPresentationBinding: Binding<HomePresentation?> {
        Binding(
            get: { router.presentedPresentation },
            set: { presentation in
                if presentation == nil {
                    router.dismissPresentation()
                }
            }
        )
    }

}

