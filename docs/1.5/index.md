# Vapor Documentation

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

This is the documentation for Vapor, a Web Framework for Swift that works on iOS, macOS, and Ubuntu; and all of the packages that Vapor offers.

Vapor is the most used web framework for Swift. It provides a beautifully expressive and easy to use foundation for your next website or API.

To view the framework's source code and code documentation, visit [Vapor's GitHub](https://github.com/vapor/vapor).

Read this in [Spanish](https://github.com/vapor/documentation/1.5/README.es.md)

Read this in [正體中文](https://github.com/vapor/documentation/1.5/README.zh-hant.md)

Read this in [简体中文](https://github.com/vapor/documentation/1.5/README.zh-cn.md)

## How To Read

You can read this guide by clicking through the folders and markdown files on [GitHub](https://github.com/vapor/documentation) or through the rendered [GitHub Pages](https://vapor.github.io/documentation/).

## API 

Auto-generated API documentation is located at [api.vapor.codes](http://api.vapor.codes).

## Packages

Here are a list of all the packages and modules included with Vapor (also useable individually).

- [Vapor](https://github.com/vapor/vapor): Swift's most used web framework.
	- Auth: User authentication and persistance.
	- Sessions: Secure, ephemeral cookie based data storage.
	- Cookies: HTTP cookies.
	- Routing: Advanced router with type-safe parameterization.
- [Fluent](https://github.com/vapor/fluent): Models, relationships, and querying for NoSQL and SQL databases.
- [Engine](https://github.com/vapor/engine): Core transport layers.
	- HTTP: Pure Swift HTTP client and server.
	- URI: Pure Swift URI parsing and serializing.
	- WebSockets: Full-duplex communication channels over a single TCP connection.
	- SMTP: Send email using Sendgrid and Gmail.
- [Multipart](https://github.com/vapor/multipart): Fast, streaming, non-blocking multipart parser and serializer.
	- Multipart: Parses and serializes `multipart/mixed`.
	- FormData: Parses and serializes `multipart/form-data`.
- [Leaf](https://github.com/vapor/leaf): An extensible templating language.
- [JSON](https://github.com/vapor/json): Maps Jay JSON to Vapor types.
- [Console](https://github.com/vapor/console): Swift wrapper for console IO and commands.
- [TLS](https://github.com/vapor/tls): Swift wrapper for CLibreSSL's new TLS.
- [Crypto](https://github.com/vapor/crypto): Cryptography from LibreSSL and Swift.
	- Digests: Hashing with and without authentication.
	- Ciphers: Encryption and decryption
	- Random: Pseudo and cryptographically secure randomness.
	- BCrypt: Pure Swift implementation.
- [Node](https://github.com/vapor/node): Data structure for easy type conversions.
	- [Polymorphic](https://github.com/vapor/polymorphic): Syntax for easily accessing values from common types like JSON.
	- [Path Indexable](https://github.com/vapor/path-indexable): A protocol for powerful subscript access of common types like JSON.
- [Core](https://github.com/vapor/core): Core extensions, type-aliases, and functions that facilitate common tasks.
- [Socks](https://github.com/vapor/socks): Swift C Socket API wrapper.

## Providers & Other

Here are a list of providers and third party packages that work great with Vapor.

- [MySQL](https://github.com/vapor/mysql): Robust MySQL interface for Swift.
	- [MySQL Driver](https://github.com/vapor/mysql-driver): MySQL driver for Fluent.
	- [MySQL Provider](https://github.com/vapor/mysql-provider): MySQL provider for Vapor.
- [SQLite](https://github.com/vapor/sqlite): SQLite 3 wrapper for Swift
	- [SQLite Driver](https://github.com/vapor/sqlite-driver): SQLite driver for Fluent.
	- [SQLite Provider](https://github.com/vapor/sqlite-provider): SQLite provider for Vapor.
- [PostgreSQL](https://github.com/vapor/postgresql): Robust PostgreSQL interface for Swift.
	- [PostgreSQL Driver](https://github.com/vapor/postgresql-driver): PostgreSQL driver for Fluent.
	- [PostgreSQL Provider](https://github.com/vapor/postgresql-provider): PostgreSQL provider for Vapor.
- [MongoKitten*](https://github.com/OpenKitten/MongoKitten): Native MongoDB driver for Swift, written in Swift
	- [Mongo Driver](https://github.com/vapor/mongo-driver): MongoKitten driver for Fluent.
	- [Mongo Provider](https://github.com/vapor/mongo-provider): MongoKitten provider for Vapor.
	- [MainecoonVapor](https://github.com/OpenKitten/MainecoonVapor): MongoKitten ORM for Vapor.
- [Redbird](https://github.com/vapor/redbird): Pure-Swift Redis client implemented from the original protocol spec..
	- [Redis Provider](https://github.com/vapor/redis-provider): Redis cache provider for Vapor.
- [Kitura Provider](https://github.com/vapor/kitura-provider): Use IBM's Kitura HTTP server in Vapor.
- [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver-Vapor): Adds the powerful logging of SwiftyBeaver to Vapor.
- [APNS](https://github.com/matthijs2704/vapor-apns): Simple APNS Library for Vapor (Swift).
- [VaporFCM](https://github.com/mdab121/vapor-fcm): Simple FCM (iOS + Android Push Notifications) library built for Vapor in Swift.
- [JWT](https://github.com/siemensikkema/vapor-jwt): JWT implementation for Vapor.
- [VaporS3Signer](https://github.com/JustinM1/VaporS3Signer): Generate V4 Auth Header/Pre-Signed URL for AWS S3 REST API
- [Flock](https://github.com/jakeheis/Flock): Automated deployment of Swift projects to servers
	- [VaporFlock](https://github.com/jakeheis/VaporFlock): Use Flock to deploy Vapor applications
- [VaporForms](https://github.com/bygri/vapor-forms): Brings simple, dynamic and re-usable web form handling to Vapor.
- [Jobs](https://github.com/BrettRToomey/Jobs): A minimalistic job/background-task system for Swift.
- [Heimdall](https://github.com/himani93/heimdall): An easy to use HTTP request logger.


## Authors

[Tanner Nelson](mailto:tanner@qutheory.io), [Logan Wright](mailto:logan@qutheory.io),and the hundreds of members of Vapor.
