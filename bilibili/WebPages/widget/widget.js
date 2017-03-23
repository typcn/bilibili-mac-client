// SEE https://static-ssl.tycdn.net/updates/bilimac.js for latest version

if(!localStorage.bilimac_player_type){
  function hidefaq(){
    localStorage['hide_faq'] = 'true';window.location.reload();
  }
  function showfaq(){
    delete localStorage['hide_faq'];window.location.reload();
  }
}

function runCloudCode(){
  console.log('BiliMac Cloud Code Init');
  window.rec_rp = function(){};

  /* Disable bilibili built-in html5 player */
  try{
    localStorage.bilibililover = 'no';
    localStorage.defaulth5 = 0;
    navigator.plugins['Shockwave Flash'] = {description:'666'}
    $('.bgray-btn-wrap').remove();
  }catch(e){

  }

  (function(){
    var c = document.createElement('link');
    c.setAttribute('rel', 'stylesheet');
    c.setAttribute('type', 'text/css');
    c.setAttribute('href', 'http://cdn2.eqoe.cn/files/bilibili/all.css');
    document.querySelector('head').appendChild(c);

    var hooked_ce = document.createElement.bind(document);
    document.createElement = function(a,b){
      if(a == 'video'){
        a = 'div';
        console.log('blocked html5 video creation');
      }
      return hooked_ce(a,b);
    }

    var origOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(a,b,c) {
        if(b.indexOf('data.bilibili.com') > -1
          || b.indexOf('interface.bilibili.com/player') > -1
          || b.indexOf('interface.bilibili.com/playurl') > -1
          || b.indexOf('bangumi.bilibili.com/web_api/user_area') > -1
          || b.indexOf('bangumi.bilibili.com/web_api/season_area') > -1){
          console.log('Request blocked: ' + b);
          if(document.querySelector('.btn-dy-wrapper')){
            window.LoadTimes = 999;
          }
          return;
        }
        this.addEventListener('load', function() {
          if(b == 'http://bangumi.bilibili.com/web_api/get_source'){
            if(this.responseText == '{"code":-40301,"message":"根据版权方要求，您所在的地区无法观看本番，敬请谅解"}'){
              document.querySelector('.limit_area_info').innerHTML = '正在解决版权限制';
              fixBangumiCopyright();
            }
          }else if(b.indexOf('/web_api/episode/') > -1){
            window.capt_cid = JSON.parse(this.responseText).result.currentEpisode.danmaku;
            window.capt_pid = JSON.parse(this.responseText).result.currentEpisode.page;
            console.log('Extra cid saved');
          }
        });
        origOpen.apply(this, arguments);
    };
  })();

  if(location.host == 'live.bilibili.com'){
    // Fix avalon ib
    var hooked_ib = document.head.insertBefore;
    document.head.insertBefore = function(a){
      if(a.src && checkBlock(a.src)){
         return console.log('Blocked script insert: ' + a.src);
      }
      var rv = hooked_ib.apply(this, arguments);
      if(rv){
        return rv;
      }
      rv = document.getElementsByTagName(a.tagName);
      if(rv && rv.length){
        return rv[0];
      }
      console.log('WARNING: failed to fix wrong insertBefore hook');
    }
  }

  function fixBangumiCopyright(){
    if(!window.episode_id){
      return;
    }else if(window.capt_cid){
      window.cid = capt_cid;
      return;
    }
    var request = new XMLHttpRequest();
    request.open('GET', 'http://bangumi.bilibili.com/web_api/episode/' + episode_id + '.json', true);
    request.onload = function() {
       var data = JSON.parse(request.responseText);
       window.cid = data.result.currentEpisode.danmaku;
       window.capt_cid = data.result.currentEpisode.danmaku;
       window.capt_pid = data.result.currentEpisode.page;
    };
    request.send();
  }

  (function(){
    var firstLoad = 0;
    var ftimes = 0;
    var hcount = 0;
    var fixISPHijack = setInterval(function() {
      try{
        window.GrayManager = { init:function(){} };
        Object.defineProperty(window.GrayManager, 'init', { writable: false} );
        Object.defineProperty(window, 'GrayManager', { writable: false} );
        localStorage.bilibililover = 'no';
        localStorage.defaulth5 = 0;
      }catch(e){

      }
      ftimes++;
      if(ftimes > 15){
        $('#hijack_tips').remove();
        return clearInterval(fixISPHijack);
      }
      //console.log('Finding ISP Hijack');
      var ifrms = $('iframe');
      for(var i = 0; i < ifrms.length; i++){
        if(ifrms[i].src.indexOf('bilibili.com') == -1){
          $(ifrms[i]).remove();
          console.log('Removed an iframe');
          hcount++;
        }
      }
      var videos = $('video');
      for(var i = 0; i < videos.length; i++){
        var tag = videos[i];
        tag.pause();
        tag.src = "";
        $(videos[i]).remove();
        console.log('Removed an video tag');
      }
      var popdivs = $('body > div:not([class])');
      for(var i = 0; i < popdivs.length; i++){
        if(popdivs[i].style.position == 'fixed' && popdivs[i].style.zIndex > 10000){
          $(popdivs[i]).remove();
        }
      }
      showHijackCount(hcount);
      if(!firstLoad){
        firstLoad = 1;
        jqueryLoaded();
      }
      try{
        fixBangumiCopyright();
        fixBangumi();
      }catch(e){

      }
    },500);

    function jqueryLoaded() {
      console.log('Loading details');
      loadOnlineCount();
      loadVersion();
    }

    function showHijackCount(c) {
      if(c == 0){
        return;
      }
      if($('#hijack_tips').length){
        $('#hijack_tips').html('拦截了 ' + c + ' 处 iFrame');
      }else{
        $("body").append('<div id="hijack_tips" style="font-size:100%;left:1em;bottom:1em;position:fixed;">拦截了 ' + c + ' 处 iFrame</div>');
      }
    }

    function loadOnlineCount() {
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
    }

    function doSpecialFix() {
      // 拜年祭 2016
      if(window.location.href == 'http://www.bilibili.com/html/bnj2016.html'){
        $('.bnj-video-part-list').click(function(e){  window.TYPCN_PLAYER_CID = e.target.getAttribute('cid') + '|' + window.location.href + '|' + document.title });
      }
      // 拜年祭 2017
      if(window.location.href == 'http://www.bilibili.com/blackboard/bnj2017.html'){
        $('.video-box').html('<div id="bofqi_embed" style="color:#fff">BILIMAC2017BNJINJECT_0.1<br><a href="#" data-cid="13562609">播放第一集</a><br><a href="#" data-cid="13562610">播放第二集</a><br><a href="#" data-cid="13562611">播放第三集结局1</a> <a href="#" data-cid="13562612">结局2</a> <a href="#" data-cid="13562613">结局3</a> <a href="#" data-cid="13562614">结局4</a><br><a href="#" data-cid="13562615">播放第四集</a></div>');
        var aid = 7248433;
        $('#bofqi_embed a').click(function(e){
          var cid = e.target.dataset.cid;
          window.sendToView({action:'playVideoByCID',data:cid + '|http://www.bilibili.com/video/av' + aid + '|' + document.title});
        });
      }
      // 老版本更新按钮
      if(!$('.z_top_nav ul .update')[0]){
          $('.z_top_nav ul').append('<li class="update"><a class="i-link" href="javascript:window.sendToView({action: \'checkforUpdate\',data:\'none\'});">检查更新</a></li>');
          if(!$('.i_face').attr('src')){
              $('.login').css('width',200).children('span').html('点击登录客户端以便发送弹幕');
          }
      }

      // 隐藏 FAQ 按钮
      if(!localStorage['hide_faq']){
        $('.z_top_nav ul').append('<li class="faq"><a class="i-link" href="javascript:hidefaq()">隐藏悬浮</a></li>');
      }else{
        $('.z_top_nav ul').append('<li class="faq"><a class="i-link" href="javascript:showfaq()">显示悬浮</a></li>');
      }
    }

    function fixBangumi() {
      // 已经被替换，重新请求页面
      if(location.href.indexOf('bangumi.bilibili.com/anime') > -1){
        if(document.querySelector('.video-list-status-text').textContent == '根据版权方要求，您所在的地区无法观看本番，敬请谅解'){
          window.location.reload(true);
        }
      }
    }

    var latest = false;

    function loadVersion() {
        var request = new XMLHttpRequest();
        request.open('GET', 'http://localhost:23330/ver', true);

        request.onload = function() {
            var data = JSON.parse(request.responseText);
            if(data.version == 2.49 || data.version == 2.51){
                latest = true;
                if(!localStorage['hide_faq']){
                  $("body").append('<div id="bm_tip">遇到问题？点击这里(0824更新)</div>');
                }
                try{
                  fixMovie();
                  fixOldVideo();
                }catch(e){

                }
            }else if(!window.bilimacVersion || window.bilimacVersion < 246){
                $("body").append('<div id="bm_tip" style="font-size:150%;">由于B站服务器更新，该版本已失效，点击这里更新</div>');
            }else{
                $("body").append('<div id="bm_tip" style="font-size:130%;">您的软件有新版本，点击这里更新</div>');
            }

            if(parseFloat(data.version) < 2.49){
              if(document.querySelector('#bofqi') && window.cid && !window.TYPCN_PLAYER_CID){
                window.TYPCN_PLAYER_CID = window.cid;
                window.sendToView({action:'preloadComment',data:TYPCN_PLAYER_CID});
                window.TYPCN_PLAYER_CID = window.TYPCN_PLAYER_CID + '|' + window.location.href + '|' + document.title;
                console.log('cloud inject player page');
                $('#bofqi').html(window.injectHTML);
                $('.player-box').html(window.injectHTML);
                var ci = document.querySelector(".cover_image");
                var imgUrl;
                if(ci && ci.src){
                    imgUrl = ci.src;
                }else if(window.wb_img){
                    imgUrl = window.wb_img;
                }
                if(imgUrl){
                    var ph = document.querySelector(".TYPCN_PLAYER_INJECT_PAGE .player-placeholder");
                    if(ph){
                        ph.style.backgroundImage = "url(http://localhost:23330/blur/" + imgUrl + ")"
                        ph.style.backgroundAttachment = "initial";
                    }
                }
              }
            }
            doSpecialFix();
            bindAction();
        };
        request.onerror = function() {
            if(!window.bilimacVersion || window.bilimacVersion < 245){
                $("body").append('<div id="bm_tip" style="font-size:130%;">由于B站防盗链更新，该版本已失效，点击这里更新</div>');
            }else if(window.bilimacVersion < 249){
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
    }

    function fixOldVideo() {
      //console.log('Running old video hotfix');
      if(window.TYPCN_PLAYER_CID){
        return;
      }
      var fv=$('#bofqiiframe').attr('src');
      if(!fv){
          fv=$('.player').attr('src');
      }
      if(!fv){
          fv=$('.player-wrapper embed').attr('flashvars');
      }
      if(!fv){
        return;
      }
      var re = /cid=(\d+)&/;
      var m = re.exec(fv);
      window.TYPCN_PLAYER_CID = m[1];
      window.sendToView({action:'preloadComment',data:TYPCN_PLAYER_CID});
      window.TYPCN_PLAYER_CID = window.TYPCN_PLAYER_CID + '|' + window.location.href + '|' + document.title;
      console.log('cloud inject player page');
      doInject();
    }

    function fixMovie() {
      var isMoviePage = (window.location.href.indexOf('bangumi.bilibili.com/movie/') > 1);
      if(isMoviePage){
        var fv=$("param[name='flashvars']").val();
        var re = /cid=(\d+)&/;
        var m = re.exec(fv);
        window.TYPCN_PLAYER_CID = m[1];
        window.TYPCN_PLAYER_CID = window.TYPCN_PLAYER_CID + '|' + window.location.href + '|' + document.title;
        doInject();
        $('.pay_msg').css('font-size','14px').text('提示信息：该视频为付费视频，BiliMac 暂时无法支持解析（待更新），建议您前往浏览器播放');
      }
    }

    function doInject() {
      $('#bofqi').html(window.injectHTML);
      $('.player-box').html(window.injectHTML);
      var ci = document.querySelector(".cover_image");
      var imgUrl;
      if(ci && ci.src){
          imgUrl = ci.src;
      }else if(window.wb_img){
          imgUrl = window.wb_img;
      }
      if(imgUrl){
          var ph = document.querySelector(".TYPCN_PLAYER_INJECT_PAGE .player-placeholder");
          if(ph){
              ph.style.backgroundImage = "url(http://localhost:23330/blur/" + imgUrl + ")"
              ph.style.backgroundAttachment = "initial";
          }
      }
    }

    function bindAction(){
      if(latest){
          $("#bm_tip").on("click", function(i) {
              window.location.href = "http://vp-hub.eqoe.cn/faq.html?v=" + Math.random();
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
  })();
}