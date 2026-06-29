// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ESADesignKit",
    defaultLocalization: "en",
    platforms: [
        // Aligned with DeviceInfo's minimums (iOS 18 / watchOS 11) since we
        // depend on and re-export it.
        .iOS(.v18),
        .macOS(.v14),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "ESADesignKit",
            targets: ["ESADesignKit"]
        )
    ],
    dependencies: [
        // Hosted dependency so the package resolves cleanly on other machines.
        .package(url: "https://github.com/holgerkrupp/SwiftDeviceInfo.git", branch: "main")
    ],
    targets: [
        .target(
            name: "ESADesignKit",
            dependencies: [
                .product(name: "DeviceInfo", package: "SwiftDeviceInfo")
            ],
            resources: [
                .process("Resources/ESAAssets.xcassets")
            ]
        ),
        .testTarget(
            name: "ESADesignKitTests",
            dependencies: ["ESADesignKit"]
        )
    ]
)
