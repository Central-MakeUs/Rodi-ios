//
//  RodiSnackbar.swift
//  Rodi
//

import SwiftUI

/// 앱 전역의 일회성 작업 결과와 안내에 사용하는 공통 스낵바입니다.
struct RodiSnackbar: View {
    let message: String

    var body: some View {
        Text(message)
            .rodiTypography(.body3Medium)
            .foregroundStyle(RodiColor.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(RodiColor.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct RodiSnackbarModifier: ViewModifier {
    let message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    GeometryReader { proxy in
                        RodiSnackbar(message: message)
                            .padding(.horizontal, 16)
                            .padding(.bottom, proxy.size.height * 0.14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .allowsHitTesting(false)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    /// 3초 자동 해제 정책은 호출 측의 상태 관리자에서 처리한다.
    func rodiSnackbar(message: String?) -> some View {
        modifier(RodiSnackbarModifier(message: message))
    }
}
