# Bilibili Mac Client

An unofficial bilibili client for mac

[![Build Status](https://app.ship.io/jobs/LajSkdYLuE7THK7n/build_status.png)](http://jenkins.eqoe.cn/job/Bilibili-for-mac/)

# Why

众所周知的原因，Flash 不支持硬解，Macbook 热的烤鸡蛋！

# Features
- 硬解播放
- libass 显示弹幕，超低 CPU 占用
- 自动拼接分段视频
- 视频缓冲过慢自动切换备用源
- 支持发送弹幕
- 弹幕透明度调整
- 本地视频弹幕播放
- 视频清晰度切换
- 网页书签调用播放器
- 弹幕关键词屏蔽

# Screenshot

![](http://ww2.sinaimg.cn/large/a74f330bjw1eqq21b23c7j21740npqbp.jpg)

# Download

[GitHub](https://github.com/typcn/bilibili-mac-client/releases)

[百度盘](http://pan.baidu.com/s/1eQvSx6i)

<del>[Mega](https://mega.co.nz/#F!48gXiAxa!BFrmfzq9c97cfSbR4A1v8g)</del>

# FAQ

Q: 提示应用程序已损坏

A: 请到设置 - 安全与隐私 - 通用 - 点击左下角的锁 - 允许任何应用

Q: 是否支持弹幕发送

A: 在视频播放界面按回车出现发送框，再次按回车隐藏

Q: 如何通过浏览器书签在客户端播放视频？

A: 随便收藏一个页面，然后点击“编辑”，名称随意 ， URL 输入 ````javascript:window.location='bl://'+window.location.hostname+window.location.pathname ```` 保存之后，在任何一个视频页面点击该书签，客户端将自动打开并播放

Q: 程序为何会连接 app.eqoe.cn

A: 如果你选择了自动更新，系统会定时检查更新，建议您开启该选项。

Q: 如何关闭弹幕

A: 点击播放器右下角的字幕按钮关闭，再次点击开启

# Known problems

- <del>在视频开始播放之前，关闭窗口会导致程序在一段时间后崩溃</del> 已修复
- 首次播放可能创建字体缓存，大约需要两分钟，多等一会即可开始播放

# 2.0 新特性进度

- [ ] 直播弹幕显示
- [ ] 弹幕高级屏蔽
- [ ] 自动换 P

# Thanks

- Bilidan
- mpv
- ISSoundAdditions
- Sparkle
- Danmaku2ass
- FFmpeg

# License

GPLv2

