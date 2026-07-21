//
//  MyView.swift
//  Rodi
//

import SwiftUI
import UIKit
import CoreLocation

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

struct MyView: View {
    let authRepository: AuthRepository
    let memberRepository: MemberRepository
    let placeRepository: PlaceRepository
    let recentLoginProviderStore: RecentLoginProviderStore
    let onSavedPlaceSelected: (PlaceListItem) -> Void
    let onLogout: () -> Void

    @Binding var isDetailPresented: Bool
    @StateObject private var viewModel: MyProfileViewModel
    @State private var path = NavigationPath()
    @State private var snackbarMessage: String?

    init(
        isDetailPresented: Binding<Bool> = .constant(false),
        authRepository: AuthRepository = AuthDependencyContainer.shared.authRepository,
        memberRepository: MemberRepository = AuthDependencyContainer.shared.memberRepository,
        placeRepository: PlaceRepository = AuthDependencyContainer.shared.placeRepository,
        recentLoginProviderStore: RecentLoginProviderStore = AuthDependencyContainer.shared.recentLoginProviderStore,
        onSavedPlaceSelected: @escaping (PlaceListItem) -> Void = { _ in },
        onLogout: @escaping () -> Void
    ) {
        _isDetailPresented = isDetailPresented
        self.authRepository = authRepository
        self.memberRepository = memberRepository
        self.placeRepository = placeRepository
        self.recentLoginProviderStore = recentLoginProviderStore
        self.onSavedPlaceSelected = onSavedPlaceSelected
        self.onLogout = onLogout
        _viewModel = StateObject(wrappedValue: MyProfileViewModel(memberRepository: memberRepository))
    }

    var body: some View {
        NavigationStack(path: $path) {
            MyProfileContent(
                profile: viewModel.profile,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                openSettings: { path.append(MyRoute.settings) },
                openDrivingGoal: { path.append(MyRoute.drivingGoal) },
                openSavedPlaces: { path.append(MyRoute.savedPlaces) },
                retry: { Task { await viewModel.load() } }
            )
            .navigationDestination(for: MyRoute.self) { route in
                destinationView(for: route)
            }
        }
        .overlay(alignment: .bottom) {
            if let snackbarMessage {
                SnackbarView(message: snackbarMessage)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 92)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: snackbarMessage)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onAppear {
            isDetailPresented = !path.isEmpty
        }
        .onChange(of: path) { path in
            isDetailPresented = !path.isEmpty
        }
    }

    @ViewBuilder
    private func destinationView(for route: MyRoute) -> some View {
        switch route {
        case .settings:
            MySettingsView(
                logoutAction: performLogout,
                withdrawalAction: performWithdrawal
            )
        case .drivingGoal:
            MyDrivingGoalView(
                initialDrivingGoal: "",
                memberRepository: memberRepository,
                onUpdated: { profile in
                    viewModel.replaceProfile(profile)
                    showSnackbar("운전 목표를 수정했어요.")
                }
            )
        case .savedPlaces:
            SavedPlacesView(
                placeRepository: placeRepository,
                selectPlaceAction: onSavedPlaceSelected
            )
        }
    }

    private func performLogout() {
        Task {
            do {
                try await authRepository.logout()
                RodiLogger.info("Logout API completed")
            } catch {
                authRepository.clearSession()
                RodiLogger.warning("Logout API failed; local session cleared. error=\(error)")
            }

            await logoutKakaoSDKSessionIfNeeded()
            onLogout()
        }
    }

    private func performWithdrawal() {
        Task {
            do {
                try await memberRepository.withdraw()
                RodiLogger.info("Member withdrawal API completed")
            } catch {
                RodiLogger.warning("Member withdrawal API failed. error=\(error)")
                return
            }

            authRepository.clearSession()
            recentLoginProviderStore.clear()
            await logoutKakaoSDKSessionIfNeeded()
            onLogout()
        }
    }

    private func logoutKakaoSDKSessionIfNeeded() async {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            UserApi.shared.logout { error in
                if let error {
                    RodiLogger.warning("Kakao SDK logout failed or no active Kakao session. error=\(error)")
                } else {
                    RodiLogger.info("Kakao SDK logout completed")
                }
                continuation.resume()
            }
        }
        #endif
    }

    private func showSnackbar(_ message: String) {
        snackbarMessage = message

        Task {
            try? await Task.sleep(for: .seconds(3))
            guard snackbarMessage == message else { return }
            snackbarMessage = nil
        }
    }
}

private enum MyRoute: Hashable {
    case settings
    case drivingGoal
    case savedPlaces
}

