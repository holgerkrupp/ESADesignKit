//
//  ESARowView.swift
//  ESADesignKit
//
//  The signature ESA list-row look: a blurred, full-bleed cover image behind a
//  `.thinMaterial` content layer. Apply it to any row content with
//  `.ESA_RowView(image:)`, passing either a `URL` or a SwiftUI `Image`.
//

import SwiftUI

/// Where the blurred background image comes from.
public enum ESAImageSource {
    /// A remote (or file) URL. Downloaded once, blurred via Core Image, and cached.
    case url(URL?)
    /// A ready-made SwiftUI `Image` (asset, SF Symbol, etc.). Blurred live.
    case image(Image)
}

/// A list-row container drawing a blurred cover image behind a material content layer.
///
/// The blur, background opacity, and content alignment are intentionally fixed so
/// every row across every app looks identical. Only `minHeight` (the row's height)
/// is meant to vary per use site.
public struct ESARowView<Content: View>: View {
    private let source: ESAImageSource
    private let minHeight: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.esaVisualStyle) private var visualStyle
    @Environment(\.esaUniformPalette) private var uniformPalette
    @State private var artworkPalette = ESAThemePalette.fallback
    private var activePalette: ESAThemePalette {
        visualStyle == .uniform ? uniformPalette : (visualStyle == .adaptiveColor ? artworkPalette : .standard)
    }

    /// The single, shared blur radius for every ESA row.
    public static var blurRadius: CGFloat { 8 }
    /// The single, shared inner padding for every ESA row.
    public static var contentPadding: CGFloat { 8 }

    public init(
        image source: ESAImageSource,
        minHeight: CGFloat = 80,
        cornerRadius: CGFloat = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.source = source
        self.minHeight = minHeight
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        ZStack {
            if visualStyle == .artwork && colorSchemeContrast == .increased {
                ESAAccessibilityBackground()
                    .accessibilityHidden(true)
            } else if visualStyle == .artwork {
                ESABlurredBackground(
                    source: source,
                    radius: Self.blurRadius,
                    placeholderColor: .accentColor
                )
                .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: minHeight)
                .clipped()
                .accessibilityHidden(true)
            } else {
                activePalette.background
                    .accessibilityHidden(true)
            }

            content
                .padding(Self.contentPadding)
                .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
                .background {
                    if visualStyle == .artwork && colorSchemeContrast == .standard && !reduceTransparency {
                        Rectangle().fill(.thinMaterial)
                    } else if visualStyle != .artwork {
                        activePalette.background
                    }
                }
                .environment(\.esaThemePalette, activePalette)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
        .modifier(ESACornerClip(radius: cornerRadius))
        .task(id: "\(visualStyle.rawValue):\(source.urlValue?.absoluteString ?? "image")") {
            guard visualStyle == .adaptiveColor, let url = source.urlValue else { return }
            let palette = await ESAArtworkPaletteCache.shared.palette(for: url)
            artworkPalette = palette?.theme ?? .fallback
        }
    }
}

// MARK: - View modifier API

public extension View {
    /// Wraps the content in an ``ESARowView`` with a blurred image loaded from `url`.
    func ESA_RowView(
        image url: URL?,
        minHeight: CGFloat = 80,
        cornerRadius: CGFloat = 0
    ) -> some View {
        ESARowView(
            image: .url(url),
            minHeight: minHeight,
            cornerRadius: cornerRadius
        ) { self }
    }

    /// Wraps the content in an ``ESARowView`` with a blurred `Image` background.
    func ESA_RowView(
        image: Image,
        minHeight: CGFloat = 80,
        cornerRadius: CGFloat = 0
    ) -> some View {
        ESARowView(
            image: .image(image),
            minHeight: minHeight,
            cornerRadius: cornerRadius
        ) { self }
    }
}

// MARK: - Helpers

private struct ESACornerClip: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        if radius > 0 {
            content.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            content
        }
    }
}

private extension ESAImageSource {
    var urlValue: URL? { if case let .url(url) = self { return url }; return nil }
}
