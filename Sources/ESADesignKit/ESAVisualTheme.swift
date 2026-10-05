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
        #if canImport(UIKit)
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

    /// Resolves the semantic palette for a themed surface and exposes it through
    /// `EnvironmentValues.esaThemePalette` to nested labels and controls.
    func esaResolveTheme(imageURL: URL? = nil, imageData: Data? = nil) -> some View {
        modifier(ESAResolveThemeModifier(imageURL: imageURL, imageData: imageData))
    }
}

private struct ESAResolveThemeModifier: ViewModifier {
    let imageURL: URL?
    let imageData: Data?
    @Environment(\.esaVisualStyle) private var style
    @Environment(\.esaUniformPalette) private var uniformPalette
    @State private var artworkPalette = ESAThemePalette.fallback

    private var cacheKey: String { imageURL?.absoluteString ?? imageData.map { "data:\($0.hashValue)" } ?? "none" }
    private var resolved: ESAThemePalette {
        switch style {
        case .artwork: return .standard
        case .adaptiveColor: return artworkPalette
        case .uniform: return uniformPalette
        }
    }

    func body(content: Content) -> some View {
        content
            .environment(\.esaThemePalette, resolved)
            .task(id: "\(style.rawValue):\(cacheKey)") {
                guard style == .adaptiveColor else { return }
                let palette: ESAArtworkPalette?
                if let imageURL {
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
        let foreground = adjusted.luminance > 0.5 ? Color.black : Color.white
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
        // Keep the dominant hue while constraining luminance so black or white
        // semantic foregrounds meet WCAG AA for normal text.
        let target = luminance > 0.45 ? 0.88 : 0.14
        let current = max(red, green, blue)
        guard current > 0 else { return RGB(red: target, green: target, blue: target) }
        let factor = min(1.0, target / current)
        let scaled = RGB(red: red * factor, green: green * factor, blue: blue * factor)
        if (target > 0.5 && scaled.luminance < 0.75) || (target <= 0.5 && scaled.luminance > 0.18) {
            return RGB(red: target, green: target, blue: target)
        }
        return scaled
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
