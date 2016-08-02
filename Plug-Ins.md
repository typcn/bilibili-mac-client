# Plugin System

(Early test , API may change)


## Get Start for new plugin api

1. Checkout this plugin: https://github.com/typcn/vp.tucao
2. Open project
3. Edit / Run

## Info.plist

- Inject Javascript on domain

Must be top level domain (example: youku.com)

- Inject Javascript file prefix

If set to "FILE" , will load Plugin.bundle/Contents/Resources/FILE.js

- Principal class

Main class of plugin , must inherit "VP_Plugin"

## Classes

```
- (id)getClassOfType:(NSString *)type{
	if([type isEqualToString:@"SubProvider"]){
		return [[YourSubtitleProvider alloc] init];
	}else{
		return NULL;		
   }
}
```

## SubtitleProvider 

See [SP_Local](https://github.com/typcn/bilibili-mac-client/blob/master/bilibili/SubHelper/SP_Local.m) or [SP_Bilibili](https://github.com/typcn/bilibili-mac-client/blob/master/bilibili/SubHelper/SP_Bilibili.m)

commentFile is XML in bilibili format

subtitleFile is in ASS subtitle format

## Example Code

https://github.com/typcn/vp.tucao

https://github.com/typcn/vp.letv

https://github.com/typcn/vp.youku

## Code Signing

Plugin need valid codesign from Apple or me (plugin/TYPCN\_Root\_G3.crt) , you can submit plugin to Plugin Store( coming soon ) , the server will sign it automaticly.