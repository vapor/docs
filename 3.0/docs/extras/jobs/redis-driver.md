# Jobs Redis Driver

In order to setup the Redis jobs driver, add the following to your SPM manifest: 

```swift
// swift-tools-version:4.0
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
let redisUrlString = "redis://localhost:6379"
guard let redisUrl = URL(string: redisUrlString) else { throw Abort(.internalServerError) }
let redisConfig = try RedisDatabase(config: RedisClientConfig(url: redisUrl))
    
var databaseConfig = DatabasesConfig()
databaseConfig.add(database: redisConfig, as: .redis)
services.register(databaseConfig)
    
services.register(JobsPersistenceLayer.self) { container -> JobsRedisDriver in
    return JobsRedisDriver(database: redisConfig, eventLoop: container.next())
}
```