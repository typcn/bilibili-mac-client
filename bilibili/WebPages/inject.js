var TYPCN_PLAYER_CID;
function applyUI(){
    try{
        $('.close-btn-wrp').parent().remove();$('.float-pmt').remove();
        $(".i-link[href='http://app.bilibili.com']").html('检查更新').attr('href','javascript:window.external.checkForUpdates()');
        if(window.LoadTimes){
            window.LoadTimes++;
        }else{
            window.LoadTimes = 1;
        }
    }catch(e){
        
    }
    if(window.location.href.indexOf("av") > 1 || window.location.href.indexOf("topic") > 1 || window.location.href.indexOf("live") > 1){
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
            if(!window.ROOMID){
                clearInterval(window.i);
                return;
            }
            fv = 'cid=' + ROOMID;
        }
        var re = /cid=(\d+)&/;
        var m = re.exec(fv);
        TYPCN_PLAYER_CID = m[1];
        
        if(!$('.i_face').attr('src')){
            $('.login').css('width',200).children('a').html('点击登录客户端以便发送弹幕');
        }
        
        if(TYPCN_PLAYER_CID){
            if(window.location.origin == 'http://live.bilibili.com'){
                if(window.ROOMID > 0){
                    if(typeof LIVEPLAY == "undefined"){
                        window.external.playVideoByCID(ROOMID.toString());
                        LIVEPLAY = 1;
                    }
                }
            }else if(window.location.href.indexOf("topic") > 1){
                $('embed').parent().html('<div class="TYPCN_PLAYER_INJECT_PAGE"><div class="player-placeholder"><div class="btn-wrapper n2"><div class="player-placeholder-head">请选择操作</div><div class="src-btn"><a href="javascript:window.external.playVideoByCID(TYPCN_PLAYER_CID)">播放</a></div><div class="src-btn"><a href="javascript:window.external.downloadVideoByCID(TYPCN_PLAYER_CID)">下载</a></div></div></div></div>');
            }else{
                $('#bofqi').html('<div class="TYPCN_PLAYER_INJECT_PAGE"><div class="player-placeholder"><div class="btn-wrapper n2"><div class="player-placeholder-head">请选择操作</div><div class="src-btn"><a href="javascript:window.external.playVideoByCID(TYPCN_PLAYER_CID)">播放</a></div><div class="src-btn"><a href="javascript:window.external.downloadVideoByCID(TYPCN_PLAYER_CID)">下载</a></div></div></div></div>');
            }
            
        }else{
            
        }
        console.log("inject success");
        clearInterval(window.i);
    }
}
if(!window.isFirstPlay){
    window.isFirstPlay = true;
    window.i = setInterval(waitForReady,500);
    console.log("start inject");
    function waitForReady(){
        if(window.LoadTimes > 15){
            clearInterval(window.i);
            return;
        }
        if(!window.isInjected){
            window.isInjected = true;
            $.getScript("http://cdn2.eqoe.cn/files/bilibili/widget-min.js");
        }
        if((typeof $) == 'function'){
            applyUI();
        }
    }
}
