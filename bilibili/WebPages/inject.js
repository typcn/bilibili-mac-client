window.bilimacVersion = 204;
var TYPCN_PLAYER_CID;
window.sendToView = function(data){
    try{
        window.webkit.messageHandlers.BLClient.postMessage(data);
    }catch(e){
        
    }
    try{
        window.external.sendMsg(data);
    }catch(e){
        
    }
}
function applyUI(){
    try{
        $('.close-btn-wrp').parent().remove();$('.float-pmt').remove();
        $(".i-link[href='http://app.bilibili.com']").html('检查更新').attr('href','javascript:window.sendToView({action: "checkforUpdate",data:"none"});');
        $(".b-head-s").html('由于 B 站网页 BUG，标签需要点击两次才能显示内容');
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
        TYPCN_PLAYER_CID = m[1];
        console.log("cid got");
        if(!$('.i_face').attr('src')){
            $('.login').css('width',200).children('a').html('点击登录客户端以便发送弹幕');
        }
        
        if(TYPCN_PLAYER_CID){
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
                $('embed').parent().html('<div class="TYPCN_PLAYER_INJECT_PAGE"><div class="player-placeholder"><div class="btn-wrapper n2"><div class="player-placeholder-head">请选择操作</div><div class="src-btn"><a href="javascript:window.sendToView({action:\'playVideoByCID\',data: TYPCN_PLAYER_CID})">播放</a></div><div class="src-btn"><a href="javascript:window.sendToView({action: \'downloadVideoByCID\',data: TYPCN_PLAYER_CID})">下载</a></div></div></div></div>');
            }else{
                console.log("inject player page");
                $('#bofqi').html('<div class="TYPCN_PLAYER_INJECT_PAGE"><div class="player-placeholder"><div class="btn-wrapper n2"><div class="player-placeholder-head">请选择操作</div><div class="src-btn"><a href="javascript:window.sendToView({action:\'playVideoByCID\',data: TYPCN_PLAYER_CID})">播放</a></div><div class="src-btn"><a href="javascript:window.sendToView({action: \'downloadVideoByCID\',data: TYPCN_PLAYER_CID})">下载</a></div></div></div></div>');
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
        if(window.LoadTimes > 5){
            clearInterval(window.i);
            return;
        }
        if(!window.isInjected){
            window.isInjected = true;
            $.getScript("http://cdn2.eqoe.cn/files/bilibili/widget-min.js?ver=" + window.bilimacVersion);
        }
        if((typeof $) == 'function'){
            applyUI();
        }
    }
}