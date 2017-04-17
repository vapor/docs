# Auth Provider

After you've [added the Auth Provider package](package.md) to your project, setting the provider up in code is easy.

## Add to Droplet

Register the `AuthProvider.Provider` with your Droplet.

```swift
import Vapor
import AuthProvider

let drop = try Droplet()

try drop.addProvider(AuthProvider.Provider.self)

...
```

## Done

You are now ready to start using the Auth package.
