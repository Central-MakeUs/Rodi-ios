import SwiftUI

struct MyAccountManagementView: View {
    let backAction: () -> Void
    let navigate: (MyRoute) -> Void
    let logoutAction: () -> Void
    let withdrawalAction: () -> Void
    @State private var confirmation: AccountConfirmation?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MySubpageHeader(title: "개인정보 관리", backAction: backAction)
                VStack(spacing: 0) {
                    Button { navigate(.contact) } label: { MyNavigationRow(title: "문의하기") }
                    Button { confirmation = .logout } label: { MyPlainRow(title: "로그아웃") }
                    Button { confirmation = .withdrawal } label: { MyPlainRow(title: "계정 삭제하기") }
                }
                .padding(.horizontal, 16)
                .buttonStyle(.plain)
                Spacer()
            }
            .background(RodiColor.white)
            .toolbar(.hidden, for: .navigationBar)

            if let confirmation {
                MyAccountConfirmationDialog(
                    confirmation: confirmation,
                    confirm: {
                        self.confirmation = nil
                        confirmation == .logout ? logoutAction() : withdrawalAction()
                    },
                    cancel: { self.confirmation = nil }
                )
            }
        }
    }
}

private enum AccountConfirmation: Equatable {
    case logout
    case withdrawal

    var title: String { self == .logout ? "로그아웃 하시겠습니까?" : "정말 계정을 삭제하시겠습니까?" }
    var message: String? { self == .logout ? nil : "삭제 후 3일 이내 재로그인 시 복구 가능합니다.  10일 이후 재가입 가능합니다." }
    var dialogHeight: CGFloat { self == .logout ? 189 : 226 }
}

private struct MyAccountConfirmationDialog: View {
    let confirmation: AccountConfirmation
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        Color.black.opacity(0.4).ignoresSafeArea().overlay {
            VStack(spacing: 0) {
                Text(confirmation.title)
                    .rodiTypography(.body1SemiBold).foregroundStyle(RodiColor.black).multilineTextAlignment(.center)
                    .frame(width: 240, height: confirmation.message == nil ? 60 : nil).padding(.top, 32)
                if let message = confirmation.message {
                    Text(message).rodiTypography(.caption1Medium).foregroundStyle(RodiColor.black).multilineTextAlignment(.center)
                        .frame(width: 240, height: 60).padding(.top, 16)
                }
                HStack(spacing: 8) {
                    Button(action: confirm) {
                        Text("예").rodiTypography(.body1Medium).foregroundStyle(RodiColor.gray800)
                            .frame(width: 116, height: 44).background(RodiColor.white).clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay { RoundedRectangle(cornerRadius: 8).stroke(RodiColor.gray300, lineWidth: 1) }
                    }
                    Button(action: cancel) {
                        Text("아니오").rodiTypography(.body1Medium).foregroundStyle(RodiColor.white)
                            .frame(width: 116, height: 44).background(RodiColor.primary).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .buttonStyle(.plain).padding(.top, 24)
                Spacer(minLength: 0)
            }
            .frame(width: 280, height: confirmation.dialogHeight)
            .background(RodiColor.white).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityElement(children: .contain)
    }
}
