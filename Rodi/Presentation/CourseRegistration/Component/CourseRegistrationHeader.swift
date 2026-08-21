import SwiftUI

struct CourseRegistrationHeader: View {
    let title: String
    let closeAction: () -> Void
    var trailingImageName: String? = nil
    var isTrailingEnabled = true
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Text(title)
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button(action: closeAction) {
                    Image("ic_chevron_left_24")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityLabel("뒤로 가기")

                Spacer()

                if let trailingImageName, let trailingAction {
                    Button(action: trailingAction) {
                        Image(trailingImageName)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .contentShape(Rectangle())
                    .disabled(!isTrailingEnabled)
                    .accessibilityLabel("완료")
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }
}
