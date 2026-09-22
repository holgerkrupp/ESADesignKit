//
//  ScrollingHero.swift
//  ESADesignKit
//
//  A content-agnostic companion to `coverHero`. Use it when the hero is a live
//  SwiftUI view (for example a map) rather than cover artwork.
//

import SwiftUI

public extension View {
    /// Draws an arbitrary view behind this scrollable view and transitions it
    /// into the frosted background as the content scrolls over it.
    ///
    /// The modifier reserves `height` points at the top of the scroll content.
    /// The hero fills that space at rest, then grows behind one continuous
    /// material sheet while the sheet rises with the scrolling content.
    ///
    /// `coverHero` remains the preferred API for images because it can infer the
    /// artwork's natural aspect ratio. Use `scrollingHero` for maps, gradients,
    /// video, or any other custom SwiftUI content.
    func scrollingHero<Hero: View>(
        height: CGFloat,
        enabled: Bool = true,
        material: Material = .ultraThinMaterial,
        @ViewBuilder hero: () -> Hero
    ) -> some View {
        modifier(
            ScrollingHeroModifier(
                hero: hero(),
                height: height,
                enabled: enabled,
                material: material
            )
        )
    }
}

private struct ScrollingHeroModifier<Hero: View>: ViewModifier {
    let hero: Hero
    let height: CGFloat
    let enabled: Bool
    let material: Material

    @State private var scrollOffset: CGFloat = 0
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        if enabled {
            if colorSchemeContrast == .increased {
                content
                    .background {
                        ESAAccessibilityBackground()
                            .ignoresSafeArea(.all)
                    }
            } else {
                GeometryReader { proxy in
                    let heroHeight = max(1, height)

                    content
                        .scrollContentBackground(.hidden)
                        .contentMargins(.top, heroHeight, for: .scrollContent)
                        .scrollingHeroTrackVerticalScroll { scrollOffset = $0 }
                        .background(alignment: .top) {
                            ScrollingHeroBackdrop(
                                hero: hero,
                                scrollOffset: scrollOffset,
                                material: material,
                                containerWidth: proxy.size.width,
                                heroHeight: heroHeight,
                                topInset: proxy.safeAreaInsets.top,
                                containerHeight: proxy.size.height
                            )
                        }
                }
            }
        } else {
            content
        }
    }
}

private extension View {
    @ViewBuilder
    func scrollingHeroTrackVerticalScroll(_ action: @escaping (CGFloat) -> Void) -> some View {
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

private struct ScrollingHeroBackdrop<Hero: View>: View {
    let hero: Hero
    let scrollOffset: CGFloat
    let material: Material
    let containerWidth: CGFloat
    let heroHeight: CGFloat
    let topInset: CGFloat
    let containerHeight: CGFloat

    var body: some View {
        let restHeight = heroHeight + topInset
        let scrolledUp = max(0, scrollOffset)
        let fullHeight = containerHeight + topInset
        let maxScale = max(1, fullHeight / max(1, restHeight))
        let scale = min(maxScale, 1 + scrolledUp / max(1, restHeight))

        ZStack(alignment: .top) {
            hero
                .frame(width: containerWidth, height: restHeight)
                .scaleEffect(scale, anchor: .top)
                .frame(width: containerWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()

            Rectangle()
                .fill(material)
                .frame(width: containerWidth, height: fullHeight + restHeight)
                .offset(y: max(0, restHeight - scrolledUp))
        }
        .frame(width: containerWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.all, edges: .vertical)
    }
}
