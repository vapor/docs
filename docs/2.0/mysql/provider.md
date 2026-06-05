# MySQL Provider

After you've [added the MySQL Provider package](package.md) to your project, setting the provider up in code is easy.

## Add to Droplet

First, register the `MySQLProvider.Provider` with your Droplet.

```swift
import Vapor
import MySQLProvider

let config = try Config()
try config.addProvider(MySQLProvider.Provider.self)

let drop = try Droplet(config)

...
```

## Configure Fluent

Once the provider is added to your Droplet, you can configure Fluent to use the MySQL driver.

`Config/fluent.json`

```json
{
    "driver": "mysql"
}
```

!!! seealso
	Learn more about configuration files in the [Settings guide](../configs/config.md).

## Configure MySQL

If you run your application now, you will likely see an error that the MySQL configuration file is missing. Let's add that now.

### Basic

Here is an example of a simple MySQL configuration file.

`Config/mysql.json`
```json
{
    "hostname": "127.0.0.1",
    "user": "root",
    "password": "password",
    "database": "hello"
}
```

!!! note
	It's a good idea to store the MySQL configuration file in the `Config/secrets` folder since it contains sensitive information.

### URL

You can also pass the MySQL credentials as a URL.

`Config/mysql.json`
```json
{
    "url": "http://root:password@127.0.0.1/hello"
}
```

### Read Replicas

Read replicas can be supplied by passing a single `master` hostname and an array of `readReplicas` hostnames.

`Config/mysql.json`
```json
{
    "master": "master.mysql.foo.com",
    "readReplicas": ["read01.mysql.foo.com", "read02.mysql.foo.com"],
    "user": "root",
    "password": "password",
    "database": "hello"
}
```

!!! tip
	You can also provide the `readReplicas` as a comma-separated string.

## Driver

You can get access to the [MySQL Driver](driver.md) on the droplet.

```swift
import Vapor
import MySQLProvider

let mysqlDriver = try drop.mysql()
```

## Configure Cache

You can also choose to use your Fluent database (now set to MySQL) for caching. 

`Config/droplet.json`

```json
{
    "driver": "fluent"
}
```

Learn more about [caching here](../cache/package.md).

## Done

Next time you boot your Droplet, you should see:

```sh
Database prepared
```

You are now ready to [start using Fluent](../fluent/getting-started) with your MySQL database.



