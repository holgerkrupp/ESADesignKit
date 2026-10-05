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
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.esaVisualStyle) private var visualStyle
    @Environment(\.esaUniformPalette) private var uniformPalette
    @State private var artworkPalette = ESAThemePalette.fallback

    private var palette: ESAThemePalette {
        visualStyle == .uniform ? uniformPalette : (visualStyle == .adaptiveColor ? artworkPalette : .standard)
    }

    /// The single, shared blur radius for the full-screen backdrop.
    public static var blurRadius: CGFloat { 50 }
    /// The single, shared opacity for the full-screen backdrop.
    public static var opacity: Double { 0.5 }

    public init(image source: ESAImageSource) {
        self.source = source
    }

    public var body: some View {
        Group {
            if colorSchemeContrast == .increased {
                ESAAccessibilityBackground()
            } else if visualStyle == .artwork {
                ESABlurredBackground(
                    source: source,
                    radius: Self.blurRadius,
                    placeholderColor: .accentColor
                )
                .scaledToFill()
                .opacity(Self.opacity)
            } else {
                palette.background
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .task(id: "\(visualStyle.rawValue):\(source.urlValue?.absoluteString ?? "image")") {
            guard visualStyle == .adaptiveColor, let url = source.urlValue else { return }
            let result = await ESAArtworkPaletteCache.shared.palette(for: url)
            artworkPalette = result?.theme ?? .fallback
        }
        .environment(\.esaThemePalette, palette)
    }
}

private extension ESAImageSource {
    var urlValue: URL? { if case let .url(url) = self { return url }; return nil }
}

// MARK: - View modifier API

public extension View {
    /// Places an ``ESAFullBackground`` (blurred image from `url`) behind this view.
    func ESAFullBackground(image url: URL?) -> some View {
        esaResolveTheme(imageURL: url).background {
            ESADesignKit.ESAFullBackground(image: .url(url))
        }
    }

    /// Places an ``ESAFullBackground`` (blurred `Image`) behind this view.
    func ESAFullBackground(image: Image) -> some View {
        esaResolveTheme().background {
            ESADesignKit.ESAFullBackground(image: .image(image))
        }
    }
}
