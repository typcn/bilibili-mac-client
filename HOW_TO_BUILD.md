# Minimum Requirements

* OS X 10.10
* Git
* XCode 6

# Download Sources

	brew install git-lfs
	git clone https://github.com/typcn/bilibili-mac-client.git
	cd bilibili-mac-client/
	git submodule update --init

# Change code signing

If you don't have code signing, please set signing to "None".

# Change bundle id

Project Navigator -> Bilibili: Change "com.typcn" to others.

# About the video quality

Debug build is using html5 playurl API. You can only play low quality videos.

If you need to play high quality video, just build with Release mode. Dynamic video parser will load into memory.
