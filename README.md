# Documentation

Read the docs at [docs.vapor.codes](https://docs.vapor.codes)

## Contributing
### *Mistakes*
---
If you have found any mistakes in the documentation, feel free to create a PR to fix it.

### *Translating*
---
> For now this only applies to the Vapor 4 Documentation.

If you wish to contribute to the Vapor documentation by translating, follow these steps below.

To start of, install [Python3](https://www.python.org/download/releases/3.0/). Once you have done that, run `pip install -r requirements.txt` in the root directory of this repository. This will install all the needed dependencies in order to be able to build the documentation.  

Following the installation of the dependencies, check if your language you want to translate to is already included in the `mkdocs.yml` file. If it is not, then you can add it like this:
```yaml
languages:
  # Structure
  <language iso code>:
    name: <The name of the language>
    site_name: <The translated site name>
    build: true # Whether the documentation gets build or not. Turn this to false for all languages you're not translating if building takes too long

  # Example
  nl:
    name: Nederlands
    site_name: Vapor Documentatie
    build: false
```
> NOTE: The language iso code you have to insert has to conform to the ISO 639-1 Standard. More information can be found [here](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).

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


  
