// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-prefs",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "prefs", targets: ["prefs"]),
    .executable(name: "plist2profile", targets: ["plist2profile"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1"),
  ],
  targets: [
    .executableTarget(
      name: "prefs",
      dependencies: [
        .product(
          name: "ArgumentParser",
          package: "swift-argument-parser"
        )],
      path: "Sources/prefs"
    ),
    .executableTarget(
      name: "plist2profile",
      dependencies: [
        .product(
          name: "ArgumentParser",
          package: "swift-argument-parser"
        )],
      path: "Sources/plist2profile"
    ),
    .executableTarget(
      name: "jyp",
      dependencies: [
        .product(
          name: "ArgumentParser",
          package: "swift-argument-parser"
        ),
        .product(
          name: "Yams",
          package: "Yams"
        ),
      ],
      path: "Sources/jyp"
    )
  ]
)
