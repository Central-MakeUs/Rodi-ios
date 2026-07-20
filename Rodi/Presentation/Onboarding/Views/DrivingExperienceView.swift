//
//  DrivingExperienceView.swift
//  Rodi
//

import SwiftUI

struct DrivingExperienceView: View {
    let selectedPeriod: LicenseDrivingPeriod?
    let selectedFrequency: RecentDrivingFrequency?
    let selectedRoadExperiences: [RoadDrivingExperience]
    let selectedSoloDrivingRange: SoloDrivingRange?
    let selectedSoloParkingLevel: SoloParkingLevel?
    let canProceed: Bool
    let onSelectPeriod: (LicenseDrivingPeriod) -> Void
    let onSelectFrequency: (RecentDrivingFrequency) -> Void
    let onToggleRoadExperience: (RoadDrivingExperience) -> Void
    let onSelectSoloDrivingRange: (SoloDrivingRange) -> Void
    let onSelectSoloParkingLevel: (SoloParkingLevel) -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    title

                    questions
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 24)
            }

            PrimaryBottomButton(
                title: "다음",
                isEnabled: canProceed,
                showsDivider: true,
                action: onNext
            )
        }
        .animation(.easeInOut(duration: 0.2), value: selectedPeriod)
        .animation(.easeInOut(duration: 0.2), value: selectedFrequency)
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

    @ViewBuilder
    private var questions: some View {
        VStack(alignment: .leading, spacing: 32) {
            OnboardingSection(title: "면허 취득 후 실제 운전한 기간을 알려주세요") {
                chipGroup(LicenseDrivingPeriod.allCases, selected: selectedPeriod, action: onSelectPeriod)
            }

            if selectedPeriod != nil {
                OnboardingSection(title: "가장 최근, 운전을 언제 하셨나요?") {
                    chipGroup(RecentDrivingFrequency.allCases, selected: selectedFrequency, action: onSelectFrequency)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if selectedFrequency != nil {
                OnboardingSection(title: "면허 취득후 도로주행을 해본 적이 있나요?", trailing: "복수선택") {
                    OnboardingChipFlow {
                        ForEach(RoadDrivingExperience.allCases) { experience in
                            OnboardingChip(
                                title: experience.rawValue,
                                isSelected: selectedRoadExperiences.contains(experience),
                                action: { onToggleRoadExperience(experience) }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if selectedRoadExperiences.contains(.soloPractice) {
                soloDrivingQuestions
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var soloDrivingQuestions: some View {
        VStack(alignment: .leading, spacing: 32) {
            OnboardingSection(title: "혼자 운전할 때 주로 어디까지 가보셨나요?") {
                chipGroup(
                    SoloDrivingRange.allCases,
                    selected: selectedSoloDrivingRange,
                    action: onSelectSoloDrivingRange
                )
            }

            OnboardingSection(title: "혼자 주차는 어느 정도까지 가능한가요?") {
                chipGroup(
                    SoloParkingLevel.allCases,
                    selected: selectedSoloParkingLevel,
                    action: onSelectSoloParkingLevel
                )
            }
        }
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
