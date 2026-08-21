//
//  LegalSettingsView.swift
//  Rodi
//

import SwiftUI

private enum LegalSettingsRoute: Route {
    case document(LegalDocument)
    case contact

    var id: String {
        switch self {
        case .document(let document): "legal.document.\(document.rawValue)"
        case .contact: "legal.contact"
        }
    }
}

struct LegalSettingsView: View {
    @StateObject private var coordinator = Coordinator<LegalSettingsRoute>()

    let title: String
    var logoutAction: (() -> Void)?
    var withdrawalAction: (() -> Void)?

    init(
        title: String = "설정",
        logoutAction: (() -> Void)? = nil,
        withdrawalAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.logoutAction = logoutAction
        self.withdrawalAction = withdrawalAction
    }

    var body: some View {
        NavigationStack(path: coordinator.pathBinding) {
            List {
                Section {
                    ForEach(LegalDocument.allCases) { document in
                        Button {
                            coordinator.router.push(.document(document))
                        } label: {
                            Text(document.title)
                                .rodiTypography(.body3Medium)
                                .foregroundStyle(RodiColor.black)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button {
                        coordinator.router.push(.contact)
                    } label: {
                        Text("문의")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.black)
                    }
                    .buttonStyle(.plain)
                }

                if let logoutAction {
                    Section {
                        Button(role: .destructive, action: logoutAction) {
                            Text("로그아웃")
                                .rodiTypography(.body3Medium)
                        }

                        if let withdrawalAction {
                            Button(role: .destructive, action: withdrawalAction) {
                                Text("회원탈퇴")
                                    .rodiTypography(.body3Medium)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LegalSettingsRoute.self) { route in
                switch route {
                case .document(let document):
                    LegalWKWebView(url: document.url)
                        .navigationTitle(document.title)
                        .navigationBarTitleDisplayMode(.inline)
                case .contact:
                    LegalWKWebView(url: LegalDocument.supportURL)
                        .navigationTitle("문의")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
