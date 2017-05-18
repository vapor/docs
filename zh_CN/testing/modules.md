---
currentMenu: testing-modules
---

# 多模块测试 （Using Multiple Modules For Testing）

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

测试一个Vapor应用程序比较棘手，需要对你的 app target 进行一些操纵。

> [WARNING] 技术上，只有当你计划在 Linux 上运行测试时，这才是必要的。如果你只想使用 `vapor test` 命令运行你的测试，你可以保持你的 test 在同一个 moudule 中。

## **Step 1:** 更新 Package.swift（Update Package.swift）

开始，你需要分割你的 Vapor 项目为两个 target： `App` 和 `AppLogic`。 `App` module 只包含 `main.swift`，`AppLogic` module 包含你 app 的实际逻辑。

```swift
import PackageDescription

let package = Package(
    name: “ProjectName”,
    targets: [
        Target(name: "App", dependencies: ["AppLogic"])
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 3)
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources"
    ]
)
```

## **Step 2:** Update Tests Folder

保证你的 tests 文件夹中有一个叫做 `LinuxMain.swift` 的文件和一个叫做 `AppLogicTests` 文件夹。在你的 `AppLogicTests` 中，你能添加你的测试文件，例如 `UserTests.swift`。

和往常一样，请确保你用 `vapor xcode -y` 重新生成一下。
