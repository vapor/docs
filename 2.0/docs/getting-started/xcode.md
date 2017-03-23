# Xcode

The first thing you'll probably notice about Vapor and Swift Package Manager projects in general is that they don't include an Xcode project. In fact, when SPM generates packages, the `.xcodeproj` file is `.gitignore`d by default.

This means we don't have to worry about `.pbxproj` conflicts, and it's easy for different platforms to utilize their own editors.

## Generate Project

### Vapor Toolbox

To generate a new Xcode project for a project, use:

```sh
vapor xcode
```

!!! tip
    If you'd like to automatically open the Xcode project, use `vapor xcode -y`

### Manual

To generate a new Xcode project manually.

```sh
swift package generate-xcodeproj
```

Open the project and continue normally.

## Flags

For some packages with underlying C dependencies, users will need to pass linker flags during **build** and **project generation**. Make sure to consult the guides associated with those dependencies. For example, MySQL:

```
swift package generate-xcodeproj -Xswiftc -I/usr/local/include/mysql -Xlinker -L/usr/local/lib
```

!!! tip
    The Vapor Toolbox automatically detects and adds linker flags required for Vapor packages.
