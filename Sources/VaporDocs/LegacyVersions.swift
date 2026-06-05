import Kiln

// Legacy Vapor documentation versions, imported from github.com/vapor/docs-legacy.
// Each is English-only and lives under docs/<id>/. Navigation was generated from
// the original MkDocs (3.0/2.0) and Couscous (1.5) menus.

let v3_0 = DocVersion(
    id: "3.0",
    name: "3.0",
    contentDirectory: "3.0",
    languages: [.init(.english, isDefault: true)]
) {
    Page("Overview", "index.md")
    Section("Install") {
        Page("macOS", "install/macos.md")
        Page("Ubuntu", "install/ubuntu.md")
    }
    Section("Getting Started") {
        Page("Hello, world", "getting-started/hello-world.md")
        Page("Toolbox", "getting-started/toolbox.md")
        Page("SPM", "getting-started/spm.md")
        Page("Xcode", "getting-started/xcode.md")
        Page("Folder Structure", "getting-started/structure.md")
        Page("Application", "getting-started/application.md")
        Page("Controllers", "getting-started/controllers.md")
        Page("Routing", "getting-started/routing.md")
        Page("Content", "getting-started/content.md")
        Page("Async", "getting-started/async.md")
        Page("Services", "getting-started/services.md")
        Page("Deployment", "getting-started/cloud.md")
    }
    Section("Async") {
        Page("Getting Started", "async/getting-started.md")
        Page("Overview", "async/overview.md")
    }
    Section("Auth") {
        Page("Getting Started", "auth/getting-started.md")
        Page("Stateless (API)", "auth/api.md")
        Page("Sessions (Web)", "auth/web.md")
    }
    Section("Console") {
        Page("Getting Started", "console/getting-started.md")
        Page("Overview", "console/overview.md")
    }
    Section("Command") {
        Page("Getting Started", "command/getting-started.md")
        Page("Overview", "command/overview.md")
    }
    Section("Crypto") {
        Page("Getting Started", "crypto/getting-started.md")
        Page("Digests", "crypto/digests.md")
        Page("Ciphers", "crypto/ciphers.md")
        Page("Asymmetric", "crypto/asymmetric.md")
        Page("Random", "crypto/random.md")
        Page("TOTP & HOTP", "crypto/otp.md")
    }
    Section("Database Kit") {
        Page("Getting Started", "database-kit/getting-started.md")
        Page("Overview", "database-kit/overview.md")
    }
    Section("Fluent") {
        Page("Getting Started", "fluent/getting-started.md")
        Page("Models", "fluent/models.md")
        Page("Querying", "fluent/querying.md")
        Page("Migrations", "fluent/migrations.md")
        Page("Relations", "fluent/relations.md")
        Page("Transaction", "fluent/transaction.md")
    }
    Section("HTTP") {
        Page("Getting Started", "http/getting-started.md")
        Page("Client", "http/client.md")
        Page("Server", "http/server.md")
        Page("Message", "http/message.md")
    }
    Section("Jobs") {
        Page("Getting Started", "jobs/getting-started.md")
        Page("Redis Driver", "jobs/redis-driver.md")
        Page("Modeling Jobs", "jobs/jobs.md")
        Page("Dispatching Jobs", "jobs/dispatching-jobs.md")
        Page("Scheduling Jobs", "jobs/scheduling-jobs.md")
    }
    Section("JWT") {
        Page("Getting Started", "jwt/getting-started.md")
        Page("Overview", "jwt/overview.md")
    }
    Section("Leaf") {
        Page("Getting Started", "leaf/getting-started.md")
        Page("Overview", "leaf/overview.md")
        Page("Custom tags", "leaf/custom-tags.md")
    }
    Section("Logging") {
        Page("Getting Started", "logging/getting-started.md")
        Page("Overview", "logging/overview.md")
    }
    Section("Multipart") {
        Page("Getting Started", "multipart/getting-started.md")
        Page("Overview", "multipart/overview.md")
    }
    Section("MySQL") {
        Page("Getting Started", "mysql/getting-started.md")
    }
    Section("PostgreSQL") {
        Page("Getting Started", "postgresql/getting-started.md")
    }
    Section("Redis") {
        Page("Getting Started", "redis/getting-started.md")
        Page("Overview", "redis/overview.md")
    }
    Section("Routing") {
        Page("Getting Started", "routing/getting-started.md")
        Page("Overview", "routing/overview.md")
    }
    Section("Service") {
        Page("Getting Started", "service/getting-started.md")
        Page("Services", "service/services.md")
        Page("Provider", "service/provider.md")
    }
    Section("SQL") {
        Page("Getting Started", "sql/getting-started.md")
        Page("Overview", "sql/overview.md")
    }
    Section("SQLite") {
        Page("Getting Started", "sqlite/getting-started.md")
    }
    Section("Template Kit") {
        Page("Getting Started", "template-kit/getting-started.md")
    }
    Section("Testing") {
        Page("Getting Started", "testing/getting-started.md")
    }
    Section("URL-Encoded Form") {
        Page("Getting Started", "url-encoded-form/getting-started.md")
        Page("Overview", "url-encoded-form/overview.md")
    }
    Section("Validation") {
        Page("Getting Started", "validation/getting-started.md")
        Page("Overview", "validation/overview.md")
    }
    Section("Vapor") {
        Page("Getting Started", "vapor/getting-started.md")
        Page("Client", "vapor/client.md")
        Page("Content", "vapor/content.md")
        Page("Sessions", "vapor/sessions.md")
        Page("WebSocket", "vapor/websocket.md")
        Page("Middleware", "vapor/middleware.md")
    }
    Section("WebSocket") {
        Page("Getting Started", "websocket/getting-started.md")
        Page("Overview", "websocket/overview.md")
    }
    Section("Deploy") {
        Page("Heroku", "deploy/heroku.md")
    }
    Section("Extras") {
        Page("Style Guide", "extras/style-guide.md")
        Page("Yeoman", "extras/yeoman.md")
    }
    Section("Version (3.0)") {
        Page("1.5", "version/1_5.md")
        Page("2.0", "version/2_0.md")
        Page("3.0", "version/3_0.md")
        Page("Upgrading", "version/upgrading.md")
        Page("Support", "version/support.md")
    }
}

