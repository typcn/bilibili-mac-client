# Bilibili Mac Client

![build status](https://git.typcn.com/ci-scripts/bilimac/badges/master/build.svg)

Mac 必备的在线视频播放器

# Features
- 硬解播放
- libass 显示弹幕，超低 CPU 占用
- 通过 [You-Get](https://github.com/soimort/you-get) 支持近百家视频网站的解析与播放
- 自动拼接分段视频
- 支持发送弹幕
- 弹幕透明度，字体大小调整
- 打开本地视频，自动加载同文件夹下的弹幕 + 字幕
- 多 Tab 浏览，一键下载视频
- 弹幕关键词屏蔽，智能屏蔽
- 支持观看直播，带有直播弹幕
- 支持自定义 mpv 配置文件，可自定义快捷键，加载 Lua 脚本
- 多语言/字体完美 ASS 字幕渲染

# Screenshot

![](http://bilimac.eqoe.cn/images/player_new.jpg)

# Download

[TYPCN 下载中心](https://typcn.download/info/574d8ead8136f301fe008e61)

[GitHub](https://github.com/typcn/bilibili-mac-client/releases)

[百度盘](http://pan.baidu.com/s/1pLSrVVP)


# FAQ

see [FAQ](http://cdn2.eqoe.cn/files/bilibili/faq.html?v=3)

# Build

see [HOW TO BUILD](https://github.com/typcn/bilibili-mac-client/blob/master/HOW_TO_BUILD.md)

# Performance

相对于 HTML5 播放器，在观看 1080P 满弹幕视频时的电量消耗

- BIlimac HWDEC ZeroCopy ![](https://cloud.githubusercontent.com/assets/8022103/20131908/5b095e04-a69b-11e6-8246-b8a9c6ffe78d.png)
- Bilimac HWDEC ![](https://cloud.githubusercontent.com/assets/8022103/20131817/ce06f94e-a69a-11e6-8175-5af40732d89e.png)
- Safari HTML5 (162%)![](https://cloud.githubusercontent.com/assets/8022103/20131799/a68ae3a8-a69a-11e6-88af-8477be180a6a.png)
- Chrome HTML5 (246%）![](https://cloud.githubusercontent.com/assets/8022103/20131748/694e513c-a69a-11e6-9f6c-7fec337f0185.png)


# Thanks

- [mpv](https://github.com/mpv-player/mpv)
- [ChromiumTabs](https://github.com/typcn/chromium-tabs)
- [GCDWebServers](https://github.com/swisspol/GCDWebServer)
- [Sparkle](http://sparkle-project.org/)
- [FFmpeg](https://www.ffmpeg.org/)
- [BarrageRenderer](https://github.com/unash/BarrageRenderer)
- [You-Get](https://github.com/soimort/you-get)

### Some files from
- https://github.com/lhecker/NSLabel ( Label Class )
- https://github.com/nickhutchinson/Cocoa-Toolkit ( Some iOS polyfill )
- https://github.com/dbainbridge/mapbox-osx ( Some iOS polyfill )
- https://github.com/niltsh/MPlayerX ( Some icons )
- https://github.com/niltsh/BGHUDAppKit ( Progress bar and volume bar )

# License

GPLv3

