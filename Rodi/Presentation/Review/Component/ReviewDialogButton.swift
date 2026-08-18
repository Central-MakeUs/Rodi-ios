import SwiftUI

struct ReviewDialogButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .rodiTypography(.buttonMedium)
                .foregroundStyle(isPrimary ? RodiColor.white : RodiColor.gray800)
                .frame(width: 116, height: 42)
                .background(isPrimary ? RodiColor.primary : RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if !isPrimary {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(RodiColor.gray300, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 116, minHeight: 44)
        .accessibilityLabel(title)
    }
}
