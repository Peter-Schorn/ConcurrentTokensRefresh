// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ConcurrentTokensRefresh",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(
            name: "OpenCombine",
            url: "https://github.com/OpenCombine/OpenCombine.git",
            from: "0.12.0"
        )
    ],
    targets: [
        .target(
            name: "ConcurrentTokensRefresh",
            dependencies: [
                .product(name: "OpenCombine", package: "OpenCombine"),
                .product(name: "OpenCombineDispatch", package: "OpenCombine"),
                .product(name: "OpenCombineFoundation", package: "OpenCombine")
            ]
        ),
        .testTarget(
            name: "ConcurrentTokensRefreshTests",
            dependencies: ["ConcurrentTokensRefresh"]
        )
    ]
)
