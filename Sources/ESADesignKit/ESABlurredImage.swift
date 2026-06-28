//
//  ESABlurredImage.swift
//  ESADesignKit
//
//  Loads and pre-blurs cover images. URLs are blurred once via Core Image and
//  cached, so we never run a live `.blur()` over a full-bleed cover in a list
//  row (which is expensive when many rows scroll).
//

import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias ESAPlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias ESAPlatformImage = NSImage
#endif

#if canImport(CoreImage)
import CoreImage
import CoreImage.CIFilterBuiltins
#endif

/// In-memory cache of already-blurred images, keyed by URL + radius.
final class ESABlurredImageCache: @unchecked Sendable {
    static let shared = ESABlurredImageCache()

    private let cache = NSCache<NSString, ESAPlatformImage>()

    private init() {
        cache.countLimit = 120
    }

    private func key(for url: URL, radius: CGFloat) -> NSString {
        "\(url.absoluteString)|r\(Int(radius.rounded()))" as NSString
    }

    func cached(for url: URL, radius: CGFloat) -> ESAPlatformImage? {
        cache.object(forKey: key(for: url, radius: radius))
    }

    func store(_ image: ESAPlatformImage, for url: URL, radius: CGFloat) {
        cache.setObject(image, forKey: key(for: url, radius: radius))
    }

    /// Returns a cached blurred image, or downloads + blurs + caches one.
    func blurredImage(for url: URL, radius: CGFloat) async -> ESAPlatformImage? {
        if let cached = cached(for: url, radius: radius) {
            return cached
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let original = ESAPlatformImage(data: data) else {
            return nil
        }

        let blurred = Self.blur(original, radius: radius) ?? original
        store(blurred, for: url, radius: radius)
        return blurred
    }

    // MARK: - Core Image blur

    private static let context: CIContext = CIContext(options: [.useSoftwareRenderer: false])

    static func blur(_ image: ESAPlatformImage, radius: CGFloat) -> ESAPlatformImage? {
        #if canImport(CoreImage)
        guard let inputCI = ciImage(from: image) else { return nil }
        let clamped = inputCI.clampedToExtent()

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = clamped
        filter.radius = Float(radius)

        guard let output = filter.outputImage?.cropped(to: inputCI.extent),
              let cgImage = context.createCGImage(output, from: inputCI.extent) else {
            return nil
        }
        return platformImage(from: cgImage, reference: image)
        #else
        return nil
        #endif
    }

    #if canImport(CoreImage)
    private static func ciImage(from image: ESAPlatformImage) -> CIImage? {
        #if canImport(UIKit)
        if let cg = image.cgImage { return CIImage(cgImage: cg) }
        return CIImage(image: image)
        #elseif canImport(AppKit)
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        return CIImage(cgImage: cg)
        #else
        return nil
        #endif
    }

    private static func platformImage(from cgImage: CGImage, reference: ESAPlatformImage) -> ESAPlatformImage {
        #if canImport(UIKit)
        return UIImage(cgImage: cgImage, scale: reference.scale, orientation: reference.imageOrientation)
        #elseif canImport(AppKit)
        return NSImage(cgImage: cgImage, size: reference.size)
        #endif
    }
    #endif
}

extension Image {
    init(esaPlatformImage: ESAPlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: esaPlatformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: esaPlatformImage)
        #endif
    }
}
