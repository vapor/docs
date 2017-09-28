# Vapor Documentation

This is the documentation for Vapor, a Web Framework for Swift that works on iOS, macOS, and Ubuntu; and all of the packages that Vapor offers.

Vapor is the most used web framework for Swift. It provides a beautifully expressive and easy to use foundation for your next website or API.

## Getting Started

If this is your first time using Vapor, head to the [Getting Started](getting-started/install-on-macos.md) section to install Swift and create your first app.

## Like Vapor?

Our small team works hard to make Vapor awesome (and free). Support the framework by starring Vapor on GitHub or donating $1 monthly--it helps us a lot. Thanks!

<a href="https://github.com/vapor/vapor" target="_blank">
	<img src="https://cloud.githubusercontent.com/assets/1342803/26243875/5490d02c-3c85-11e7-9667-d56eb97c2cf9.png" style="height:40px">
</a>
<a href="https://opencollective.com/vapor" target="_blank">
	<img src="https://cloud.githubusercontent.com/assets/1342803/26243876/54913ce2-3c85-11e7-9848-121adbe92198.png" style="margin-left: 10px; height:40px">
</a>


## Other Sources

Here are some other great places to find information about Vapor.

### API

Auto-generated API documentation is located at [api.vapor.codes](http://api.vapor.codes).

### Stack Overflow

View or ask questions related to Vapor on Stack Overflow using the [`vapor`](http://stackoverflow.com/questions/tagged/vapor) tag.

### GitHub

#### Source Code

To view the framework's source code and code documentation, visit [Vapor's GitHub](https://github.com/vapor/vapor).

#### Issues

To view open bug reports and feature requests, or to create one, visit the [issues](https://github.com/vapor/vapor/issues) tab on [Vapor's GitHub](https://github.com/vapor/vapor).

## Packages

Vapor is a modular framework built for a modular language. Code is split up into modules which are grouped to form packages. Packages can be added to your project by adding the package's Git url to your `Package.swift` file. Once a package is included, all of its modules will be available to `import`. You can read more about packages and modules in the Swift Package Manager [conceptual overview](https://swift.org/package-manager/).

Below is a list of packages and modules that come with or can be used by Vapor projects. Packages will have a link to their respective GitHub page.

### Core

Core packages are maintained by the Vapor team.

#### Included

The following packages are included with Vapor by default.

!!! tip
	These packages can also be used individually

- [Vapor](vapor/index.md): Swift's most used web framework.
- [Routing](routing/index.md): Advanced router with type-safe parameterization.
- [HTTP](http/index.md): HTTP client and server.
- [WebSockets](websockets/index.md): Full-duplex communication channels over a single TCP connection.
- [Multipart](multipart/index.md): Fast, streaming, non-blocking multipart parser and serializer.
- [JSON](vapor/json.md): Conveniences for working with JSON in Swift.ole IO and commands.
- [TLS](tls/index.md): Swift wrapper for CLibreSSL's new TLS.
- [Crypto](crypto/index.md): Cryptography from LibreSSL and Swift.
	- [Digests](crypto/hash.md): Hashing with and without authentication.
	- [Random](crypto//random.md): Pseudo and cryptographically secure randomness.
	- [BCrypt & PBKDF2](crypto/passwords.md): Pure Swift implementation.
- [Socks](sockets/index.md): Swift C Socket API wrapper.

#### Providers

These are officially supported packages for Vapor that are not included by default.

- [Fluent](https://github.com/vapor/fluent): Models, relationships, and querying for NoSQL and SQL databases.
	- [Fluent Provider](https://github.com/vapor/fluent-provider): Fluent provider for Vapor.
- [MySQL](https://github.com/vapor/mysql): Robust MySQL interface for Swift.
	- [MySQL Driver](https://github.com/vapor/mysql-driver): MySQL driver for Fluent.
	- [MySQL Provider](https://github.com/vapor/mysql-provider): MySQL provider for Vapor.
- [Leaf](https://github.com/vapor/leaf): An extensible templating language.
	- [Leaf Provider](https://github.com/vapor/leaf-provider): Leaf provider for Vapor.
- [Redis](https://github.com/vapor/redbird): Pure-Swift Redis client implemented from the original protocol spec.
	- [Redis Provider](https://github.com/vapor/redis-provider): Redis cache provider for Vapor.
- [JWT](https://github.com/vapor/jwt): JSON Web Tokens in Swift.
	- [JWT Provider](https://github.com/vapor/jwt-provider): JWT conveniences for Vapor.

### Community

These are packages maintained by community members that work great with Vapor.

- [PostgreSQL](https://github.com/vapor/postgresql): Robust PostgreSQL interface for Swift.
	- [PostgreSQL Driver](https://github.com/vapor/postgresql-driver): PostgreSQL driver for Fluent.
	- [PostgreSQL Provider](https://github.com/vapor/postgresql-provider): PostgreSQL provider for Vapor.
- [MongoKitten](https://github.com/OpenKitten/MongoKitten): Native MongoDB driver for Swift, written in Swift
	- [Mongo Driver](https://github.com/vapor/mongo-driver): MongoKitten driver for Fluent.
	- [Mongo Provider](https://github.com/vapor/mongo-provider): MongoKitten provider for Vapor.
- [Kitura Provider](https://github.com/vapor/kitura-provider): Use IBM's Kitura HTTP server in Vapor.
- [SwiftyBeaver](https://github.com/vapor-community/swiftybeaver-provider): Adds the powerful logging of SwiftyBeaver to Vapor.
- [APNS](https://github.com/matthijs2704/vapor-apns): Simple APNS Library for Vapor (Swift).
- [VaporFCM](https://github.com/mdab121/vapor-fcm): Simple FCM (iOS + Android Push Notifications) library built for Vapor in Swift.
- [VaporS3Signer](https://github.com/JustinM1/VaporS3Signer): Generate V4 Auth Header/Pre-Signed URL for AWS S3 REST API
- [Flock](https://github.com/jakeheis/Flock): Automated deployment of Swift projects to servers
	- [VaporFlock](https://github.com/jakeheis/VaporFlock): Use Flock to deploy Vapor applications
- [VaporForms](https://github.com/bygri/vapor-forms): Brings simple, dynamic and re-usable web form handling to Vapor.
- [Jobs](https://github.com/BrettRToomey/Jobs): A minimalistic job/background-task system for Swift.
- [Heimdall](https://github.com/himani93/heimdall): An easy to use HTTP request logger.
- [SteamPress](https://github.com/brokenhandsio/SteamPress): A blogging engine for Vapor.
- [Vapor Security Headers](https://github.com/brokenhandsio/VaporSecurityHeaders): Add common security headers to your Vapor Application.
- [MarkdownProvider](https://github.com/vapor-community/markdown-provider) - Easily use Markdown from Leaf.
- [Vapor OAuth](https://github.com/brokenhandsio/vapor-oauth) - An OAuth2 Provider library for Vapor

### Providers

Vapor providers are a convenient way to add functionality to your Vapor projects. For a full list of providers, check out the [`vapor-provider`](https://github.com/search?utf8=✓&q=topic%3Avapor-provider&type=Repositories) tag on GitHub.

## Authors

[Tanner Nelson](mailto:tanner@vapor.codes), [Logan Wright](mailto:logan@vapor.codes), [Joannis Orlandos](mailto:joannis@qutheory.io), and the hundreds of members of Vapor.
