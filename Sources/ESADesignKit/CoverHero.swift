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
    ///   - material: Frosting material for the content that covers the hero.
    ///   - placeholderAspectRatio: Width/height used to size the hero when there is no image.
    ///
    /// This modifier adapts the content automatically: it makes the scroll
    /// content transparent, reserves the cover's footprint with a scrollable top
    /// margin, and paints one continuous frosted sheet behind the content that
    /// rises over the cover as you scroll — so no per-row/header/spacer helpers
    /// are required. (The `frosted…` helpers in FrostedContent.swift remain
    /// available for hand-built layouts that need finer control.)
    func coverHero(
        imageData: Data?,
        title: String = "",
        enabled: Bool = true,
        material: Material = .ultraThinMaterial,
        placeholderAspectRatio: CGFloat = 3.0 / 2.0
    ) -> some View {
        modifier(
            CoverHeroModifier(
                content: ESACoverHeroContent(imageData: imageData),
                title: title,
                enabled: enabled,
                material: material,
                placeholderAspectRatio: placeholderAspectRatio
            )
        )
    }

    /// Draws a cover hero from an ``ESAImageSource`` — a remote/file `URL` or a
    /// ready-made SwiftUI `Image`. This is the companion to `coverHero(imageData:)`
    /// for callers that work in URLs or `Image`s instead of raw `Data`.
    ///
    /// URL sources are downloaded (and cached) off the main thread, so the hero and
    /// its aspect ratio come from the real pixels. `Image` sources are drawn as-is;
    /// because a SwiftUI `Image` does not expose its pixel size, they fall back to
    /// `placeholderAspectRatio` for the resting hero height.
    ///
    /// - Parameters:
    ///   - source: A `.url(URL?)` or `.image(Image)` cover source.
    ///   - title: Optional title drawn across the bottom of the cover. Empty hides it.
    ///   - enabled: When `false` the modifier is a no-op (e.g. on regular-width layouts).
    ///   - material: Frosting material for the content that covers the hero.
    ///   - placeholderAspectRatio: Width/height used until the image loads / when there is none.
    func coverHero(
        image source: ESAImageSource,
        title: String = "",
        enabled: Bool = true,
        material: Material = .ultraThinMaterial,
        placeholderAspectRatio: CGFloat = 3.0 / 2.0
    ) -> some View {
        modifier(
            CoverHeroSourceModifier(
                source: source,
                title: title,
                enabled: enabled,
                material: material,
                placeholderAspectRatio: placeholderAspectRatio
            )
        )
    }

    /// Convenience for `coverHero(image: .url(url), …)`.
    func coverHero(
        image url: URL?,
        title: String = "",
        enabled: Bool = true,
        material: Material = .ultraThinMaterial,
        placeholderAspectRatio: CGFloat = 3.0 / 2.0
    ) -> some View {
        coverHero(
            image: .url(url),
            title: title,
            enabled: enabled,
            material: material,
            placeholderAspectRatio: placeholderAspectRatio
        )
    }

    /// Convenience for `coverHero(image: .image(image), …)`.
    func coverHero(
        image: Image,
        title: String = "",
        enabled: Bool = true,
        material: Material = .ultraThinMaterial,
        placeholderAspectRatio: CGFloat = 3.0 / 2.0
    ) -> some View {
        coverHero(
            image: .image(image),
            title: title,
            enabled: enabled,
            material: material,
            placeholderAspectRatio: placeholderAspectRatio
        )
    }
}

// MARK: - Resolved cover content

/// The cover the hero actually draws, resolved from whatever source the caller
/// passed. A `platformImage` carries real pixels (so its aspect ratio is known);
/// a SwiftUI `image` is drawn as-is with the placeholder aspect ratio.
enum ESACoverHeroContent {
    case empty
    case platformImage(ESAPlatformImage)
    case image(Image)

    init(imageData: Data?) {
        if let imageData, let image = ESAPlatformImage(data: imageData) {
            self = .platformImage(image)
        } else {
            self = .empty
        }
    }

    /// The cover's natural width/height, or `placeholder` when it can't be derived
    /// (no image, or a SwiftUI `Image` whose pixel size is opaque to us).
    func aspectRatio(placeholder: CGFloat) -> CGFloat {
        if case let .platformImage(image) = self,
           image.size.width > 0, image.size.height > 0 {
            return image.size.width / image.size.height
        }
        return placeholder
    }
}

// MARK: - Source-driven modifier

/// Resolves an ``ESAImageSource`` into ``ESACoverHeroContent`` (downloading URL
/// sources off the main thread) and hands it to ``CoverHeroModifier``.
private struct CoverHeroSourceModifier: ViewModifier {
    let source: ESAImageSource
    let title: String
    let enabled: Bool
    let material: Material
    let placeholderAspectRatio: CGFloat
    @State private var resolved: ESACoverHeroContent

    init(
        source: ESAImageSource,
        title: String,
        enabled: Bool,
        material: Material,
        placeholderAspectRatio: CGFloat
    ) {
        self.source = source
        self.title = title
        self.enabled = enabled
        self.material = material
        self.placeholderAspectRatio = placeholderAspectRatio
        // Seed synchronously so a static `Image` (or a cached URL) shows without a
        // placeholder frame; a cold URL resolves in `.task`.
        _resolved = State(initialValue: Self.immediateContent(for: source))
    }

    func body(content: Content) -> some View {
        content
            .modifier(
                CoverHeroModifier(
                    content: resolved,
                    title: title,
                    enabled: enabled,
                    material: material,
                    placeholderAspectRatio: placeholderAspectRatio
                )
            )
            .task(id: taskID) { await resolve() }
    }

