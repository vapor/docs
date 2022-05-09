# Xcode

This page goes over some tips and tricks for using Xcode. If you use a different development environment, you can skip this.

## Custom Working Directory

By default Xcode will run your project from the _DerivedData_ folder. This folder is not the same as your project's root folder (where your _Package.swift_ file is). This means that Vapor will not be able to find files and folders like _.env_ or _Public_.

You can tell this is happening if you see the following warning when running your app. 

```fish
[ WARNING ] No custom working directory set for this scheme, using /path/to/DerivedData/project-abcdef/Build/
```

To fix this, set a custom working directory in the Xcode scheme for your project. 

First, edit your project's scheme by clicking on the scheme selector by the play and stop buttons. 

![Xcode Scheme Area](images/xcode-scheme-area.png)

Select _Edit Scheme..._ from the dropdown.

![Xcode Scheme Menu](images/xcode-scheme-menu.png)

In the scheme editor, choose the _Run_ action and the _Options_ tab. Check _Use custom working directory_ and enter the path to your project's root folder.

![Xcode Scheme Options](images/xcode-scheme-options.png)

You can get the full path to your project's root by running `pwd` from a terminal window open there.

```fish
# verify we are in vapor project folder
vapor --version
# get path to this folder
pwd
```

You should see output similar to the following.

```
framework: 4.x.x
toolbox: 18.x.x
/path/to/project
```
