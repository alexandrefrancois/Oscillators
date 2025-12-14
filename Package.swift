// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Oscillators",
    platforms: [
            .macOS(.v10_15), .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Oscillators",
            targets: ["Oscillators"]
        ),
        .library(
            name: "OscillatorsCpp",
            targets: ["OscillatorsCpp"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
              url: "https://github.com/apple/swift-atomics.git",
              .upToNextMajor(from: "1.2.0") // or `.upToNextMinor
            )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Oscillators",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics")
            ]
        ),
        .target(name: "OscillatorsCpp",
            cxxSettings: [.headerSearchPath(".")]
        ),
        .testTarget(
            name: "OscillatorsTests",
            dependencies: ["Oscillators", "OscillatorsCpp"]
        ),
    ],
    cxxLanguageStandard: CXXLanguageStandard.cxx17
)
