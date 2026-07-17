//
//  CreatedByView.swift
//  ESADesignKit
//
//  The shared "Created in Buxtehude by Extremely Successful Apps" footer.
//

import SwiftUI

public struct CreatedByView: View {
    private let creditText: LocalizedStringKey
    private let websiteURL: URL?
    private let gitURL: URL?
    private let showVersion: Bool

    /// - Parameters:
    ///   - creditText: The line shown above the company link.
    ///   - websiteURL: Where the company label links to.
    ///   - gitURL: The source-code repository. Pass `nil` to hide the link.
    ///   - showVersion: Whether to append the app's version/build number.
    public init(
        creditText: LocalizedStringKey = "Created in Buxtehude by",
        websiteURL: URL? = URL(string: "https://extremelysuccessfulapps.com"),
        gitURL: URL? = nil,
        showVersion: Bool = true
    ) {
        self.creditText = creditText
        self.websiteURL = websiteURL
        self.gitURL = gitURL
        self.showVersion = showVersion
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text(creditText)

            if let websiteURL {
                Link(destination: websiteURL) {
                    Label {
                        Text("Extremely Successful Apps")
                    } icon: {
                        Image.esaLogo
                    }
                   // .tint(.accentColor)
                }
            }

            if let gitURL {
                Divider()
                Link(destination: gitURL) {
                    Label {
                        Text("Get the source code")
                    } icon: {
                        Image.esaGitHubLogo
                    }
                    .tint(.accentColor)
                }
            }

            if showVersion {
                ESAVersionNumberView()
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
    }
}

/// Displays the host app's short version string and build number.
public struct ESAVersionNumberView: View {
    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    private var versionNumber: String {
        let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0000"
        return "Version \(short) - (\(build))"
    }

    public var body: some View {
        Text(versionNumber)
    }
}

#Preview {
    CreatedByView(gitURL: URL(string: "https://github.com/holgerkrupp/PodcastClient"))
}
