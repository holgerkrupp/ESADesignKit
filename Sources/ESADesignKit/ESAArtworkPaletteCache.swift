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

        // Quantize into 5-bit RGB buckets and choose a frequent, saturated
        // color. Counting exact RGB values made shadows, black borders, and
        // tiny quantization differences drown out the artwork's actual hue.
        // Transparent pixels are excluded; a small sample bounds the cost.
        var histogram: [UInt32: (count: Int, red: Double, green: Double, blue: Double, score: Double)] = [:]
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 12 {
            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let maximum = max(red, green, blue)
            let minimum = min(red, green, blue)
            let saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum
            guard maximum > 0.06 else { continue }

            let key = (UInt32(pixels[index] >> 3) << 10)
                | (UInt32(pixels[index + 1] >> 3) << 5)
                | UInt32(pixels[index + 2] >> 3)
            var bucket = histogram[key, default: (0, 0, 0, 0, 0)]
            bucket.count += 1
            bucket.red += red
            bucket.green += green
            bucket.blue += blue
            // Favor vivid artwork colors without allowing a tiny accent to
            // outweigh a color that is genuinely present across the cover.
            bucket.score += 0.25 + saturation * 1.75
            histogram[key] = bucket
        }
        guard let dominant = histogram.max(by: { $0.value.score < $1.value.score })?.value,
              dominant.count > 0 else { return nil }
        let divisor = Double(dominant.count)
        let rgb = RGB(red: dominant.red / divisor,
                      green: dominant.green / divisor,
                      blue: dominant.blue / divisor)
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
