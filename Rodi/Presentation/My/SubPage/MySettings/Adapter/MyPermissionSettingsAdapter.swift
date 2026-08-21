import ActivityKit
import CoreLocation

@MainActor
struct MyPermissionSettingsAdapter {
    struct Snapshot: Equatable {
        let locationAuthorizationStatus: CLAuthorizationStatus
        let areLiveActivitiesEnabled: Bool
    }

    func snapshot() -> Snapshot {
        .init(
            locationAuthorizationStatus: CLLocationManager().authorizationStatus,
            areLiveActivitiesEnabled: ActivityAuthorizationInfo().areActivitiesEnabled
        )
    }

    func openSettings() {
        AppSettings.openSetting()
    }
}
