//
//  OnboardingDrivingExperienceView.swift
//  Rodi
//

import SwiftUI

struct OnboardingDrivingExperienceView: View {
    let state: OnboardingDrivingExperienceReducer.State
    let send: (OnboardingDrivingExperienceReducer.Action) -> Void

    private var answers: OnboardingDrivingExperienceReducer.Answers {
        state.answers
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    title
                    questions
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            PrimaryBottomButton(
                title: "다음",
                isEnabled: answers.canProceed,
                showsDivider: true,
                action: { send(.nextTapped) }
            )
        }
        .animation(.easeInOut(duration: 0.2), value: answers.licenseDrivingPeriod)
        .animation(.easeInOut(duration: 0.2), value: answers.recentDrivingFrequency)
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
                chipGroup(
                    LicenseDrivingPeriod.allCases,
                    selected: answers.licenseDrivingPeriod,
                    action: { send(.selectLicenseDrivingPeriod($0)) }
                )
            }

            if answers.licenseDrivingPeriod != nil {
                OnboardingSection(title: "가장 최근, 운전을 언제 하셨나요?") {
                    chipGroup(
                        RecentDrivingFrequency.allCases,
                        selected: answers.recentDrivingFrequency,
                        action: { send(.selectRecentDrivingFrequency($0)) }
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if answers.recentDrivingFrequency != nil {
                OnboardingSection(title: "면허 취득후 도로주행을 해본 적이 있나요?", trailing: "복수선택") {
                    RodiChipFlow {
                        ForEach(RoadDrivingExperience.allCases) { experience in
                            RodiSelectionChip(
                                title: experience.rawValue,
                                isSelected: answers.selectedRoadDrivingExperiences.contains(experience),
                                action: { send(.toggleRoadDrivingExperience(experience)) }
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if answers.selectedRoadDrivingExperiences.contains(.soloPractice) {
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
                    selected: answers.soloDrivingRange,
                    action: { send(.selectSoloDrivingRange($0)) }
                )
            }

            OnboardingSection(title: "혼자 주차는 어느 정도까지 가능한가요?") {
                chipGroup(
                    SoloParkingLevel.allCases,
                    selected: answers.soloParkingLevel,
                    action: { send(.selectSoloParkingLevel($0)) }
                )
            }
        }
    }

    private func chipGroup<Option: Identifiable & RawRepresentable & Equatable>(
        _ options: [Option],
        selected: Option?,
        action: @escaping (Option) -> Void
    ) -> some View where Option.RawValue == String {
        RodiChipFlow {
            ForEach(options) { option in
                RodiSelectionChip(
                    title: option.rawValue,
                    isSelected: option == selected,
                    action: { action(option) }
                )
            }
        }
    }
}
