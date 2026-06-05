---
currentMenu: guide-folder-structure
---

# Folder Structure

The first step to creating an awesome application is knowing where things are. If you created your project using the [Toolbox](../getting-started/toolbox.md) or from a template, you will already have the folder structure created.

If you are making a Vapor application from scratch, this will show you exactly how to set it up.

## Minimum Folder Structure

We recommend putting all of your Swift code inside of the `App/` folder. This will allow you to create subfolders in `App/` to organize your models and resources.

This works best with the Swift package manager's restrictions on how packages should be structured.

```
.
├── App
│   └── main.swift
├── Public
└── Package.swift
```

The `Public` folder is where all publicly accessible files should go. This folder will be automatically checked every time a URL is requested that is not found in your routes.

> Note: The `FileMiddleware` is responsible for accessing files from the `Public` folder.

## Models

The `Models` folder is a recommendation of where you can put your database and other models, following the MVC pattern.

```
.
├── App
.   └── Models
.       └── User.swift
```

## Controllers

The `Controllers` folder is a recommendation of where you can put your route controllers, following the MVC pattern.

```
.
├── App
.   └── Controllers
.       └── UserController.swift
```

## Views

The `Views` folder in `Resources` is where Vapor will look when you render views.

```
.
├── App
└── Resources
    └── Views
         └── user.html
```

The following code would load the `user.html` file.

```swift
drop.view.make("user.html")
```

## Config

Vapor has a sophisticated configuration system that involves a hierarchy of configuration importance.

```
.
├── App
└── Config
  └── app.json         // default app.json
    └── development
         └── app.json  // overrides app.json when in development environment
    └── production
         └── app.json  // overrides app.json when in production environment
    └── secrets
         └── app.json  // overrides app.json in all environments, ignored by git
```

`.json` files are structured in the `Config` folder as shown above. The configuration will be applied dependant on where the `.json` file exists in the hierarchy. Learn more in [Config](config.md).

Learn about changing environments (the `--env=` flag) in the [Droplet](droplet.md) section.
