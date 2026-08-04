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
        .shadow(color: Color(hex: 0x222222, alpha: 0.08), radius: 4, x: 0, y: -3)
        .ignoresSafeArea(edges: .bottom)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: RodiBottomTabBarHeightPreferenceKey.self,
                    value: proxy.size.height
                )
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: Layout
extension RodiBottomTabBar {
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

// 실제 탭 바가 화면에서 차지하는 높이를 Home의 지도 오버레이와 공유한다.
struct RodiBottomTabBarHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
