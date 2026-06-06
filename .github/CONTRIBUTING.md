# Contributing to Vapor Docs

Found a mistake or want to add something? Fork the documentation, fix it, and submit a pull request.

We'll merge it as soon as we can.

Thanks!

## Developing

### 1.0

Install `couscous` through Composer and run `couscous preview`

### 2.0+

The docs are generated with [Kiln](https://github.com/brokenhandsio/kiln), so
you'll need a Swift 6.2+ toolchain. Build the site with:

```sh
swift run VaporDocs
```

This writes the generated site to `site/`. Preview it with any static file
server, e.g.:

```sh
python3 -m http.server --directory site
```

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
