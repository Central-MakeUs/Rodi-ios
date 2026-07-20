//
//  OnboardingAnalysisDialog.swift
//  Rodi
//

import ImageIO
import SwiftUI
import UIKit

struct OnboardingAnalysisDialog: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("연습 유형 분석 중")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray800)

                AnimatedGIFView(assetName: "img_onboarding_analysis")
                    .frame(width: 170, height: 150)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 56)
            .frame(width: 290, height: UIScreen.main.bounds.height * 0.5)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct OnboardingAnalysisCompletionDialog: View {
    let analysis: MemberOnboardingAnalysis
    let recentFrequency: RecentDrivingFrequency?
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("연습 유형 분석 완료!")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                Image("img_profile_dummy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 14)

                Text(analysis.level.displayName)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)
                    .padding(.top, 10)

                Text(analysis.level.description(recentFrequency: recentFrequency))
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)

                Divider()
                    .overlay(RodiColor.primaryMinus100)
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 8) {
                    Text("추천 연습 유형")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.black)

                    FlowLayout(spacing: 8) {
                        ForEach(analysis.level.recommendedPracticeTitles, id: \.self) { title in
                            Text(title)
                                .rodiTypography(.caption1Medium)
                                .foregroundStyle(RodiColor.gray800)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RodiColor.primary50)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)

                Button(action: onConfirm) {
                    Text("확인")
                        .rodiTypography(.buttonMedium)
                        .foregroundStyle(RodiColor.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .background(RodiColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 22)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
            .frame(width: 290)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityAddTraits(.isModal)
    }
}

private extension MemberOnboardingSubmission.DrivingLevel {
    var displayName: String {
        switch self {
        case .seed: "Seed"
        case .rookie: "Rookie"
        case .owner: "Owner"
        case .explorer: "Explorer"
        case .navigator: "Navigator"
        }
    }

    var recommendedPracticeTitles: [String] {
        switch self {
        case .seed:
            ["직선주행", "좌우 회전", "차선변경"]
        case .rookie:
            ["유턴", "교차로", "주차"]
        case .owner:
            ["고속진입", "합류", "다차로 주행"]
        case .explorer:
            ["비보호 좌회전", "회전 교차로", "좁은 도로 주행", "코너링"]
        case .navigator:
            ["코스 등록", "리뷰 작성", "추천 코스 공유"]
        }
    }

    func description(recentFrequency: RecentDrivingFrequency?) -> String {
        let frequency: String
        switch recentFrequency {
        case .almostNever: frequency = "잘 안"
        case .oneToTwoMonthly: frequency = "가끔"
        case .onceWeekly: frequency = "종종"
        case .twoToThreeWeekly: frequency = "자주"
        case .fourOrMoreWeekly: frequency = "거의 매일"
        case .none: frequency = ""
        }

        switch self {
        case .seed:
            return frequency.isEmpty
                ? "도로에서 직접 핸들 잡는 게 아직 낯설어요."
                : "혼자서 \(frequency) 나가는데,도로에서 직접 핸들 잡는 게 아직 낯설어요."
        case .rookie:
            return "교차로·유턴이 아직 긴장돼요."
        case .owner:
            return "고속도로 합류·다차로 주행이 아직 어려워요."
        case .explorer:
            return "더 다양한 상황들을 연습하고 싶어요."
        case .navigator:
            return "길잡이로 함께해요. 익숙한 운전 경험을 바탕으로 다른 운전자에게 도움이 되는 코스를 남겨보세요."
        }
    }
}

private struct AnimatedGIFView: UIViewRepresentable {
    let assetName: String
    private let displaySize = CGSize(width: 170, height: 150)

    func makeUIView(context: Context) -> GIFImageView {
        let imageView = GIFImageView(intrinsicSize: displaySize)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = animatedImage(named: assetName)
        return imageView
    }

    func updateUIView(_ imageView: GIFImageView, context: Context) {}

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: GIFImageView,
        context: Context
    ) -> CGSize? {
        displaySize
    }

    private func animatedImage(named name: String) -> UIImage? {
        guard let data = NSDataAsset(name: name)?.data,
              let source = CGImageSourceCreateWithData(data as CFData, nil)
        else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        guard frameCount > 0 else { return nil }

        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for index in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))
            duration += frameDuration(at: index, source: source)
        }

        guard !images.isEmpty else { return nil }
        return UIImage.animatedImage(with: images, duration: max(duration, 0.1))
    }

    private func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.1
        }

        let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval
        let delay = unclamped ?? (gifProperties[kCGImagePropertyGIFDelayTime] as? TimeInterval) ?? 0.1
        return max(delay, 0.02)
    }
}

private final class GIFImageView: UIImageView {
    private let fixedIntrinsicSize: CGSize

    init(intrinsicSize: CGSize) {
        fixedIntrinsicSize = intrinsicSize
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        fixedIntrinsicSize
    }
}
