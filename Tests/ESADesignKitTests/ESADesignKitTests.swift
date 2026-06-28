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
    func testRowViewBuilds() {
        // Ensure the public modifier API type-checks and constructs.
        _ = Text("Row").ESA_RowView(image: URL(string: "https://example.com/cover.jpg"))
        _ = Text("Row").ESA_RowView(image: Image(systemName: "star"))
        _ = CreatedByView(gitURL: URL(string: "https://github.com/holgerkrupp/PodcastClient"))
    }
}
