chrome.runtime.sendMessage({blGetScript: window.location.host}, function(response) {
	if(response != '!'){
		var request = new XMLHttpRequest();
		request.open('POST', 'http://localhost:23330/rpc', true);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		var urle = 'action=setVUrl&data=' + encodeURIComponent(window.location.href);
		request.onerror = function() {
			if(response.autoopen){
				window.location.assign('bl://open_without_gui');
			}
		};
		request.send(urle);

		if(window.location.host == "www.bilibili.com"){
			localStorage['bilimac_player_type'] = 'force';
			var injectStr = "try{localStorage.bilimac_original_player=document.getElementById('bofqi').innerHTML;}catch(e){delete localStorage.bilimac_original_player;localStorage['bilimac_player_type'] = 'available';}" + response.script;
			if(response.replaceType == 'bilibili_helper'){
				console.log('use bilibili helper mode');
				localStorage['bilimac_player_type'] = 'available';
				injectStr = "try{localStorage.bilimac_original_player=document.getElementById('bofqi').innerHTML;}catch(e){delete localStorage.bilimac_original_player;}";
			}
			if(response.hidefaq){
				localStorage['hide_faq'] = 'true';
				console.log('hide faq passed');
			}else{
				delete localStorage['hide_faq'];
				console.log('remove hide faq');
			}
			var script = document.createElement('script');
			script.textContent = injectStr;
			(document.head||document.documentElement).appendChild(script);
			script.parentNode.removeChild(script);	
		}else{
			var script = document.createElement('script');
			script.textContent = response.script;
			(document.head||document.documentElement).appendChild(script);
			script.parentNode.removeChild(script);
		}

		if(response.script.length > 50){
			// Only apply analytics to bilibili mac supported and user plugin installed domain
			(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
			(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
			m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
			})(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

			ga('create', 'UA-53371941-7', 'auto');
			ga('send', 'pageview');
		}
	}
});