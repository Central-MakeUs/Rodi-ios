//
//  OptionalDrivingPreferenceView.swift
//  Rodi
//

import SwiftUI

struct OptionalDrivingPreferenceView: View {
    private enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let goalLimit = 30
    }

    let selectedPracticeSituations: [PracticeSituation]
    let selectedVehicleType: VehicleType?
    let drivingGoal: String
    let canProceed: Bool
    let onTogglePracticeSituation: (PracticeSituation) -> Void
    let onSelectVehicleType: (VehicleType) -> Void
    let onSkip: () -> Void
    let onNext: (String) -> Void

    @State private var goalText: String
    @State private var isGoalFieldFocused = false

    init(
        selectedPracticeSituations: [PracticeSituation],
        selectedVehicleType: VehicleType?,
        drivingGoal: String,
        canProceed: Bool,
        onTogglePracticeSituation: @escaping (PracticeSituation) -> Void,
        onSelectVehicleType: @escaping (VehicleType) -> Void,
        onSkip: @escaping () -> Void,
        onNext: @escaping (String) -> Void
    ) {
        self.selectedPracticeSituations = selectedPracticeSituations
        self.selectedVehicleType = selectedVehicleType
        self.drivingGoal = drivingGoal
        self.canProceed = canProceed
        self.onTogglePracticeSituation = onTogglePracticeSituation
        self.onSelectVehicleType = onSelectVehicleType
        self.onSkip = onSkip
        self.onNext = onNext
        _goalText = State(initialValue: drivingGoal)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        title
                            .padding(.bottom, 40)

                        practiceSituationSection
                            .padding(.bottom, 32)

                        vehicleTypeSection
                            .padding(.bottom, 32)

                        drivingGoalSection
                            .id(ScrollTarget.drivingGoal)
                    }
                    .padding(.horizontal, Metrics.horizontalPadding)
                    .padding(.bottom, isGoalFieldFocused ? 24 : 80)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: isGoalFieldFocused) { isFocused in
                    guard isFocused else { return }

                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        proxy.scrollTo(ScrollTarget.drivingGoal, anchor: .bottom)
                    }
                }
            }

            DualBottomButton(
                secondaryTitle: "건너뛰기",
                primaryTitle: "다음",
                isPrimaryEnabled: canProceed,
                secondaryAction: onSkip,
                primaryAction: { onNext(goalText) }
            )
            .opacity(isGoalFieldFocused ? 0 : 1)
            .allowsHitTesting(!isGoalFieldFocused)
            .accessibilityHidden(isGoalFieldFocused)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("추가 정보를 입력하면 더 정확해요.")
                .rodiTypography(.heading2)
                .foregroundStyle(RodiColor.black)

            Text("딱 맞는 코스 추천을 위한 선택항목이에요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: dismissGoalKeyboard)
    }

    private var practiceSituationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("더 연습해보고 싶은 상황이 있나요?")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)

                Text("최대 3개")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
            }

            Text("1순위부터 순서대로 선택해주세요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
                .padding(.top, 10)

            practiceSituationChips
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var vehicleTypeSection: some View {
        OnboardingSection(title: "주로 타는 차종은 무엇인가요?") {
            vehicleTypeChips
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: dismissGoalKeyboard)
    }

    private var drivingGoalSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("이루고 싶은 운전 목표를 입력해주세요.")
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)
                .padding(.bottom, 12)

            OnboardingLimitedTextField(
                text: $goalText,
                placeholder: "ex)강남 운전 자신있게 하기!",
                characterLimit: Metrics.goalLimit,
                isFocused: $isGoalFieldFocused
            )
            .padding(.vertical, 16)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isGoalFieldFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
            }

            Text("\(goalText.count) / \(Metrics.goalLimit)")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var practiceSituationChips: some View {
        OnboardingChipFlow {
            ForEach(PracticeSituation.allCases) { situation in
                let selectionOrder = selectedPracticeSituations.firstIndex(of: situation).map { $0 + 1 }

                OnboardingChip(
                    title: situation.rawValue,
                    isSelected: selectionOrder != nil,
                    selectionOrder: selectionOrder,
                    action: {
                        dismissGoalKeyboard()
                        onTogglePracticeSituation(situation)
                    }
                )
            }
        }
    }

    private var vehicleTypeChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                vehicleChip(.compact)
                vehicleChip(.small)
                vehicleChip(.medium)
                vehicleChip(.semiLarge)
            }

            HStack(spacing: 6) {
                vehicleChip(.large)
                vehicleChip(.suv)
            }
        }
    }

    private func vehicleChip(_ vehicleType: VehicleType) -> some View {
        OnboardingChip(
            title: vehicleType.rawValue,
            isSelected: selectedVehicleType == vehicleType,
            action: {
                dismissGoalKeyboard()
                onSelectVehicleType(vehicleType)
            }
        )
    }

    private func dismissGoalKeyboard() {
        isGoalFieldFocused = false
    }
}

private extension OptionalDrivingPreferenceView {
    enum ScrollTarget {
        case drivingGoal
    }
}
