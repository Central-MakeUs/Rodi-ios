//
//  RodiBottomTabBar.swift
//  Rodi
//

import SwiftUI

struct RodiBottomTabBar: View {
    let selectedTab: RodiTab
    let homeAction: () -> Void
    let myAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                title: "홈",
                iconName: selectedTab == .home ? "ic_tab_home_active" : "ic_tab_home_inactive",
                isSelected: selectedTab == .home,
                action: homeAction
            )

            Spacer(minLength: 0)

            tabButton(
                title: "마이",
                iconName: selectedTab == .my ? "ic_tab_my_active" : "ic_tab_my_inactive",
                isSelected: selectedTab == .my,
                action: myAction
            )
        }
        .frame(width: 160)
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(RodiColor.white)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityElement(children: .contain)
    }

    private func tabButton(
        title: String,
        iconName: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.pretendard(size: 13, weight: .semibold))
                    .tracking(-0.26)
                    .foregroundStyle(isSelected ? Color(hex: 0x1A1A1A) : Color(hex: 0xBEBEBE))
            }
            .frame(width: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
