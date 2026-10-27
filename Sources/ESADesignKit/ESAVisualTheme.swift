//
//  ESAVisualTheme.swift
//
//  Shared visual styles and semantic colors for ESA surfaces.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The visual treatment used by ESADesignKit surfaces.
public enum ESAVisualStyle: String, CaseIterable, Codable, Sendable {
    /// The original blurred artwork and frosted material appearance.
    case artwork
    /// A solid, accessible color derived from the current artwork.
    case adaptiveColor
    /// A host supplied palette used independently of artwork.
    case uniform
}

/// Five discrete Artwork backdrop treatments. The default (.standard) preserves
/// the original 8pt row blur, 50pt full-screen blur and frosted materials.
/// Host apps persist the raw value; ESADesignKit only consumes the environment.
public enum ESAArtworkBlurLevel: Int, CaseIterable, Codable, Sendable {
    case minimal = 0
    case soft = 1
    case standard = 2
    case strong = 3
    case maximum = 4

    public var rowBlurRadius: CGFloat {
        switch self {
        case .minimal: 2
        case .soft: 5
        case .standard: 8
        case .strong: 14
        case .maximum: 24
        }
    }

    public var fullBackgroundBlurRadius: CGFloat {
        switch self {
        case .minimal: 12
        case .soft: 30
        case .standard: 50
        case .strong: 65
        case .maximum: 80
        }
    }

    /// For the transparent content over rows. Higher levels frost more heavily.
    public var rowMaterial: Material {
        switch self {
        case .minimal, .soft: .ultraThinMaterial
        case .standard: .thinMaterial
        case .strong: .regularMaterial
        case .maximum: .thickMaterial
        }
    }

    /// For a detail screen's moving coverHero content sheet. This is supplied
    /// explicitly by host views; the hero image itself is never blurred.
    public var detailMaterial: Material {
        switch self {
        case .minimal, .soft, .standard: .ultraThinMaterial
        case .strong: .thinMaterial
        case .maximum: .regularMaterial
        }
    }
}

/// Semantic colors used by themed content and surfaces.
public struct ESAThemePalette: @unchecked Sendable {
    public let background: Color
    public let primaryForeground: Color
    public let secondaryForeground: Color
    public let controlForeground: Color
    public let separator: Color
    public let accent: Color?

    public init(
        background: Color,
        primaryForeground: Color,
        secondaryForeground: Color,
        controlForeground: Color,
        separator: Color,
        accent: Color? = nil
    ) {
        self.background = background
        self.primaryForeground = primaryForeground
        self.secondaryForeground = secondaryForeground
        self.controlForeground = controlForeground
        self.separator = separator
        self.accent = accent
    }

    /// A system-aware neutral palette suitable as a host app's starting point.
    public static let standard: ESAThemePalette = {
        #if os(watchOS)
        // UIKit exposes none of its label/background color constants on
        // watchOS. Let native watch surfaces supply their background while
        // retaining SwiftUI's adaptive semantic foregrounds.
        ESAThemePalette(background: .clear,
                        primaryForeground: .primary,
                        secondaryForeground: .secondary,
                        controlForeground: .primary,
                        separator: .secondary.opacity(0.35), accent: .accentColor)
        #elseif canImport(UIKit)
        ESAThemePalette(background: Color(uiColor: .systemBackground),
                        primaryForeground: Color(uiColor: .label),
                        secondaryForeground: Color(uiColor: .secondaryLabel),
                        controlForeground: Color(uiColor: .label),
                        separator: Color(uiColor: .separator), accent: .accentColor)
        #elseif canImport(AppKit)
        ESAThemePalette(background: Color(nsColor: .windowBackgroundColor),
                        primaryForeground: .primary, secondaryForeground: .secondary,
                        controlForeground: .primary, separator: .gray.opacity(0.35), accent: .accentColor)
        #else
        ESAThemePalette(background: .white, primaryForeground: .black,
                        secondaryForeground: .black, controlForeground: .black,
                        separator: .gray.opacity(0.35), accent: .accentColor)
        #endif
    }()

    /// A deterministic palette used until artwork has loaded or if analysis fails.
    public static let fallback = ESAArtworkPalette(background: RGB(red: 0.16, green: 0.18, blue: 0.22)).theme
}

private struct ESAVisualStyleKey: EnvironmentKey {
    static let defaultValue: ESAVisualStyle = .artwork
}

private struct ESAArtworkBlurLevelKey: EnvironmentKey {
    static let defaultValue: ESAArtworkBlurLevel = .standard
}

