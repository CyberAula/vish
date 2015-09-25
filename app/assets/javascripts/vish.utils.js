Vish.Utils = (function(V,undefined){
  
    var init = function(){ };

    var convertToTagsArray = function(tags){
      var tagsArray = [];
      
      if((!tags)||(tags.length==0)){
        return tagsArray;
      }
      
      $.each(tags, function(index, tag) {
        tagsArray.push(tag.value)
      });
      
      return tagsArray;
    };


    var validateInput = function(inputId){
      
      if(! $("#" + inputId).val()){
        return false;
      }
      
      return $("#" + inputId).val().trim() != "";
    };

    /* usage:
     * Vish.Utils.isMobile.any()
     */
    var isMobile = {
      Android: function() {
          return navigator.userAgent.match(/Android/i);
      },
      BlackBerry: function() {
          return navigator.userAgent.match(/BlackBerry/i);
      },
      iOS: function() {
          return navigator.userAgent.match(/iPhone|iPad|iPod/i);
      },
      Opera: function() {
          return navigator.userAgent.match(/Opera Mini/i);
      },
      Windows: function() {
          return navigator.userAgent.match(/IEMobile/i);
      },
      any: function() {
          return (isMobile.Android() || isMobile.BlackBerry() || isMobile.iOS() || isMobile.Opera() || isMobile.Windows());
      }
    };

    return {
      init : init,
      isMobile : isMobile,
      validateInput : validateInput,
      convertToTagsArray : convertToTagsArray     
    };

    
    

}) (Vish);