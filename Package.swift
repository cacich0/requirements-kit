// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
  name: "RequirementsKit",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6)
  ],
  products: [
    .library(
      name: "RequirementsKit",
      targets: ["RequirementsKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0")
  ],
  targets: [
    // Макрос плагин
    .macro(
      name: "RequirementsKitMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),
    
    // Основная библиотека
    .target(
      name: "RequirementsKit",
      dependencies: ["RequirementsKitMacros"],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency"),
        .unsafeFlags(["-Xfrontend", "-warn-concurrency"], .when(configuration: .debug))
      ]),
    
    // Тесты
    .testTarget(
      name: "RequirementsKitTests",
      dependencies: ["RequirementsKit"])
  ],
  swiftLanguageModes: [.v6]
)