private struct ESAUniformPaletteKey: EnvironmentKey {
    static let defaultValue: ESAThemePalette = .standard
}

private struct ESASurfacePaletteKey: EnvironmentKey {
    static let defaultValue: ESAThemePalette = .standard
}

public extension EnvironmentValues {
    /// The active ESADesignKit visual style. Defaults to the original Artwork style.
    var esaVisualStyle: ESAVisualStyle {
        get { self[ESAVisualStyleKey.self] }
        set { self[ESAVisualStyleKey.self] = newValue }
    }

    /// Controls Artwork-only row and detail backdrop blur; unrelated designs
    /// and accessibility solid-background fallbacks are not affected.
    var esaArtworkBlurLevel: ESAArtworkBlurLevel {
        get { self[ESAArtworkBlurLevelKey.self] }
        set { self[ESAArtworkBlurLevelKey.self] = newValue }
    }

    /// The host app's palette for the Uniform visual style.
    var esaUniformPalette: ESAThemePalette {
        get { self[ESAUniformPaletteKey.self] }
        set { self[ESAUniformPaletteKey.self] = newValue }
    }

    /// Semantic palette resolved for the nearest ESADesignKit surface.
    var esaThemePalette: ESAThemePalette {
        get { self[ESASurfacePaletteKey.self] }
        set { self[ESASurfacePaletteKey.self] = newValue }
    }
}

public extension View {
    /// Sets the visual style for ESADesignKit surfaces below this view.
    /// The host app owns persistence of this preference.
    func esaVisualStyle(_ style: ESAVisualStyle, uniformPalette: ESAThemePalette = .standard) -> some View {
        environment(\.esaVisualStyle, style)
            .environment(\.esaUniformPalette, uniformPalette)
    }

    /// Supplies the Artwork blur preset to ESADesignKit descendants.
    func esaArtworkBlurLevel(_ level: ESAArtworkBlurLevel) -> some View {
        environment(\.esaArtworkBlurLevel, level)
    }

    /// Resolves the semantic palette for a themed surface and exposes it through
    /// `EnvironmentValues.esaThemePalette` to nested labels and controls.
    func esaResolveTheme(imageURL: URL? = nil, imageData: Data? = nil) -> some View {
        modifier(ESAResolveThemeModifier(imageURL: imageURL, imageData: imageData, imageSource: nil))
    }

    /// Resolves artwork from an image source that already contains decoded pixels.
    func esaResolveTheme(image source: ESAImageSource) -> some View {
        modifier(ESAResolveThemeModifier(imageURL: nil, imageData: nil, imageSource: source))
    }
}

public extension ESAThemePalette {
    /// Resolves an artwork hue into contrast-safe light and dark surfaces.
    /// The same extracted color is kept, with luminance adjusted for the
    /// active appearance so the design remains recognizable in both modes.
    func adaptiveVariant(for colorScheme: ColorScheme) -> ESAThemePalette {
        guard let source = RGB(color: background) else { return self }

        let variant: RGB
        let foreground: Color
        switch colorScheme {
        case .light:
            variant = source.luminance < 0.84
                ? source.adjustedLuminance(toward: RGB(red: 1, green: 1, blue: 1), target: 0.84)
                : source
            foreground = .black
        case .dark:
            variant = source.luminance > 0.12
                ? source.adjustedLuminance(toward: RGB(red: 0, green: 0, blue: 0), target: 0.12)
                : source
            foreground = .white
        @unknown default:
            return self
        }

        return ESAThemePalette(
            background: variant.color,
            primaryForeground: foreground,
            secondaryForeground: foreground.opacity(0.84),
            controlForeground: foreground,
            separator: foreground.opacity(0.35),
            accent: accent
        )
    }
}

private struct ESAResolveThemeModifier: ViewModifier {
    let imageURL: URL?
    let imageData: Data?
    let imageSource: ESAImageSource?
    @Environment(\.esaVisualStyle) private var style
    @Environment(\.esaUniformPalette) private var uniformPalette
    @Environment(\.colorScheme) private var colorScheme
    @State private var artworkPalette = ESAThemePalette.fallback

