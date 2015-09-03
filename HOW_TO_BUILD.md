# Minimum Requirements

* OS X 10.10
* Git
* XCode 6

# Download Sources

	git clone https://github.com/typcn/bilibili-mac-client.git
	git submodule update --init

# Add key file

Create a file at bilibili/APIKey.h

	NSString *APIKey = @"Your Bilibili API KEY";
	NSString *APISecret = @"Your Bilibili API Secret";
( If you don't have it, please [contact me](mailto:typcncom@gmail.com) )

Then open bilibili.xcodeproj to edit or build.

( If you don't have code signing , please set signing to "None" )

# About libraries

If you can't download libraries from git-lfs, please run following commands.

	cd bilibili/libs/
	rm -rf *
	wget http://7xkd32.dl1.z0.glb.clouddn.com/bilibili/libs/0.zip
	unzip 0.zip