    private var taskID: String {
        switch source {
        case let .url(url): return url?.absoluteString ?? "none"
        case .image: return "image"
        }
    }

    @MainActor
    private func resolve() async {
        switch source {
        case let .image(image):
            resolved = .image(image)
        case let .url(url):
            guard let url else {
                resolved = .empty
                return
            }
            if let cached = ESAImageCache.shared.cached(for: url) {
                resolved = .platformImage(cached)
                return
            }
            if let image = await ESAImageCache.shared.image(for: url),
               url.absoluteString == taskID {
                resolved = .platformImage(image)
            }
        }
    }

    private static func immediateContent(for source: ESAImageSource) -> ESACoverHeroContent {
        switch source {
        case let .image(image):
            return .image(image)
        case let .url(url):
            if let url, let cached = ESAImageCache.shared.cached(for: url) {
                return .platformImage(cached)
            }
            return .empty
        }
    }
}

// MARK: - Modifier

private struct CoverHeroModifier: ViewModifier {
    let content: ESACoverHeroContent
    let title: String
    let enabled: Bool
    let material: Material
    let placeholderAspectRatio: CGFloat
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content viewContent: Content) -> some View {
        if enabled {
            if colorSchemeContrast == .increased {
                viewContent
                    .background {
                        ESAAccessibilityBackground()
                            .ignoresSafeArea(.all)
                    }
            } else {
                let aspect = self.content.aspectRatio(placeholder: placeholderAspectRatio)

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let topInset = proxy.safeAreaInsets.top
                    // Reserve the cover's natural full-width height for the scroll
                    // content — measured below the bar, exactly like the content itself.
                    let coverHeight = width / max(0.01, aspect)

                    viewContent
                        // Make the content see-through so the backdrop shows, and reserve
                        // the cover's footprint with a scrollable top margin (works for
                        // List and ScrollView alike).
                        .scrollContentBackground(.hidden)
                        .contentMargins(.top, coverHeight, for: .scrollContent)
                        .esaTrackVerticalScroll { scrollOffset = $0 }
                        // A single full-bleed backdrop draws the cover and the frosted
                        // sheet in one coordinate space, so they always meet with no gap.
                        // The resting cover is extended by the top safe-area inset so its
                        // bottom lands exactly where the (inset) content begins.
                        .background(alignment: .top) {
                            CoverHeroBackdrop(
                                content: self.content,
                                title: title,
                                scrollOffset: scrollOffset,
                                material: material,
                                containerWidth: width,
                                coverHeight: coverHeight,
                                topInset: topInset,
                                containerHeight: proxy.size.height
                            )
                        }
                }
            }
        } else {
            viewContent
        }
    }
}

// MARK: - Scroll tracking (availability-guarded)

private extension View {
    /// Reports upward scroll distance from the resting position. Content margins
    /// are exposed as scroll insets, so raw `contentOffset.y` stays negative while
    /// the first frosted content is already moving over the hero.
    @ViewBuilder
    func esaTrackVerticalScroll(_ action: @escaping (CGFloat) -> Void) -> some View {
        if #available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *) {
            self.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, newValue in
                action(newValue)
            }
        } else {
            self
        }
    }
}

// MARK: - Cover backdrop

/// The full-bleed backdrop behind the content: the cover pinned to the top plus a
/// frosted sheet directly below it, laid out in one coordinate space so they meet
/// seamlessly at any aspect ratio. At rest the cover fills the width at its natural
/// height (extended by the top safe-area inset so it reaches the content); scrolling
/// up grows the cover while the frosted sheet rises over it until the cover fills the
/// whole height.
private struct CoverHeroBackdrop: View {
    let content: ESACoverHeroContent
    let title: String
    let scrollOffset: CGFloat
    let material: Material
    /// The scroll container's width; the zoomed cover is cropped to this.
    let containerWidth: CGFloat
    /// The cover's natural full-width height (matches the reserved content margin).
    let coverHeight: CGFloat
    /// Top safe-area inset, so the resting cover reaches down to the content.
    let topInset: CGFloat
    /// The scroll container's height inside the safe area.
    let containerHeight: CGFloat

    var body: some View {
        // The resting cover bleeds under the top bar, so it must be that much taller
        // for its bottom to meet the safe-area-inset content.
        let restHeight = coverHeight + topInset
        let scrolledUp = max(0, scrollOffset)
        let fullHeight = containerHeight + topInset

        // Grow from the natural height until the cover covers the whole height.
        let maxScale = max(1, fullHeight / max(1, restHeight))
        let scale = min(maxScale, 1 + scrolledUp / max(1, restHeight))

        ZStack(alignment: .top) {
            cover
                .frame(width: containerWidth)
                .frame(height: restHeight)
                .overlay(alignment: .bottom) { titleOverlay }
                .scaleEffect(scale, anchor: .top)
                .frame(width: containerWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()

            // Frosted sheet, directly below the resting cover, rising as we scroll up.
            Rectangle()
                .fill(material)
                .frame(width: containerWidth, height: fullHeight + restHeight)
                .offset(y: max(0, restHeight - scrolledUp))
        }
        .frame(width: containerWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        // Bleed vertically under the status bar / home indicator, but keep the
        // artwork and title clipped to the scroll container's horizontal bounds.
        .ignoresSafeArea(.all, edges: .vertical)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var cover: some View {
        switch content {
        case let .platformImage(image):
            // The frame matches the cover's aspect ratio, so filling it shows the
            // whole cover at rest; the zoom crops it uniformly as it grows.
            Image(esaPlatformImage: image)
                .resizable()
                .scaledToFill()
        case let .image(image):
            image
                .resizable()
                .scaledToFill()
        case .empty:
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
