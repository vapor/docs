---
currentMenu: LoginRedirectMiddleware
---

# Login Redirect Middleware

`LoginRedirectMiddleware` is a Middleware to be used when you what to create an automatic redirection from any routes when the user is not authenticated.

## Examples 
In your main.swift file

```swift
drop.grouped(LoginRedirectMiddleware(loginRoute: "/login")).group("admin") { routeAdmin in
            let imagesViewController = ImagesViewController()
            routeAdmin.get("images", handler: imagesViewController.indexView)
            routeAdmin.get("images", Image.self, handler: imagesViewController.imageSelectedView)

        }
```

> If the user is not connected when GET /admin/images is requested, user-agent will be redirected automatically to `/login` route