let v2_0 = DocVersion(
    id: "2.0",
    name: "2.0",
    contentDirectory: "2.0",
    languages: [.init(.english, isDefault: true)]
) {
    Page("Overview", "index.md")
    Section("Getting started") {
        Page("Install: macOS", "getting-started/install-on-macos.md")
        Page("Install: Ubuntu", "getting-started/install-on-ubuntu.md")
        Page("Toolbox", "getting-started/toolbox.md")
        Page("Hello, World", "getting-started/hello-world.md")
        Page("Manual", "getting-started/manual.md")
        Page("Xcode", "getting-started/xcode.md")
    }
    Section("Vapor") {
        Page("Folder Structure", "vapor/folder-structure.md")
        Page("Droplet", "vapor/droplet.md")
        Page("Views", "vapor/views.md")
        Page("Controllers", "vapor/controllers.md")
        Page("Provider", "vapor/provider.md")
        Page("Hash", "vapor/hash.md")
        Page("Log", "vapor/log.md")
        Page("Commands", "vapor/commands.md")
    }
    Section("Configs") {
        Page("Config", "configs/config.md")
    }
    Section("JSON") {
        Page("Package", "json/package.md")
        Page("Overview", "json/overview.md")
    }
    Section("Routing") {
        Page("Package", "routing/package.md")
        Page("Overview", "routing/overview.md")
        Page("Parameters", "routing/parameters.md")
        Page("Group", "routing/group.md")
        Page("Collection", "routing/collection.md")
    }
    Section("Fluent") {
        Page("Package", "fluent/package.md")
        Page("Getting Started", "fluent/getting-started.md")
        Page("Model", "fluent/model.md")
        Page("Database", "fluent/database.md")
        Page("Query", "fluent/query.md")
        Page("Relations", "fluent/relations.md")
    }
    Section("Cache") {
        Page("Package", "cache/package.md")
        Page("Overview", "cache/overview.md")
    }
    Section("MySQL") {
        Page("Package", "mysql/package.md")
        Page("Provider", "mysql/provider.md")
        Page("Driver", "mysql/driver.md")
    }
    Section("Redis") {
        Page("Package", "redis/package.md")
        Page("Provider", "redis/provider.md")
    }
    Section("Auth") {
        Page("Package", "auth/package.md")
        Page("Provider", "auth/provider.md")
        Page("Getting Started", "auth/getting-started.md")
        Page("Helper", "auth/helper.md")
        Page("Password", "auth/password.md")
        Page("Persist", "auth/persist.md")
        Page("Redirect Middleware", "auth/redirect-middleware.md")
    }
    Section("JWT") {
        Page("Package", "jwt/package.md")
        Page("Overview", "jwt/overview.md")
    }
    Section("Sessions") {
        Page("Package", "sessions/package.md")
        Page("Sessions", "sessions/sessions.md")
    }
    Section("HTTP") {
        Page("Package", "http/package.md")
        Page("Request", "http/request.md")
        Page("Response", "http/response.md")
        Page("Middleware", "http/middleware.md")
        Page("Body", "http/body.md")
        Page("ResponseRepresentable", "http/response-representable.md")
        Page("Responder", "http/responder.md")
        Page("Client", "http/client.md")
        Page("Server", "http/server.md")
        Page("CORS", "http/cors.md")
    }
    Section("Leaf") {
        Page("Package", "leaf/package.md")
        Page("Provider", "leaf/provider.md")
        Page("Overview", "leaf/leaf.md")
    }
    Section("Validation (WIP)") {
        Page("Package", "validation/package.md")
        Page("Overview", "validation/overview.md")
    }
    Section("Node") {
        Page("Package", "node/package.md")
        Page("Getting Started", "node/getting-started.md")
    }
    Section("Core") {
        Page("Package", "core/package.md")
        Page("Overview", "core/overview.md")
    }
    Section("Bits") {
        Page("Package", "bits/package.md")
        Page("Overview", "bits/overview.md")
    }
    Section("Debugging") {
        Page("Package", "debugging/package.md")
        Page("Overview", "debugging/overview.md")
    }
    Section("Deploy") {
        Page("Cloud", "deploy/cloud.md")
        Page("Nginx", "deploy/nginx.md")
        Page("Apache2", "deploy/apache2.md")
        Page("Supervisor", "deploy/supervisor.md")
    }
    Section("Version (2.0)") {
        Page("1.5", "version/1_5.md")
        Page("2.0", "version/2_0.md")
        Page("3.0", "version/3_0.md")
        Page("Support", "version/support.md")
    }
}

