chrome.runtime.onInstalled.addListener(function(details) {
 if (details.reason == "update") {
    var opt={
      type: "basic",
      title: "Bilibili Mac Client Helper 更新 1.4",
      message: "支持 You-Get 插件，解析播放近百家视频网站\n与 Bilibili 助手兼容，同时安装以支持 html5 与 mac 客户端播放器一键切换\n支持自动静默打开客户端等功能，可到扩展设置中开启",
      iconUrl: "img/icon48.png"
    }
    if(localStorage.lastNotification != 1.4){
      localStorage.lastNotification = 1.4;
      showNotification(opt);
    }
 };
});

function showNotification(opt){
    var notification = chrome.notifications.create(status.toString(),opt,function(notifyId){return notifyId});
    setTimeout(function(){
        chrome.notifications.clear(status.toString(),function(){});
    },6000);
}

function updateScriptList(){
  var request = new XMLHttpRequest();
  request.open('POST', 'http://localhost:23330/interactive', true);
  request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      var data = JSON.parse(request.responseText);
      for(var i = 0;i < data.length;i++){
        var k = 'script_' + data[i].site.replace(/\./g, '_');
        localStorage[k] = data[i].script;
      }
      localStorage.lastUpdate = Date.now();
      delete request;
    }
  };
  request.send('action=scriptList&data=none');
}

setInterval(updateScriptList,60000 * 5);
updateScriptList();

chrome.extension.onMessage.addListener(
    function(request, sender, sendResponse) {
      if(request.blGetScript){
        var host_comp = request.blGetScript.split('.');
        var host_len = host_comp.length;
        var item_key = host_comp[host_len-2] + '_' + host_comp[host_len-1];
        var is_disable = localStorage['disable_' + item_key];
        if(!is_disable){
          var script = localStorage['script_' + item_key];
          if(!script || script.length < 5){
            sendResponse('!');
          }else{
            if(localStorage['no_close_replace'] == 'true'){
                var request = new XMLHttpRequest();
                request.open('GET', 'http://localhost:23330/ver', false);  // `false` makes the request synchronous
                request.send(null);

                if (request.status === 200) {
                  sendResponse({script:script,replaceType:localStorage['replace_in'],hidefaq:localStorage['hide_faq'],autoopen:localStorage['auto_open']});
                }else{
                  sendResponse('!');
                }
            }else{
                sendResponse({script:script,replaceType:localStorage['replace_in'],hidefaq:localStorage['hide_faq'],autoopen:localStorage['auto_open']});
            }
          }
        }else{
          sendResponse('!');
        }
      }
    }
);