import Kiln

let v4_0 = DocVersion(
    id: "4.0",
    name: "4.0 (latest)",
    isDefault: true,
    contentDirectory: "4.0",
    languages: languages
) {
        Page("Welcome", "index.md")
        Section("Install") {
            Page("macOS", "install/macos.md")
            Page("Linux", "install/linux.md")
        }
        Section("Getting Started") {
            Page("Hello, world", "getting-started/hello-world.md")
            Page("Folder Structure", "getting-started/folder-structure.md")
            Page("SwiftPM", "getting-started/spm.md")
            Page("Xcode", "getting-started/xcode.md")
        }
        Section("Basics") {
            Page("Routing", "basics/routing.md")
            Page("Controllers", "basics/controllers.md")
            Page("Content", "basics/content.md")
            Page("Client", "basics/client.md")
            Page("Validation", "basics/validation.md")
            Page("Async", "basics/async.md")
            Page("Logging", "basics/logging.md")
            Page("Environment", "basics/environment.md")
            Page("Errors", "basics/errors.md")
        }
        Section("Fluent") {
            Page("Overview", "fluent/overview.md")
            Page("Model", "fluent/model.md")
            Page("Relations", "fluent/relations.md")
            Page("Migrations", "fluent/migration.md")
            Page("Query", "fluent/query.md")
            Page("Transactions", "fluent/transaction.md")
            Page("Schema", "fluent/schema.md")
            Page("Advanced", "fluent/advanced.md")
        }
        Section("Leaf") {
            Page("Getting Started", "leaf/getting-started.md")
            Page("Overview", "leaf/overview.md")
            Page("Custom Tags", "leaf/custom-tags.md")
        }
        Section("Redis") {
            Page("Overview", "redis/overview.md")
            Page("Sessions", "redis/sessions.md")
        }
        Section("Advanced") {
            Page("Middleware", "advanced/middleware.md")
            Page("Testing", "advanced/testing.md")
            Page("Server", "advanced/server.md")
            Page("Files", "advanced/files.md")
            Page("Commands", "advanced/commands.md")
            Page("Queues", "advanced/queues.md")
            Page("WebSockets", "advanced/websockets.md")
            Page("Sessions", "advanced/sessions.md")
            Page("Services", "advanced/services.md")
            Page("Request", "advanced/request.md")
            Page("APNS", "advanced/apns.md")
            Page("Tracing", "advanced/tracing.md")
        }
        Section("Security") {
            Page("Authentication", "security/authentication.md")
            Page("Crypto", "security/crypto.md")
            Page("Passwords", "security/passwords.md")
            Page("JWT", "security/jwt.md")
        }
        Section("Deploy") {
            Page("DigitalOcean", "deploy/digital-ocean.md")
            Page("Fly", "deploy/fly.md")
            Page("Heroku", "deploy/heroku.md")
            Page("Supervisor", "deploy/supervisor.md")
            Page("Systemd", "deploy/systemd.md")
            Page("Nginx", "deploy/nginx.md")
            Page("Docker", "deploy/docker.md")
        }
        Section("Contributing") {
            Page("Contributing Guide", "contributing/contributing.md")
        }
        Section("Version (4.0)") {
            Page("Upgrading", "upgrading.md")
        }
        Page("Release Notes", "release-notes.md")
}