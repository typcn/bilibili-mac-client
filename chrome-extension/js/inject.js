chrome.runtime.sendMessage({blGetScript: window.location.host}, function(response) {
	if(response != '!'){
		var request = new XMLHttpRequest();
		request.open('POST', 'http://localhost:23330/rpc', true);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		var urle = 'action=setVUrl&data=' + encodeURIComponent(window.location.href);
		request.send(urle);
		if(window.location.host == "www.bilibili.com"){
			localStorage['bilimac_player_type'] = 'force';
			var injectStr = "localStorage.bilimac_original_player=document.getElementById('bofqi').innerHTML;" + response.script;
			if(response.replaceType == 'bilibili_helper'){
				console.log('use bilibili helper mode');
				localStorage['bilimac_player_type'] = 'available';
				injectStr = "localStorage.bilimac_original_player=document.getElementById('bofqi').innerHTML";
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
	}
});