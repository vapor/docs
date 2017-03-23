---
currentMenu: getting-started-xcode
---

# Xcode

The first thing you'll probably notice about Vapor and SwiftPM projects in general is that we don't include an Xcode project. In fact, when SwiftPM generates packages, the `.xcodeproj` file is gitignored by default.

This means we don't have to worry about pbxproj conflicts, and it's easy for different platforms to utilize their own editors.

## Generate Project

### Vapor Toolbox

To generate a new Xcode project for a project, use:

```bash
vapor xcode
```

> If you'd like to automatically open the Xcode project, use `vapor xcode -y`

### Manual

To generate a new Xcode project manually.

```bash
swift package generate-xcodeproj
```

Open the project and continue normally.

## Flags

For many packages with underlying c-dependencies, users will need to pass linker flags during **build** AND **project generation**. Make sure to consult the guides associated with those dependencies. For example:

```
vapor xcode --mysql
```

or

```
swift package generate-xcodeproj -Xswiftc -I/usr/local/include/mysql -Xlinker -L/usr/local/lib
```
