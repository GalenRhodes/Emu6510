// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "Emu6510",
                      platforms: [ .macOS(.v10_15), .tvOS(.v13), .iOS(.v13), .watchOS(.v6) ],
                      products: [ .library(name: "Emu6510", targets: [ "Emu6510" ]), ],
                      dependencies: [ .package(name: "Rubicon", url: "https://github.com/GalenRhodes/Rubicon", from: "0.2.13"), ],
                      targets: [ .target(name: "Emu6510", dependencies: [ "Rubicon" ]), .testTarget(name: "Emu6510Tests", dependencies: [ "Emu6510" ]), ])
