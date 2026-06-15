// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TyradsSDKIOS",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TyradsSDKIOS", targets: ["TyradsSDKIOS"]),
    ],
    targets: [
        .target(
            name: "TyradsSDKIOS",
            path: "Sources/TyradsSDKIOS",
            resources: [
                .process("Resources/Images"),
                .copy("Resources/Fonts"),
                .process("Resources/Localization"),
            ]
        ),
        .testTarget(
            name: "TyradsSDKIOSTests",
            dependencies: ["TyradsSDKIOS"],
            path: "Tests/TyradsSDKIOSTests"
        ),
    ]
)
