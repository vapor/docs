# Status codes

Status codes are exclusively part of the [HTTP Response](response.md) and are required.

Status codes are a 3 digit number.

The first of the 3 numbers indicated the type of response.

\_xx | Meaning
-----|--------
1xx  | Informational response
2xx  | Success
3xx  | Redirection
4xx  | Client error
5xx  | Server error

The other 2 numbers in a status code are used to define a specific code.

## Selecting a status code

The enum `Status` has all supported status codes. It can be accessed using a `.` or created using an integer literal.

```swift
let ok = Status.ok
let notFound = Status.notFound
```

```swift
let ok: Status = 200
let notFound: Status = 404
```

## Informational responses

Informational responses indicate a [Request](request.md) was received and understood.

### 101 - switching protocols

Switching Protocols is a status code used to upgrade the connection to a different protocol. Commonly used by [WebSocket](../websocket/websocket.md) or HTTP/2.

## Success responses

Success responses indicate that the request was received, understood, accepted and processed.

### 200 - OK

200, or "OK" is the most common status code. It's used to indicate successful processing of the Request.

## Redirection responses

Redirection responses indicate the client must take additional action to complete the request. Many of these status codes are used in URL redirection.

## Client error responses

Client errors indicate an error was caused by the client.

### 400 - Bad Request

The error was caused by the client sending an invalid request.

For example an invalid message, malformed request syntax or too large request size.

### 403 - Forbidden

The client does not have the permissions to execute this operation on the specified resource.

### 404 - Not found

The requested resource does not exist.

## Server error responses

Server errors occur when the an error occurred on the server side.

### 500 - Internal Server Error

Internal server errors are almost exclusively used when an error occurred on the server.
