//
//  _CancelID.swift
//  Rodi
//
//  Created by Yundal8755 on 7/1/26.
//

import Foundation

struct _CancelID: Hashable {
    private let uuid = UUID()
    let id: AnyHashable

    init(id: AnyHashable) {
        self.id = id
    }
}