let v1_5 = DocVersion(
    id: "1.5",
    name: "1.5",
    contentDirectory: "1.5",
    languages: [.init(.english, isDefault: true)]
) {
    Page("Overview", "index.md")
    Section("Getting Started") {
        Page("Install Swift 3: macOS", "getting-started/install-swift-3-macos.md")
        Page("Install Swift 3: Ubuntu", "getting-started/install-swift-3-ubuntu.md")
        Page("Install Toolbox", "getting-started/install-toolbox.md")
        Page("Hello, World", "getting-started/hello-world.md")
        Page("Manual", "getting-started/manual.md")
        Page("Xcode", "getting-started/xcode.md")
    }
    Section("Guide") {
        Page("Droplet", "guide/droplet.md")
        Page("Folder Structure", "guide/folder-structure.md")
        Page("JSON", "guide/json.md")
        Page("Config", "guide/config.md")
        Page("Views", "guide/views.md")
        Page("Leaf", "guide/leaf.md")
        Page("Controllers", "guide/controllers.md")
        Page("Middleware", "guide/middleware.md")
        Page("Validation", "guide/validation.md")
        Page("Provider", "guide/provider.md")
        Page("Sessions", "guide/sessions.md")
        Page("Hash", "guide/hash.md")
        Page("Commands", "guide/commands.md")
    }
    Section("Routing") {
        Page("Basic", "routing/basic.md")
        Page("Route Parameters", "routing/parameters.md")
        Page("Query Parameters", "routing/query-parameters.md")
        Page("Group", "routing/group.md")
        Page("Collection", "routing/collection.md")
    }
    Section("Fluent") {
        Page("Driver", "fluent/driver.md")
        Page("Model", "fluent/model.md")
        Page("Query", "fluent/query.md")
        Page("Relation", "fluent/relation.md")
    }
    Section("Auth") {
        Page("User", "auth/user.md")
        Page("Middleware", "auth/middleware.md")
        Page("Request", "auth/request.md")
        Page("Protect", "auth/protect.md")
    }
    Section("HTTP") {
        Page("Response", "http/response.md")
        Page("Body", "http/body.md")
        Page("ResponseRepresentable", "http/response-representable.md")
        Page("Responder", "http/responder.md")
        Page("Client", "http/client.md")
        Page("Server", "http/server.md")
        Page("CORS", "http/cors.md")
    }
    Section("WebSockets") {
        Page("Droplet", "websockets/droplet.md")
        Page("Custom", "websockets/custom.md")
    }
    Section("Version (1.5)") {
        Page("1.5", "switch/1_5.md")
        Page("2.0", "switch/2_0.md")
        Page("3.0", "switch/3_0.md")
    }
}
