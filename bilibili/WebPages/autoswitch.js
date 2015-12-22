function attachAutoSwitch(){
    if($('#v_bgm_list_data .active').length > 0){
        _attachBGM()
    }else if($('.v-plist .curPage').length > 0){
        _attachPRG();
    }
    
}

function _attachBGM(){
    var active = parseInt($('#v_bgm_list_data .active').attr('idx'));
    if(active > -1){
        var target = active  + 1;
        var url = $('#v_bgm_list_data a[idx=' + target + ']').attr('href');
        if(url && url.length > 0){
            url += '?autoplay=1';
            window.sendToView({'action':'goURL','data':'http://www.bilibili.com' + url});
        }
    }
}

function _attachPRG(){
    var nextUrl = $('.v-plist .curPage').next().attr('href');
    if(nextUrl && nextUrl.length > 1){
        window.sendToView({'action':'goURL','data':'http://www.bilibili.com' + nextUrl + '?autoplay=1'});
    }
}


attachAutoSwitch()