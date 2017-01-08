# Documentación de Vapor 

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

Esta es la documentación de Vapor, el _framework web_ para Swift que funciona sobre iOS, macOS y ubuntu; y sobre todos los _paquetes_ que Vapor ofrece.

Vapor es el _framework web_  más utilizado para Swift. Proporciona una base maravillosamente expresiva y fácil de usar para tu próximo sitio web o API.

Para ver el código fuente y la documentación del código visita [Vapor's GitHub](https://github.com/vapor/vapor).

Para leer esto en chino [正體中文](https://github.com/vapor/documentation/blob/master/README.zh-hant.md)

Para leer esto en [inglés](https://github.com/vapor/documentation/blob/master/README.md)

## Cómo leer esta documentación.

Puede leer esta guía haciendo clic en las carpetas y los archivos de [GitHub](https://github.com/vapor/documentation) o a través de las páginas generadas [GitHub Pages](https://vapor.github.io/documentation/).

## API 

La documentación de la API generada automáticamente se encuentra en [api.vapor.codes](http://api.vapor.codes).

## Paquetes

Aquí hay una lista de todos los paquetes y módulos incluidos con Vapor (también _utilizables_ individualmente).

- [Vapor](https://github.com/vapor/vapor): Swift el _framework web_ más utilizado.
	- Auth: Autenticación y persistencia de usuarios.
	- Sessions: Almacenamiento de datos seguro y _efímero_ basado en cookies.
	- Cookies: Cookies HTTP.
	- Routing: Enrutador avanzado con parametrización segura.
- [Fluent](https://github.com/vapor/fluent): Modelos, relaciones y consulta de bases de datos NoSQL y SQL.
- [Engine](https://github.com/vapor/engine): Capas de transporte principales.
	- HTTP: Cliente y servidor HTTP completamente en Swift.
	- URI:  Parseo y _serialización_ completamente en Swift.
	- WebSockets: Canales de comunicación full-duplex a través de una sola conexión TCP.		
	- SMTP: Envío de correo electrónico con SendGrill y Gmail.
- [Leaf](https://github.com/vapor/leaf): Un lenguaje de plantillas extensible.
- [JSON](https://github.com/vapor/json): Mapas Jay JSON a tipos de Vapor.
- [Console](https://github.com/vapor/console): Wrapper en Swift para E/S de consola y comandos.
- [TLS](https://github.com/vapor/tls): Wrapper en Swift para el nuevo TLS de CLibreSSL.
- [Crypto](https://github.com/vapor/crypto): Criptografía  de LibreSSL y Swift.
	- Digests: _Hashing_ con y sin autenticación.
	- Ciphers: Encriptación y descifrado.
	- Random: Pseudo aleatoriedad criptográficamente segura.
	- BCrypt: Implementación completamente en Swift.
- [Node](https://github.com/vapor/node): Estructura de datos para fáciles conversiones de tipo.
	- [Polymorphic](https://github.com/vapor/polymorphic): Sintaxis para acceder fácilmente a valores de tipos comunes como JSON.
	- [Path Indexable](https://github.com/vapor/path-indexable): Un protocolo para un acceso poderoso via _subscript_ a tipos comunes como JSON.
- [Core](https://github.com/vapor/core): Extensions básicas, alias de tipos, y funciones que facilitan tareas comunes.
- [Socks](https://github.com/vapor/socks): _API Wrapper_ para acceder a sockets en C.

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