private struct MyProfileContent: View {
    let profile: MemberProfile?
    let isLoading: Bool
    let errorMessage: String?
    let openSettings: () -> Void
    let openDrivingGoal: () -> Void
    let openSavedPlaces: () -> Void
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    profileSection
                        .padding(.horizontal, 16)

                    Rectangle()
                        .fill(RodiColor.primaryMinus100)
                        .frame(height: 2)
                        .padding(.top, 20)

                    savedPlacesRow
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                }
                .padding(.bottom, 114)
            }
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack {
            Text("프로필")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Spacer()

                Button(action: openSettings) {
                    Image("ic_setting")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("설정")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var profileSection: some View {
        if let profile {
            MyProfileCard(profile: profile, openDrivingGoal: openDrivingGoal)
                .padding(.top, 16)
        } else if isLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 227)
                .padding(.top, 16)
        } else {
            VStack(spacing: 12) {
                Text(errorMessage ?? "내 정보를 불러오지 못했어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray700)

                Button(action: retry) {
                    Text("다시 시도")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 227)
            .padding(.top, 16)
        }
    }

    private var savedPlacesRow: some View {
        Button(action: openSavedPlaces) {
            HStack(spacing: 4) {
                Text("저장 목록")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)

                Text("(\(profile?.savedPlaceCount ?? 0))")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RodiColor.gray700)
                    .frame(width: 20, height: 20)
            }
            .frame(maxWidth: .infinity, minHeight: 20)
        }
        .buttonStyle(.plain)
        .disabled(profile == nil)
        .accessibilityLabel("저장 목록 \(profile?.savedPlaceCount ?? 0)개")
    }
}

private struct MyProfileCard: View {
    let profile: MemberProfile
    let openDrivingGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Image("img_profile_dummy_2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .background(RodiColor.primary100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.nickname)
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                        .lineLimit(1)

                    Text("레벨")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray700)
                        .padding(.top, 8)

                    Text(profile.level.displayName)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.black)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("추천 연습 유형")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)

                HStack(spacing: 4) {
                    ForEach(profile.recommendationTags, id: \.self) { tag in
                        Text(PlacePracticeType.displayName(for: tag))
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RodiColor.primary50)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                .lineLimit(1)
            }
            .padding(.top, 12)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text("운전 목표")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)

                Button(action: openDrivingGoal) {
                    HStack(spacing: 8) {
                        Text(profile.drivingGoal?.isEmpty == false ? profile.drivingGoal! : "아직 설정한 운전 목표가 없어요.")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.black)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RodiColor.gray700)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("운전 목표")
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, minHeight: 227, maxHeight: 227, alignment: .top)
        .background(
            RadialGradient(
                colors: [RodiColor.white, RodiColor.primary20],
                center: .bottom,
                startRadius: 30,
                endRadius: 250
            )
        )
        .overlay(alignment: .topTrailing) {
            Image("img_stamp")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .opacity(0.2)
                .padding(.top, 15)
                .padding(.trailing, 11)
                .accessibilityHidden(true)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RodiColor.primary50, lineWidth: 1)
        }
    }
}

private struct MySettingsView: View {
    let logoutAction: () -> Void
    let withdrawalAction: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "설정")

            VStack(spacing: 0) {
                NavigationLink {
                    MyPermissionSettingsView()
                } label: {
                    MyNavigationRow(title: "권한 설정 변경")
                }

                NavigationLink {
                    MyTermsView()
                } label: {
                    MyNavigationRow(title: "약관 다시보기")
                }

                NavigationLink {
                    MyOpenSourceLicenseView()
                } label: {
                    MyNavigationRow(title: "오픈소스 라이센스")
                }

                NavigationLink {
                    MyAccountManagementView(
                        logoutAction: logoutAction,
                        withdrawalAction: withdrawalAction
                    )
                } label: {
                    MyNavigationRow(title: "계정정보 관리")
                }

                HStack {
                    Text("버전")
                        .rodiTypography(.body1Medium)
                    Spacer()
                    Text(appVersion)
                        .rodiTypography(.body1Medium)
                }
                .foregroundStyle(RodiColor.black)
                .frame(height: 45)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }
}

private struct MyAccountManagementView: View {
    let logoutAction: () -> Void
    let withdrawalAction: () -> Void
    @State private var confirmation: AccountConfirmation?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MySubpageHeader(title: "개인정보 관리")

