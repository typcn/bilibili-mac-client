#!/bin/sh

#  startaria.sh
#  bilibili
#
#  Created by TYPCN on 2015/9/6.
#  Copyright (c) 2016 TYPCN. All rights reserved.
touch "/Users/Shared/aria2.session"
/Applications/Bilibili.app/Contents/Resources/aria2c -s10 -k1M -x10 --input-file="/Users/Shared/aria2.session" --save-session="/Users/Shared/aria2.session" --save-session-interval=10 --dir="$HOME/Movies/Bilibili/" --enable-rpc=true --rpc-listen-all=false --rpc-listen-port=23336 --rpc-allow-origin-all --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/601.1.43 (KHTML, like Gecko) Version/9.0 Safari/601.1.43" -c -D