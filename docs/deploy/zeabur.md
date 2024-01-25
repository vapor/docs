## What is Zeabur

[Zeabur](https://zeabur.com) is a platform that helps you deploy your service with one click, No matter what programming language or framework you use.

## Signing Up

You need a Zeabur account. If you don't have one, please use the following link to create:
</br>
https://zeabur.com/zh-TW/login

Zeabur uses "Login with GitHub" and needs access to your GitHub repos. You could change its access to your different projects and organizations later.

## Upload Your Project to GitHub

Before you deploy your Vapor project, you need to upload it to GitHub. Zeabur connects to your GitHub account, and you can select your public or private repo to deploy on Zeabur's Dashboard.

### Remove Docker File

The project created by the Vapor command has Dockerfile and docker-compose.yml by default. To avoid being recognized as the Docker Container by Zeabur, you need to delete these two files:

```bash
rm Dockerfile docker-compose.yml
```

### Sync Your Files

Make sure that all your changes have been synchronized to GitHub:

```bash
git add .
git commit -m "your commit message"
git push
```

## Deployment

Go to [Zeabur Console](https://dash.zeabur.com) and create a new project.

Then, click the `Deploy New Service` button and select deploy from GitHub.

After you select the repository and branch, Zeabur will automatically start building your service.

Zeabur will automatically detect that your service is built by Vapor, so you don't need to do any additional configuration. Your deployment will be completed in a few minutes.

## Next

After the deployment is completed, you may need to configure the domain for your Vapor website.

Open the "Domain" tab of the service page, and then click "Generate Domain" or "Custom Domain".

For more information on how to bind a domain to your service, please refer to Zeabur's Docs on [Domain Binding](/deploy/domain-binding).
