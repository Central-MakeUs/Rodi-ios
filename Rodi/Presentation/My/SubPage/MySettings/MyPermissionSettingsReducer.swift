import CoreLocation

@MainActor
struct MyPermissionSettingsReducer: Reducer {
    struct State: Equatable {
        var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
        var areLiveActivitiesEnabled = false
    }

    enum Action {
        case appeared
        case appBecameActive
        case settingsTapped
    }

    private let adapter: MyPermissionSettingsAdapter

    init(adapter: MyPermissionSettingsAdapter) {
        self.adapter = adapter
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared, .appBecameActive:
            let snapshot = adapter.snapshot()
            state.locationAuthorizationStatus = snapshot.locationAuthorizationStatus
            state.areLiveActivitiesEnabled = snapshot.areLiveActivitiesEnabled

        case .settingsTapped:
            adapter.openSettings()
        }

        return .none
    }
}
