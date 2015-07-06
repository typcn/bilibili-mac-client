$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href','http://cdn2.eqoe.cn/files/bilibili/all.css') );
//$("body").append('<div id="bm_menu" class="round-button"><div class="round-button-circle"><a href="javascript:;" class="round-button">Menu</a></div></div>');
$("body").append('<div id="bm_tip">遇到问题？点击这里</div>');
$.getJSON("https://storage.typcn.com/_api/bilibili",function(d) {
	$(".index_online").append('<br><span class="web-online">Mac 客户端在线:' + d.online + '</span><a title="如果禁止了统计则不算在内">30天用户量:'+ d.monthUser +'</a><br>如果您觉得本软件好用，不妨分享给朋友');
});
$("#bm_tip").on("click",function(e) {
	window.location.href = "http://cdn2.eqoe.cn/files/bilibili/faq.html?v=2";
});