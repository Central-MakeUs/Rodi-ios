#if DEBUG
import SwiftUI

struct DebugNicknamePreviewPage: View {
    @Environment(\.dismiss) private var dismiss

    private var previewState: OnboardingProfileReducer.State {
        var session = OnboardingSession()
        session.nickname = "로디"
        return .init(session: session, screen: .nickname)
    }

    var body: some View {
        OnboardingContainer(step: .nickname) {
            NicknameView(state: previewState, send: { _ in })
        } onBack: {
            dismiss()
        }
    }
}
#endif
