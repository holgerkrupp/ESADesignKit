//
//  ESAImages.swift
//  ESADesignKit
//
//  Shared imagery and brand symbols for Extremely Successful Apps.
//

import SwiftUI

public extension Image {
    /// The "Extremely Successful Apps" brand logo (custom SF Symbol).
    static var esaLogo: Image {
        Image("extremelysuccessfullogo", bundle: .module)
    }

    /// The GitHub logo used for "Get the source code" links.
    static var esaGitHubLogo: Image {
        Image("githublogo", bundle: .module)
    }
}

/// Raw symbol names, in case callers want to build the `Image`/`Label` themselves.
public enum ESASymbol {
    public static let logo = "extremelysuccessfullogo"
    public static let gitHubLogo = "githublogo"
}
