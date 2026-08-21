import SwiftUI

struct HomeBottomSheetView: View {
    @Environment(\.screenBounds) private var screenBounds
    @Environment(\.screenSafeAreaInsets) private var screenSafeAreaInsets
    @State private var settlingRecommendationHeight: CGFloat?
    @State private var settlingCourseHeight: CGFloat?
    @State private var settlingDetailOffset: CGFloat?
    @State private var settlementToken = UUID()
    @State private var settlementTask: Task<Void, Never>?
    @State private var panTranslation: CGFloat = 0
    @State private var courseDetailHeight: CGFloat = 180
    @State private var parkingDetailHeight: CGFloat = 180

    let state: HomeBottomSheetReducer.State
    let send: (HomeBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let bottomTabBarHeight: CGFloat
    let onCourseDetailHeightChanged: (CGFloat) -> Void
    let onParkingDetailHeightChanged: (CGFloat) -> Void
    let onVisibleHeightChanged: (CGFloat, Bool) -> Void
    let onCourseExpansionSettled: () -> Void
    let requestLocationPermission: () -> Void
    let debugReviewTestAction: () -> Void
    let debugHardWithdrawAction: () async throws -> Void

    init(
        state: HomeBottomSheetReducer.State,
        send: @escaping (HomeBottomSheetReducer.Action) -> Void,
        userLocation: RodiCoordinate?,
        hasLocationPermission: Bool,
        bottomTabBarHeight: CGFloat,
        onCourseDetailHeightChanged: @escaping (CGFloat) -> Void = { _ in },
        onParkingDetailHeightChanged: @escaping (CGFloat) -> Void = { _ in },
        onVisibleHeightChanged: @escaping (CGFloat, Bool) -> Void = { _, _ in },
        onCourseExpansionSettled: @escaping () -> Void = {},
        requestLocationPermission: @escaping () -> Void,
        debugReviewTestAction: @escaping () -> Void = {},
        debugHardWithdrawAction: @escaping () async throws -> Void = {}
    ) {
        self.state = state
        self.send = send
        self.userLocation = userLocation
        self.hasLocationPermission = hasLocationPermission
        self.bottomTabBarHeight = bottomTabBarHeight
        self.onCourseDetailHeightChanged = onCourseDetailHeightChanged
        self.onParkingDetailHeightChanged = onParkingDetailHeightChanged
        self.onVisibleHeightChanged = onVisibleHeightChanged
        self.onCourseExpansionSettled = onCourseExpansionSettled
        self.requestLocationPermission = requestLocationPermission
        self.debugReviewTestAction = debugReviewTestAction
        self.debugHardWithdrawAction = debugHardWithdrawAction
    }

    var body: some View {
        sheetContainer
            .ignoresSafeArea(edges: .bottom)
        .onAppear(perform: reportVisibleHeight)
        .onChange(of: state.route) { _ in
            reportVisibleHeight()
        }
        .onChange(of: state.recommendList.presentation) { _ in
            reportVisibleHeight()
        }
        .onChange(of: state.courseDetail.presentation) { _ in
            reportVisibleHeight()
        }
        .onDisappear(perform: cancelSettlement)
    }

    private var sheetContainer: some View {
        ZStack(alignment: .bottom) {
            if isRecommendationCollapsed {
                HomeListButton(action: presentRecommendationList)
                    .padding(.bottom, bottomTabBarHeight + 12)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showsSheet {
                sheetContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(!isSettling)
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}


// MARK: - Layout
extension HomeBottomSheetView {

    private var screenHeight: CGFloat {
        max(screenBounds?.height ?? 0, 1)
    }

    private var mediumHeight: CGFloat {
        screenHeight * 0.5
    }

    private var isRecommendationCollapsed: Bool {
        state.route == .recommendList && state.recommendList.presentation == .collapsed
    }

    private func presentRecommendationList() {
        guard isRecommendationCollapsed else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            send(.recommendList(.present))
        }
    }

    private var showsSheet: Bool {
        !isRecommendationCollapsed
    }

    private var recommendationHeight: CGFloat {
        if let settlingRecommendationHeight {
            return settlingRecommendationHeight
        }

        let baseHeight = state.recommendList.presentation == .expanded ? screenHeight : mediumHeight
        return min(max(baseHeight - panTranslation, 0), screenHeight)
    }

    private var courseSheetHeight: CGFloat {
        if let settlingCourseHeight {
            return settlingCourseHeight
        }

        guard state.courseDetail.presentation == .sheet else {
            return screenHeight
        }

        return HomeBottomSheetLayout.sheetHeight(
            baseHeight: courseDetailHeight,
            translation: panTranslation,
            screenHeight: screenHeight
        )
    }

    private var fixedSheetOffset: CGFloat {
        if let settlingDetailOffset {
            return settlingDetailOffset
        }

        return max(panTranslation, 0)
    }

    private var visibleSheetHeight: CGFloat {
        guard showsSheet else { return 0 }

        switch state.route {
        case .recommendList:
            return recommendationHeight
        case .filter, .parkingDetail:
            return max(fixedSheetHeight - fixedSheetOffset, 0)
        case .courseDetail:
            return courseSheetHeight
        }
    }

    private var isSettling: Bool {
        settlingRecommendationHeight != nil
            || settlingCourseHeight != nil
            || settlingDetailOffset != nil
    }

    private var fixedSheetOpacity: CGFloat {
        HomeBottomSheetLayout.dismissalOpacity(
            visibleHeight: fixedSheetHeight - fixedSheetOffset,
            totalHeight: fixedSheetHeight
        )
    }

    private var fixedSheetHeight: CGFloat {
        switch state.route {
        case .filter:
            return mediumHeight
        case .parkingDetail:
            return parkingSheetHeight
        case .courseDetail:
            return courseSheetHeight
        case .recommendList:
            return recommendationHeight(for: state.recommendList.presentation)
        }
    }

    private var recommendationSheetOpacity: CGFloat {
        HomeBottomSheetLayout.dismissalOpacity(
            visibleHeight: recommendationHeight,
            totalHeight: recommendationHeight(for: state.recommendList.presentation)
        )
    }

    @ViewBuilder
    private var sheetContent: some View {
        HomeBottomSheetRouteContent(
            state: state,
            screenSafeAreaInsets: screenSafeAreaInsets,
            recommendationHeight: recommendationHeight,
            recommendationOpacity: recommendationSheetOpacity,
            fixedSheetHeight: fixedSheetHeight,
            fixedSheetOffset: fixedSheetOffset,
            fixedSheetOpacity: fixedSheetOpacity,
            courseSheetHeight: courseSheetHeight,
            courseDetailHeight: courseDetailHeight,
            parkingSheetHeight: parkingSheetHeight,
            isSettling: isSettling,
            userLocation: userLocation,
            hasLocationPermission: hasLocationPermission,
            debugReviewTestAction: debugReviewTestAction,
            debugHardWithdrawAction: debugHardWithdrawAction,
            recommendationPanChanged: updateRecommendationPan,
            recommendationPanEnded: settleRecommendation,
            detailPanChanged: updateDetailPan,
            detailPanEnded: { settleDetail(translation: $0, dismissThreshold: $1) },
            coursePanChanged: updateCoursePan,
            coursePanEnded: settleCourse,
            sendRecommendation: { send(.recommendList($0)) },
            sendFilter: handleFilterAction,
            sendCourseDetail: handleCourseDetailAction,
            sendParkingDetail: handleParkingDetailAction,
            requestLocationPermission: requestLocationPermission,
            courseDetailHeightChanged: updateCourseDetailHeight,
            parkingDetailHeightChanged: updateParkingDetailHeight
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func reportVisibleHeight() {
        onVisibleHeightChanged(visibleSheetHeight, false)
    }

    private func updateCourseDetailHeight(_ height: CGFloat) {
        guard height > 0,
              abs(courseDetailHeight - height) > 0.5
        else {
            return
        }

        courseDetailHeight = height
        onCourseDetailHeightChanged(height)
    }

    private func updateParkingDetailHeight(_ height: CGFloat) {
        guard height > 0,
              abs(parkingDetailHeight - height) > 0.5
        else {
            return
        }

        parkingDetailHeight = height
        onParkingDetailHeightChanged(parkingSheetHeight)
    }

    /// 주차장 콘텐츠 높이에는 fixedSheet가 추가하는 indicator 영역이 포함되지 않는다.
    /// 실제 화면·지도 제어에 사용하는 높이는 둘을 합친 값이어야 한다.
    private var parkingSheetHeight: CGFloat {
        parkingDetailHeight + dragHandleHeight
    }

    private var dragHandleHeight: CGFloat { 24 }

}

// MARK: - Gesture
extension HomeBottomSheetView {

    private func updateRecommendationPan(_ translation: CGFloat) {
        guard !isSettling else { return }
        let adjustedTranslation = isRecommendationEmptyResult ? max(translation, 0) : translation
        panTranslation = adjustedTranslation
        onVisibleHeightChanged(recommendationHeight(for: adjustedTranslation), true)
    }

    private func updateDetailPan(_ translation: CGFloat) {
        guard !isSettling else { return }
        panTranslation = max(translation, 0)
        onVisibleHeightChanged(max(fixedSheetHeight - panTranslation, 0), true)
    }

    private func updateCoursePan(_ translation: CGFloat) {
        guard !isSettling else { return }
        panTranslation = translation
        onVisibleHeightChanged(courseSheetHeight, true)
    }

    private func recommendationHeight(for translation: CGFloat) -> CGFloat {
        HomeBottomSheetLayout.sheetHeight(
            baseHeight: state.recommendList.presentation == .expanded ? screenHeight : mediumHeight,
            translation: translation,
            screenHeight: screenHeight
        )
    }

    private func settleRecommendation(translation: CGFloat) {
        let adjustedTranslation = isRecommendationEmptyResult ? max(translation, 0) : translation
        let currentHeight = recommendationHeight(for: adjustedTranslation)
        let destination = HomeBottomSheetLayout.recommendationDestination(
            height: currentHeight,
            screenHeight: screenHeight
        )
        let targetHeight = recommendationHeight(for: destination)
        let duration: TimeInterval
        switch destination {
        case .collapsed:
            duration = 0.1
        case .medium:
            duration = 0.20
        case .expanded:
            duration = 0
        }

        beginSettlement(
            immediately: {
                settlingRecommendationHeight = currentHeight
                panTranslation = 0
            },
            animate: {
                settlingRecommendationHeight = targetHeight
                onVisibleHeightChanged(targetHeight, true)
            },
            completion: {
                switch destination {
                case .collapsed:
                    send(.recommendList(.collapse))
                case .medium:
                    send(.recommendList(.present))
                case .expanded:
                    send(.recommendList(.expand))
                }
                settlingRecommendationHeight = nil
                onVisibleHeightChanged(0, false)
            },
            duration: duration
        )
    }

    private func settleDetail(
        translation: CGFloat,
        dismissThreshold: CGFloat,
        forceDismiss: Bool = false
    ) {
        let currentOffset = max(translation, 0)
        let dismissAction = detailDismissAction
        let shouldDismiss = (forceDismiss || currentOffset >= dismissThreshold) && dismissAction != nil
        let actionToSend = shouldDismiss ? dismissAction : nil
        let targetOffset = shouldDismiss ? screenHeight + 24 : 0

        beginSettlement(
            immediately: {
                settlingDetailOffset = currentOffset
                panTranslation = 0
            },
            animate: {
                settlingDetailOffset = targetOffset
                onVisibleHeightChanged(max(fixedSheetHeight - targetOffset, 0), true)
            },
            completion: {
                if let actionToSend {
                    send(actionToSend)
                }
                settlingDetailOffset = nil
                onVisibleHeightChanged(0, false)
            },
            duration: shouldDismiss ? 0.25 : 0.22
        )
    }

    private func settleCourse(translation: CGFloat) {
        let currentHeight = HomeBottomSheetLayout.sheetHeight(
            baseHeight: courseDetailHeight,
            translation: translation,
            screenHeight: screenHeight
        )
        let destination = HomeBottomSheetLayout.courseDestination(
            height: currentHeight,
            restingHeight: courseDetailHeight,
            screenHeight: screenHeight
        )
        let targetHeight: CGFloat
        let duration: TimeInterval

        switch destination {
        case .dismissed:
            targetHeight = 0
            duration = 0.25

        case .resting:
            targetHeight = courseDetailHeight
            duration = 0.22

        case .expanded:
            targetHeight = screenHeight
            duration = 0
        }

        beginSettlement(
            immediately: {
                settlingCourseHeight = currentHeight
                panTranslation = 0
            },
            animate: {
                settlingCourseHeight = targetHeight
                onVisibleHeightChanged(targetHeight, true)
            },
            completion: {
                switch destination {
                case .dismissed:
                    send(.courseDetail(.dismiss))

                case .resting:
                    break

                case .expanded:
                    onCourseExpansionSettled()
                }
                settlingCourseHeight = nil
                onVisibleHeightChanged(0, false)
            },
            duration: duration
        )
    }

    private func dismissCurrentDetail() {
        guard let action = detailDismissAction else { return }
        send(action)
    }

    private func handleFilterAction(_ action: FilterBottomSheetReducer.Action) {
        if case .dismiss = action {
            send(.filter(.dismiss))
        } else {
            send(.filter(action))
        }
    }

    private func handleCourseDetailAction(_ action: CourseDetailBottomSheetReducer.Action) {
        if case .dismiss = action {
            dismissCurrentDetail()
        } else {
            send(.courseDetail(action))
        }
    }

    private func handleParkingDetailAction(_ action: ParkingDetailBottomSheetReducer.Action) {
        if case .dismiss = action {
            dismissCurrentDetail()
        } else {
            send(.parkingDetail(action))
        }
    }

    private var detailDismissAction: HomeBottomSheetReducer.Action? {
        switch state.route {
        case .filter:
            .filter(.dismiss)
        case .courseDetail:
            .courseDetail(.dismiss)
        case .parkingDetail:
            .parkingDetail(.dismiss)
        case .recommendList:
            nil
        }
    }

    private var isRecommendationEmptyResult: Bool {
        state.recommendList.items.isEmpty
            && !state.recommendList.isInitialLoading
            && state.recommendList.errorMessage == nil
    }

    private func recommendationHeight(
        for presentation: RecommendListBottomSheetReducer.Presentation
    ) -> CGFloat {
        switch presentation {
        case .collapsed:
            0
        case .medium:
            mediumHeight
        case .expanded:
            screenHeight
        }
    }

    private func beginSettlement(
        immediately: () -> Void,
        animate: @escaping () -> Void,
        completion: @escaping () -> Void,
        duration: TimeInterval
    ) {
        settlementTask?.cancel()
        let token = UUID()
        settlementToken = token

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, immediately)

        DispatchQueue.main.async {
            guard settlementToken == token else { return }
            withAnimation(.easeOut(duration: duration), animate)
        }

        settlementTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, settlementToken == token else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction, completion)
            settlementTask = nil
        }
    }

    private func cancelSettlement() {
        settlementTask?.cancel()
        settlementTask = nil
        settlementToken = UUID()

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            panTranslation = 0
            settlingRecommendationHeight = nil
            settlingDetailOffset = nil
        }
        onVisibleHeightChanged(0, false)
    }
}
