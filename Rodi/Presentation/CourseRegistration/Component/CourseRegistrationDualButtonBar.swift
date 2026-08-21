import SwiftUI

struct CourseRegistrationDualButtonBar: View {
    let leadingTitle: String
    let isLeadingEnabled: Bool
    let leadingAction: () -> Void
    let trailingTitle: String
    let isTrailingEnabled: Bool
    let trailingAction: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Button(action: leadingAction) {
                Text(leadingTitle)
                    .rodiTypography(.buttonMedium)
                    .foregroundStyle(isLeadingEnabled ? RodiColor.gray800 : RodiColor.gray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(RodiColor.gray300, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .disabled(!isLeadingEnabled)

            Button(action: trailingAction) {
                Text(trailingTitle)
                    .rodiTypography(.buttonMedium)
                    .foregroundStyle(isTrailingEnabled ? RodiColor.white : RodiColor.gray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(isTrailingEnabled ? RodiColor.primary : RodiColor.gray300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!isTrailingEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RodiColor.gray200)
                .frame(height: 1)
        }
        .background(RodiColor.white)
    }
}
