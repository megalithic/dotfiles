// swift-tools-version: 6.2
// Ultimate.app's menu bar count. setup-ultimate-app compiles the sources with swiftc
// into the bundle; this package exists for `swift test`.
import PackageDescription

let package = Package(
  name: "UltimateMenu",
  platforms: [.macOS("26.0")],
  targets: [
    .executableTarget(name: "UltimateMenu", swiftSettings: [.swiftLanguageMode(.v5)]),
    .testTarget(
      name: "UltimateMenuTests", dependencies: ["UltimateMenu"],
      swiftSettings: [.swiftLanguageMode(.v5)])
  ]
)
