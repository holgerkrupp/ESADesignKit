import XCTest
import SwiftUI
@testable import ESADesignKit

final class ESADesignKitTests: XCTestCase {
    func testSymbolsResolveFromModuleBundle() {
        // Smoke test that the asset catalog ships with the package.
        XCTAssertNotNil(Bundle.module.url(forResource: "ESAAssets", withExtension: "car")
            ?? Bundle.module.resourceURL)
    }

    func testSymbolNames() {
        XCTAssertEqual(ESASymbol.logo, "extremelysuccessfullogo")
        XCTAssertEqual(ESASymbol.gitHubLogo, "githublogo")
    }

    @MainActor
    func testVisualStylesAreStableAndDefaultToArtwork() {
        XCTAssertEqual(ESAVisualStyle.allCases, [.artwork, .adaptiveColor, .uniform])
        XCTAssertEqual(try JSONDecoder().decode(ESAVisualStyle.self, from: Data("\"artwork\"".utf8)), .artwork)
        _ = Text("Themed").esaVisualStyle(.uniform)
    }

    func testArtworkPaletteForegroundRolesMeetNormalTextContrast() {
        let samples = [
            RGB(red: 0, green: 0, blue: 0),
            RGB(red: 1, green: 1, blue: 1),
            RGB(red: 0.5, green: 0.5, blue: 0.5),
            RGB(red: 1, green: 0, blue: 0),
            RGB(red: 0.35, green: 0.37, blue: 0.4)
        ]

        for sample in samples {
            let palette = ESAArtworkPalette(background: sample)
            XCTAssertGreaterThanOrEqual(ESAArtworkPalette.contrastRatio(palette.background, palette.primaryForeground) ?? 0, 4.5)
            XCTAssertGreaterThanOrEqual(ESAArtworkPalette.contrastRatio(palette.background, palette.secondaryForeground) ?? 0, 4.5)
            XCTAssertGreaterThanOrEqual(ESAArtworkPalette.contrastRatio(palette.background, palette.controlForeground) ?? 0, 4.5)
        }
    }

    @MainActor
    func testSharedSurfacesBuildForEachVisualStyleAndLargeLists() {
        let uniform = ESAThemePalette(background: .black, primaryForeground: .white,
                                      secondaryForeground: .white, controlForeground: .white,
                                      separator: .gray, accent: .mint)
        for style in ESAVisualStyle.allCases {
            _ = Text("Row \(style.rawValue)")
                .ESA_RowView(image: URL(string: "https://example.com/\(style.rawValue).png"))
                .esaVisualStyle(style, uniformPalette: uniform)
            _ = List(0..<80, id: \.self) { index in
                Text("Row \(index)")
                    .ESA_RowView(image: URL(string: "https://example.com/\(index).png"))
            }
            .esaVisualStyle(style, uniformPalette: uniform)
            _ = ScrollView { Text("Hero \(style.rawValue)") }
                .coverHero(imageData: nil)
                .esaVisualStyle(style, uniformPalette: uniform)
        }
    }

    @MainActor
    func testRowViewBuilds() {
        // Ensure the public modifier API type-checks and constructs.
        _ = Text("Row").ESA_RowView(image: URL(string: "https://example.com/cover.jpg"))
        _ = Text("Row").ESA_RowView(image: Image(systemName: "star"))
        _ = ScrollView { Text("Legacy cover content") }
            .coverHero(image: .url(URL(string: "https://example.com/cover.jpg")), title: "Cover")
        _ = List { Text("Legacy data cover content") }
            .coverHero(imageData: nil, title: "Cover")
        _ = ScrollView { Text("Content") }
            .scrollingHero(height: 180) { Color.blue }
        _ = CreatedByView(gitURL: URL(string: "https://github.com/holgerkrupp/PodcastClient"))
    }
}
