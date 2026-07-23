//
//  RodiLevelProfileImage.swift
//  Rodi
//

import SwiftUI

/// 레벨별 rabbit asset을 일관된 비율로 보여주는 공용 프로필 이미지입니다.
struct RodiLevelProfileImage: View {
    private let assetName: String
    private let size: CGFloat
    private let backgroundColor: Color?
    private let cornerRadius: CGFloat
    private let imageOffsetY: CGFloat

    init(
        level: MemberProfile.Level,
        size: CGFloat,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        imageOffsetY: CGFloat = 10
    ) {
        self.init(
            assetName: level.profileImageAssetName,
            size: size,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            imageOffsetY: imageOffsetY
        )
    }

    init(
        level: MemberOnboardingSubmission.DrivingLevel,
        size: CGFloat,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        imageOffsetY: CGFloat = 10
    ) {
        self.init(
            assetName: level.profileImageAssetName,
            size: size,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            imageOffsetY: imageOffsetY
        )
    }

    var body: some View {
        ZStack {
            if let backgroundColor {
                backgroundColor
            }

            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: imageOffsetY)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
    }

    private init(
        assetName: String,
        size: CGFloat,
        backgroundColor: Color?,
        cornerRadius: CGFloat,
        imageOffsetY: CGFloat
    ) {
        self.assetName = assetName
        self.size = size
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.imageOffsetY = imageOffsetY
    }
}

private extension MemberProfile.Level {
    var profileImageAssetName: String {
        switch self {
        case .seed: "img_rabbit_seed"
        case .rookie: "img_rabbit_rookie"
        case .owner: "img_rabbit_owner"
        case .explorer: "img_rabbit_explorer"
        case .navigator: "img_rabbit_navigation"
        }
    }
}

private extension MemberOnboardingSubmission.DrivingLevel {
    var profileImageAssetName: String {
        switch self {
        case .seed: "img_rabbit_seed"
        case .rookie: "img_rabbit_rookie"
        case .owner: "img_rabbit_owner"
        case .explorer: "img_rabbit_explorer"
        case .navigator: "img_rabbit_navigation"
        }
    }
}
