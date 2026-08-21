import CoreLocation
import SwiftUI

struct MyPermissionSettingsView: View {
    let backAction: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = Store(
        state: MyPermissionSettingsReducer.State(),
        reducer: MyPermissionSettingsReducer(adapter: .init())
    )

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "권한 설정 변경", backAction: backAction)
            VStack(spacing: 32) {
                permissionSettingButton(
                    title: "위치",
                    status: locationAuthorizationTitle,
                    description: "내 위치 확인과 주행 거리 측정에 사용해요."
                )
                permissionSettingButton(
                    title: "실시간 현황",
                    status: liveActivityAuthorizationTitle,
                    description: "앱을 나가도 주행 상태와 진행률을 확인해요."
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            Spacer()
        }
        .background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
        .onAppear { store.send(.appeared) }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            store.send(.appBecameActive)
        }
    }

    private var locationAuthorizationTitle: String {
        switch store.state.locationAuthorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: "허용됨"
        case .denied, .restricted: "허용 안 됨"
        case .notDetermined: "설정 필요"
        @unknown default: "설정 필요"
        }
    }

    private var liveActivityAuthorizationTitle: String {
        store.state.areLiveActivitiesEnabled ? "허용됨" : "허용 필요"
    }

    private func permissionSettingButton(title: String, status: String, description: String) -> some View {
        Button { store.send(.settingsTapped) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(title).rodiTypography(.body1Medium).foregroundStyle(RodiColor.black)

                    Spacer()

                    Text(status).rodiTypography(.body1Medium).foregroundStyle(RodiColor.gray600)

                    Image("ic_chevron_right_20")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(RodiColor.gray600)
                        .frame(width: 20, height: 20)
                }
                Text(description).rodiTypography(.caption2Medium).foregroundStyle(RodiColor.gray600)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
