# Minimum Requirements

* OS X 10.10
* Git
* Xcode 6

# Download Sources

	brew install git-lfs
	git lfs install
	git clone https://github.com/typcn/bilibili-mac-client.git
	cd bilibili-mac-client/
	git submodule update --init
	
# Open Project in Xcode

Open `VideoPolymer.xcworkspace` with Xcode.

Note: Do not just open `bilibili.xcodeproj`. It is incomplete.

# Change code signing

If you don't have code signing, please set signing to “None”.

# Change bundle id

Project Navigator -> Bilibili: Change “com.typcn” to others.

# Build

Select “bilibili” as the active scheme at the upper left corner of the Xcode window. Then click “build”. The app will start automatically.

# About the video quality

In Debug build, HTML5 playurl API is used. You can only play low quality videos.

If you need play high quality video, just build with Release mode. Dynamic video parser will be loaded into memory.
