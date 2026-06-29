//
//  ESABlurredBackground.swift
//  ESADesignKit
//
//  Shared blurred cover-image view used by both `ESA_RowView` and
//  `ESAFullBackground`. URLs are downloaded once, blurred via Core Image, and
//  cached; ready-made `Image`s are blurred live.
//

import SwiftUI

struct ESABlurredBackground: View {
    let source: ESAImageSource
    let radius: CGFloat
    let placeholderColor: Color

    var body: some View {
        switch source {
        case let .url(url):
            ESABlurredURLImage(url: url, radius: radius, placeholderColor: placeholderColor)
        case let .image(image):
            // No pixels to pre-process, so blur live. Fine for static assets/symbols.
            image
                .resizable()
                .scaledToFill()
                .blur(radius: radius)
        }
    }
}

struct ESABlurredURLImage: View {
    let url: URL?
    let radius: CGFloat
    let placeholderColor: Color

    @State private var loadedImage: Image?
    @State private var lastAppliedKey = ""

    private var key: String {
        guard let url else { return "none" }
        return "\(url.absoluteString)|r\(Int(radius.rounded()))"
    }

    var body: some View {
        Group {
            if let loadedImage {
                loadedImage
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(placeholderColor)
            }
        }
        .task(id: key) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard key != lastAppliedKey else { return }
        guard let url else {
            loadedImage = nil
            lastAppliedKey = key
            return
        }

        // Seed instantly from cache if we have it.
        if let cached = ESABlurredImageCache.shared.cached(for: url, radius: radius) {
            loadedImage = Image(esaPlatformImage: cached)
            lastAppliedKey = key
            return
        }

        if let platformImage = await ESABlurredImageCache.shared.blurredImage(for: url, radius: radius),
           key == self.key {
            loadedImage = Image(esaPlatformImage: platformImage)
            lastAppliedKey = key
        }
    }
}
