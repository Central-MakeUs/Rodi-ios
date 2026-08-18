import SwiftUI

struct ReviewFormHeader: View {
    let title: String
    let showsBack: Bool
    var backAction: (() -> Void)?
    let closeAction: () -> Void

    var body: some View {
        RodiCenteredNavigationHeader(title: title) {
            Group {
                if showsBack, let backAction {
                    Button(action: backAction) {
                        Image("ic_chevron_left_24")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("이전 화면")
                } else {
                    Color.clear
                        .accessibilityHidden(true)
                }
            }
        } trailing: {
            Button(action: closeAction) {
                Image("ic_close")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("닫기")
        }
    }
}
