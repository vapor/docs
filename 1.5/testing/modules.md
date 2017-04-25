---
currentMenu: testing-modules
---

# Using Multiple Modules For Testing

Testing a Vapor app gets tricky, and requires some maneuvering of your app targets.

> [WARNING] Technically this is only necessary if you plan to run your tests on Linux. You can keep your tests in the same module if you want to only run your tests from the command line using `vapor test`

## **Step 1:** Update Package.swift

To start, you need to split up your Vapor project into a target called `App`, and a target called `Run`. The `Run` module will only include a `main.swift`, and your `App` will contain the actual logic for the app.

Add a `Sources/Run` folder to your project, then add `targets` to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
    name: “ProjectName”,
    targets: [
        Target(name: "App"),
        Target(name: "Run", dependencies: ["App"])
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 1, minor: 5)
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

If you don't already have a `Tests` folder at the root of your project, add one.

Make sure that your tests folder has a file called `LinuxMain.swift` and a folder called `AppTests`. In your `AppTests`, you can add your testing files like `UserTests.swift`.

As always, make sure that you regenerate with `vapor xcode -y`.

As long as there is at least one test file under `AppTests`, your generated Xcode project will have an `AppTests` target that you can run as usual. You can also run the tests from the command line with `vapor test`.
