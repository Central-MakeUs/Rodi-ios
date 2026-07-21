//
//  LegalWebView.swift
//  Rodi
//
//  Created by Codex on 6/29/26.
//

import SwiftUI
import WebKit

struct LegalWebView: View {
    let title: String
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LegalWKWebView(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct LegalSettingsView: View {
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
        NavigationStack {
            List {
                Section {
                    ForEach(LegalDocument.allCases) { document in
                        NavigationLink {
                            LegalWKWebView(url: document.url)
                                .navigationTitle(document.title)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            Text(document.title)
                                .rodiTypography(.body3Medium)
                                .foregroundStyle(RodiColor.black)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        LegalWKWebView(url: LegalDocument.supportURL)
                            .navigationTitle("문의")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Text("문의")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.black)
                    }
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
        }
    }
}

struct LegalWKWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard uiView.url != url else { return }
        uiView.load(URLRequest(url: url))
    }
}
