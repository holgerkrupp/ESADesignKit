//
//  ESAArtworkPaletteCache.swift
//

import SwiftUI
import CoreGraphics

/// Thread-safe, in-memory cache for representative artwork palettes.
final class ESAArtworkPaletteCache: @unchecked Sendable {
    static let shared = ESAArtworkPaletteCache()
    private let cache = NSCache<NSString, ESAArtworkPaletteBox>()

    private init() { cache.countLimit = 240 }

    func palette(for url: URL) async -> ESAArtworkPalette? {
        let key = url.absoluteString as NSString
        let cached = cache.object(forKey: key)?.value
        if let cached { return cached }

        // Reuse the sharp image cache used by coverHero. The cache is populated
        // from this download path, so palette extraction never redownloads it.
        guard let image = await ESAImageCache.shared.image(for: url) else { return nil }
        return await palette(for: image, key: url.absoluteString)
    }

    func palette(for image: ESAPlatformImage, key: String) async -> ESAArtworkPalette? {
        let cacheKey = key as NSString
        if let cached = cache.object(forKey: cacheKey)?.value { return cached }
        let result = await Task.detached(priority: .utility) { Self.extract(from: image) }.value
        if let result {
            let palette = ESAArtworkPalette(background: result)
            cache.setObject(ESAArtworkPaletteBox(palette), forKey: cacheKey)
            return palette
        }
        return nil
    }

    private static func extract(from image: ESAPlatformImage) -> RGB? {
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return nil }
        #elseif canImport(AppKit)
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #endif
        let width = 48, height = 48
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .low
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { return nil }

        // Quantize into 5-bit RGB buckets and choose the most frequent bucket.
        // Transparent pixels are excluded; a small sample bounds the cost.
        var histogram: [UInt32: Int] = [:]
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 12 {
            let r = UInt32(pixels[index] >> 3), g = UInt32(pixels[index + 1] >> 3), b = UInt32(pixels[index + 2] >> 3)
            histogram[(r << 10) | (g << 5) | b, default: 0] += 1
        }
        guard let dominant = histogram.max(by: { $0.value < $1.value })?.key else { return nil }
        let rgb = RGB(red: Double((dominant >> 10) & 31) / 31,
                      green: Double((dominant >> 5) & 31) / 31,
                      blue: Double(dominant & 31) / 31)
        return rgb
    }
}

/// Public entry point for extracting accessible palettes from existing artwork.
public enum ESAArtworkPaletteExtractor {
    /// A deterministic palette to use while artwork loads or if decoding fails.
    public static let fallback = ESAThemePalette.fallback

    /// Extracts a palette using the shared URL image cache.
    public static func palette(for url: URL) async -> ESAArtworkPalette? {
        await ESAArtworkPaletteCache.shared.palette(for: url)
    }

    /// Extracts a palette from encoded image data, keyed by a stable content hash.
    public static func palette(for imageData: Data) async -> ESAArtworkPalette? {
        await ESAArtworkPaletteCache.shared.palette(for: imageData)
    }
}

private final class ESAArtworkPaletteBox: NSObject {
    let value: ESAArtworkPalette
    init(_ value: ESAArtworkPalette) { self.value = value }
}

/// Stable cache key for content callers that do not have a URL.
extension ESAArtworkPaletteCache {
    func palette(for data: Data) async -> ESAArtworkPalette? {
        let hash = data.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        let key = "data:\(String(hash, radix: 16))"
        if let image = ESAPlatformImage(data: data) { return await palette(for: image, key: key) }
        return nil
    }
}
