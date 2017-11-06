# Route

Route is an object that contains the essential information of an HTTP Route.

It contains the route's Method, path components and responder.

## Extensions

Routes are Extensible using the `extend` property. This allow storing additional data for use by integrating libraries.

The purpose is to allow tools (such as documentation tools) to hook into the Vapor routing process.
