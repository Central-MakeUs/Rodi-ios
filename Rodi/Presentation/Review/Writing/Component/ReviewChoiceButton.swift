import SwiftUI

struct ReviewChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .rodiTypography(.body3Medium)
                .foregroundStyle(isSelected ? RodiColor.white : RodiColor.gray800)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(isSelected ? RodiColor.primary : RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? RodiColor.primary : RodiColor.gray300, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 44)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
