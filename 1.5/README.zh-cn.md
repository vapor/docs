# Vapor 文档

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

这是 Vapor 的说明文档, Vapor 是一个可以在 iOS, macOS 及 Ubuntu 上执行的 Web framework，以及其他相关的组件。

Vapor 是一个在 Swift 上很受欢迎的 Web framework。它提供了清晰易用的 API 及许多方便的基础功能，方便我们用它建立网站或是后台。

我们可以在 [Vapor's GitHub](https://github.com/vapor/vapor) 查看源码及说明文档。

阅读 [繁体中文](https://github.com/vapor/documentation/1.5/README.zh-hant.md)

阅读 [Spanish](https://github.com/vapor/documentation/1.5/README.es.md)

阅读 [English](https://github.com/vapor/documentation/1.5/README.md)

## 说明文档

可在 [GitHub](https://github.com/vapor/documentation) 上浏览说明文档，特別是 markdown 文档(后缀名为 .md 的文档)。或是查看 [GitHub Pages](https://vapor.github.io/documentation/) 上的文件。

## 组件
以下是 Vapor 提供的组件及模板(我们也可以不通过 Vapor，而直接使用它们。)

- [Vapor](https://github.com/vapor/vapor): Swift 上最常用到 web framework。
	- Auth: 使用认证及存储控制(persistance)。
	- Sessions: 建立在 cookie 机制上安全、短暂的资料存储。
	- Cookies: HTTP cookies.
	- Routing: 可通过变量确定(type-safe)的参数来设定路径。
- [Fluent](https://github.com/vapor/fluent): 用来操作 SQL 或 NoSQL 资料库。
- [Engine](https://github.com/vapor/engine): 传输的核心层。
	- HTTP: HTTP 用戶端及服务端。
	- URI: URI 的解析及组成。
	- WebSockets: TCB 连线双向沟通管道。
	- SMTP: 通过 Sendgrid 及 Gmail 发送邮件。
- [Leaf](https://github.com/vapor/leaf): 一种可扩展的脚本语言(extensible templating language)。(注: 可以用来建立使用界面。)
- [JSON](https://github.com/vapor/json): 用 [Jay JSON]((https://github.com/dantoml/jay)) 解析工具生成 Vapor 物件。
- [Console](https://github.com/vapor/console): 用來处理 console 的输入、输出指令的  Swift 工具。
- [TLS](https://github.com/vapor/tls): 用來处理 CLibreSSL 的新型 TLS 的 Swift 工具。
- [Crypto](https://github.com/vapor/crypto): 在 LibreSSL 及 Swift 上进行加密的工具。
	- Digests: 哈希与认证。
	- Ciphers: 编码及解码。
	- Random: 安全的随机数。
	- BCrypt: 完全用 Swift 所写。
- [Node](https://github.com/vapor/node): 可以轻易地进行类型转换。
	- [Polymorphic](https://github.com/vapor/polymorphic): 如同 JSON 一般可以轻易调用数据。
	- [Path Indexable](https://github.com/vapor/path-indexable): 如同 JSON 一样可以用来处理复杂的资料结构。
- [Core](https://github.com/vapor/core): 核心扩展，类型别名和一些常见任务的功能。
- [Socks](https://github.com/vapor/socks): 将 C 语言的 Socket API 包装成 Swift 语言。

## 可组合使用的框架

以下是可以和 Vapor 同时使用的组件列表。(译：原文里这里还有个东西叫 Provider，是一种 protocol，让我们可以在 Vapor 中像第三方组件一样使用。)

- [MySQL](https://github.com/vapor/mysql): 可通过 Swift 操作 MySQL 的框架。
	- [MySQL Driver](https://github.com/vapor/mysql-driver): 通过 Fluent 操作 MySQL 的框架。
	- [MySQL Provider](https://github.com/vapor/mysql-provider): 让 MySQL 可以在 Vapor 上运作的 provider。
- [SQLite](https://github.com/vapor/sqlite): 可通过 Swift 操作 SQLite 3 的框架。
	- [SQLite Driver](https://github.com/vapor/sqlite-driver): 通过 Fluent 操作 SQLite 的工具。
	- [SQLite Provider](https://github.com/vapor/sqlite-provider): 让 SQLite 可以在 Vapor 上运作的 provider。
- [PostgreSQL](https://github.com/vapor/postgresql): 用 Swift 操作 PostgreSQL 的工具。
	- [PostgreSQL Driver](https://github.com/vapor/postgresql-driver): 用 Fluent 操作 PostgreSQL 的框架。
	- [PostgreSQL Provider](https://github.com/vapor/postgresql-provider): 让 PostgreSQL 可以运行在 Vapor 上的 provider。
- [MongoKitten*](https://github.com/OpenKitten/MongoKitten): 用 Swift 写的 MongoDB driver。
	- [Mongo Driver](https://github.com/vapor/mongo-driver): Fluent 用的 MongoKitten driver。
	- [Mongo Provider](https://github.com/vapor/mongo-provider): Vapor 用的 MongoKitten provider.
	- [MainecoonVapor](https://github.com/OpenKitten/MainecoonVapor): Vapor 的 MongoKitten 组件关联管理。
- [Redbird](https://github.com/vapor/redbird): 遵循原始协定创造的 Swift Redis client 端。
	- [Redis Provider](https://github.com/vapor/redis-provider): Vapor 的 Redis cache provider。
- [Kitura Provider](https://github.com/vapor/kitura-provider): 在 Vapor 中使用 IBM 的 Kitura HTTP Server。
- [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver-Vapor): 在 Vapor 中使用 SwiftBeaver 的框架。(译注: 像强化版的 NSLog() 或 print())
- [APNS](https://github.com/matthijs2704/vapor-apns): 用来操作 Apple 推送的工具。
- [VaporFCM](https://github.com/mdab121/vapor-fcm): 用于发送FCM通知的简单库。
- [JWT](https://github.com/siemensikkema/vapor-jwt): 让我们可以设定一些规则以取得特定资源的工具。
- [VaporS3Signer](https://github.com/JustinM1/VaporS3Signer): 用来产生 HTTP request 的 headers 及已经签证过的 URL，用来 request AWS S3 的 REST API。
- [Flock](https://github.com/jakeheis/Flock): 自动将 Swift 专案发布上主机。
	- [VaporFlock](https://github.com/jakeheis/VaporFlock): 利用 Flock 发布 Vapor applications。
- [VaporForms](https://github.com/bygri/vapor-forms): 让我们在处理前端送来的 form request 时可以轻松一点的框架。
- [Jobs](https://github.com/BrettRToomey/Jobs): 在某个特定的时间点执行某些程式码的框架。
- [Heimdall](https://github.com/himani93/heimdall): 用来将收到的 http request 记录到某个档案的框架，且可以用试算表类型(ex: excel, google sheets)的软件开启。


## 作者

[Tanner Nelson](mailto:tanner@qutheory.io), [Logan Wright](mailto:logan@qutheory.io), [Jinxiansen](mailto:hi@jinxiansen.com), 以及其他上百位 Vapor 的贡献者们。
