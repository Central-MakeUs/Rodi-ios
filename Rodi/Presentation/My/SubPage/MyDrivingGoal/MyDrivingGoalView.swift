//
//  MyDrivingGoalView.swift
//  Rodi
//

import SwiftUI

struct MyDrivingGoalView: View {
    private enum Metrics {
        static let characterLimit = 30
    }

    let onUpdated: (MemberProfile) -> Void
    let backAction: () -> Void

    @StateObject private var store: StoreOf<MyDrivingGoalReducer>
    @FocusState private var isFieldFocused: Bool

    init(
        initialDrivingGoal: String,
        memberRepository: MemberRepository,
        onUpdated: @escaping (MemberProfile) -> Void,
        backAction: @escaping () -> Void
    ) {
        self.onUpdated = onUpdated
        self.backAction = backAction
        _store = StateObject(
            wrappedValue: Store(
                state: MyDrivingGoalReducer.State(drivingGoal: initialDrivingGoal),
                reducer: MyDrivingGoalReducer(memberRepository: memberRepository)
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("이루고 싶은 운전 목표를 입력해주세요.")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .padding(.bottom, 12)

                RodiTextField(
                    text: Binding(
                        get: { store.state.drivingGoal },
                        set: { store.send(.drivingGoalChanged($0)) }
                    ),
                    placeholder: "ex)강남 운전 자신있게 하기!",
                    characterLimit: Metrics.characterLimit,
                    isFocused: $isFieldFocused
                )
                .frame(height: 20)
                .padding(.vertical, 16)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFieldFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
                }

                Text("\(store.state.drivingGoal.count) / \(Metrics.characterLimit)")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isFieldFocused = false
                }
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .rodiSnackbar(message: store.state.errorMessage)
        .onChange(of: store.state.updatedProfile) { profile in
            guard let profile else { return }
            onUpdated(profile)
            backAction()
        }
    }

    private var header: some View {
        ZStack {
            Text("운전 목표")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button(action: backAction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RodiColor.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")

                Spacer()

                Button(action: saveDrivingGoal) {
                    Circle()
                        .fill(store.state.canSave ? RodiColor.primary : RodiColor.primary100)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if store.state.isSaving {
                                ProgressView()
                                    .tint(RodiColor.white)
                                    .scaleEffect(0.65)
                            } else {
                                Image(store.state.canSave ? "ic_driving_goal_check_active" : "ic_driving_goal_check_inactive")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!store.state.canSave || store.state.isSaving)
                .accessibilityLabel("운전 목표 저장")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }

    private func saveDrivingGoal() {
        isFieldFocused = false
        store.send(.saveTapped)
    }
}
