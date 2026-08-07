//
//  OnboardingRouterView.swift
//  Rodi
//

import Clarity
import SwiftUI

struct OnboardingRouterView: View {
    @StateObject private var coordinator: Coordinator<OnboardingRoute>
    @State private var session: OnboardingSession
    @State private var automaticLoginCommand: LoginCommand?
    @State private var hasStarted = false

    private let sessionStore: OnboardingSessionStore
    private let onComplete: () -> Void
    private let automaticLoginProvider: SocialLoginProvider?
    private let automaticLoginRequestConsumed: () -> Void
    private let dependencies: AppDependencies

    init(
        onComplete: @escaping () -> Void,
        automaticLoginProvider: SocialLoginProvider? = nil,
        automaticLoginRequestConsumed: @escaping () -> Void = {},
        sessionStore: OnboardingSessionStore = .init(),
        dependencies: AppDependencies
    ) {
        let restored = sessionStore.load()
        _coordinator = StateObject(
            wrappedValue: Coordinator(
                path: Self.navigationPath(for: restored.route, session: restored.session),
                acceptsSystemPath: { currentPath, proposedPath in
                    !(currentPath == [.terms] && proposedPath.isEmpty)
                }
            )
        )
        _session = State(initialValue: restored.session)
        self.sessionStore = sessionStore
        self.onComplete = onComplete
        self.automaticLoginProvider = automaticLoginProvider
        self.automaticLoginRequestConsumed = automaticLoginRequestConsumed
        self.dependencies = dependencies
    }

    var body: some View {
        NavigationStack(path: coordinator.pathBinding) {
            LoginView(
                session: session,
                command: automaticLoginCommand,
                onTransition: handle,
                authRepository: dependencies.authRepository,
                recentLoginProviderStore: dependencies.recentLoginProviderStore,
                socialLoginService: SocialLoginService()
            )
            .navigationDestination(for: OnboardingRoute.self) { route in
                destination(for: route)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .onAppear(perform: startIfNeeded)
        .onChange(of: coordinator.path) { _ in
            if let route = coordinator.path.last {
                sessionStore.save(session, route: route)
            }
        }
        .clarityMask()
    }
}

// MARK: Layout
private extension OnboardingRouterView {
    
    @ViewBuilder
    func destination(for route: OnboardingRoute) -> some View {
        switch route {
        case .terms:
            OnboardingContainer(step: .terms) {
                OnboardingTermsView(session: session, onTransition: handle)
            } onBack: {}

        case .nickname:
            OnboardingProfileView(
                session: session,
                screen: .nickname,
                onTransition: handle,
                memberRepository: dependencies.memberRepository
            )

        case .drivingExperience:
            OnboardingProfileView(
                session: session,
                screen: .drivingExperience,
                onTransition: handle,
                memberRepository: dependencies.memberRepository
            )

        case .optionalDrivingPreference:
            OnboardingProfileView(
                session: session,
                screen: .drivingPreference,
                onTransition: handle,
                memberRepository: dependencies.memberRepository
            )

        case .safety:
            OnboardingPermissionView(session: session, screen: .safety, onTransition: handle)

        case .locationPermission:
            OnboardingPermissionView(session: session, screen: .locationPermission, onTransition: handle)
        }
    }

    func handle(_ transition: OnboardingTransition) {
        session = transition.updatedSession

        switch transition.navigation {
        case .push(let route):
            sessionStore.save(session, route: route)
            coordinator.router.push(route)

        case .pop:
            coordinator.router.pop()
            if let route = coordinator.path.last {
                sessionStore.save(session, route: route)
            }

        case .complete:
            sessionStore.markCompleted()
            onComplete()
        }
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        RodiAnalytics.track(.onboardingStarted(entryMode: session.entryMode))

        guard coordinator.path.isEmpty, let automaticLoginProvider else { return }
        automaticLoginRequestConsumed()
        automaticLoginCommand = .init(kind: .login(automaticLoginProvider))
    }

    static func navigationPath(
        for route: OnboardingRoute?,
        session: OnboardingSession
    ) -> [OnboardingRoute] {
        guard let route else { return [] }

        let memberRoutes: [OnboardingRoute] = [
            .terms,
            .nickname,
            .drivingExperience,
            .optionalDrivingPreference,
            .safety,
            .locationPermission
        ]
        let guestRoutes: [OnboardingRoute] = [.terms, .safety, .locationPermission]
        let routes = session.isGuest ? guestRoutes : memberRoutes

        guard let routeIndex = routes.firstIndex(of: route) else { return [route] }
        return Array(routes[...routeIndex])
    }
}
