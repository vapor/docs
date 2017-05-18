---
currentMenu: guide-folder-structure
---

# 目录结构 （Folder Structure）

> 翻译：[@孟祥月_iOS](http://weibo.com/u/1750643861)

创建一个好的应用的第一步是知道所有的内容都在哪里。如果你使用 [Toolbox](../getting-started/toolbox.md) 或者从一个模板创建你的项目的时候，你已经有了一个被创建好的目录结构。

如果你从一个脚手架创建了 Vapor 程序，这里将要给你展示怎么设置它。


## 最小目录结构 （Minimum Folder Structure）

我们建议将你的所有的代码放到 `App/` 文件夹。你可以在 `App/` 目录下创建子目录，用于组织你的 models 和 resourcees。

This works best with the Swift package manager's restrictions on how packages should be structured.
这个结构和 Swift Package Manager 的关于如何组织打包结构的限制能够结合的比较好。

```
.
├── App
│   └── main.swift
├── Public
└── Package.swift
```

`Public` 文件夹放置所有公开访问的文件。每次当一个 URL 请求在你的 routes 里面没有被发现的时候，这个文件夹将会被检查是否能够匹配该 URL。

> 注意： `FileMiddleware` 是用来响应访问 `Public` 文件夹的中间价。

## Models

`Models` 文件夹建议用来存放数据库和其他 models 相关的东西，这个遵从 MVC 模式。

```
.
├── App
.   └── Models
.       └── User.swift
```

## Controllers

The `Controllers` folder is a recommendation of where you can put your route controllers, following the MVC pattern.
`Controllers` 文件夹建议用来放置你的 router controller，这个遵从 MVC 模式。

```
.
├── App
.   └── Controllers
.       └── UserController.swift
```

## Views

当你渲染 view 的时候，`Resources` 目录下的 `Views` 文件夹将会被 Vapor 用来查找对应 view。

```
.
├── App
└── Resources
    └── Views
         └── user.html
```

下面的代码将会加载 `user.html` 文件。

```swift
drop.view.make("user.html")
```

## Config

Vapor 有一个复杂（精细）的配置系统，及涉及配置重要性的层次结构。

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

像上面展示的那样，在 `Config` 目录中的 `.json` 文件是结构化的。这个配置将会在什么环境生效，依赖于 `.json` 文件在目录层次的位置。 更多内容请看 [Config](config.md)。

在 [Droplet](droplet.md) 章节，我们已经知道如何改变环境 (the `--env=` flag)。
