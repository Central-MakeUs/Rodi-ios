import SwiftUI

struct RouteGuidanceAppDialog: View {
    enum Mode: Equatable {
        case choose
        case install

        var title: String {
            switch self {
            case .choose: "네비게이션 앱을 선택하세요"
            case .install: "길 안내를 위해 네비게이션 앱\n설치가 필요합니다."
            }
        }
    }

    let mode: Mode
    let closeAction: () -> Void
    let onceAction: (RouteGuidanceApp) -> Void
    let alwaysAction: (RouteGuidanceApp) -> Void
    let installAction: (RouteGuidanceApp) -> Void

    @State private var selectedApp: RouteGuidanceApp?

    var body: some View {
        RodiModalBackground {
            dialogContent
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var dialogContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: closeAction) {
                    Image("ic_close")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(RodiColor.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닫기")
            }

            Text(mode.title)
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, mode == .choose ? 0 : 8)

            HStack(spacing: 52) {
                appSelectionButton(.kakaoMap)
                appSelectionButton(.kakaoNavi)
            }
            .padding(.top, mode == .choose ? 20 : 28)

            switch mode {
            case .choose:
                HStack(spacing: 8) {
                    actionButton(title: "이번만", isPrimary: false) {
                        guard let selectedApp else { return }
                        onceAction(selectedApp)
                    }
                    actionButton(title: "항상", isPrimary: true) {
                        guard let selectedApp else { return }
                        alwaysAction(selectedApp)
                    }
                }
                .padding(.top, 20)
            case .install:
                actionButton(title: "설치하기", isPrimary: true) {
                    guard let selectedApp else { return }
                    installAction(selectedApp)
                }
                .padding(.top, 20)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(RodiColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func appSelectionButton(_ app: RouteGuidanceApp) -> some View {
        Button {
            selectedApp = app
        } label: {
            VStack(spacing: 12) {
                Image(app.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(app.displayName)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)
            }
            .frame(width: 76)
            .padding(.vertical, 6)
            .background(selectedApp == app ? RodiColor.gray100 : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(app.displayName)
        .accessibilityAddTraits(selectedApp == app ? .isSelected : [])
    }

    private func actionButton(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        let isEnabled = selectedApp != nil

        return Button(action: action) {
            Text(title)
                .rodiTypography(.buttonMedium)
                .foregroundStyle(buttonForegroundColor(isPrimary: isPrimary, isEnabled: isEnabled))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(buttonBackgroundColor(isPrimary: isPrimary, isEnabled: isEnabled))
                .overlay {
                    if !isPrimary {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isEnabled ? RodiColor.gray300 : RodiColor.gray200, lineWidth: 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func buttonBackgroundColor(isPrimary: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return RodiColor.gray200 }
        return isPrimary ? RodiColor.primary : RodiColor.white
    }

    private func buttonForegroundColor(isPrimary: Bool, isEnabled: Bool) -> Color {
        guard isEnabled else { return RodiColor.gray400 }
        return isPrimary ? RodiColor.white : RodiColor.gray800
    }
}
