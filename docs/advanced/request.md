# Request

## Overview

The `Request` class contains all the information for an incoming HTTP request. It is passed into your route closures and most other Vapor methods.

### IP Address

Often it can be useful to get the IP address of the client making the request. This can be done using the `remoteAddress` property on `Request`.

```swift
let ip = request.remoteAddress.ipAddress
```
