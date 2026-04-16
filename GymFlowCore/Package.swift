// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GymFlowCore",
    defaultLocalization: "zh-Hant",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "GymFlowCore",
            targets: ["GymFlowCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0")
    ],
    targets: [
        .target(
            name: "GymFlowCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            resources: [
                .process("SeedData")
            ]
        ),
        .testTarget(
            name: "GymFlowCoreTests",
            dependencies: ["GymFlowCore"]
        )
    ]
)
