!!! warning
    This section may contain outdated information.

# Using Multiple Modules For Testing

Testing a Vapor app gets tricky, and requires some maneuvering of your app targets.

> [WARNING] Technically this is only necessary if you plan to run your tests on Linux. You can keep your tests in the same module if you want to only run your tests from the command line using `vapor test`

## **Step 1:** Update Package.swift

To start, you need to split up your Vapor project into a target called `App`, and a target called `AppLogic`. The App module will only include a `main.swift`, and your `AppLogic` will contain the actual logic for the app.

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

Make sure that your tests folder has a file called `LinuxMain.swift` and a folder called `AppLogicTests`. In your `AppLogicTests`, you can add your testing files like `UserTests.swift`.

As always, make sure that you regenerate with `vapor xcode -y`
