import Clarity
import SwiftUI

struct MyNicknameView: View {
    @StateObject private var store: StoreOf<MyNicknameReducer>
    @FocusState private var isFieldFocused: Bool
    @State private var isKeyboardVisible = false
    @State private var isExitRequested = false

    private let onUpdated: (String) -> Void
    private let backAction: () -> Void

    init(
        initialNickname: String,
        memberRepository: MemberRepository,
        onUpdated: @escaping (String) -> Void,
        backAction: @escaping () -> Void
    ) {
        self.onUpdated = onUpdated
        self.backAction = backAction
        _store = StateObject(wrappedValue: Store(
            state: MyNicknameReducer.State(nickname: initialNickname),
            reducer: MyNicknameReducer(memberRepository: memberRepository)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            VStack(alignment: .leading, spacing: 0) {
                Text("원하는 닉네임을 입력해주세요.")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .padding(.bottom, 12)

                RodiTextField(
                    text: Binding(
                        get: { store.state.nickname },
                        set: { store.send(.nicknameChanged($0)) }
                    ),
                    placeholder: "",
                    characterLimit: MemberNicknamePolicy.maximumLength,
                    isFocused: $isFieldFocused
                )
                .frame(height: 50)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFieldFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
                }
                .disabled(store.state.isSaving || isExitRequested)
                .accessibilityLabel("닉네임")
                .clarityMask()

                Text("\(store.state.nickname.count)/\(MemberNicknamePolicy.maximumLength)")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)

                if let message = store.state.errorMessage {
                    Text(message)
                        .rodiTypography(.caption1SemiBold)
                        .foregroundStyle(RodiColor.informationCancel)
                        .padding(.top, 12)
                        .accessibilityLabel("오류: \(message)")
                }

                Text("닉네임을 바꾸면 30일 후에 다시 바꿀 수 있어요.")
                    .rodiTypography(.caption1SemiBold)
                    .foregroundStyle(RodiColor.gray500)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer(minLength: 0)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { isFieldFocused = false }
        }
        .background(RodiColor.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(RodiInteractivePopGestureEnabler(isEnabled: !store.state.isSaving && !isExitRequested))
        .onAppear {
            store.send(.appeared)
        }
        .task { isFieldFocused = true }
        .onDisappear { store.send(.disappeared) }
        .onChange(of: store.state.updatedNickname) { nickname in
            guard let nickname else { return }
            onUpdated(nickname)
            requestExit()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { _ in
            isKeyboardVisible = false
            if isExitRequested { backAction() }
        }
    }

    private var header: some View {
        ZStack {
            Text("닉네임 수정")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button(action: requestExit) {
                    Image("ic_chevron_left_24")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 56, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(store.state.isSaving || isExitRequested)
                .accessibilityLabel("뒤로가기")

                Spacer()

                Button {
                    guard store.state.canSave else { return }
                    isFieldFocused = false
                    store.send(.saveTapped)
                } label: {
                    Image(store.state.canSave ? "ic_check_circle_active" : "ic_check_circle_inactive")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 56, alignment: .trailing)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!store.state.canSave || isExitRequested)
                .accessibilityLabel("닉네임 저장")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }

    private func requestExit() {
        guard !store.state.isSaving, !isExitRequested else { return }
        isExitRequested = true
        isFieldFocused = false
        if !isKeyboardVisible { backAction() }
    }
}
