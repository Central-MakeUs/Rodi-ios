import SwiftUI

enum CourseRegistrationMapPinLayout {
    static let size: CGFloat = 34
    static let centerAlignmentOffsetY: CGFloat = -15.5
}

struct CourseRegistrationMovingPin: View {
    let target: CourseRegistrationInputTarget

    var body: some View {
        Image(target.movingPinAssetName)
            .resizable()
            .scaledToFit()
            .frame(
                width: CourseRegistrationMapPinLayout.size,
                height: CourseRegistrationMapPinLayout.size
            )
            .offset(y: CourseRegistrationMapPinLayout.centerAlignmentOffsetY)
            .accessibilityHidden(true)
    }
}
