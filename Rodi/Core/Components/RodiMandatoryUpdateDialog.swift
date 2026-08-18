import SwiftUI

struct RodiMandatoryUpdateDialog: View {
    let updateAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 20, trailing: 20)) {
                VStack(spacing: 0) {
                    Text("업데이트가 필요해요")
                        .rodiTypography(.headline1)
                        .foregroundStyle(RodiColor.black)

                    Text("최신 버전으로 업데이트한 후\n서비스를 계속 이용할 수 있어요.")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray700)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)

                    Button(action: updateAction) {
                        Text("업데이트")
                            .rodiTypography(.buttonMedium)
                            .foregroundStyle(RodiColor.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RodiColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                    .accessibilityLabel("앱 업데이트")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}
