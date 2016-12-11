# Minimum Requirements

* OS X 10.10
* Git
* XCode 6

# Download Sources

	brew install git-lfs
	git clone https://github.com/typcn/bilibili-mac-client.git
	git submodule update --init

# Change code signing

If you don't have code signing , please set signing to "None"

# Change bundle id

Project Navigator -> Bilibili -> Change com.typcn to others

# About the video quality

Debug build is using html5 playurl api, you can only play low quality videos.

If you need play high quality video , just build with Release mode, dynamic video parser will load into memory.

# About libraries

If you can't download libraries from git-lfs, please run following commands.

	cd bilibili/libs/
	rm -rf *.dylib
	wget http://7xkd32.dl1.z0.glb.clouddn.com/bilibili/libs/2.zip
	unzip 2.zip
