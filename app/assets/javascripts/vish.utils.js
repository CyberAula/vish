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

    return {
      init : init,
      validateInput : validateInput,
      convertToTagsArray : convertToTagsArray     
    };

}) (Vish);