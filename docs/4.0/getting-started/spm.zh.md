# Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/)(SPM) 用于构建项目的源代码和依赖项。由于 Vapor 严重依赖 SPM，因此最好了解其工作原理。

SPM 与 Cocoapods，Ruby gems 和 NPM 相似。你可以在命令行中将 SPM 与 `swift build`、`swift test` 等命令或兼容的 IDE 结合使用。但是，与其他软件包管理器不同，SPM 软件包没有中央软件包索引。SPM 使用 [Git 标签](https://git-scm.com/book/en/v2/Git-Basics-Tagging) 和 URL 来获取 Git 存储库和依赖版本。

## Package Manifest

SPM 在项目中查找的第一项是 package 清单。它应始终位于项目的根目录中，并命名为 `Package.swift`。

看一下这个示例：

```swift
// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
       .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
```

下面将对这段代码的各部分进行说明。

### Tools Version

第一行表示需要使用的 Swift tools 版本号，它指明了 Swift 的最低可用版本。Package 描述 API 可能随着 Swift 版本而改变，所以这一行将让 Swift 确认怎么去解析你的配置文件。

### Package Name

`Package` 的第一个参数代表当前 package 的名字。如果软件包是公共的，你应该使用 Git 存储库的 URL 的最后一段作为名称

### Platforms

`platforms` 数组指定此程序包支持的平台和版本。通过指定 `.macOS（.v12)`，说明此软件包需要 macOS 12 或更高版本。 Xcode 加载该项目时，它将最低部署版本设置为 macOS 12，以便你可以使用所有可用的 API。

### Dependencies

dependencies 字段代表项目需要依赖的 package。所有 Vapor 应用都依赖 Vapor package ，但是你也可以添加其它想要的依赖库。

如上面这个示例，[vapor/vapor](https://github.com/vapor/vapor) 4.76.0 或以上版本是这个 package 的 dependency。当在 package 中添加了 dependency 后，接下来你必须设置是哪个 targets 依赖了新的可用模块。

### Targets

Targets 是你的 package 里包含 modules、executables 以及 tests 总和。虽然可以添加任意多的 targets 来组织代码，但大部分 Vapor 应用有 2 个 target 就足够了。每个 target 声明了它依赖的 module。为了在代码中可以 import 这些 modules ，你必须在这里添加 module 名字。一个 target 可以依赖于工程中其它的 target 或者任意你添加在 [dependencies](#dependencies) 数组中且暴露出来的 modules。

## 目录结构

以下是典型的 SPM package 目录结构。

```
.
├── Sources
│   └── App
│       └── (Source code)
├── Tests
│   └── AppTests
└── Package.swift
```

每个 `.target` 或 `.executableTarget` 对应于 `Sources` 中的一个文件夹。
每个 `.testTarget` 对应 `Tests` 中的一个文件夹。

## Package.resolved

第一次构建成功后，SPM 将会自动创建一个 `Package.resolved` 文件。`Package.resolved` 保存了当前项目所有用到的依赖库版本。下一次当你构建你的项目时将会同样的版本，甚至是这些依赖有更新的版本时也不会使用。

更新依赖, 运行 `swift package update`.

## Xcode

如果使用 Xcode 11 或更高版本，则在修改 `Package.swift` 文件时，将自动更改 dependencies、targets、products 等。

如果要更新到最新的依赖项，请使用 File &rarr; Swift Packages &rarr; 更新到最新的 Swift Package 版本。

你可能还想将 `.swiftpm` 文件添加到你的 `.gitignore` 文件中（Xcode 在此处存储 Xcode 项目配置）。
