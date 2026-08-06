//
//  View+.swift
//  MiniHack
//
//  Created by mac on 5/15/26.
//

import SwiftUI

extension View {

    func rodiSnackbar(message: String?) -> some View {
        modifier(RodiSnackbarModifier(message: message))
    }
}
