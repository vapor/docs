# Documentation

Read the docs at [docs.vapor.codes](https://docs.vapor.codes)

# Start with Docker 
* Prerequisite for this setup, you must have docker and docker compose installed on the system 

1. first clone the repo 

2. then run 
```
docker compose up 
```
3. then open from the browser on the port 8000 
e.g.  
```
http://127.0.1.1:8000
```

## Contributing

If you want to add information to the docs or have found any mistakes you wish to fix, feel free to create a PR  for the change.

### *Translating*
---

Localised docs are incredibly useful for allowing people to learn Vapor in their native language. If you wish to contribute to the Vapor documentation by translating, follow the steps below.

The docs are generated with [Kiln](https://github.com/brokenhandsio/kiln), a documentation site generator written in Swift, so you'll need a Swift 6.2+ toolchain (no Python required). Build the site by running `swift run VaporDocs` in the root of the repository; the generated site is written to the `site/` directory.

The translations live in `Sources/VaporDocs/Languages.swift` — the `languages` array (which `Version4.swift` passes to the docs site). Check whether the language you want to translate to is already there. If not, add it:
```swift
Language(
    .dutch,                       // a built-in LanguageCode, or .custom(code: "xx", name: "…")
    siteName: "Vapor Documentatie",
    description: "Vapor documentatie (webframework voor Swift).",
    navTranslations: [
        "Welcome": "Welkom",
        "Install": "Installeren",
    ],
    customStrings: [
        // Docs-specific navbar/footer strings. Copy the keys from the English
        // block above; any you leave out fall back to English.
        "skipToContent": "Naar de inhoud",
        // …
    ],
    image: "assets/og/nl-2x.png", // per-language social card (see below)
    localisation: .init(
        searchPlaceholder: "Zoeken"
        // … other built-in UI strings; any left unset fall back to English
    )
)
```

Navigation titles are translated via `navTranslations`, keyed by the English title used in the `navigation` tree. Kiln's built-in UI strings (search box, "previous"/"next", error page, …) are translated via `localisation`, and the docs-specific chrome (the language/version/theme picker labels, footer links, the skip-to-content link, …) via `customStrings` — copy its keys from the English language block. Anything you leave unset in either falls back to English, so partial translations are fine.

Each language also gets its own social/OpenGraph preview card. Add a `1200×630` PNG (ideally 2×, i.e. `2400×1260`) at `docs/4.0/assets/og/<language code>-2x.png` and point to it with `image: "assets/og/<code>-2x.png"`. Omit it and the language falls back to the site-wide card.

Copy the markdown file you would like to translate and name it `<original file name>.<language code>.md`. For example:
```
- index.md     <- the original English documentation
- index.nl.md  <- the Dutch translation
```

You can preview your changes by running `swift run VaporDocs` and serving the output, e.g. `python3 -m http.server --directory site`. Once you are satisfied with your translations, feel free to create a PR.

> NOTE: If a file isn't translated, it will just default to the default language file. So you don't have to translate everything all at once.

> NOTE: The docs and main site show a small banner offering visitors their preferred language ("This site is available in …"). For a brand-new language to be *proactively suggested* there, its locale and native name also need adding to the `LOCALES` map in the shared design repo, [vapor/design](https://github.com/vapor/design) (`src/js/languageSuggestion.js`). The translation works without this — the banner just won't suggest the new language until it's added.

Finally, you should add the new language to the [issue template](https://github.com/vapor/docs/blob/main/.github/translation_needed.description.leaf) to ensure that any future changes are applied to the new translation.

## Licensing

<p xmlns:cc="http://creativecommons.org/ns#" xmlns:dct="http://purl.org/dc/terms/">
Except where otherwise noted, <a property="dct:title" rel="cc:attributionURL" href="https://github.com/vapor/docs">Vapor Documentation</a> by <a rel="cc:attributionURL dct:creator" property="cc:attributionName" href="https://vapor.codes">Vapor</a> is licensed under <a href="http://creativecommons.org/licenses/by-nc-sa/4.0/" rel="license noopener noreferrer">CC BY-NC-SA 4.0 <img style="height: 16px;" src="https://mirrors.creativecommons.org/presskit/icons/cc.svg"> <img style="height: 16px" src="https://mirrors.creativecommons.org/presskit/icons/by.svg"> <img style="height: 16px" src="https://mirrors.creativecommons.org/presskit/icons/nc.svg"> <img style="height: 16px;" src="https://mirrors.creativecommons.org/presskit/icons/sa.svg"></a>
</p>
 
