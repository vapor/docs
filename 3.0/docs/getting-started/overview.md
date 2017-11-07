# Overview

Vapor is a web framework and ecosystem for developing backends. To get started, this section will cover all concepts surrounding the ecosystem. It is optional, and can be skipped by those who already have experience in web/backend development.

## HTTP

At the heart of the web lies HTTP. HTTP (or HyperText Transfer Protocol) is used for communicating multiple types of media between a client and a server.

[This page](http.md) will cover most of HTTP in depth.

## Async and Codable

If you're coming from another language, chances are you've never heard of Swift's Codable protocol. If you don't know what protocols are we can highly recommend reading up on [the swift language guide](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/index.html). This is a thorough and easy to understand guide through the Swift language. It is not required to read the entire guide before starting, although most concepts mentioned throughout the Vapor documentation will be explained in the guide.

Asynchronous programming specifically is an essential part of the Vapor ecosystem that we recommend people [that is described here](async-and-codable.md).

[The same article](async-and-codable.md) will dive into Codable, a very simple protocol but important protocol in Vapor 3.

## Databases

Last, but not least, most applications will need a database for managing information such as user accounts, articles and other types of data.

Choosing a database can be a complex task for beginners and reading into your database of choice before starting can save a lot of frustration. We aim to simplify this stage [in this article.](databases.md)

## Front-end

Depending on your application you may need one or more clients to interact with your website. Frontends are very broad. Websites are a frontend that can be designed in various ways. Applications such as iOS and android apps are also considered frontends.

To assist designing your application you can [read this article.](application-desing.md)