                VStack(spacing: 0) {
                    NavigationLink {
                        MyContactView()
                    } label: {
                        MyNavigationRow(title: "문의하기")
                    }

                    Button {
                        confirmation = .logout
                    } label: {
                        MyPlainRow(title: "로그아웃")
                    }
                    .buttonStyle(.plain)

                    Button {
                        confirmation = .withdrawal
                    } label: {
                        MyPlainRow(title: "계정 삭제하기")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(RodiColor.white)
            .toolbar(.hidden, for: .navigationBar)

            if let confirmation {
                MyAccountConfirmationDialog(
                    confirmation: confirmation,
                    confirm: {
                        self.confirmation = nil
                        switch confirmation {
                        case .logout:
                            logoutAction()
                        case .withdrawal:
                            withdrawalAction()
                        }
                    },
                    cancel: {
                        self.confirmation = nil
                    }
                )
            }
        }
    }
}

private enum AccountConfirmation {
    case logout
    case withdrawal

    var title: String {
        switch self {
        case .logout:
            "로그아웃 하시겠습니까?"
        case .withdrawal:
            "정말 계정을 삭제하시겠습니까?"
        }
    }

    var message: String? {
        switch self {
        case .logout:
            nil
        case .withdrawal:
            "삭제 후 3일 이내 재로그인 시 복구 가능합니다.  10일 이후 재가입 가능합니다."
        }
    }

    var dialogHeight: CGFloat {
        switch self {
        case .logout:
            189
        case .withdrawal:
            226
        }
    }
}

private struct MyAccountConfirmationDialog: View {
    let confirmation: AccountConfirmation
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        Color.black
            .opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 0) {
                    Text(confirmation.title)
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)
                        .multilineTextAlignment(.center)
                        .frame(width: 240, height: confirmation.message == nil ? 60 : nil)
                        .padding(.top, 32)

                    if let message = confirmation.message {
                        Text(message)
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)
                            .frame(width: 240, height: 60)
                            .padding(.top, 16)
                    }

                    HStack(spacing: 8) {
                        Button(action: confirm) {
                            Text("예")
                                .rodiTypography(.body1Medium)
                                .foregroundStyle(RodiColor.gray800)
                                .frame(width: 116, height: 44)
                                .background(RodiColor.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(RodiColor.gray300, lineWidth: 1)
                                }
                        }

                        Button(action: cancel) {
                            Text("아니오")
                                .rodiTypography(.body1Medium)
                                .foregroundStyle(RodiColor.white)
                                .frame(width: 116, height: 44)
                                .background(RodiColor.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)

                    Spacer(minLength: 0)
                }
                .frame(width: 280, height: confirmation.dialogHeight)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityElement(children: .contain)
    }
}

private struct MyContactView: View {
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "문의하기")

            VStack(alignment: .leading, spacing: 8) {
                Text("문의 이메일")
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.black)

                Text("yangyunseo71@gmail.com로 연락바랍니다.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MyTermsView: View {
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "약관 다시보기")

            VStack(spacing: 0) {
                ForEach(LegalDocument.allCases) { document in
                    NavigationLink {
                        MyLegalDocumentView(document: document)
                    } label: {
                        MyNavigationRow(title: document.title)
                    }
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MyLegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: document.title)

            LegalWKWebView(url: document.url)
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MyOpenSourceLicenseView: View {
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "오픈소스 라이센스")
            LegalWKWebView(url: LegalDocument.openSourceLicenseURL)
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MyPermissionSettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "권한 설정 변경")

            Button(action: openSystemLocationSettings) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("위치")
                            .rodiTypography(.body1Medium)
                            .foregroundStyle(RodiColor.black)

                        Spacer()

                        Text(locationAuthorizationTitle)
                            .rodiTypography(.body1Medium)
                            .foregroundStyle(RodiColor.gray600)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(RodiColor.gray700)
                            .frame(width: 20, height: 20)
                    }

                    Text("내 주변 운전 연습 코스를 추천하기 위해 필요해요.")
                        .rodiTypography(.caption2Medium)
                        .foregroundStyle(RodiColor.gray600)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshAuthorizationStatus)
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            refreshAuthorizationStatus()
        }
    }

    private var locationAuthorizationTitle: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "허용됨"
        case .denied, .restricted:
            "허용 안 됨"
        case .notDetermined:
            "설정 필요"
        @unknown default:
            "설정 필요"
        }
    }

    private func refreshAuthorizationStatus() {
        authorizationStatus = CLLocationManager().authorizationStatus
    }

    private func openSystemLocationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

struct MySubpageHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Text(title)
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RodiColor.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")

                Spacer()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }
}

private struct MyNavigationRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(RodiColor.gray700)
                .frame(width: 20, height: 20)
        }
        .frame(height: 45)
        .contentShape(Rectangle())
    }
}

private struct MyPlainRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .rodiTypography(.body1Medium)
                .foregroundStyle(RodiColor.black)
            Spacer()
        }
        .frame(height: 45)
        .contentShape(Rectangle())
    }
}

private struct MyRoutePlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: title)

            VStack(spacing: 12) {
                Text("준비 중이에요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray700)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}
