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

You'll need Python3 to build the docs. You can download this from the [Python Website](https://www.python.org/download/releases/3.0/) or install via Homebrew. Once installed, run `pip install -r requirements.txt` in the root directory of this repository. This will install all the needed dependencies in order to be able to build the documentation.  

Following the installation of the dependencies, check if your language you want to translate to is already included in the `mkdocs.yml` file. If it is not, then you can add it like this:
```yaml
languages:
  # Structure
  <language iso code>:
    name: <The name of the language>
    site_name: <The translated site name>
    build: true # Whether the documentation gets build or not. You can disable this if you don't want to build your language or want to temporarily disable other languages

  # Example
  nl:
    name: Nederlands
    site_name: Vapor Documentatie
    build: true
```
> NOTE: The language code you have to add must conform to the ISO 639-1 Standard. More information can be found [here](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).

If there are navigation components that have to be translated, then you can add them under `nav_translations` in the mkdocs file. This is done by specifying a keyword defined in the `nav:` section of the `mkdocs.yml` file and then adding the translation. An example can be found below of how to add those:
```yaml
nav_translations:
  # Structure
  <language code>:
    <keyword>: <translation>

  # Example
  nl:
    Welcome: Welkom
    Install: Installeren
```

Copy the markdown file you would like to translate and name it `<original name file>.<language code>.md`. 
For example:
```
- index.md <- the original english documentation
- index.nl.md <- the dutch translation of the english documentation file
```

You can check it out by running `mkdocs serve` in the terminal. Once you are satisfied with your translations, feel free to create a PR. Don't forget to turn the `build` flag to true for all languages!

> NOTE: If a file isn't translated, it will just default to the default language file. So you don't have to translate everything all at once.

Finally, you should add the new language to the [issue template](https://github.com/vapor/docs/blob/main/.github/workflows/translation-issue-template.md) to ensure that any future changes are applied to the new translation.


  
