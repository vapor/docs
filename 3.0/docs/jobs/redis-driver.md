# Jobs Redis Driver

In order to setup the Redis jobs driver, add the following to your SPM manifest: 

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...
        .package(url: "https://github.com/vapor-community/jobs-redis-driver.git", from: "0.2.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["JobsRedisDriver", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

Don't forget to add the module as a dependency in the `targets` array. Once you have added the dependency, regenerate your Xcode project with the following command:

### Configuration 

In your `configure.swift` file, add the following:

```swift
guard let url = URL(string: "redis://127.0.0.1:6379") else { throw Abort(.internalServerError) }
guard let configuration = RedisConfiguration(url: url) else { throw Abort(.internalServerError) }
    
services.register(JobsPersistenceLayer.self) { container -> JobsRedisDriver in
    let client = RedisConnectionSource(config: configuration, eventLoop: container.next())
    return JobsRedisDriver(client: client, eventLoop: container.next())
}
```