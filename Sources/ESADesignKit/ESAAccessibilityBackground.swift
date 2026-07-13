//
//  ESAAccessibilityBackground.swift
//  ESADesignKit
//

import SwiftUI

/// The opaque, maximum-contrast background requested by the system's
/// Increase Contrast accessibility setting.
struct ESAAccessibilityBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Color(white: colorScheme == .dark ? 0 : 1)
    }
}
