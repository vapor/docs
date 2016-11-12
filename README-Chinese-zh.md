# Vapor Documentation

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

這是 Vapor 的說明文件, Vapor 是一個可以在 iOS, macOS 及 Ubuntu 上執行的 Web framework； 以及其他由 Vapor 所提供的套件。

Vapor 是一個在 Swift 上很受歡迎的 Web framework。它提供了清楚的 API 及許多方便的基礎功能，您可以用它建立網站或是後台。

您可以在 [Vapor's GitHub](https://github.com/vapor/vapor) 查看原始碼及說明文件。

## 如何閱讀說明文件

在 [GitHub](https://github.com/vapor/documentation) 上瀏覽每個資料夾，特別是 markdown 檔(副檔名為 .md 的檔案)。或是看 [GitHub Pages](https://vapor.github.io/documentation/)。

## 套件
以下是 Vapor 提供的套件及模組(您也可以不透過 Vapor 而直接使用它們)

- [Vapor](https://github.com/vapor/vapor): Swift 上最常被使用到的 web framework。
	- Auth: 使用者的認證及存續控制(persistance)。
	- Sessions: 建立在 cookie 上的安全、短暫的資料儲存。
	- Cookies: HTTP cookies.
	- Routing: 可透過變數類型確定(type-safe)的參數來設定路徑。
- [Fluent](https://github.com/vapor/fluent): 用來操作 SQL 或 NoSQL 資料庫。
- [Engine](https://github.com/vapor/engine): 傳輸的核心層。
	- HTTP: HTTP 用戶端及主機端。
	- URI: URI 的分解及組成。
	- WebSockets: 在一個 TCB 連線中進行雙向的溝通管道。
	- SMTP: 透過 Sendgrid 及 Gmail 發送郵件。
- [Leaf](https://github.com/vapor/leaf): 一種可擴張的樣本語言(extensible templating language)。(譯註: 這可以用來建立使用者介面。)
- [JSON](https://github.com/vapor/json): 將 [Jay](https://github.com/dantoml/jay) JSON 物件生成對應的 Vapor types 的工具。
- [Console](https://github.com/vapor/console): Swift wrapper for console IO and commands.
- [TLS](https://github.com/vapor/tls): Swift wrapper for CLibreSSL's new TLS.
- [Crypto](https://github.com/vapor/crypto): Cryptography from LibreSSL and Swift.
	- Digests: Hashing with and without authentication.
	- Ciphers: Encryption and decryption
	- Random: Psuedo and cryptographically secure randomness.
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
- [JWT](https://github.com/siemensikkema/vapor-jwt): JWT implementation for Vapor.
- [VaporS3Signer](https://github.com/JustinM1/VaporS3Signer): Generate V4 Auth Header/Pre-Signed URL for AWS S3 REST API
- [Flock](https://github.com/jakeheis/Flock): Automated deployment of Swift projects to servers
	- [VaporFlock](https://github.com/jakeheis/VaporFlock): Use Flock to deploy Vapor applications


## Authors

[Tanner Nelson](mailto:tanner@qutheory.io), [Logan Wright](mailto:logan@qutheory.io), and the hundreds of members of Vapor.
