### Add PostgreSQL database

Visit your applicatio at dashboard.heroku.com annd go to the **Add-ons** section.

From here enter `postgress` and you'll see an option for `Heroku Postgres`. Select it.

Choose the hobby dev free plan, and provision. Heroku will do the rest.

Once you finish, you’ll see the database appears under the **Resources** tab.

### Configure the database

We have to now tell our app how to access the database. In our app directory, let's run.

```bash
heroku config
```

This will make output somewhat like this

```none
=== today-i-learned-vapor Config Vars
DATABASE_URL: postgres://cybntsgadydqzm:2d9dc7f6d964f4750da1518ad71hag2ba729cd4527d4a18c70e024b11cfa8f4b@ec2-54-221-192-231.compute-1.amazonaws.com:5432/dfr89mvoo550b4
```

**DATABASE_URL** here will represent out postgres database. **NEVER** hard code the static url from this, heroku will rotate it and it will break your application. It is also bad practice.

Here is an example databsae configuration

```swift
let databaseConfig: PostgreSQLDatabaseConfig
if let url = Environment.get("DATABASE_URL") {
  // configuring database
  databaseConfig = PostgreSQLDatabaseConfig(url: url)!
} else {
  // ...
}
```

Don't forget to commit these changes

```none
git add .
git commit -m "configured heroku database"
```

### Reverting your database

You can revert or run other commmands on heroku with the `run` command. Vapor's project is by default also named `Run`, so it reads a little funny.

To revert your database:

```bash
heroku run Run -- revert --all --yes --env production
```

To migrate

```bash
heroku run Run -- migrate --env production
```