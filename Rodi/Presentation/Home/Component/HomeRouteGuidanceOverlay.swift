import SwiftUI

/// Home이 선택된 장소의 길안내 dialog를 한 곳에서 조립한다.
struct HomeRouteGuidanceOverlay: View {
    let presentation: RouteGuidanceFlowPresentation?
    let routeOnlyAction: () -> Void
    let openSettingsAction: () -> Void
    let closeAction: () -> Void
    let appSelectedAction: (RouteGuidanceApp, Bool) -> Void
    let installSelectedAction: (RouteGuidanceApp) -> Void
    let activeMeasurementEndedAction: () -> Void

    var body: some View {
        ZStack {
            liveActivityPermissionDialog
            routeGuidanceDialog
            activeMeasurementDialog
        }
    }

    @ViewBuilder
    private var liveActivityPermissionDialog: some View {
        if presentation == .liveActivityPermission {
            LiveActivityPermissionDialog(
                routeOnlyAction: routeOnlyAction,
                openSettingsAction: openSettingsAction,
                closeAction: closeAction
            )
            .zIndex(10)
        }
    }

    @ViewBuilder
    private var routeGuidanceDialog: some View {
        if let presentation,
           let mode = dialogMode(for: presentation) {
            RouteGuidanceAppDialog(
                mode: mode,
                closeAction: closeAction,
                onceAction: { app in appSelectedAction(app, false) },
                alwaysAction: { app in appSelectedAction(app, true) },
                installAction: installSelectedAction
            )
            .zIndex(11)
        }
    }

    @ViewBuilder
    private var activeMeasurementDialog: some View {
        if case let .activeMeasurement(courseName) = presentation {
            ActiveCourseMeasurementDialog(
                courseName: courseName,
                continueAction: closeAction,
                endAction: activeMeasurementEndedAction
            )
            .zIndex(12)
        }
    }

    private func dialogMode(for presentation: RouteGuidanceFlowPresentation) -> RouteGuidanceAppDialog.Mode? {
        switch presentation {
        case .chooseApp: .choose
        case .installApp: .install
        case .activeMeasurement, .liveActivityPermission: nil
        }
    }
}
