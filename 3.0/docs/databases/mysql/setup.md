# MySQL Setup

This page guides you through installing and connecting to MySQL or MariaDB.

## Installation

First, you need to install MySQL on your server or test environment.

### Ubuntu

Ubuntu has a thorough guide [here](https://help.ubuntu.com/lts/serverguide/mysql.html) outlining both basic installation, configuration as well as advanced configurations.

### macOS

Assuming you've installed [homebrew](https://brew.sh) you can use the following command to set up MySQL.

```bash
brew install mysql
```

Any issues and further configuration will be explained in the terminal on completion of the installation.

## Connecting

The MySQL driver works with an automatically managed connection pool.

The following code creates a new connectionpool to `localhost` and the default MySQL port. The user that's being authenticated with is `root` and the password is `nil` for "no password". If you do set a password, even if it's empty `""` it will be treated differently. Users without a password must specify `nil` and must not specify `""`.

The database is the database that is selected and authenticated to. Any future queries will be sent to this database.

The `worker` is defined in [the async documentation](../async/worker.md).

```swift
let connectionPool = ConnectionPool(hostname: "localhost", user: "root", password: nil, database: "test-db", worker: worker)
```

Creating a connection pool successfully does not imply that the configuration is correct. The (first) query's success or failure will indicate the successful or unsuccessful connection. This way the API stays much simpler than it would otherwise be.

[Learn how you can execute queries here](basics.md)
