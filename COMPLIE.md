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

Then open bilibili.xcodeproj to edit or complie