import LicenseList
import SwiftUI

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
            LicenseListView().licenseViewStyle(.withRepositoryAnchorLink)
        }.background(RodiColor.white).toolbar(.hidden, for: .navigationBar)
    }
}
