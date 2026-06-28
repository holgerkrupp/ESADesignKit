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
        // DeviceInfo stays its own package; ESADesignKit owns the dependency and
        // re-exports it so consuming apps don't reference it directly.
        .package(path: "../DeviceInfo")
    ],
    targets: [
        .target(
            name: "ESADesignKit",
            dependencies: [
                .product(name: "DeviceInfo", package: "DeviceInfo")
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
