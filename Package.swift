// swift-tools-version:5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Gryphon - Copyright (2018) Vinícius Jorge Vendramini (“Licensor”)
// Licensed under the Hippocratic License, Version 2.1 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import PackageDescription

// To use a beta version of SwiftSyntax:
//
//let swiftSyntaxPackage = Package.Dependency.package(
//	url: "https://github.com/apple/swift-syntax.git",
//	.revision("release/5.6")) // <- git branch name

// Which SwiftSyntax version to use
#if swift(>=5.8)
let swiftSyntaxPackage = Package.Dependency.package(
  url: "https://github.com/apple/swift-syntax.git",
  from: "508.0.0")
#elseif swift(>=5.7)
let swiftSyntaxPackage = Package.Dependency.package(
  url: "https://github.com/apple/swift-syntax.git",
  from: "0.50700.1")
#elseif swift(>=5.6)
let swiftSyntaxPackage = Package.Dependency.package(
	url: "https://github.com/apple/swift-syntax.git",
  from: "0.50600.1")
#elseif swift(>=5.5)
let swiftSyntaxPackage = Package.Dependency.package(
	url: "https://github.com/apple/swift-syntax.git",
  from: "0.50500.0")
#elseif swift(>=5.4)
let swiftSyntaxPackage = Package.Dependency.package(
	url: "https://github.com/apple/swift-syntax.git",
  from: "0.50400.0")
#elseif swift(>=5.3)
let swiftSyntaxPackage = Package.Dependency.package(
	url: "https://github.com/apple/swift-syntax.git",
  from: "0.50300.0")
#else
let swiftSyntaxPackage = Package.Dependency.package(
	url: "https://github.com/apple/swift-syntax.git",
  from: "0.50200.0")
#endif

// Which modules to import from SwiftSyntax (and SourceKitten)
#if swift(>=5.6)
let gryphonLibDependencies: [Target.Dependency] = [
	.product(name: "SwiftSyntax", package: "swift-syntax"),
	.product(name: "SwiftSyntaxParser", package: "swift-syntax"),
	.product(name: "SourceKittenFramework", package: "SourceKitten")
]
#else
let gryphonLibDependencies: [Target.Dependency] = [
	.product(name: "SwiftSyntax", package: "SwiftSyntax"),
	.product(name: "SourceKittenFramework", package: "SourceKitten")
]
#endif

let package = Package(
	name: "Gryphon",
	platforms: [
    .macOS(.v12)
		/* Linux */
	],
	products: [
		.executable(name: "gryphon", targets: ["Gryphon"])
	],
	dependencies: [
		swiftSyntaxPackage,
    .package(
      url: "https://github.com/jpsim/SourceKitten",
      from: "0.34.1")
	],
	targets: [
		.target(
			name: "GryphonLib",
			dependencies: gryphonLibDependencies),
		.target(
			name: "Gryphon",
			dependencies: ["GryphonLib"]),
		.testTarget(
			name: "GryphonLibTests",
			dependencies: ["GryphonLib"])
	],
	swiftLanguageVersions: [.v5]
)
