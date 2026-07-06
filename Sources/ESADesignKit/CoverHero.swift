//
//  CoverHero.swift
//  ESADesignKit
//
//  An immersive "cover hero" for detail screens. The cover image is drawn
//  *behind* the scrollable content: at rest the whole cover shows at its natural
//  full-width height; scrolling up grows the cover — pinned to the top — until it
//  covers the container's full height, so the (frosted) content slides up over
//  it. Because the cover lives behind the content, the content reliably covers
//  it regardless of how the content is built (`List`, `ScrollView`, …).
//
//  Pair `.coverHero(…)` with a frosting helper so the content actually covers the
//  hero as it scrolls: `frostedDetailRow` / `frostedDetailSectionHeader` for a
//  `List`, or `frostedContentPanel` for other content. See FrostedContent.swift.
//

import SwiftUI

// MARK: - Public API

public extension View {
    /// Draws a full-width cover image behind this scrollable view and grows it as
    /// the view scrolls up so frosted content can slide over it.
    ///
    /// Works with any scrollable container (`List`, `ScrollView`, …). Scroll
    /// tracking uses `onScrollGeometryChange`, so the zoom is active on
    /// iOS 18 / macOS 15 / watchOS 11 and newer; on older systems the cover is
    /// shown without the grow-on-scroll effect.
    ///
    /// - Parameters:
    ///   - imageData: Encoded cover image (PNG/JPEG/…). `nil` shows a placeholder.
    ///   - title: Optional title drawn across the bottom of the cover. Empty hides it.
    ///   - enabled: When `false` the modifier is a no-op (e.g. on regular-width layouts).
    ///   - placeholderAspectRatio: Width/height used to size the hero when there is no image.
    func coverHero(
        imageData: Data?,
        title: String = "",
        enabled: Bool = true,
        placeholderAspectRatio: CGFloat = 3.0 / 2.0
    ) -> some View {
        modifier(
            CoverHeroModifier(
                imageData: imageData,
                title: title,
                enabled: enabled,
                placeholderAspectRatio: placeholderAspectRatio
            )
        )
    }
}

// MARK: - Modifier

private struct CoverHeroModifier: ViewModifier {
    let imageData: Data?
    let title: String
    let enabled: Bool
    let placeholderAspectRatio: CGFloat
    @State private var scrollOffset: CGFloat = 0

    func body(content: Content) -> some View {
        if enabled {
            content
                .esaTrackVerticalScroll { scrollOffset = $0 }
                .background(alignment: .top) {
                    CoverHeroBackground(
                        imageData: imageData,
                        title: title,
                        scrollOffset: scrollOffset,
                        placeholderAspectRatio: placeholderAspectRatio
                    )
                }
        } else {
            content
        }
    }
}

// MARK: - Scroll tracking (availability-guarded)

private extension View {
    /// Reports the container's vertical content offset. A no-op on systems
    /// without `onScrollGeometryChange`.
    @ViewBuilder
    func esaTrackVerticalScroll(_ action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newValue in
                action(newValue)
            }
        } else {
            self
        }
    }
}

// MARK: - Cover background

/// The cover, drawn behind the content. At rest it fills the width at its natural
/// height; as the container scrolls up it grows — pinned to the top — until it
/// covers the whole height, then holds.
private struct CoverHeroBackground: View {
    let imageData: Data?
    let title: String
    let scrollOffset: CGFloat
    var placeholderAspectRatio: CGFloat = 3.0 / 2.0

    var body: some View {
        let platformImage = imageData.flatMap { ESAPlatformImage(data: $0) }
        let aspect = aspectRatio(for: platformImage)

        GeometryReader { proxy in
            let width = proxy.size.width
            let containerHeight = proxy.size.height
            // The cover's natural full-width height — the resting hero size.
            let restHeight = width / aspect
            let scrolledUp = max(0, scrollOffset)

            // Grow from the natural height until the cover covers the whole
            // container height, then hold.
            let maxScale = max(1, containerHeight / max(1, restHeight))
            let scale = min(maxScale, 1 + scrolledUp / max(1, restHeight))

            cover(platformImage)
                .frame(width: width, height: restHeight)
                .overlay(alignment: .bottom) { titleOverlay }
                .scaleEffect(scale, anchor: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
        }
        .accessibilityHidden(true)
    }

    private func aspectRatio(for image: ESAPlatformImage?) -> CGFloat {
        if let size = image?.size, size.width > 0, size.height > 0 {
            return size.width / size.height
        }
        return placeholderAspectRatio
    }

    @ViewBuilder
    private func cover(_ image: ESAPlatformImage?) -> some View {
        if let image {
            // The frame matches the cover's aspect ratio, so filling it shows the
            // whole cover at rest; the zoom crops it uniformly as it grows.
            Image(esaPlatformImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle()
                    .fill(.quaternary)
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var titleOverlay: some View {
        if !title.isEmpty {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.6)
                .shadow(radius: 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 40)
                .padding(.bottom, 16)
                .background(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
    }
}
