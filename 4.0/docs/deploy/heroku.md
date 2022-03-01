# What is Heroku

Heroku is a popular all in one hosting solution, you can find more at [heroku.com](https://www.heroku.com)

## Signing Up

You'll need a heroku account, if you don't have one, please sign up here: [https://signup.heroku.com/](https://signup.heroku.com/)

## Installing CLI

Make sure that you've installed the heroku cli tool.

### HomeBrew

```bash
brew install heroku/brew/heroku
```

### Other Install Options

See alternative install options here: [https://devcenter.heroku.com/articles/heroku-cli#download-and-install](https://devcenter.heroku.com/articles/heroku-cli#download-and-install).

### Logging in

once you've installed the cli, login with the following:

```bash
heroku login
```

verify that the correct email is logged in with:

```bash
heroku auth:whoami
```

### Create an application

Visit dashboard.heroku.com to access your account, and create a new application from the drop down in the upper right hand corner. Heroku will ask a few questions such as region and application name, just follow their prompts.

### Git

Heroku uses Git to deploy your app, so you’ll need to put your project into a Git repository, if it isn’t already.

#### Initialize Git

If you need to add Git to your project, enter the following command in Terminal:

```bash
git init
```

#### Master

By default, Heroku deploys the **master** branch. Make sure all changes are checked into this branch before pushing.

Check your current branch with

```bash
git branch
```

The asterisk indicates current branch.

```bash
* master
  commander
  other-branches
```

!!! note 
    If you don’t see any output and you’ve just performed `git init`. You’ll need to commit your code first then you’ll see output from the `git branch` command.


If you’re _not_ currently on **master**, switch there by entering:

```bash
git checkout master
```

#### Commit changes

If this command produces output, then you have uncommitted changes.

```bash
git status --porcelain
```

Commit them with the following

```bash
git add .
git commit -m "a description of the changes I made"
```

#### Connect with Heroku

Connect your app with heroku (replace with your app's name).

```bash
$ heroku git:remote -a your-apps-name-here
```

### Set Buildpack

Set the buildpack to teach heroku how to deal with vapor.

```bash
heroku buildpacks:set vapor/vapor
```

### Swift version file

The buildpack we added looks for a **.swift-version** file to know which version of swift to use. (replace 5.2.1 with whatever version your project requires.)

```bash
echo "5.2.1" > .swift-version
```

This creates **.swift-version** with `5.2.1` as its contents.


### Procfile

Heroku uses the **Procfile** to know how to run your app, in our case it needs to look like this:

```
web: Run serve --env production --hostname 0.0.0.0 --port $PORT
```

we can create this with the following terminal command

```bash
echo "web: Run serve --env production" \
  "--hostname 0.0.0.0 --port \$PORT" > Procfile
```

### Commit changes

We just added these files, but they're not committed. If we push, heroku will not find them.

Commit them with the following.

```bash
git add .
git commit -m "adding heroku build files"
```

### Deploying to Heroku

You're ready to deploy, run this from the terminal. It may take a while to build, this is normal.

```none
git push heroku master
```

### Scale Up

Once you've built successfully, you need to add at least one server, one web is free and you can get it with the following:

```bash
heroku ps:scale web=1
```

### Continued Deployment

Any time you want to update, just get the latest changes into master and push to heroku and it will redeploy

## Postgres

### Add PostgreSQL database

Visit your application at dashboard.heroku.com and go to the **Add-ons** section.

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

Here is an example database configuration

```swift
if let databaseURL = Environment.get("DATABASE_URL") {
    app.databases.use(try .postgres(
        url: databaseURL
    ), as: .psql)
} else {
    // ...
}
```

Unverified TLS is required if you are using Heroku Postgres's standard plan:

```swift
if let databaseURL = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: databaseURL) {
    postgresConfig.tlsConfiguration = .makeClientConfiguration()
    postgresConfig.tlsConfiguration?.certificateVerification = .none
    app.databases.use(.postgres(
        configuration: postgresConfig
    ), as: .psql)
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
heroku run Run -- migrate --revert --all --yes --env production
```

To migrate

```bash
heroku run Run -- migrate --env production
```
