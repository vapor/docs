# Xcode


If you're on a Mac, you can develop your Vapor project using Xcode. 
You can build, run, and stop your server from within Xcode, as well as use breakpoints to debug your code.

<img width="1072" alt="screen shot 2017-05-15 at 7 14 48 pm" src="https://cloud.githubusercontent.com/assets/1342803/26072406/4d74dfca-39a3-11e7-98c7-d9a678d3fe17.png">

To use Xcode, you will first need to generate a `*.xcodeproj` file.

## Generate Project

### Vapor Toolbox

To generate a new Xcode project for a project, use:

```sh
vapor xcode
```

!!! tip
    If you'd like to automatically open the Xcode project, use `vapor xcode -y`

### Select 'Run'

Make sure after generating your Xcode project that you properly select the executable if you're trying to run your application.

<img src="https://cloud.githubusercontent.com/assets/6710841/26517851/72841fd6-426f-11e7-9e6c-945d22933094.png" alt="select 'run' from dropdown" width="300">

### Manual

To generate a new Xcode project manually.

```sh
swift package generate-xcodeproj
```

Open the project and continue normally.
