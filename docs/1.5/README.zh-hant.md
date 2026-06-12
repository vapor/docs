# Vapor Documentation

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

這是 Vapor 的說明文件, Vapor 是一個可以在 iOS, macOS 及 Ubuntu 上執行的 Web framework，以及其他相關的套件。

Vapor 是一個在 Swift 上很受歡迎的 Web framework。它提供了清楚易用的 API 及許多方便的基礎功能，方便我們用它建立網站或是後台。

我們可以在 [Vapor's GitHub](https://github.com/vapor/vapor) 查看原始碼及說明文件。

閱讀 [English](https://github.com/vapor/documentation/1.5/README.md)

閱讀 [Spanish](https://github.com/vapor/documentation/1.5/README.es.md)

閱讀 [简体中文](https://github.com/vapor/documentation/1.5/README.zh-cn.md)

## 如何閱讀說明文件

在 [GitHub](https://github.com/vapor/documentation) 上瀏覽每個資料夾，特別是 markdown 檔(副檔名為 .md 的檔案)。或是看 [GitHub Pages](https://vapor.github.io/documentation/) 上的文件。

## 套件
以下是 Vapor 提供的套件及模組(我們也可以直接使用它們，不透過 Vapor。)

- [Vapor](https://github.com/vapor/vapor): Swift 上最常被使用到的 web framework。
	- Auth: 使用者的認證及存續控制(persistance)。
	- Sessions: 建立在 cookie 機制上安全、短暫的資料儲存。
	- Cookies: HTTP cookies.
	- Routing: 可透過變數類型確定(type-safe)的參數設定來設定路徑。
- [Fluent](https://github.com/vapor/fluent): 用來操作 SQL 或 NoSQL 資料庫。
- [Engine](https://github.com/vapor/engine): 傳輸的核心層。
	- HTTP: HTTP 用戶端及主機端。
	- URI: URI 的分解及組成。
	- WebSockets: 在一個 TCB 連線中進行雙向的溝通管道。
	- SMTP: 透過 Sendgrid 及 Gmail 發送郵件。
- [Leaf](https://github.com/vapor/leaf): 一種可擴張的樣本語言(extensible templating language)。(譯註: 這可以用來建立使用者介面。)
- [JSON](https://github.com/vapor/json): 用 [Jay JSON]((https://github.com/dantoml/jay)) 解析工具產生Vapor物件。
- [Console](https://github.com/vapor/console): 用來處理 console 的輸入、輸出及指令的 Swift 工具。
- [TLS](https://github.com/vapor/tls): 用來處理 CLibreSSL 的新型 TLS 的 Swift 工具。
- [Crypto](https://github.com/vapor/crypto): 在 LibreSSL 及 Swift 上進行加密的工具。
	- Digests: 無論有沒有認證(authentication)都可以進行雜湊(hash)。
	- Ciphers: 編碼及解碼。
	- Random: 安全的隨機性。
	- BCrypt: 完全用 Swift 實作。
- [Node](https://github.com/vapor/node): 可以輕易地進行類型轉換的資料結構。
	- [Polymorphic](https://github.com/vapor/polymorphic): 如同 JSON 一般可以輕易取用資料的語法。
	- [Path Indexable](https://github.com/vapor/path-indexable): 如同 JSON 一樣可以用來處理複雜的資料結構。
- [Core](https://github.com/vapor/core): 主要的 extension 群，例如: 變數類型的重新命名、在許多地方都會被使用的 function 等。
- [Socks](https://github.com/vapor/socks): 將 C 語言的 Socket API 包裝成 Swift 語言。

## 可合併使用的套件

以下是可以和 Vapor 合併運用的套件列表。(譯註：原文裡這裡還有個東西叫 Provider，那是一種 protocol，讓我們可以掛到 Vapor 中如同第三方元件一樣使用。)

- [MySQL](https://github.com/vapor/mysql): 可透過 Swift 操作 MySQL 的套件。
	- [MySQL Driver](https://github.com/vapor/mysql-driver): 透過 Fluent 操作 MySQL 的套件。
	- [MySQL Provider](https://github.com/vapor/mysql-provider): 讓 MySQL 可以在 Vapor 上運作的 provider。
- [SQLite](https://github.com/vapor/sqlite): 可透過 Swift 操作 SQLite 3 的套件。
	- [SQLite Driver](https://github.com/vapor/sqlite-driver): 透迥 Fluent 操作 SQLite 的工具。
	- [SQLite Provider](https://github.com/vapor/sqlite-provider): 讓 SQLite 可以在 Vapor 上運作的 provider。
- [PostgreSQL](https://github.com/vapor/postgresql): 用 Swift 操作 PostgreSQL 的工具。
	- [PostgreSQL Driver](https://github.com/vapor/postgresql-driver): 用 Fluent 操作 PostgreSQL 的套件。
	- [PostgreSQL Provider](https://github.com/vapor/postgresql-provider): 讓 PostgreSQL 可以運作在 Vapor 上的 provider。
- [MongoKitten*](https://github.com/OpenKitten/MongoKitten): 用 Swift 寫的 MongoDB driver。
	- [Mongo Driver](https://github.com/vapor/mongo-driver): Fluent 用的 MongoKitten driver。
	- [Mongo Provider](https://github.com/vapor/mongo-provider): Vapor 用的 MongoKitten provider.
	- [MainecoonVapor](https://github.com/OpenKitten/MainecoonVapor): Vapor 的 MongoKitten 物件關聯管理。
- [Redbird](https://github.com/vapor/redbird): 遵循原始協定的規格實作出來的 Swift Redis client 端。
	- [Redis Provider](https://github.com/vapor/redis-provider): Vapor 的 Redis cache provider。
- [Kitura Provider](https://github.com/vapor/kitura-provider): 在 Vapor 中使用 IBM 的 Kitura HTTP Server。
- [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver-Vapor): 在 Vapor 中使用 SwiftBeaver 的套件。(譯註: 就像強化版的 NSLog() 或 print())
- [APNS](https://github.com/matthijs2704/vapor-apns): 用來操作 Apple 推播的工具。
- [VaporFCM](https://github.com/mdab121/vapor-fcm): 用于发送FCM通知的简单库。
- [JWT](https://github.com/siemensikkema/vapor-jwt): 讓我們可以設定一些規則以取得特定資源的工具。
- [VaporS3Signer](https://github.com/JustinM1/VaporS3Signer): 用來產生 HTTP request 的 headers 及已經簽證過的 URL，用來 request AWS S3 的 REST API。
- [Flock](https://github.com/jakeheis/Flock): 自動將 Swift 專案發佈上主機。
	- [VaporFlock](https://github.com/jakeheis/VaporFlock): 利用 Flock 發佈 Vapor applications。
- [VaporForms](https://github.com/bygri/vapor-forms): 讓我們在處理前端送來的 form request 時可以輕鬆一點的套件。
- [Jobs](https://github.com/BrettRToomey/Jobs): 在某個特定的時間點執行某些程式碼的套件。
- [Heimdall](https://github.com/himani93/heimdall): 用來將收到的 http request 記錄到某個檔案的套件，且這個寫好的檔可以用試算表類型(ex: excel, google sheets)的軟體開啟。


## 作者們

[Tanner Nelson](mailto:tanner@qutheory.io), [Logan Wright](mailto:logan@qutheory.io)，以及其他上百位 Vapor 的貢獻者們。
