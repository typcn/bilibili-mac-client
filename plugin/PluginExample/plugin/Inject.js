
window.sendToPlugin = function(data){
    var request = new XMLHttpRequest();
    request.open('POST', 'http://localhost:23330/pluginCall', true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.send(JSON.stringify(data));
}


document.body.innerHTML = '<a id="test" href="#">Click to test</a>';

document.getElementById('test').addEventListener('click',testclick);

function testclick(){
    // action ( event name ) format is pluginName-str
    sendToPlugin({ action:'Example-ShowExamplePanel', data:'123' });
}