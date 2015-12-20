window.bilimacVersion = 224;
window.injectHTML = 'INJ_HTML';
window.sendToView = function(data){
    $.post("http://localhost:23330/rpc",data);
}
function applyUI(){
    try{
        $('.close-btn-wrp').parent().remove();$('.float-pmt').remove();
        if(!$('.z_top_nav ul .update')[0]){
            $('.z_top_nav ul').append('<li class="update"><a class="i-link" href="javascript:window.sendToView({action: \'checkforUpdate\',data:\'none\'});">检查更新</a></li>');
        }
        if(!$('.i_face').attr('src')){
            $('.login').css('width',200).children('span').html('点击登录客户端以便发送弹幕');
        }else{
            window.sendToView({"action":"setcookie","data":document.cookie});
        }
        if(window.LoadTimes){
            window.LoadTimes++;
        }else{
            window.LoadTimes = 1;
        }
    }catch(e){
        
    }
    if(window.location.href.indexOf("av") > 1 || window.location.href.indexOf("topic") > 1 || window.location.href.indexOf("live") > 1 || window.location.href.indexOf("html") > 1){
        console.log("getting cid");
        try{
            var fv=$("param[name='flashvars']").val();
            if(!fv){
                fv=$('#bofqiiframe').attr('src');
            }
            if(!fv){
                fv=$('.player').attr('src');
            }
            if(!fv){
                fv=$('.player-wrapper embed').attr('flashvars');
            }
            if(!fv){
                fv = 'cid=' + $("#modVideoCid").text() + '&';
            }
            if(window.ROOMID){
                fv = 'cid=' + window.ROOMID + '&';
            }
        }catch(e){
            console.log(e);
        }
        console.log("fv:" + fv);
        var re = /cid=(\d+)&/;
        var m = re.exec(fv);
        window.TYPCN_PLAYER_CID = m[1];
        console.log("cid got");
        
        if(window.TYPCN_PLAYER_CID){
            if(window.location.origin == 'http://live.bilibili.com'){
                console.log("inject live page");
                if(window.ROOMID > 0){
                    if(typeof LIVEPLAY == "undefined"){
                        $("#object").remove();
                        window.sendToView({action: "playVideoByCID",data: ROOMID.toString() + '|' + window.location.href + '|' + document.title});
                        LIVEPLAY = 1;
                    }
                }
            }else if(window.location.href.indexOf("topic") > 1){
                console.log("inject topic page");
                $('embed').parent().html(window.injectHTML);
            }else{
                window.sendToView({action:'preloadComment',data:TYPCN_PLAYER_CID});
                window.TYPCN_PLAYER_CID = window.TYPCN_PLAYER_CID + '|' + window.location.href + '|' + document.title;
                console.log("inject player page");
                $('#bofqi').html(window.injectHTML);
                $('.player-box').html(window.injectHTML);
                var ci = document.querySelector(".cover_image");
                if(ci && ci.src){
                    var ph = document.querySelector(".TYPCN_PLAYER_INJECT_PAGE .player-placeholder");
                    if(ph){
                        ph.style.backgroundImage = "url(http://localhost:23330/blur/" + ci.src + ")"
                        ph.style.backgroundAttachment = "initial";
                    }
                }
                if(window.location.href.indexOf('autoplay') > -1){
                    setTimeout(function(){
                       window.sendToView({action:'playVideoByCID',data:TYPCN_PLAYER_CID})
                    },200);
                }
            }
            clearInterval(window.i);
        }else{
            
        }
        console.log("inject success");
        
    }else if(window.location.href.indexOf('mimi.gg') > -1){
        var mimierr = document.querySelector('.error-content-inner');
        if(mimierr.innerHTML == '该页面无法在您所在的区域访问。' || mimierr.innerHTML == '正在等待页面加载'){
            mimierr.innerHTML = '正在尝试替换播放器';
            var request = new XMLHttpRequest();
            request.open('GET', 'https://mimi.tgod.co' + window.location.pathname, true);
            
            request.onload = function() {
                if (request.status >= 200 && request.status < 400) {
                    if(window.location.pathname == '/'){
                        $('html').html(request.responseText);
                    }else{
                        document.getElementsByTagName('html')[0].innerHTML = request.responseText;
                        replaceMimi();
                    }
                } else {
                    document.querySelector('.error-content-inner').innerHTML = '替换服务器错误';
                }
            };
            
            request.onerror = function() {
               document.querySelector('.error-content-inner').innerHTML = '无法替换播放器';
            };
            
            request.send();
            clearInterval(window.i);
        }else{
            replaceMimi();
        }
    }
}

function replaceMimi(){
    var scr = $('#bofqi script').html();
    var re = /cid=(\d+)&/;
    var m = re.exec(scr);
    window.TYPCN_PLAYER_CID = m[1];
    console.log("cid got");

    if(window.TYPCN_PLAYER_CID){
        var loc = window.location.href.replace('mm','av').replace('https://mimi.tgod.co/v/','http://www.bilibili.com/video/');
        window.TYPCN_PLAYER_CID = window.TYPCN_PLAYER_CID + '|' + loc + '|' + document.title + '|2';
        console.log("inject player page");
        $('#bofqi').html(window.injectHTML);
        var ph = document.querySelector(".TYPCN_PLAYER_INJECT_PAGE .player-placeholder");
        if(ph){
            var re = /http:\/\/.*?\.jpg/;
            var m = re.exec($('.page-wrp script')[1].innerHTML);
            ph.style.backgroundImage = "url(http://localhost:23330/blur/" + m[0] + ")"
            ph.style.backgroundAttachment = "initial";
            ph.style.height = "530px";
        }
        clearInterval(window.i);
    }
}

if(!window.isFirstPlay){
    window.isFirstPlay = true;
    window.i = setInterval(waitForReady,500);
    console.log("start inject");
    function waitForReady(){
        if(window.LoadTimes > 8){
            clearInterval(window.i);
            return;
        }
        if(!window.isInjected){
            window.isInjected = true;
            $.getScript("http://cdn.eqoe.cn/files/bilibili/widget-min.js?ver=" + window.bilimacVersion);
        }
        if((typeof $) == 'function'){
            applyUI();
        }
    }
    var mimierr = document.querySelector('.error-content-inner');
    if(mimierr && mimierr.innerHTML == '该页面无法在您所在的区域访问。'){
        mimierr.innerHTML = '正在等待页面加载';
    }
}