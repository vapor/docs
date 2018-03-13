# Databases

Databases are an important choice for many applications. They come in many flavours for many different use cases.

This article covers the four most popular databases used by our users.

### Database terminology

**Databases** are a data management system. They allow storing data such as users, articles, relations (such as friends) and any other data structures. Databases allow querying and managing (large) data sets efficiently.

**Queries** are a request for (mutation of) information. The most popular query language is SQL, a simple, string based and easily readable query language.

**NoSQL** databases are databases which do not query using the SQL syntax. They often also serve a more specific use case.

## MongoDB

MongoDB is the only database in this list that is not an SQL database (or NoSQL). It is designed for extremely large datasets, often with a complex structure. MongoDB supports recursive structures, unlike SQL databases which are one-dimensional.

MongoDB's advantages lie in its architectural difference. It's more easily integrated in data models and more scalable.

The downsides of MongoDB are that the familiar SQL syntax and some table joins are not supported. MongoDB is also a fairly new player, so although it has become very stable and mature it is not as battle tested over the years compared to MySQL. MongoDB does not support auto incremented integers.

## MySQL

MySQL is one of the oldest and most robust databases in this list. Its old age has proven the database to be stable and trustworthy. It is an SQL database, meaning its queries are standardized, widely used, familiar and supported. This makes it extremely attractive to established businesses running SQL.

[MySQL documentation can be found here.](../mysql/index.md)

<!-- ## PostgreSQL -->

## SQLite

SQLite is a database that is designed for small applications. It is extremely easy to use in that it only requires a filesystem. It must not be used on cloud services such as [Vapor cloud](../vapor/cloud.md) or heroku as those don't persist the SQLite file.

SQLite is very limited in its supported datatypes and should only be used for the most basic applications that should be developed in little time. SQLite databases aren't scalable across multiple servers.

Using SQLite is [described more thoroughly here.](../sqlite/overview.md)
