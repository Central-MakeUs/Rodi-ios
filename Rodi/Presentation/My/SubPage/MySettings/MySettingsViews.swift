//
//  MySettingsViews.swift
//  Rodi
//

import CoreLocation
import SwiftUI
import UIKit

struct MySettingsView: View {
    let backAction: () -> Void
    let navigate: (MyRoute) -> Void

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "설정", backAction: backAction)
            VStack(spacing: 0) {
                navigationButton("권한 설정 변경", to: .permissions)
                navigationButton("약관 다시보기", to: .terms)
                navigationButton("오픈소스 라이센스", to: .licenses)
                navigationButton("계정정보 관리", to: .accountManagement)
                HStack {
                    Text("버전").rodiTypography(.body1Medium)
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
                        .rodiTypography(.body1Medium)
                }
                .foregroundStyle(RodiColor.black)
                .frame(height: 45)
            }
            .padding(.horizontal, 16)
            .buttonStyle(.plain)
            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func navigationButton(_ title: String, to route: MyRoute) -> some View {
        Button { navigate(route) } label: { MyNavigationRow(title: title) }
    }
}

struct MyAccountManagementView: View {
    let backAction: () -> Void
    let navigate: (MyRoute) -> Void
    let logoutAction: () -> Void
    let withdrawalAction: () -> Void
    @State private var confirmation: AccountConfirmation?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MySubpageHeader(title: "개인정보 관리", backAction: backAction)
                VStack(spacing: 0) {
                    Button { navigate(.contact) } label: { MyNavigationRow(title: "문의하기") }
                    Button { confirmation = .logout } label: { MyPlainRow(title: "로그아웃") }
                    Button { confirmation = .withdrawal } label: { MyPlainRow(title: "계정 삭제하기") }
                }
                .padding(.horizontal, 16)
                .buttonStyle(.plain)
                Spacer()
            }
            .background(RodiColor.white)
            .toolbar(.hidden, for: .navigationBar)

            if let confirmation {
                MyAccountConfirmationDialog(
                    confirmation: confirmation,
                    confirm: {
                        self.confirmation = nil
                        confirmation == .logout ? logoutAction() : withdrawalAction()
                    },
                    cancel: { self.confirmation = nil }
                )
            }
        }
    }
}

private enum AccountConfirmation: Equatable {
    case logout
    case withdrawal

    var title: String { self == .logout ? "로그아웃 하시겠습니까?" : "정말 계정을 삭제하시겠습니까?" }
    var message: String? { self == .logout ? nil : "삭제 후 3일 이내 재로그인 시 복구 가능합니다.  10일 이후 재가입 가능합니다." }
    var dialogHeight: CGFloat { self == .logout ? 189 : 226 }
}

private struct MyAccountConfirmationDialog: View {
    let confirmation: AccountConfirmation
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        Color.black.opacity(0.4).ignoresSafeArea().overlay {
            VStack(spacing: 0) {
                Text(confirmation.title)
                    .rodiTypography(.body1SemiBold).foregroundStyle(RodiColor.black).multilineTextAlignment(.center)
                    .frame(width: 240, height: confirmation.message == nil ? 60 : nil).padding(.top, 32)
                if let message = confirmation.message {
                    Text(message).rodiTypography(.caption1Medium).foregroundStyle(RodiColor.black).multilineTextAlignment(.center)
                        .frame(width: 240, height: 60).padding(.top, 16)
                }
                HStack(spacing: 8) {
                    Button(action: confirm) {
                        Text("예").rodiTypography(.body1Medium).foregroundStyle(RodiColor.gray800)
                            .frame(width: 116, height: 44).background(RodiColor.white).clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay { RoundedRectangle(cornerRadius: 8).stroke(RodiColor.gray300, lineWidth: 1) }
                    }
                    Button(action: cancel) {
                        Text("아니오").rodiTypography(.body1Medium).foregroundStyle(RodiColor.white)
                            .frame(width: 116, height: 44).background(RodiColor.primary).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .buttonStyle(.plain).padding(.top, 24)
                Spacer(minLength: 0)
            }
            .frame(width: 280, height: confirmation.dialogHeight)
            .background(RodiColor.white).clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityElement(children: .contain)
    }
}

struct MyContactView: View {
    let backAction: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "문의하기", backAction: backAction)
            VStack(alignment: .leading, spacing: 8) {
                Text("문의 이메일").rodiTypography(.body1Medium).foregroundStyle(RodiColor.black)
                Text("yangyunseo71@gmail.com로 연락바랍니다.").rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray800)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16).padding(.top, 24)
            Spacer()
        }.background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
    }
}

struct MyTermsView: View {
    let backAction: () -> Void
    let navigate: (MyRoute) -> Void
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "약관 다시보기", backAction: backAction)
            VStack(spacing: 0) {
                ForEach(LegalDocument.allCases) { document in
                    Button { navigate(.legalDocument(document)) } label: { MyNavigationRow(title: document.title) }
                }
            }.padding(.horizontal, 16).buttonStyle(.plain)
            Spacer()
        }.background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
    }
}

struct MyLegalDocumentView: View {
    let document: LegalDocument
    let backAction: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: document.title, backAction: backAction)
            LegalWKWebView(url: document.url)
        }.background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
    }
}

struct MyOpenSourceLicenseView: View {
    let backAction: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "오픈소스 라이센스", backAction: backAction)
            LegalWKWebView(url: LegalDocument.openSourceLicenseURL)
        }.background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
    }
}

struct MyPermissionSettingsView: View {
    let backAction: () -> Void
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "권한 설정 변경", backAction: backAction)
            Button(action: openSystemLocationSettings) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("위치").rodiTypography(.body1Medium).foregroundStyle(RodiColor.black)
                        Spacer()
                        Text(locationAuthorizationTitle).rodiTypography(.body1Medium).foregroundStyle(RodiColor.gray600)
                        Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium)).foregroundStyle(RodiColor.gray700).frame(width: 20, height: 20)
                    }
                    Text("내 주변 운전 연습 코스를 추천하기 위해 필요해요.").rodiTypography(.caption2Medium).foregroundStyle(RodiColor.gray600)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }
            .buttonStyle(.plain).padding(.horizontal, 16).padding(.top, 24)
            Spacer()
        }
        .background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshAuthorizationStatus)
        .onChange(of: scenePhase) { phase in if phase == .active { refreshAuthorizationStatus() } }
    }

    private var locationAuthorizationTitle: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: "허용됨"
        case .denied, .restricted: "허용 안 됨"
        case .notDetermined: "설정 필요"
        @unknown default: "설정 필요"
        }
    }
    private func refreshAuthorizationStatus() { authorizationStatus = CLLocationManager().authorizationStatus }
    private func openSystemLocationSettings() { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
}
