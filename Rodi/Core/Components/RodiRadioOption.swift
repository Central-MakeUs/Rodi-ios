import SwiftUI

struct RodiRadioOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? RodiColor.primary : RodiColor.white)
                        .frame(width: 20, height: 20)

                    Circle()
                        .stroke(isSelected ? RodiColor.primary : RodiColor.gray300, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(RodiColor.white)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 24, height: 24)

                Text(title)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)
            }
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
