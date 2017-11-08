# HTTP

At the heart of the web lies HTTP. HTTP (or HyperText Transfer Protocol) is used for communicating multiple types of media between a client and a server.

HTTP comes in two major versions. `HTTP/1` and `HTTP/2`. Vapor comes with HTTP/1 support by default but has an official package for HTTP/2, too.

### What is the difference?

HTTP/1 is a protocol designed in the '90s for the then new and rapidly evolving internet. The protocol is designed around simplicity above security and functionality.

HTTP/2 is a protocol with security and performance in mind. Designed with experience of the past 20 years of internet in addition to modern standards such as a high bandwidth and many resources per page.

## How it works

At the heart of HTTP lie the [Request](../http/request.md) and [Response](../http/response,d). Both of them are "HTTP Messages". Both HTTP messages consists of [Headers](../http/headers.md) and [a body](../http/body.md).

HTTP clients connect to an HTTP server. The clients can send a request to which the server will send a response.

Bodies contain the concrete information being transferred. Think of the web-page, images, videos, [JSON](../vapor/json.md) and [forms](../http/multipart.md).

Headers contain metadata.

[Cookies](../http/cookies.md) are metadataabout the client that, for example, can be used for identifying users after they've (successfully) logged in. One of these methods are [session tokens](../jwt/index.md).

Another type of metadata can be related to the content. For example, defining the type of content transferred in the body.

### Request

Requests have two additional properties in addition to all properties of a Message. The [Method](../http/method.md) and [path](../http/uri.md).

The path is used to specify the resource being accessed. Although there are conventions, there are no rules/limitations to how you structure your paths except their format. Paths consist of [components](../routing/parameters.md). The components are separated by a forward slash (`/`). All components must be encoded with percent encoding, affecting special characters only.

The [method](../http/method.md) indicated the operation to this resource. `GET` is used for reading a resource where `DELETE` will (attempt to) remove the resource. This does not mean you need to blindly comply. If a user doesn't have the permissions for said operation, you can emit a response indicating this.

### Response

Responses have one additional property in addition to the message's properties. This is [the status code](../http/status.md). The status code is used to indicate to the client what the status/result is of a Request. If a client was not authenticated, for example, you would return a status 401 or 403 for "Unauthorized" or "Forbidden" respectively. [More about status codes here.](../http/status.md)

## Handling requests

Requests in Vapor will be handled by a [router](../vapor/routing.md). This allows registering a path to a method. For example, registering `.get("users")` will register the path `/users/` to the method `GET`. The responder/closure associated with this route can then handle requests sent to `/users/` with the `GET` method.

## Types of endpoints

In the web we usually define two types of endpoints. Either a website or an API. Websites are HTML pages, usually with associated styling, code and images. APIs are endpoints that communicate with raw information rather than types and user friendly information. APIs are aimed to developers and their applications.

iOS and Android apps usually communicate with an API, where a web browser such as Safari, Firefox, Chrome or Edge will usually communicate with a website.

### Websites

Websites come in two major flavours. Server and client rendered pages. "Rendering" in this context doesn't mean the graphical rendering on your monitor, but instead the way information is injected into the HTML DOM to display the information to the users.

Server rendered pages make use of a templating system such as [leaf](../leaf/index.md) whereas client rendered pages communicate with an API.

### API

APIs are endpoints that sometimes receive but always reply with raw data. The raw data can be in any format. Most commonly, APIs communicate with [JSON](../vapor/json.md). Sometimes, they communicate with XML or other data types. Vapor can flexibly switch between supported formats, both by official or by community made libraries.

APIs in Vapor are (almost) always creating using a "MVC" or "Model View Controller" model [which we explain here.](controllers.md)

Designing an API in Vapor is really simple. [We dive into this more here.](application-design.md)
