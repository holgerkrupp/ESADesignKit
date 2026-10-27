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
/// The standard Artwork preset keeps the original 50pt blur and 0.5 dimming;
/// apps may opt into a different blur level through the environment.
public struct ESAFullBackground: View {
    private let source: ESAImageSource
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.esaVisualStyle) private var visualStyle
    @Environment(\.esaArtworkBlurLevel) private var artworkBlurLevel
    @Environment(\.esaUniformPalette) private var uniformPalette
    @State private var artworkPalette = ESAThemePalette.fallback

    private var palette: ESAThemePalette {
        visualStyle == .uniform
            ? uniformPalette
            : (visualStyle == .adaptiveColor ? artworkPalette.adaptiveVariant(for: colorScheme) : .standard)
    }

    /// The legacy standard blur radius, preserved for compatibility.
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
                    radius: artworkBlurLevel.fullBackgroundBlurRadius,
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
        .task(id: "\(visualStyle.rawValue):\(source.cacheKey)") {
            guard visualStyle == .adaptiveColor else { return }
            let result: ESAArtworkPalette?
            switch source {
            case let .url(url):
                if let url {
                    result = await ESAArtworkPaletteCache.shared.palette(for: url)
                } else {
                    result = nil
                }
            case .image:
                result = nil
            case let .platformImage(image):
                result = await ESAArtworkPaletteCache.shared.palette(for: image, key: source.cacheKey)
            }
            artworkPalette = result?.theme ?? .fallback
        }
        .environment(\.esaThemePalette, palette)
    }
}

private extension ESAImageSource {
    var urlValue: URL? { if case let .url(url) = self { return url }; return nil }

    var cacheKey: String {
        switch self {
        case let .url(url): url?.absoluteString ?? "none"
        case .image: "image"
        case let .platformImage(image): "platform:\(ObjectIdentifier(image).hashValue)"
        }
    }
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
