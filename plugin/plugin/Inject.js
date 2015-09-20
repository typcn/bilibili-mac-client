
window.sendToPlugin = function(data){
    var request = new XMLHttpRequest();
    request.open('POST', 'http://localhost:23330/pluginCall', true);
    request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
    request.send(data);
}


document.body.innerHTML = '<a id="test" href="#">Click to test</a>';

document.getElementById('test').addEventListener('click',testclick);

function testclick(){
    // action ( event name ) format is pluginName-str
    sendToPlugin({ action:'Example-ShowExamplePanel', data:'123' });
}