(function() {
  var blockList = ['cnzz','tajs.qq.com','data.bilibili.com'];

  if(document.head){
    headLoaded();
  }else{
      var observer = new MutationObserver(function(mutations) {
        if(document.head){
          observer.disconnect();
          headLoaded();
        }
      });
      observer.observe(document, {
        childList: true,
        subtree: true
      });
  }

  function headLoaded(){
    var hooked_ib = document.head.insertBefore;
    document.head.insertBefore = function(a){
       if(a.src && checkBlock(a.src)){
           return console.log('Blocked script insert: ' + a.src);
       }
       return hooked_ib.apply(this, arguments);
    }
  }

  function checkBlock(str){
    for(var i = 0; i < blockList.length; i++){
      if(str.indexOf(blockList[i]) > -1){
        return true;
      }
    }
    return false;
  }
})();
