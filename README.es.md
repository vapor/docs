# Documentación de Vapor 

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

Esta es la documentación de Vapor, el _framework web_ para Swift que funciona sobre iOS, macOS y ubuntu; y sobre todos los _paquetes_ que Vapor ofrece.

Vapor es el _framework web_  más utilizado para Swift. 

Vapor is the most used web framework for Swift. Proporciona una base maravillosamente expresiva y fácil de usar para tu próximo sitio web o API.

Para ver el código fuente y la documentación del código visita [Vapor's GitHub](https://github.com/vapor/vapor).

Para leer esto en chino [正體中文](https://github.com/vapor/documentation/blob/master/README.zh-hant.md)

Para leer esto en [inglés](https://github.com/vapor/documentation/blob/master/README.md)

## Cómo leer esta documentación.

Puede leer esta guía haciendo clic en las carpetas y los archivos de [GitHub](https://github.com/vapor/documentation) o a través de las páginas generadas [GitHub Pages](https://vapor.github.io/documentation/).

## API 

La documentación de la API generada automáticamente se encuentra en [api.vapor.codes](http://api.vapor.codes).

## Paquetes

Aquí hay una lista de todos los paquetes y módulos incluidos con Vapor (también _utilizables_ individualmente).

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

## Proveedores y otros.

Aquí hay una lista de proveedores y paquetes de terceros que funcionan muy bien con Vapor.

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
- [VaporForms](https://github.com/bygri/vapor-forms): Brings simple, dynamic and re-usable web form handling to Vapor.
- [Jobs](https://github.com/BrettRToomey/Jobs): A minimalistic job/background-task system for Swift.
- [Heimdall](https://github.com/himani93/heimdall): An easy to use HTTP request logger.


## Autores

[Tanner Nelson](mailto:tanner@qutheory.io), [Logan Wright](mailto:logan@qutheory.io), y los cientos de miembros de Vapor.
