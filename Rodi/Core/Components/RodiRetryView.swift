import SwiftUI

struct RodiRetryView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)

            RodiRetryButton(action: retryAction)
        }
        .multilineTextAlignment(.center)
    }
}

struct RodiRetryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("다시 시도")
                .rodiTypography(.body2Medium)
                .foregroundStyle(RodiColor.white)
                .padding(8)
                .background(RodiColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
