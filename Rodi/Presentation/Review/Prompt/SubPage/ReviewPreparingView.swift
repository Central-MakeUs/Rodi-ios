import SwiftUI

struct ReviewPreparingView: View {
    var body: some View {
        RodiModalBackground {
            ProgressView()
                .tint(RodiColor.primary)
                .padding(28)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("후기 등록 준비 중")
        }
    }
}
