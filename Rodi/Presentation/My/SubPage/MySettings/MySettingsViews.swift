//
//  MySettingsViews.swift
//  Rodi
//

import SwiftUI

struct MySettingsView: View {
    let backAction: () -> Void
    let navigate: (MyRoute) -> Void

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "설정", backAction: backAction)
            VStack(spacing: 0) {
                navigationButton("권한 설정 변경", to: .permissions)
                navigationButton("약관 다시보기", to: .terms)
                navigationButton("데이터 출처", to: .dataSource)
                navigationButton("오픈소스 라이센스", to: .licenses)
                navigationButton("계정정보 관리", to: .accountManagement)
                navigationButton("차단목록", to: .blockedMembers)
                HStack {
                    Text("버전").rodiTypography(.body1Medium)
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
                        .rodiTypography(.body1Medium)
                }
                .foregroundStyle(RodiColor.black)
                .frame(height: 45)
            }
            .padding(.horizontal, 16)
            .buttonStyle(.plain)
            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func navigationButton(_ title: String, to route: MyRoute) -> some View {
        Button { navigate(route) } label: { MyNavigationRow(title: title) }
    }
}
