import SwiftUI

/// 지도 화면에서 네트워크 단절이 지속될 때 지도를 대신해 표시한다.
struct MapNetworkUnavailableView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("ic_network_inactive")
                .frame(width: 60, height: 60)

            Text("지도를 불러올 수 없어요")
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.gray800)

            Text("현재 위치 정보를 확인하기 위해\n네트워크 연결 상태를 확인해 주세요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray800)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RodiColor.white)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("네트워크 연결이 끊겨 지도를 불러올 수 없습니다")
    }
}
