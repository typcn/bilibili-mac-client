chrome.runtime.sendMessage({blGetScript: window.location.host}, function(response) {
	if(response != '!'){
		var request = new XMLHttpRequest();
		request.open('POST', 'http://localhost:23330/rpc', true);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		var urle = 'action=setVUrl&data=' + encodeURIComponent(window.location.href);
		request.send(urle);
		var script = document.createElement('script');
		script.textContent = response;
		(document.head||document.documentElement).appendChild(script);
		script.parentNode.removeChild(script);
	}
});