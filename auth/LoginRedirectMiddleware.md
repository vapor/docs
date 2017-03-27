---
currentMenu: LoginRedirectMiddleware
---

# Login Redirect Middleware

`LoginRedirectMiddleware` is a Middleware to be used when you want to create an automatic redirection from any routes when the user is not authenticated. Users that want to access to a protected route will be redirected to a single route.

## Example
In your main.swift file:

```swift
drop.grouped(LoginRedirectMiddleware(loginRoute: "/login")).group("admin") { routeAdmin in
            let imagesViewController = ImagesViewController()
            routeAdmin.get("images", handler: imagesViewController.indexView)
            routeAdmin.get("images", Image.self, handler: imagesViewController.imageSelectedView)

        }
```

> If the user is not connected when GET /admin/images is requested, user-agent will be redirected automatically to `/login` route

