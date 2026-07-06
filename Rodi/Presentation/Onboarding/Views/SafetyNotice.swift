//
//  SafetyNotice.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct SafetyNotice: View {
    var body: some View {
        Text(attributedNotice)
            .rodiTypography(.caption1Medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RodiColor.primary20)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var attributedNotice: AttributedString {
        var text = AttributedString("로디는 사고가 나지 않는 장소를 보장하지 않습니다.\n연습에 적합한 장소를 추천 드리더라도, 도로 위에서 발생하는\n모든 사고의 책임은 운전자 본인에게 있습니다.\n항상 교통 법규를 준수하고, 안전을 최우선으로 생각해 주세요.")
        text.foregroundColor = RodiColor.gray800

        if let range = text.range(of: "사고가 나지 않는 장소를 보장하지 않습니다.") {
            text[range].foregroundColor = RodiColor.primary
        }

        if let range = text.range(of: "모든 사고의 책임은 운전자 본인에게 있습니다.") {
            text[range].foregroundColor = RodiColor.primary
        }

        return text
    }
}
