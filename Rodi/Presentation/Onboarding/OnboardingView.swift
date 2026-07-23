//
//  OnboardingView.swift
//  Rodi
//
//  Created by mac on 7/1/26.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    let automaticLoginProvider: AuthProvider?
    let automaticLoginRequestConsumed: () -> Void
    let authRepository: AuthRepository
    let memberRepository: MemberRepository
    let onboardingDraftStore: OnboardingDraftStore
    let recentLoginProviderStore: RecentLoginProviderStore

    @StateObject var onboardingStore: StoreOf<OnboardingReducer>
    @State var locationPermission: LocationPermissionRequester
    @State var socialLoginService: SocialLoginService

    @MainActor
    init(
        onComplete: @escaping () -> Void,
        automaticLoginProvider: AuthProvider? = nil,
        automaticLoginRequestConsumed: @escaping () -> Void = {}
    ) {
        self.onComplete = onComplete
        self.automaticLoginProvider = automaticLoginProvider
        self.automaticLoginRequestConsumed = automaticLoginRequestConsumed
        self.authRepository = AuthDependencyContainer.shared.authRepository
        self.memberRepository = AuthDependencyContainer.shared.memberRepository
        let draftStore = OnboardingDraftStore()
        self.onboardingDraftStore = draftStore
        let recentLoginProviderStore = AuthDependencyContainer.shared.recentLoginProviderStore
        self.recentLoginProviderStore = recentLoginProviderStore
        let recentLoginProvider = recentLoginProviderStore.load()
        let initialState: OnboardingState
        if let draft = draftStore.load() {
            initialState = OnboardingState(draft: draft, recentLoginProvider: recentLoginProvider)
        } else {
            initialState = OnboardingState(recentLoginProvider: recentLoginProvider)
        }
        _onboardingStore = StateObject(wrappedValue: Store(state: initialState, reducer: OnboardingReducer()))
        _locationPermission = State(initialValue: LocationPermissionRequester())
        _socialLoginService = State(initialValue: SocialLoginService())
    }

    @MainActor
    init(
        onComplete: @escaping () -> Void,
        onboardingStore: StoreOf<OnboardingReducer>,
        locationPermission: LocationPermissionRequester,
        socialLoginService: SocialLoginService,
        automaticLoginProvider: AuthProvider? = nil,
        automaticLoginRequestConsumed: @escaping () -> Void = {},
        authRepository: AuthRepository? = nil,
        memberRepository: MemberRepository? = nil,
        onboardingDraftStore: OnboardingDraftStore? = nil,
        recentLoginProviderStore: RecentLoginProviderStore? = nil
    ) {
        self.onComplete = onComplete
        self.automaticLoginProvider = automaticLoginProvider
        self.automaticLoginRequestConsumed = automaticLoginRequestConsumed
        self.authRepository = authRepository ?? AuthDependencyContainer.shared.authRepository
        self.memberRepository = memberRepository ?? AuthDependencyContainer.shared.memberRepository
        self.onboardingDraftStore = onboardingDraftStore ?? OnboardingDraftStore()
        self.recentLoginProviderStore = recentLoginProviderStore ?? AuthDependencyContainer.shared.recentLoginProviderStore
        _onboardingStore = StateObject(wrappedValue: onboardingStore)
        _locationPermission = State(initialValue: locationPermission)
        _socialLoginService = State(initialValue: socialLoginService)
    }

    var body: some View {
        OnboardingContainer(step: onboardingStore.state.step) {
            onboardingStepView
        } onBack: {
            onboardingStore.send(.navigation(.backTapped))
        }
        .sheet(item: selectedTermsPageBinding) { terms in
            LegalWebView(title: terms.title, url: terms.url)
        }
        .alert("로그인에 실패했어요", isPresented: loginAlertBinding) {
            Button("확인") {
                onboardingStore.send(.entry(.dismissLoginAlert))
            }
        } message: {
            Text(onboardingStore.state.loginAlertMessage ?? "")
        }
        .onOpenURL { url in
            _ = socialLoginService.handleOpenURL(url)
        }
        .onAppear {
            guard let automaticLoginProvider else { return }
            automaticLoginRequestConsumed()

            switch automaticLoginProvider {
            case .apple:
                startAppleLogin()
            case .kakao:
                startKakaoLogin()
            }
        }
        .onChange(of: onboardingStore.state.didComplete) { didComplete in
            guard didComplete else { return }
            onboardingDraftStore.clear()
            onComplete()
        }
        .onChange(of: onboardingStore.state.onboardingDraft) { draft in
            guard let draft else { return }
            onboardingDraftStore.save(draft)
        }
        .overlay {
            if let withdrawalDialog = onboardingStore.state.withdrawalDialog {
                WithdrawalAccountDialog(
                    state: withdrawalDialog,
                    restoreAction: {
                        guard case .restore(let recovery) = withdrawalDialog else { return }
                        startWithdrawalRestore(recovery)
                    },
                    dismissAction: {
                        onboardingStore.send(.entry(.dismissWithdrawalDialog))
                    }
                )
                .transition(.opacity)
            } else if onboardingStore.state.isOnboardingAnalysisPresented {
                OnboardingAnalysisDialog()
                    .transition(.opacity)
            } else if onboardingStore.state.isOnboardingAnalysisCompletionPresented,
                      let analysis = onboardingStore.state.onboardingAnalysis {
                OnboardingAnalysisCompletionDialog(
                    analysis: analysis,
                    recentFrequency: onboardingStore.state.recentDrivingFrequency,
                    onConfirm: {
                        onboardingStore.send(.optionalDrivingPreference(.analysisCompletionConfirmed))
                    }
                )
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var onboardingStepView: some View {
        switch onboardingStore.state.step {
            case .entry:
                OnboardingEntryView(
                    isAuthenticating: onboardingStore.state.isAuthenticating,
                    recentLoginProvider: onboardingStore.state.recentLoginProvider,
                    onBrowse: startBrowse,
                    onAppleLogin: startAppleLogin,
                    onKakaoLogin: startKakaoLogin
                )
            
            case .terms:
                TermsAgreementView(
                    agreedTerms: onboardingStore.state.agreedTerms,
                    isAllAgreed: onboardingStore.state.isAllTermsAgreed,
                    onToggleAll: { onboardingStore.send(.terms(.toggleAll)) },
                    onToggleTerms: { onboardingStore.send(.terms(.toggle($0))) },
                    onOpenTerms: { onboardingStore.send(.terms(.open($0))) },
                    onNext: { onboardingStore.send(.terms(.nextTapped)) }
                )
            
            case .nickname:
                NicknameSetupView(
                    nickname: onboardingStore.state.nickname,
                    isNextEnabled: onboardingStore.state.canProceedFromNickname,
                    onNext: { onboardingStore.send(.nickname(.nextTapped)) }
                )
            
            case .drivingExperience:
                DrivingExperienceView(
                    selectedPeriod: onboardingStore.state.licenseDrivingPeriod,
                    selectedFrequency: onboardingStore.state.recentDrivingFrequency,
                    selectedRoadExperiences: onboardingStore.state.selectedRoadDrivingExperiences,
                    selectedSoloDrivingRange: onboardingStore.state.soloDrivingRange,
                    selectedSoloParkingLevel: onboardingStore.state.soloParkingLevel,
                    canProceed: onboardingStore.state.canProceedFromDrivingExperience,
                    onSelectPeriod: { onboardingStore.send(.drivingExperience(.selectLicenseDrivingPeriod($0))) },
                    onSelectFrequency: { onboardingStore.send(.drivingExperience(.selectRecentDrivingFrequency($0))) },
                    onToggleRoadExperience: { onboardingStore.send(.drivingExperience(.toggleRoadDrivingExperience($0))) },
                    onSelectSoloDrivingRange: { onboardingStore.send(.drivingExperience(.selectSoloDrivingRange($0))) },
                    onSelectSoloParkingLevel: { onboardingStore.send(.drivingExperience(.selectSoloParkingLevel($0))) },
                    onNext: { onboardingStore.send(.drivingExperience(.nextTapped)) }
                )
            
            case .optionalDrivingPreference:
                OptionalDrivingPreferenceView(
                    selectedPracticeSituations: onboardingStore.state.selectedPracticeSituations,
                    selectedVehicleType: onboardingStore.state.vehicleType,
                    drivingGoal: onboardingStore.state.drivingGoal,
                    canProceed: onboardingStore.state.canProceedFromOptionalDrivingPreference,
                    onTogglePracticeSituation: { onboardingStore.send(.optionalDrivingPreference(.togglePracticeSituation($0))) },
                    onSelectVehicleType: { onboardingStore.send(.optionalDrivingPreference(.selectVehicleType($0))) },
                    onSkip: { submitOnboarding(drivingGoal: "", shouldSkip: true) },
                    onNext: { submitOnboarding(drivingGoal: $0, shouldSkip: false) }
                )
            
            case .safety:
                SafetyAgreementView(
                    agreedSafetyItems: onboardingStore.state.agreedSafetyItems,
                    isAllAgreed: onboardingStore.state.isAllSafetyAgreed,
                    onToggleSafety: { onboardingStore.send(.safety(.toggle($0))) },
                    onNext: { onboardingStore.send(.safety(.finishTapped)) }
                )
            
            case .locationPermission:
                LocationPermissionView(onAllow: requestLocationPermission)
        }
    }
}
