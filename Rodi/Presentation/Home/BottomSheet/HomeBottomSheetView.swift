import SwiftUI

private enum CourseSheetDestination {
    case dismissed
    case resting
    case expanded
}

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
    @State private var activeCourseMeasurementDialog: ActiveCourseMeasurementDialogConfiguration?

    let state: HomeBottomSheetReducer.State
    let send: (HomeBottomSheetReducer.Action) -> Void
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let memberRepository: MemberRepository
    let bottomTabBarHeight: CGFloat
    let onCourseDetailHeightChanged: (CGFloat) -> Void
    let onParkingDetailHeightChanged: (CGFloat) -> Void
    let onVisibleHeightChanged: (CGFloat, Bool) -> Void
    let onCourseExpansionSettled: () -> Void
    let requestLocationPermission: () -> Void
    let presentLiveActivityPermissionDialog: (LiveActivityPermissionDialogConfiguration) -> Void
    let presentRouteGuidanceDialog: (RouteGuidanceAppDialogConfiguration) -> Void
    let debugReviewTestAction: () -> Void
    let debugHardWithdrawAction: @MainActor () async throws -> Void

    init(
        state: HomeBottomSheetReducer.State,
        send: @escaping (HomeBottomSheetReducer.Action) -> Void,
        userLocation: RodiCoordinate?,
        hasLocationPermission: Bool,
        memberRepository: MemberRepository,
        bottomTabBarHeight: CGFloat,
        onCourseDetailHeightChanged: @escaping (CGFloat) -> Void = { _ in },
        onParkingDetailHeightChanged: @escaping (CGFloat) -> Void = { _ in },
        onVisibleHeightChanged: @escaping (CGFloat, Bool) -> Void = { _, _ in },
        onCourseExpansionSettled: @escaping () -> Void = {},
        requestLocationPermission: @escaping () -> Void,
        presentLiveActivityPermissionDialog: @escaping (LiveActivityPermissionDialogConfiguration) -> Void = { _ in },
        presentRouteGuidanceDialog: @escaping (RouteGuidanceAppDialogConfiguration) -> Void = { _ in },
        debugReviewTestAction: @escaping () -> Void = {},
        debugHardWithdrawAction: @escaping @MainActor () async throws -> Void = {}
    ) {
        self.state = state
        self.send = send
        self.userLocation = userLocation
        self.hasLocationPermission = hasLocationPermission
        self.memberRepository = memberRepository
        self.bottomTabBarHeight = bottomTabBarHeight
        self.onCourseDetailHeightChanged = onCourseDetailHeightChanged
        self.onParkingDetailHeightChanged = onParkingDetailHeightChanged
        self.onVisibleHeightChanged = onVisibleHeightChanged
        self.onCourseExpansionSettled = onCourseExpansionSettled
        self.requestLocationPermission = requestLocationPermission
        self.presentLiveActivityPermissionDialog = presentLiveActivityPermissionDialog
        self.presentRouteGuidanceDialog = presentRouteGuidanceDialog
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

            if let configuration = activeCourseMeasurementDialog {
                ActiveCourseMeasurementDialog(
                    courseName: configuration.courseName,
                    continueAction: {
                        activeCourseMeasurementDialog = nil
                        configuration.continueAction()
                    },
                    endAction: {
                        activeCourseMeasurementDialog = nil
                        configuration.endAction()
                    }
                )
                .zIndex(1)
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

        return sheetHeight(baseHeight: courseDetailHeight, translation: panTranslation)
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
        dismissalOpacity(
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
        dismissalOpacity(
            visibleHeight: recommendationHeight,
            totalHeight: recommendationHeight(for: state.recommendList.presentation)
        )
    }

    @ViewBuilder
    private var sheetContent: some View {
        switch state.route {
        case .recommendList:
            recommendationSheet

        case .filter:
            fixedSheet(
                height: mediumHeight,
                dismissThreshold: 72,
                contentBottomInset: screenSafeAreaInsets.bottom
            ) {
                FilterBottomSheetView(
                    state: state.filter,
                    send: handleFilterAction
                )
            }

        case .courseDetail:
            if state.courseDetail.detail != nil {
                courseDetailSheet
            } else if state.resolvingPlaceID != nil || state.isDetailPresentationPending {
                recommendationSheet
            } else {
                EmptyView()
            }

        case .parkingDetail:
            if state.parkingDetail.detail != nil {
                fixedSheet(height: parkingSheetHeight, dismissThreshold: 48) {
                    ParkingDetailBottomSheetView(
                        state: state.parkingDetail,
                        send: handleParkingDetailAction,
                        userLocation: userLocation,
                        hasLocationPermission: hasLocationPermission,
                        memberRepository: memberRepository,
                        requestLocationPermission: requestLocationPermission,
                        presentActiveMeasurementDialog: { configuration in
                            activeCourseMeasurementDialog = configuration
                        },
                        presentLiveActivityPermissionDialog: presentLiveActivityPermissionDialog,
                        presentRouteGuidanceDialog: presentRouteGuidanceDialog
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, screenSafeAreaInsets.bottom)
                    .background {
                        BottomSheetContentHeightObserver(onHeightChanged: updateParkingDetailHeight)
                    }
                }
            } else if state.resolvingPlaceID != nil || state.isDetailPresentationPending {
                recommendationSheet
            } else {
                EmptyView()
            }
        }
    }

    private var recommendationSheet: some View {
        Group {
            if state.recommendList.presentation == .expanded {
                expandedRecommendationSheet
            } else {
                sheetChrome {
                    VStack(spacing: 0) {
                        dragHandle(
                            onChanged: updateRecommendationPan,
                            onEnded: settleRecommendation
                        )

                        RecommendListBottomSheetView(
                            state: state.recommendList,
                            send: { send(.recommendList($0)) },
                            debugReviewTestAction: debugReviewTestAction,
                            debugHardWithdrawAction: debugHardWithdrawAction
                        )
                        .padding(.bottom, screenSafeAreaInsets.bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(height: recommendationHeight, alignment: .top)
        .opacity(recommendationSheetOpacity)
    }

    private var expandedRecommendationSheet: some View {
        VStack(spacing: 0) {
            RecommendListBottomSheetView(
                state: state.recommendList,
                send: { send(.recommendList($0)) },
                debugReviewTestAction: debugReviewTestAction,
                debugHardWithdrawAction: debugHardWithdrawAction
            )
            .padding(.bottom, screenSafeAreaInsets.bottom)
        }
        .padding(.top, screenSafeAreaInsets.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RodiColor.white)
        .ignoresSafeArea()
    }

    private var courseDetailSheet: some View {
        Group {
            if state.courseDetail.presentation == .expandedDetail {
                Color.clear
            } else {
                VStack(spacing: 0) {
                    dragHandle(
                        onChanged: updateCoursePan,
                        onEnded: settleCourse
                    )

                    CourseDetailBottomSheetView(
                        state: state.courseDetail,
                        send: handleCourseDetailAction,
                        userLocation: userLocation,
                        hasLocationPermission: hasLocationPermission,
                        memberRepository: memberRepository,
                        requestLocationPermission: requestLocationPermission,
                        presentActiveMeasurementDialog: { configuration in
                            activeCourseMeasurementDialog = configuration
                        },
                        presentLiveActivityPermissionDialog: presentLiveActivityPermissionDialog,
                        presentRouteGuidanceDialog: presentRouteGuidanceDialog
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
                .background {
                    BottomSheetContentHeightObserver(onHeightChanged: updateCourseDetailHeight)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(height: courseSheetHeight, alignment: .top)
                .background(RodiColor.white)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                )
                .shadow(color: RodiColor.black.opacity(0.08), radius: 4, x: 0, y: -3)
                .opacity(
                    dismissalOpacity(
                        visibleHeight: courseSheetHeight,
                        totalHeight: courseDetailHeight
                    )
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func fixedSheet<Content: View>(
        height: CGFloat,
        dismissThreshold: CGFloat,
        contentBottomInset: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) -> some View {
        sheetChrome {
            VStack(spacing: 0) {
                dragHandle(
                    onChanged: updateDetailPan,
                    onEnded: { settleDetail(translation: $0, dismissThreshold: dismissThreshold) }
                )

                content()
                    .padding(.bottom, contentBottomInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(height: height, alignment: .top)
        .offset(y: fixedSheetOffset)
        .opacity(fixedSheetOpacity)
    }

    private func sheetChrome<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .background(RodiColor.white)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )
            .shadow(color: RodiColor.black.opacity(0.08), radius: 4, x: 0, y: -3)
    }

    private func dismissalOpacity(visibleHeight: CGFloat, totalHeight: CGFloat) -> CGFloat {
        guard totalHeight > 0 else { return 1 }
        let visibleRatio = visibleHeight / totalHeight
        return min(max((visibleRatio - 0.1) / 0.6, 0), 1)
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

    private func dragHandle(
        onChanged: @escaping (CGFloat) -> Void,
        onEnded: @escaping (CGFloat) -> Void
    ) -> some View {
        dragIndicator
            .frame(maxWidth: .infinity)
            .frame(height: dragHandleHeight, alignment: .top)
            .contentShape(Rectangle())
            .overlay {
                BottomSheetPanGestureView(
                    isEnabled: !isSettling,
                    onChanged: onChanged,
                    onEnded: onEnded
                )
            }
    }

    private var dragIndicator: some View {
        Capsule()
            .fill(RodiColor.gray400)
            .frame(width: 60, height: 4)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 24, alignment: .top)
    }

}

private struct ActiveCourseMeasurementDialog: View {
    let courseName: String
    let continueAction: () -> Void
    let endAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog {
                VStack(spacing: 0) {
                    Text("‘\(courseName)’")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.primary)
                    Text("아직 코스를 연습 중이신가요?")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                        .padding(.top, 4)
                    Text("코스 주행을 이어서 측정할까요?")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    HStack(spacing: 8) {
                        ReviewDialogButton(title: "측정 종료", isPrimary: false, action: endAction)
                        ReviewDialogButton(title: "계속 측정", isPrimary: true, action: continueAction)
                    }
                    .padding(.top, 24)
                }
            } closeAction: {
                continueAction()
            }
        }
    }
}

private struct BottomSheetContentHeightObserver: UIViewRepresentable {
    let onHeightChanged: (CGFloat) -> Void

    func makeUIView(context: Context) -> HeightObservingView {
        HeightObservingView(onHeightChanged: onHeightChanged)
    }

    func updateUIView(_ uiView: HeightObservingView, context: Context) {
        uiView.onHeightChanged = onHeightChanged
    }

    final class HeightObservingView: UIView {
        var onHeightChanged: (CGFloat) -> Void
        private var lastReportedHeight: CGFloat = 0

        init(onHeightChanged: @escaping (CGFloat) -> Void) {
            self.onHeightChanged = onHeightChanged
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let height = bounds.height
            guard height > 0,
                  abs(lastReportedHeight - height) > 0.5
            else {
                return
            }

            lastReportedHeight = height
            DispatchQueue.main.async { [weak self] in
                self?.onHeightChanged(height)
            }
        }
    }
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
        sheetHeight(
            baseHeight: state.recommendList.presentation == .expanded ? screenHeight : mediumHeight,
            translation: translation
        )
    }

    private func sheetHeight(baseHeight: CGFloat, translation: CGFloat) -> CGFloat {
        min(max(baseHeight - translation, 0), screenHeight)
    }

    private func settleRecommendation(translation: CGFloat) {
        let adjustedTranslation = isRecommendationEmptyResult ? max(translation, 0) : translation
        let currentHeight = recommendationHeight(for: adjustedTranslation)
        let destination = recommendationDestination(for: currentHeight)
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
        let currentHeight = sheetHeight(baseHeight: courseDetailHeight, translation: translation)
        let destination = courseDestination(for: currentHeight)
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

    private func courseDestination(for height: CGFloat) -> CourseSheetDestination {
        if height <= max(courseDetailHeight - 48, 0) {
            return .dismissed
        }
        if height / screenHeight >= 0.55 {
            return .expanded
        }
        return .resting
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

    private func recommendationDestination(
        for height: CGFloat
    ) -> RecommendListBottomSheetReducer.Presentation {
        let heightRatio = height / screenHeight

        if heightRatio <= 0.45 {
            return .collapsed
        }
        if heightRatio >= 0.55 {
            return .expanded
        }
        return .medium
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
