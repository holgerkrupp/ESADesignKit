//
//  ESAFullBackground.swift
//  ESADesignKit
//
//  The signature ESA full-screen backdrop: a heavily blurred, dimmed cover image
//  that fills the whole screen (behind safe areas) under a detail view's content.
//  Apply it to a scroll/list container with `.ESAFullBackground(image:)`, passing
//  either a `URL` or a SwiftUI `Image`.
//

import SwiftUI

/// A full-bleed blurred cover image, sized to fill and dimmed — the standard ESA
/// detail-screen backdrop.
///
/// Like `ESARowView`, the blur radius and dim are intentionally fixed so the look
/// is identical everywhere it's used.
public struct ESAFullBackground: View {
    private let source: ESAImageSource

    /// The single, shared blur radius for the full-screen backdrop.
    public static var blurRadius: CGFloat { 50 }
    /// The single, shared opacity for the full-screen backdrop.
    public static var opacity: Double { 0.5 }

    public init(image source: ESAImageSource) {
        self.source = source
    }

    public var body: some View {
        ESABlurredBackground(
            source: source,
            radius: Self.blurRadius,
            placeholderColor: .accentColor
        )
        .scaledToFill()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .opacity(Self.opacity)
    }
}

// MARK: - View modifier API

public extension View {
    /// Places an ``ESAFullBackground`` (blurred image from `url`) behind this view.
    func ESAFullBackground(image url: URL?) -> some View {
        background {
            ESADesignKit.ESAFullBackground(image: .url(url))
        }
    }

    /// Places an ``ESAFullBackground`` (blurred `Image`) behind this view.
    func ESAFullBackground(image: Image) -> some View {
        background {
            ESADesignKit.ESAFullBackground(image: .image(image))
        }
    }
}
