# Plugin System

(Early test , API may change)


## Get Start

1. download the repo ( see [HOW\_TO\_BUILD](https://github.com/typcn/bilibili-mac-client/blob/master/HOW_TO_BUILD.md) )
2. Open VideoPolymer.xcworkspace and locate to PluginExample.xcodeproj
3. Edit / Run

## Info.plist

- Inject Javascript on domain

Must be top level domain (example: youku.com)

- Inject Javascript file prefix

If set to "FILE" , will load Plugin.bundle/Contents/Resources/FILE.js

- Principal class

Main class of plugin , must inherit "VP_Plugin"

## Code

See ExamplePlugin in workspace

## Code Signing

Plugin need valid codesign from Apple or me (plugin/TYPCN\_Root\_G3.crt) , you can submit plugin to Plugin Store( coming soon ) , the server will sign it automaticly.