//
//  FrostedContent.swift
//  ESADesignKit
//
//  Frosting helpers that make scrolling content cover a `coverHero` behind it.
//
//  The hero itself (CoverHero.swift) is container-agnostic, but *covering* it is
//  not: a `List` renders each row and section header as a separate cell, so it
//  must be frosted per-row + per-header (there is no single background spanning a
//  List's cells). Other content — a `VStack` inside a `ScrollView` — can be
//  frosted with one panel background. Hence two sets of helpers below.
//

import SwiftUI

public extension View {
    /// Frosts a single detail-`List` row so it covers a `coverHero` behind it.
    /// Apply to each content row (or to a `Section`, which applies it to its rows).
    /// - Parameters:
    ///   - material: The frosting material. Defaults to `.ultraThinMaterial`.
    ///   - enabled: When `false` the row stays clear (e.g. on regular-width layouts).
    func frostedDetailRow(_ material: Material = .ultraThinMaterial, enabled: Bool = true) -> some View {
        modifier(FrostedDetailRow(material: material, enabled: enabled))
    }

    /// Frosts a detail-`List` section header so it covers a `coverHero` behind it,
    /// matching `frostedDetailRow`. Apply to the header content.
    func frostedDetailSectionHeader(_ material: Material = .ultraThinMaterial, enabled: Bool = true) -> some View {
        modifier(FrostedDetailSectionHeader(material: material, enabled: enabled))
    }

    /// Frosts arbitrary, non-`List` content — e.g. a `VStack` inside a
    /// `ScrollView` — so it covers a `coverHero` behind it. Inserts a top spacer
    /// sized to the cover so the hero shows at rest and the content begins below.
    /// - Parameters:
    ///   - coverImageData: The same cover image passed to `coverHero`, used to
    ///     size the spacer to the cover's natural height.
    ///   - material: The frosting material behind the content.
    ///   - enabled: When `false` the content is returned unchanged.
    ///   - placeholderAspectRatio: Width/height used when there is no image.
    func frostedContentPanel(
        coverImageData: Data?,
        material: Material = .ultraThinMaterial,
        enabled: Bool = true,
        placeholderAspectRatio: CGFloat = 3.0 / 2.0
    ) -> some View {
        modifier(
            FrostedContentPanel(
                coverImageData: coverImageData,
                material: material,
                enabled: enabled,
                placeholderAspectRatio: placeholderAspectRatio
            )
        )
    }
}

// MARK: - List helpers

private struct FrostedDetailRow: ViewModifier {
    let material: Material
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .listRowBackground(Rectangle().fill(material))
                .listRowSeparator(.hidden)
        } else {
            content
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }
}

private struct FrostedDetailSectionHeader: ViewModifier {
    let material: Material
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(material)
                .listRowInsets(EdgeInsets())
        } else {
            content
        }
    }
}

// MARK: - Non-List helper

private struct FrostedContentPanel: ViewModifier {
    let coverImageData: Data?
    let material: Material
    let enabled: Bool
    let placeholderAspectRatio: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            VStack(spacing: 0) {
                CoverHeroSpacer(imageData: coverImageData, placeholderAspectRatio: placeholderAspectRatio)
                content
                    .frame(maxWidth: .infinity)
                    .background(material)
            }
        } else {
            content
        }
    }
}

// MARK: - Spacer

/// A clear spacer sized to the cover hero's footprint (full width at the cover's
/// natural height). Use it as the first row of a `List` so the hero shows at rest
/// and the content begins directly below it. (`frostedContentPanel` inserts one
/// for you for non-`List` content.)
public struct CoverHeroSpacer: View {
    private let imageData: Data?
    private let placeholderAspectRatio: CGFloat

    public init(imageData: Data?, placeholderAspectRatio: CGFloat = 3.0 / 2.0) {
        self.imageData = imageData
        self.placeholderAspectRatio = placeholderAspectRatio
    }

    public var body: some View {
        Color.clear
            .aspectRatio(coverAspect, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityHidden(true)
    }

    private var coverAspect: CGFloat {
        if let data = imageData,
           let image = ESAPlatformImage(data: data),
           image.size.width > 0, image.size.height > 0 {
            return image.size.width / image.size.height
        }
        return placeholderAspectRatio
    }
}
