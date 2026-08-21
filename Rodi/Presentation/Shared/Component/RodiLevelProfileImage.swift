//
//  RodiLevelProfileImage.swift
//  Rodi
//

import SwiftUI

/// 레벨별 rabbit asset을 일관된 비율로 보여주는 공용 프로필 이미지입니다.
struct RodiLevelProfileImage: View {
    struct Config {
        enum Level: String {
            case seed = "SEED"
            case rookie = "ROOKIE"
            case owner = "OWNER"
            case explorer = "EXPLORER"
            case navigator = "NAVIGATOR"

            var name: String {
                rawValue
            }

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

        let level: Level?
        let assetName: String
        let size: CGFloat
        let containerHeight: CGFloat
        let backgroundColor: Color?
        let cornerRadius: CGFloat
        let imageOffsetY: CGFloat

        init(
            level: Level? = nil,
            assetName: String,
            size: CGFloat,
            containerHeight: CGFloat? = nil,
            backgroundColor: Color? = nil,
            cornerRadius: CGFloat = 0,
            imageOffsetY: CGFloat = 10
        ) {
            self.level = level
            self.assetName = assetName
            self.size = size
            self.containerHeight = containerHeight ?? size
            self.backgroundColor = backgroundColor
            self.cornerRadius = cornerRadius
            self.imageOffsetY = imageOffsetY
        }
    }

    private let assetName: String
    private let size: CGFloat
    private let containerHeight: CGFloat
    private let backgroundColor: Color?
    private let cornerRadius: CGFloat
    private let imageOffsetY: CGFloat

    init(
        level: MemberProfile.Level,
        size: CGFloat,
        containerHeight: CGFloat? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        imageOffsetY: CGFloat = 10
    ) {
        self.init(config: .init(
            assetName: level.profileImageAssetName,
            size: size,
            containerHeight: containerHeight,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            imageOffsetY: imageOffsetY
        ))
    }

    init(
        level: MemberOnboardingSubmission.DrivingLevel,
        size: CGFloat,
        containerHeight: CGFloat? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        imageOffsetY: CGFloat = 10
    ) {
        self.init(config: .init(
            assetName: level.profileImageAssetName,
            size: size,
            containerHeight: containerHeight,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            imageOffsetY: imageOffsetY
        ))
    }

    init(
        level: ReviewLevel,
        size: CGFloat,
        containerHeight: CGFloat? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 0,
        imageOffsetY: CGFloat = 10
    ) {
        self.init(config: .init(
            assetName: level.profileImageAssetName,
            size: size,
            containerHeight: containerHeight,
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            imageOffsetY: imageOffsetY
        ))
    }

    init(config: Config) {
        assetName = config.assetName
        size = config.size
        containerHeight = config.containerHeight
        backgroundColor = config.backgroundColor
        cornerRadius = config.cornerRadius
        imageOffsetY = config.imageOffsetY
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
        .frame(width: size, height: containerHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .accessibilityHidden(true)
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

private extension ReviewLevel {
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
