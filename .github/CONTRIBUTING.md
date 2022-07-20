# Contributing to Vapor Docs

Found a mistake or want to add something? Fork the documentation, fix it, and submit a pull request.

We'll merge it as soon as we can.

Thanks!

## Developing

### 1.0

Install `couscous` through Composer and run `couscous preview`

### 2.0+

Install Homebrew.

See [Homebrew](https://brew.sh)

Install Python 3.

```sh
brew install python3
```

Install MkDocs and MkDocs Material theme.

```sh
pip3 install mkdocs
pip3 install mkdocs-material
```

Run with `mkdocs serve`

## Testing

If you want to check dead links, use markdown-link-check

```sh
npm install --save-dev markdown-link-check
```

Run with 

```sh
find . -name \*.md -print0 | xargs -0 -n1 markdown-link-check -q -c markdown-link-check-config.yml
```
on directly under the repository.


OR   

Run docker directly under the repository

```sh
docker run -v ${PWD}:/tmp:ro --rm -i --entrypoint "sh" ghcr.io/tcort/markdown-link-check:stable  "-c" "find /tmp -name \*.md -print0 | xargs -0 -n1 markdown-link-check -q -c /tmp/markdown-link-check-config.yml"
```



### Maintainers 
- [@0xtim](https://github.com/0xTim)
- [@mcdappdev](https://github.com/mcdappdev)

See https://github.com/vapor/vapor/blob/main/.github/maintainers.md for more information. 
