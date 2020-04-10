# Contributing to Vapor Docs

Found a mistake or want to add something? Fork the documentation, fix it, and submit a pull request.

We'll merge it as soon as we can.

Thanks!

## Developing

### 1.0

Install `couscous` through Composer and run `couscous preview`

### 2.0 and 3.0

Install MkDocs and MkDocs Material theme.

```sh
pip install mkdocs
pip install mkdocs-material
```

Run with `mkdocs serve`


### 4.0

Install and launch Docker.

```
brew cask install docker
```

Usage:

```
docker build -f web.Dockerfile . -t docs
docker run -d -p 80:80 docs
```

Then, open a browser and enter the URL: `http://localhost/4.0`

### Maintainers 
- [Tanner Nelson](mailto:tanner@vapor.codes)
- [晋先森](mailto:hi@jinxiansen.com)
