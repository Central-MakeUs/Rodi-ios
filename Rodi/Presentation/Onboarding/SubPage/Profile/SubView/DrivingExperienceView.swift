import SwiftUI

struct DrivingExperienceView: View {
    let state: OnboardingProfileReducer.State
    let send: (OnboardingProfileReducer.Action) -> Void

    var body: some View {
        OnboardingServerFormView(state: state, send: send)
    }
}
