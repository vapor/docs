---
currentMenu: guide-config
---

# Config

An application's configuration settings. Cloud applications generally require complex configurations that can adjust based on their environment. Vapor intends to provide a flexible configuration interaction that can be customized for a given user.

## QuickStart

For Vapor applications, configuration files are expected to be nested under a top level folder named `Config`. Here's an example of a basic config featuring a single `servers` configuration.

```bash
./
├── Config/
│   ├── servers.json
```

And an example of how this might look:

```JSON
{
  "http": {
    "host": "0.0.0.0",
    "port": 8080
  }
}
```

What that's saying, is that our application should start a single server named 'http' serving port `8080` on host `0.0.0.0`. This represents the following url: `http://localhost:8080`.

### Custom Keys

Let's add a custom key to the `servers.json` file:

```JSON
{
  "http": {
    "host": "0.0.0.0",
    "port": 8080,
    "custom-key": "custom value"
  }
}
```

This can be accessed from your application's config using the following.

```swift
let customValue = drop.config["servers", "http", "custom-key"]?.string ?? "default"
```

That's it, feel free to add and utilize keys as necessary to make your application configuration easier.

## Config Syntax

You can access your config directory with the following syntax. `app.config[<#file-name#>, <#path#>, <#to#>, <#file#>]`. For example, let's hypothesize that in addition to the `servers.json` file we mentioned earlier, there is also a `keys.json` that looks like this:

```JSON
{
  "test-names": [
    "joe",
    "jane",
    "sara"
  ],
  "mongo": {
    "url" : "www.customMongoUrl.com"
  }
}
```

We can access this file by making sure the first argument in our subscript is keys. To get the first name in our list:

```swift
let name = drop.config["keys", "test-names", 0]?.string ?? "default"
```

Or our mongo url:

```swift
let mongoUrl = drop.config["keys", "mongo", "url"]?.string ?? "default"
```

## Advanced Configurations

Having the default `servers.json` is great, but what about more complex scenarios. For example, what if we want a different host in production and in development? These complex scenarios can be achieved by adding additional folders to our `Config/` directory. Here's an example of a folder structure that's setup for production and development environments.

```bash
WorkingDirectory/
├── Config/
│   ├── servers.json
│   ├── production/
│   │   └── servers.json
│   ├── development/
│   │   └── servers.json
│   └── secrets/
│       └── servers.json
```

> You can specify the environment through the command line by using --env=. Custom environments are also available, a few are provided by default: production, development, and testing.

```bash
vapor run --env=production
```

### PRIORITY

Config files will be accessed in the following priority.

1. CLI (see below)
2. Config/secrets/
3. Config/name-of-environment/
4. Config/

What this means is that if a user calls `app.config["servers", "host"]`, the key will be searched in the CLI first, then the `secrets/` directory, then the top level default configs.

> `secrets/` directory should very likely be added to the gitignore.

### EXAMPLE

Let's start with the following JSON files.

#### `servers.json`

```JSON
{
  "http": {
    "host": "0.0.0.0",
    "port": 9000
  }
}
```

#### `production/servers.json`

```JSON
{
  "http": {
    "host": "127.0.0.1",
    "port": "$PORT"
  }
}
```

> The `"$NAME"` syntax is available for all values to access environment variables.

Please notice that `servers.json`, and `production/servers.json` both declare the same keys: `host`, and `port`. In our application, we'll call:

```swift
// will load 0.0.0.0 or 127.0.0.1 based on above config
let host = drop.config["servers", "http", "host"]?.string ?? "0.0.0.0"
// will load 9000, or environment variable port.
let port = drop.config["servers", "http", "port"]?.int ?? 9000
```

## COMMAND LINE

In addition to json files nested within the `Config/` directory, we can also use the command line to pass arguments into our config. By default, these values will be set as the "cli" file, but more complex options are also available.

#### 1. `--KEY=VALUE`

Arguments set through the command line can be accessed through config's cli file. For example, the following CLI command:

```bash
--mongo-password=$MONGO_PASSWORD
```

would be accessible within your application by using the following:

```swift
let mongoPassword = drop.config["cli", "mongo-password"]?.string
```

#### 2. `--CONFIG:FILE-NAME.KEY=CUSTOM-VALUE`

If you want command line arguments set to a file besides "cli", you can use this more advanced specification. For example, the following CLI command:

```bash
--config:keys.analytics=124ZH61F
```

would be accessible within your application by using the following:

```swift
let analyticsKey = drop.config["keys", "analytics"]?.string
```
