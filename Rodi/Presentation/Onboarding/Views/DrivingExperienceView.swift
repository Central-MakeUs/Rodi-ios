//
//  DrivingExperienceView.swift
//  Rodi
//

import SwiftUI

struct DrivingExperienceView: View {
    let selectedPeriod: LicenseDrivingPeriod?
    let selectedFrequency: RecentDrivingFrequency?
    let selectedRoadExperience: RoadDrivingExperience?
    let canProceed: Bool
    let onSelectPeriod: (LicenseDrivingPeriod) -> Void
    let onSelectFrequency: (RecentDrivingFrequency) -> Void
    let onSelectRoadExperience: (RoadDrivingExperience) -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    title

                    VStack(alignment: .leading, spacing: 32) {
                        OnboardingSection(title: "면허 취득 후 실제 운전한 기간을 알려주세요") {
                            chipGroup(LicenseDrivingPeriod.allCases, selected: selectedPeriod, action: onSelectPeriod)
                        }

                        OnboardingSection(title: "가장 최근, 운전을 언제 하셨나요?") {
                            chipGroup(RecentDrivingFrequency.allCases, selected: selectedFrequency, action: onSelectFrequency)
                        }

                        OnboardingSection(title: "면허 취득 후 도로 주행을 해본 적이 있나요?") {
                            chipGroup(RoadDrivingExperience.allCases, selected: selectedRoadExperience, action: onSelectRoadExperience)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 24)
            }

            PrimaryBottomButton(title: "다음", isEnabled: canProceed, action: onNext)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("운전 경험에 대해 알려주세요.")
                .rodiTypography(.heading2)
                .foregroundStyle(RodiColor.black)

            Text("자세히 입력할수록 더 잘 맞는 연습 장소를 추천해요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chipGroup<Option: Identifiable & RawRepresentable & Equatable>(
        _ options: [Option],
        selected: Option?,
        action: @escaping (Option) -> Void
    ) -> some View where Option.RawValue == String {
        OnboardingChipFlow {
            ForEach(options) { option in
                OnboardingChip(
                    title: option.rawValue,
                    isSelected: option == selected,
                    action: { action(option) }
                )
            }
        }
    }
}
