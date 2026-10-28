// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AlBayanApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AlBayanApp",
            targets: ["AlBayanApp"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AlBayanApp",
            path: "AlBayanApp",
            exclude: [
                "Resources/Info.plist",
                "Resources/Assets.xcassets",
                "Resources/AppIcon.png",
                "Resources/GoogleService-Info.plist"
            ]
        ),
    ]
)
