// chrome.storage.local.set({'value': theValue}, function() {
// message('Settings saved');
// });
load();

function $(sel){
  var s = document.querySelectorAll(sel);
  if(!s){
    return;
  }else if(s.length == 1){
    return s[0]; 
  }else{
    return s;
  }
}

function API(name,action,data,callback){
  var request = new XMLHttpRequest();
  request.open('POST', 'http://localhost:23330/' + name, true);
  request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');

  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      var data = JSON.parse(request.responseText);
      callback(0,data);
    } else {
      callback(-2);
    }
  };

  request.onerror = function() {
    callback(-1);
  };
  var d = data || 'none';
  var urle = 'action=' + encodeURIComponent(action) + '&data=' + encodeURIComponent(d);
  request.send(urle);
}

function load(){
  var lastUp = parseInt(localStorage.lastUpdate) || 0;
  var manifest = chrome.runtime.getManifest();

  fetch('http://localhost:23330/ver', {
    method: 'get'
  }).then(function(response) {
    return response.json();
  }).then(function(response){
    $("#title").innerHTML = 'Bilibili for mac ' + response.version + ' ( Build ' + response.build + ' ) Ext ' + manifest.version;
    if(Date.now() - lastUp > 600000){
      getScriptList();
    }else{
      showPluginList();
    }

    refreshPluginList();
  }).catch(function(err) {
    $("#loading p").innerHTML = '连接失败，请确保 <a href="http://bilimac.eqoe.cn/" target="_blank">Bilibili for mac</a> 处于开启状态';
  });
}

function getScriptList(){
  API('interactive','scriptList',null,function(err,data){
    if(err){
      console.log('Update failed');
    }else{
      for(var i = 0;i < data.length;i++){
        var k = 'script_' + data[i].site.replace(/\./g, '_');
        localStorage[k] = data[i].script;
      }
      localStorage.lastUpdate = Date.now();
      console.log('Updated Script List');
      showPluginList();
    }
  });
}

function refreshPluginList(){
  API('interactive','pluginList',null,function(err,data){
    if(err){
      console.log('Update failed');
    }else{
      var html = '';
      for(var i = 0;i < data.length;i++){
        var pluginName = data[i].file.replace('.bundle','');
        if(pluginName == "bilibili"){
          data[i].domain = "bilibili.com";
        }
        html += plug_tmpl(pluginName, data[i].domain, data[i].ver);
      }
      pluginListBody.innerHTML = html;
      componentHandler.upgradeDom();
      var elem = $('.plugin-select');
      for(var i = 0;i < elem.length;i++){
        elem[i].addEventListener('click',setChecked);
      }
    }
  });
}

function showPluginList(){
  $('#loading').style.display = 'none';
  $('#mainList').style.display = '';
}

$("#reloadPlugin").addEventListener("click",function(){
  getScriptList();
  showPluginList();
});

$("#downloadManager").addEventListener("click",function(){
  chrome.tabs.create({ url: "http://static.tycdn.net/downloadManager/" });
});

$("#pluginCenter").addEventListener("click",function(){
  call_uri("bl://vp-hub.eqoe.cn/");
});

$("#getUserByComment").addEventListener("click",function(){
  chrome.tabs.create({ url: "http://biliquery.typcn.com/?noredir" });
});

$("#softwareSettings").addEventListener("click",function(){
  var request = new XMLHttpRequest();
  request.open('POST', 'http://localhost:23330/pluginCall', true);
  request.setRequestHeader('Content-Type', 'application/json');
  request.onerror = function() {
    call_uri("bl://open_without_gui");
  };
  request.send(JSON.stringify({action:'bilibili-setActive',data:'none'}));
  API('rpc','showSettings',null,function(){});
});

function plug_tmpl(name,site,ver){
  site = site.replace(/\./g,'_');
  var disable = localStorage['disable_' + site];
  var checked = '';
  if(!disable){
    checked = 'checked';
  }
  var str = '<tr> \
  <td class="mdl-data-table__cell--non-numeric">' + name + '</td> \
  <td>' + ver + '</td> \
  <td> \
    <label class="mdl-switch mdl-js-switch mdl-js-ripple-effect" for="' + name + '" style="width: auto;"> \
      <input type="checkbox" id="' + name + '" class="mdl-switch__input plugin-select" ' + checked + ' data-site="' + site + '"/> \
      <span class="mdl-switch__label"></span> \
    </label> \
  </td> \
  </tr>';
  return str;
}

function setChecked(e){
  var site = e.target.dataset.site;
  console.log(site,e.target.checked);
  if(e.target.checked){
    delete localStorage['disable_' + site];
  }else{
    localStorage['disable_' + site] = 'true';
  }
}

function call_uri(uri){
  chrome.tabs.getAllInWindow(function(a){
    for(var i = 0;i < a.length;i++){
      if(a[i].url.indexOf('http://') > -1){
        chrome.tabs.executeScript(a[i].id, {code: "window.location.assign('" + uri + "');"}, function(response) {
          
        });
        return;
      }
    }
  });
}

$("#bili_helper").addEventListener("click",function(e){
  if(e.target.checked){
    localStorage['replace_in'] = 'bilibili_helper';
  }else{
    localStorage['replace_in'] = 'self';
  }
});

if(localStorage['replace_in'] == 'bilibili_helper'){
  $("#bili_helper").checked = true;
}

$("#no_close_replace").addEventListener("click",function(e){
  if(e.target.checked){
    localStorage['no_close_replace'] = 'true';
  }else{
    delete localStorage['no_close_replace'];
  }
});

if(localStorage['no_close_replace'] == 'true'){
  $("#no_close_replace").checked = true;
}

$("#hide_faq").addEventListener("click",function(e){
  if(e.target.checked){
    localStorage['hide_faq'] = 'true';
  }else{
    delete localStorage['hide_faq'];
  }
});

if(localStorage['hide_faq'] == 'true'){
  $("#hide_faq").checked = true;
}

$("#auto_open").addEventListener("click",function(e){
  if(e.target.checked){
    localStorage['auto_open'] = 'true';
  }else{
    delete localStorage['auto_open'];
  }
});

if(localStorage['auto_open'] == 'true'){
  $("#auto_open").checked = true;
}