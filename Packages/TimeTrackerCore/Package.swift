// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TimeTrackerCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "TimeTrackerCore", targets: ["TimeTrackerCore"])
    ],
    targets: [
        .target(name: "TimeTrackerCore"),
        .testTarget(name: "TimeTrackerCoreTests", dependencies: ["TimeTrackerCore"])
    ],
    swiftLanguageModes: [.v6]
)
