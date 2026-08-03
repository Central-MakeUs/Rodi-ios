//
//  OnboardingTermsView.swift
//  Rodi
//

import SwiftUI

struct OnboardingTermsView: View {
    @StateObject private var store: StoreOf<OnboardingTermsReducer>
    private let onTransition: (OnboardingTransition) -> Void

    private enum Layout {
        static let titleTopInset: CGFloat = 52
    }

    init(
        session: OnboardingSession,
        onTransition: @escaping (OnboardingTransition) -> Void
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: .init(session: session),
                reducer: OnboardingTermsReducer()
            )
        )
        self.onTransition = onTransition
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            allTermsButton
            termsList
            Spacer()

            PrimaryBottomButton(
                title: "다음",
                isEnabled: state.isAllTermsAgreed,
                showsDivider: true,
                action: { send(.nextTapped) }
            )
        }
        .sheet(item: selectedTermsPageBinding) { terms in
            LegalWebView(title: terms.title, url: terms.url)
        }
        .onChange(of: store.state.transition) { transition in
            guard let transition else { return }
            onTransition(transition)
            store.send(.transitionConsumed)
        }
    }

    private var state: OnboardingTermsReducer.State {
        store.state
    }

    private func send(_ action: OnboardingTermsReducer.Action) {
        store.send(action)

    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("로디 서비스 시작하기")
                .rodiTypography(.heading2)
                .foregroundStyle(RodiColor.black)

            Text("아래 약관에 동의해주세요")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray800)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, Layout.titleTopInset)
    }

    private var allTermsButton: some View {
        Button {
            send(.toggleAll)
        } label: {
            HStack(spacing: 8) {
                CheckIcon(isActive: state.isAllTermsAgreed)
                Text("약관 전체 동의")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        state.isAllTermsAgreed ? RodiColor.gray900 : RodiColor.gray300,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 34)
    }

    private var termsList: some View {
        VStack(spacing: 20) {
            ForEach(TermsAgreement.allCases) { terms in
                TermsRow(
                    terms: terms,
                    isChecked: state.agreedTerms.contains(terms),
                    onCheck: { send(.toggle(terms)) },
                    onOpen: { send(.open(terms)) }
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }

    private var selectedTermsPageBinding: Binding<TermsAgreement?> {
        Binding(
            get: { state.selectedTermsPage },
            set: { terms in
                if terms == nil {
                    send(.dismissTermsPage)
                }
            }
        )
    }
}

private struct TermsRow: View {
    let terms: TermsAgreement
    let isChecked: Bool
    let onCheck: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onCheck) {
                CheckIcon(isActive: isChecked)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("약관 선택: \(terms.title)")
            .accessibilityValue(isChecked ? "선택됨" : "선택 안 됨")

            Button(action: onOpen) {
                HStack {
                    Text(terms.title)
                        .rodiTypography(.body1Medium)
                        .foregroundStyle(RodiColor.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.pretendard(size: 13, weight: .medium))
                        .foregroundStyle(RodiColor.gray600)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 44)
    }
}
