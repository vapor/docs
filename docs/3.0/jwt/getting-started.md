# Getting Started with JWT

JWT ([vapor/jwt](https://github.com/vapor/jwt)) is a package for parsing and serializing **J**SON **W**eb **T**okens supporting both HMAC and RSA signing. JWTs are often used for implementing _decentralized_ authentication and authorization. 

Since all of the authenticated user's information can be embedded _within_ a JWT, there is no need to query a central authentication server with each request to your service. Unlike standard bearer tokens that must be looked up in a centralized database, JWTs contain cryptographic signatures that can be used to independently verify their authenticity.

If implemented correctly, JWTs can be a powerful tool for making your application [horizontally scalable](https://stackoverflow.com/questions/11707879/difference-between-scaling-horizontally-and-vertically-for-databases). Learn more about JWT at [jwt.io](https://jwt.io).

!!! tip
    If your goal is not horizontal scalability, a standard bearer token will likely be a better solution. JWTs have some downsides worth considering such as the inability to revoke a token once it has been issued (until it expires normally). 

Let's take a look at how you can get started using JWT.

## Package

The first step to using JWT is adding it as a dependency to your project in your SPM package manifest file.

```swift
// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        /// Any other dependencies ...

        // 🔏 JSON Web Token signing and verification (HMAC, RSA).
        .package(url: "https://github.com/vapor/jwt.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: ["JWT", ...]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
    ]
)
```

That's it for basic setup. The next section will give you an overview of the package's APIs. As always, feel free to visit the [API Docs](https://api.vapor.codes/jwt/latest/JWT/index.html) for more specific information.
