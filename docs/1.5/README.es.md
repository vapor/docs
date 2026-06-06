# Documentación de Vapor 

[![Stack Overflow](https://img.shields.io/stackexchange/stackoverflow/t/vapor.svg)](http://stackoverflow.com/questions/tagged/vapor)

Esta es la documentación de Vapor, el _framework web_ para Swift que funciona sobre iOS, macOS y ubuntu; y sobre todos los _paquetes_ que Vapor ofrece.

Vapor es el _framework web_  más utilizado para Swift. Proporciona una base maravillosamente expresiva y fácil de usar para tu próximo sitio web o API.

Para ver el código fuente y la documentación del código visita [Vapor's GitHub](https://github.com/vapor/vapor).

Para leer esto en [正體中文](https://github.com/vapor/documentation/1.5/README.zh-hant.md)

Para leer esto en [简体中文](https://github.com/vapor/documentation/blob/README.zh-cn.md)

Para leer esto en [English](https://github.com/vapor/documentation/1.5/README.md)

## Cómo leer esta documentación.

Puedes leer esta guía haciendo clic en las carpetas y los archivos de [GitHub](https://github.com/vapor/documentation) o a través de las páginas generadas [GitHub Pages](https://vapor.github.io/documentation/).

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
- [Core](https://github.com/vapor/core): Extensiones básicas, _alias_ de tipos, y funciones que facilitan tareas comunes.
- [Socks](https://github.com/vapor/socks): _API Wrapper_ para acceder a sockets en C.

## Proveedores y otros.

Aquí hay una lista de proveedores y paquetes de terceros que funcionan muy bien con Vapor.

- [MySQL](https://github.com/vapor/mysql): Interface robusta MySQL para Swift.
	- [MySQL Driver](https://github.com/vapor/mysql-driver): _Driver_ MySQL  para Fluent.
	- [MySQL Provider](https://github.com/vapor/mysql-provider): Proveedor MySQL para Vapor.
- [SQLite](https://github.com/vapor/sqlite): _Wrapper_ SQLite 3  para Swift
	- [SQLite Driver](https://github.com/vapor/sqlite-driver): _Driver_ SQLite  para Fluent.
	- [SQLite Provider](https://github.com/vapor/sqlite-provider): Proveedor SQLite provider para Vapor.
- [PostgreSQL](https://github.com/vapor/postgresql): Interface PostgreSQL robusta  para Swift.
	- [PostgreSQL Driver](https://github.com/vapor/postgresql-driver): _Driver_  PostgreSQL para Fluent.
	- [PostgreSQL Provider](https://github.com/vapor/postgresql-provider): Proveedor  PostgreSQL para Vapor.
- [MongoKitten*](https://github.com/OpenKitten/MongoKitten): _Driver_ nativo  MongoDB, escrito en Swift
	- [Mongo Driver](https://github.com/vapor/mongo-driver): _Driver_ MongoKitten para Fluent.
	- [Mongo Provider](https://github.com/vapor/mongo-provider): Proveedor MongoKitten para Vapor.
	- [MainecoonVapor](https://github.com/OpenKitten/MainecoonVapor): MongoKitten ORM para Vapor.
- [Redbird](https://github.com/vapor/redbird): Un cliente Redis completamente en Swift implementado directamente desde la especificación del protocolo.
	- [Redis Provider](https://github.com/vapor/redis-provider): Proveedor del _cache_ de Redis para Vapor.
- [Kitura Provider](https://github.com/vapor/kitura-provider): Permite usar el servidor HTTP de IBM (Kitura) en Vapor.
- [SwiftyBeaver](https://github.com/SwiftyBeaver/SwiftyBeaver-Vapor): Agrega el potente _logging_ de SwiftyBeaver a Vapor.
- [APNS](https://github.com/matthijs2704/vapor-apns): Sencilla biblioteca APNS para Vapor (Swift).
- [VaporFCM](https://github.com/mdab121/vapor-fcm): Sencilla biblioteca FCM para Vapor.
- [JWT](https://github.com/siemensikkema/vapor-jwt): Implementación JWT para Vapor.
- [VaporS3Signer](https://github.com/JustinM1/VaporS3Signer): Gerera _V4 Auth Header/Pre-Signed URL_ para _AWS S3 REST API_.
- [Flock](https://github.com/jakeheis/Flock): _Despliegue_ automatizado de proyectos Swift en servidores.
	- [VaporFlock](https://github.com/jakeheis/VaporFlock): Utiliza Flock para _desplegar_ aplicaciones de vapor
- [VaporForms](https://github.com/bygri/vapor-forms): Brinda a Vapor un manejo de formularios web simple, dinámico y _reutilizable_.
- [Jobs](https://github.com/BrettRToomey/Jobs): Un sistema minimalista para ejecutar _jobs_/tareas en _2o plano_ para Swift.
- [Heimdall](https://github.com/himani93/heimdall): Un _logger_ de _requet's_ HTTP fácil de usar.


## Autores

[Tanner Nelson](mailto:tanner@qutheory.io), [Logan Wright](mailto:logan@qutheory.io), y los cientos de miembros de Vapor.
