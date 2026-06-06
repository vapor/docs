# Xcode

If you're on a Mac, you can develop your Vapor project using Xcode. 
You can build, run, and stop your server from within Xcode, as well as use breakpoints and instruments to debug your code.

<img width="1072" alt="Xcode 9 running Vapor" src="https://user-images.githubusercontent.com/1342803/32910761-1f8dd56e-cad8-11e7-9869-feccf89f775e.png">

Xcode is a great way to develop Vapor apps, but you can use any text editor you like.

## Generate Project

To use Xcode, you just need to generate an Xcode project using [Vapor Toolbox](toolbox.md).

```sh
vapor xcode
```

!!! tip
	Don't worry about comitting the generated Xcode Project to git, just generate a new
	one whenever you need it.

## Run

To build and run your Vapor app, first make sure you have the `Run` scheme selected from the schemes menu.
Also make sure to select "My Mac" as the device.

<img width="434" alt="Run Scheme" src="https://user-images.githubusercontent.com/1342803/32917883-944f3f30-caee-11e7-980f-860ee70bd873.png">

Once that's selected, just click the play button or press `Command + R` on your keyboard.

## Test

To run your unit tests, select the scheme ending in `-Package` and press `Command + U`.

!!! warning
	There may be a few extraneous schemes in the dropdown menu. Ignore them!
