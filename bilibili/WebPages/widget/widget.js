$("head").append($('<link rel="stylesheet" type="text/css" />').attr("href", "http://cdn2.eqoe.cn/files/bilibili/all.css"));

var latest = false;

var request = new XMLHttpRequest();
request.open('GET', 'http://localhost:23330/ver', true);

request.onload = function() {
    var data = JSON.parse(request.responseText);
    if(data.version == 2.20){
        latest = true;
        if(!localStorage['hide_faq']){
          $("body").append('<div id="bm_tip">遇到问题？点击这里(1021)</div>');
        }
    }else if(!window.bilimacVersion || window.bilimacVersion < 213){
        $("body").append('<div id="bm_tip" style="font-size:130%;">由于B站防盗链更新，该版本已失效，点击这里更新</div>');
    }else{
        $("body").append('<div id="bm_tip" style="font-size:130%;">您的软件有新版本，点击这里更新</div>');
    }
    fixUpdate();
    bindAction();
};

request.onerror = function() {
    if(!window.bilimacVersion || window.bilimacVersion < 213){
        $("body").append('<div id="bm_tip" style="font-size:130%;">由于B站防盗链更新，该版本已失效，点击这里更新</div>');
    }else if(window.bilimacVersion < 220){
        $("body").append('<div id="bm_tip" style="font-size:130%;">您的软件有新版本，点击这里更新</div>');
    }else{
        if(!localStorage['hide_faq']){
          $("body").append('<div id="bm_tip">遇到问题？点击这里(1021)</div>');
        }
        latest = true;
    }
    bindAction();
};

request.send();

function bindAction(){
  if(latest){
      $("#bm_tip").on("click", function(i) {
          window.location.href = "http://vp-hub.eqoe.cn/faq.html";
      });
  }else{
      $("#bm_tip").on("click", function(i) {
          var data = {action: "checkforUpdate",data:"none"};
          try{
              window.webkit.messageHandlers.BLClient.postMessage(data);
          }catch(e){
            try{
                window.external.checkforUpdates();
            }catch(e){
                $.post("http://localhost:23330/rpc",data);
            }
          }
      });
  }
}

if(!localStorage.bilimac_player_type){
  function hidefaq(){
    localStorage['hide_faq'] = 'true';window.location.reload();
  }
  function showfaq(){
    delete localStorage['hide_faq'];window.location.reload();
  }

  if(!localStorage['hide_faq']){
    $('.z_top_nav ul').append('<li class="faq"><a class="i-link" href="javascript:hidefaq()">隐藏悬浮</a></li>');
  }else{
    $('.z_top_nav ul').append('<li class="faq"><a class="i-link" href="javascript:showfaq()">显示悬浮</a></li>');
  }
}

function fixUpdate(){
  if(!$('.z_top_nav ul .update')[0]){
      $('.z_top_nav ul').append('<li class="update"><a class="i-link" href="javascript:window.sendToView({action: \'checkforUpdate\',data:\'none\'});">检查更新</a></li>');
      if(!$('.i_face').attr('src')){
          $('.login').css('width',200).children('span').html('点击登录客户端以便发送弹幕');
      }
  }
}

$(".index-online").height('100');

$.ajax({ 
  url: 'https://storage.typcn.com/_api/bilibili', 
  dataType: 'json', 
  success: function(i){
    if(latest){
      $(".index-online").append('<br><span class="mac-online">Mac 客户端在线:' + i.online + '</span><i class="s-line"></i><span class="month-user">30天用户量:' + i.monthUser 
        + '</span><br><span class="mac-tip">点击最上方的新建标签按钮可以浏览插件中心</span></a>');
    }else{
      $(".index-online").append('<br><span class="web-online">Mac 客户端在线:' + i.online + '</span><i class="s-line"></i><span class="month-user">30天用户量:' + i.monthUser 
        + '</span><br><span class="mac-tip">点击最上方的新建标签按钮可以浏览插件中心</span></a>');
    }
    
  }, 
  timeout: 3000,
  error: function(jqXHR, status, errorThrown){
    $(".index-online").append('<br>读取在线人数信息失败，错误代码: '+status+'<br>');
  } 
}); 