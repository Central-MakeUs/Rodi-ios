//
//  WithdrawalAccountDialog.swift
//  Rodi
//

import SwiftUI

struct WithdrawalAccountDialog: View {
    let state: LoginWithdrawalDialogState
    let restoreAction: () -> Void
    let dismissAction: () -> Void

    var body: some View {
        Color.black
            .opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 0) {
                    Text("탈퇴 처리 중 계정")
                        .font(.pretendard(size: 16, weight: .bold))
                        .foregroundStyle(RodiColor.gray800)
                        .padding(.top, 32)

                    Text(message)
                        .font(.pretendard(size: 13, weight: .medium))
                        .foregroundStyle(RodiColor.gray700)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .frame(height: 76)

                    buttonRow
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                }
                .frame(width: 280)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.15), radius: 6)
            }
            .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var buttonRow: some View {
        switch state {
        case .restore:
            HStack(spacing: 8) {
                dialogButton(title: "예", style: .secondary, action: restoreAction)
                dialogButton(title: "아니오", style: .primary, action: dismissAction)
            }
            .padding(.horizontal, 20)

        case .rejoinLocked:
            dialogButton(title: "확인", style: .primary, action: dismissAction)
                .frame(width: 116)
        }
    }

    private var message: String {
        switch state {
        case .restore:
            return "계정을 복구하시겠습니까?"
        case .rejoinLocked(let rejoinAvailableAt):
            guard let rejoinAvailableAt else {
                return "현재는 재가입할 수 없어요."
            }
            return "\(Self.rejoinDateFormatter.string(from: rejoinAvailableAt)) 이후 재가입 가능해요."
        }
    }

    private func dialogButton(
        title: String,
        style: DialogButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.pretendard(size: 16, weight: .medium))
                .foregroundStyle(style.foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(style.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if style == .secondary {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(RodiColor.gray300, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private enum DialogButtonStyle {
        case primary
        case secondary

        var foreground: Color {
            switch self {
            case .primary: RodiColor.white
            case .secondary: RodiColor.gray800
            }
        }

        var background: Color {
            switch self {
            case .primary: RodiColor.primary
            case .secondary: RodiColor.white
            }
        }
    }

    private static let rejoinDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()
}
