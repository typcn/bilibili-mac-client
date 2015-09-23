window.bilimacVersion = 208;
window.injectHTML = 'INJ_HTML';
window.sendToView = function(data){
    $.post("http://localhost:23330/rpc",data);
}
function applyUI(){
    try{
        $('.close-btn-wrp').parent().remove();$('.float-pmt').remove();
        $(".i-link[href='http://app.bilibili.com']").html('检查更新').attr('href','javascript:window.sendToView({action: "checkforUpdate",data:"none"});');
        $(".b-head-s").html('由于 B 站网页 BUG，标签需要点击两次才能显示内容');
        if(!$('.i_face').attr('src')){
            $('.login').css('width',200).children('a').html('点击登录客户端以便发送弹幕');
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
    if(window.location.href.indexOf("av") > 1 || window.location.href.indexOf("topic") > 1 || window.location.href.indexOf("live") > 1){
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
                        window.sendToView({action: "playVideoByCID",data: ROOMID.toString()});
                        LIVEPLAY = 1;
                    }
                }
            }else if(window.location.href.indexOf("topic") > 1){
                console.log("inject topic page");
                $('embed').parent().html(window.injectHTML);
            }else{
                console.log("inject player page");
                $('#bofqi').html(window.injectHTML);
                var ci = document.querySelector(".cover_image");
                if(ci && ci.src){
                    var ph = document.querySelector(".TYPCN_PLAYER_INJECT_PAGE .player-placeholder");
                    if(ph){
                        ph.style.backgroundImage = "url(http://localhost:23330/blur/" + ci.src + ")"
                        ph.style.backgroundAttachment = "initial";
                    }
                }
            }
            clearInterval(window.i);
        }else{
            
        }
        console.log("inject success");
        
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
}