    private var cacheKey: String {
        if let imageSource {
            switch imageSource {
            case let .url(url): return url?.absoluteString ?? "none"
            case .image: return "image"
            case let .platformImage(image): return "platform:\(ObjectIdentifier(image).hashValue)"
            }
        }
        return imageURL?.absoluteString ?? imageData.map { "data:\($0.hashValue)" } ?? "none"
    }
    private var resolved: ESAThemePalette {
        switch style {
        case .artwork: return .standard
        case .adaptiveColor: return artworkPalette.adaptiveVariant(for: colorScheme)
        case .uniform: return uniformPalette
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.esaThemePalette, resolved)
            .task(id: "\(style.rawValue):\(cacheKey)") {
                guard style == .adaptiveColor else { return }
                let palette: ESAArtworkPalette?
                if let imageSource {
                    switch imageSource {
                    case let .url(url):
                        if let url {
                            palette = await ESAArtworkPaletteCache.shared.palette(for: url)
                        } else {
                            palette = nil
                        }
                    case .image:
                        palette = nil
                    case let .platformImage(image):
                        palette = await ESAArtworkPaletteCache.shared.palette(for: image, key: cacheKey)
                    }
                } else if let imageURL {
                    palette = await ESAArtworkPaletteCache.shared.palette(for: imageURL)
                } else if let imageData {
                    palette = await ESAArtworkPaletteCache.shared.palette(for: imageData)
                } else {
                    palette = nil
                }
                artworkPalette = palette?.theme ?? .fallback
            }
    }
}

/// A representative artwork color and its contrast-safe semantic palette.
public struct ESAArtworkPalette: @unchecked Sendable {
    public let background: Color
    public let primaryForeground: Color
    public let secondaryForeground: Color
    public let controlForeground: Color
    public let separator: Color
    public let accent: Color?

    init(background: RGB) {
        let adjusted = background.accessibleBackground
        self.background = adjusted.color
        // Choose the contrasting neutral at the WCAG AA crossover. Keeping
        // the extracted background intact lets saturated cover colors remain
        // vivid while still providing readable text and controls.
        let foreground = adjusted.luminance > 0.179 ? Color.black : Color.white
        primaryForeground = foreground
        secondaryForeground = foreground
        controlForeground = foreground
        separator = foreground.opacity(0.35)
        accent = nil
    }

    public var theme: ESAThemePalette {
        ESAThemePalette(background: background, primaryForeground: primaryForeground,
                        secondaryForeground: secondaryForeground, controlForeground: controlForeground,
                        separator: separator, accent: accent)
    }

    /// Relative luminance contrast ratio between two sRGB colors.
    public static func contrastRatio(_ first: Color, _ second: Color) -> Double? {
        guard let a = RGB(color: first), let b = RGB(color: second) else { return nil }
        let light = max(a.luminance, b.luminance)
        let dark = min(a.luminance, b.luminance)
        return (light + 0.05) / (dark + 0.05)
    }
}

struct RGB: Sendable {
    var red: Double
    var green: Double
    var blue: Double

    var color: Color { Color(red: red, green: green, blue: blue) }
    var luminance: Double {
        func linear(_ value: Double) -> Double { value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
    var accessibleBackground: RGB {
        // The palette selects black above 0.179 luminance and white at or
        // below it. Both choices meet WCAG AA contrast for normal text, so
        // preserve the extracted artwork color instead of dimming every dark
        // hue to the same near-black value.
        self
    }

    func adjustedLuminance(toward destination: RGB, target: Double) -> RGB {
        var lower = 0.0
        var upper = 1.0
        let increasingLuminance = target > luminance
        for _ in 0..<20 {
            let amount = (lower + upper) / 2
            let candidate = RGB(
                red: red + (destination.red - red) * amount,
                green: green + (destination.green - green) * amount,
                blue: blue + (destination.blue - blue) * amount
            )
            let shouldIncreaseAmount = increasingLuminance
                ? candidate.luminance < target
                : candidate.luminance > target
            if shouldIncreaseAmount { lower = amount } else { upper = amount }
        }
        let amount = (lower + upper) / 2
        return RGB(
            red: red + (destination.red - red) * amount,
            green: green + (destination.green - green) * amount,
            blue: blue + (destination.blue - blue) * amount
        )
    }

    init(red: Double, green: Double, blue: Double) { self.red = red; self.green = green; self.blue = blue }
    init?(color: Color) {
        #if canImport(UIKit)
        let value = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard value.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        self.init(red: Double(r), green: Double(g), blue: Double(b))
        #elseif canImport(AppKit)
        guard let value = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        self.init(red: value.redComponent, green: value.greenComponent, blue: value.blueComponent)
        #else
        return nil
        #endif
    }
}

private extension Color {
    init(uiColor: PlatformColor) {
        #if canImport(UIKit)
        self.init(uiColor)
        #elseif canImport(AppKit)
        self.init(nsColor: uiColor)
        #endif
    }
}

#if canImport(UIKit)
private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
private typealias PlatformColor = NSColor
#endif
