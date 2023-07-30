// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

enum SwiftlaneCore {
    static let core: Target.Dependency = .product(name: "SwiftlaneCore", package: "SwiftlaneCore")
    static let mocks: Target.Dependency = .product(name: "SwiftlaneCoreMocks", package: "SwiftlaneCore")
    static let unitTestTools: Target.Dependency = .product(name: "SwiftlaneUnitTestTools", package: "SwiftlaneCore")
}

var products: [Product] = [
    .executable(name: "SwiftlaneCLI", targets: ["SwiftlaneCLI"]),
    .library(name: "Swiftlane", type: .static, targets: ["Swiftlane"]),
]

let mainTargetDependencies: [Target.Dependency] = [
    SwiftlaneCore.core,
    "Xcodebuild",
    "Simulator",
    "Guardian",
    "Provisioning",
    "GitLabAPI",
    "JiraAPI",
    "AppStoreConnectAPI",
    "FirebaseAPI",
    "MattermostAPI",

    .product(name: "ArgumentParser", package: "swift-argument-parser"),
    "PerfectRainbow",
    "XMLCoder",
]

var targets: [Target] = [
    .executableTarget(
        name: "SwiftlaneCLI",
        dependencies: mainTargetDependencies + [
            "Swiftlane",
        ]
    ),

    .target(
        name: "Swiftlane",
        dependencies: mainTargetDependencies
    ),
    .testTarget(
        name: "SwiftlaneTests",
        dependencies: mainTargetDependencies + [
            "Swiftlane",
            "SwiftyMocky",
            SwiftlaneCore.unitTestTools,
            SwiftlaneCore.mocks,
        ],
        resources: [.copy("Stubs")]
    ),
]

addProductAndTargets(
    name: "Networking",
    dependencies: [SwiftlaneCore.core, "Yams"]
)

addProductAndTargets(
    name: "Git",
    dependencies: ["PerfectRainbow", SwiftlaneCore.core],
    testResources: [.copy("Stubs")]
)

addProductAndTargets(
    name: "Simulator",
    dependencies: [SwiftlaneCore.core],
    testResources: [.copy("Stubs")]
)

addProductAndTargets(
    name: "Xcodebuild",
    dependencies: [SwiftlaneCore.core, "Simulator", "XcodeProj", "Provisioning"],
    excludeFiles: ["XCTestProductsServices/README.md"],
    testResources: [.copy("Stubs")]
)

addProductAndTargets(
    name: "Provisioning",
    dependencies: [
        SwiftlaneCore.core,
        "Git",
        "AppStoreConnectAPI",
        "Bagbutik",
    ],
    testResources: [.copy("Stubs")]
)

addProductAndTargets(
    name: "Guardian",
    dependencies: [SwiftlaneCore.core, "Networking", "GitLabAPI", "JiraAPI", "Git", "Xcodebuild"]
)

// MARK: Mattermost API

addProductAndTargets(
    name: "MattermostAPI",
    dependencies: [SwiftlaneCore.core, "Networking"],
    testsTargetNameSuffix: nil
)

// MARK: GitLab API

addProductAndTargets(
    name: "GitLabAPI",
    dependencies: [SwiftlaneCore.core, "Networking", "Yams"],
    testResources: [.copy("Stubs")]
)

// MARK: JiraAPI

addProductAndTargets(
    name: "JiraAPI",
    dependencies: [SwiftlaneCore.core, "Networking"],
    testResources: [.copy("Stubs")]
)

// MARK: App Store Connect API

addProductAndTargets(
    name: "AppStoreConnectAPI",
    dependencies: [SwiftlaneCore.core, "Networking", "AppStoreConnectJWT", "Bagbutik"]
)

// MARK: Firebase API

addProductAndTargets(
    name: "FirebaseAPI",
    dependencies: [SwiftlaneCore.core, "Networking"]
)

// MARK: - Package

let package = Package(
    name: "Swiftlane",
    platforms: [.macOS(.v12)],
    products: products,
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        .package(url: "https://github.com/apple/swift-argument-parser", "1.1.4" ..< "1.2.0"), // 1.2.0 Bugs (default value for @Flag)
        .package(url: "https://github.com/nstmrt/PerfectRainbow", from: "4.0.2"),
        .package(url: "https://github.com/nstmrt/SwiftyMocky.git", from: "4.1.1"),
        .package(url: "https://github.com/MaxDesiatov/XMLCoder", from: "0.13.1"),
        .package(url: "https://github.com/swiftlane-code/AppStoreConnectJWT.git", from: "0.9.0"),
        .package(url: "https://github.com/swiftlane-code/SwiftlaneCore.git", from: "0.9.1"),
        .package(url: "https://github.com/tuist/XcodeProj.git", from: "8.7.1"),
        .package(url: "https://github.com/MortenGregersen/Bagbutik", from: "3.0.1"),
    ],
    targets: targets
)

/// Creates a target(1) and a respected unit tests target, adding both to `targets` global array.
/// Unit tests target dependencies include SwiftyMocky automatically.
///
/// Creates library product with the target(1) and adds it to `products` global array.
///
/// - Parameters:
///   - name: name of target(1) and product.
///   - dependencies: common dependecies of target(1) and unit tests target.
///   - testResources: resource to add to unit tests target.
///   - testDependencies: additional dependencies for unit tests target.
///   - nameSuffix: unit test target name suffix.
///   - mocksDependency: name of SwiftyMocky dependency.
func addProductAndTargets(
    name: String,
    dependencies: [Target.Dependency],
    excludeFiles: [String] = [],
    testResources: [Resource]? = nil,
    testDependencies: [Target.Dependency] = [],
    testsTargetNameSuffix: String? = "Tests",
    mocksDependency: Target.Dependency = "SwiftyMocky"
) {
    products.append(.library(name: name, type: .static, targets: [name]))

    targets.append(contentsOf: [
        .target(
            name: name,
            dependencies: dependencies,
            exclude: excludeFiles
        ),
    ])

    testsTargetNameSuffix.map { suffix in
        targets.append(contentsOf: [
            .testTarget(
                name: name + suffix,
                dependencies: dependencies
                    + [.target(name: name)]
                    + testDependencies
                    + [mocksDependency]
                    + [
                        SwiftlaneCore.mocks,
                        SwiftlaneCore.unitTestTools,
                    ],
                resources: testResources
            ),
        ])
    }
}
