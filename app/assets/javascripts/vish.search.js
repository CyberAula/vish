/*
 * ViSH Search Module
 */
Vish.Search = (function(V,undefined){
  
  /* options is an object with:
      { object_subtypes: ["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Officedoc", "Video", "Swf", "Audio", "Zipfile", "Picture"],
        
      }  */
  var init = function(options){
    options = options || {};

    //take the params from the URL and mark them in the sidebar
    var params = _getUrlParameters(document.location.toString());
    //default type, array with only one value, all_entities
    params["type"] = params["type"] ? params["type"]:[""];
    _fillSidebarWithParams(options, params);
    
  }

   
  var _fillSidebarWithParams = function(options, params){
    var object_subtypes;
    //remove all previous filters
    $("#search-sidebar ul li").removeClass("search-sidebar-selected"); 

    //first the top level filter, entity (all, user or learning resource)
    if(!params["type"] || params["type"].indexOf("") > -1){
      $("#search-sidebar ul li[filter='all_type']").addClass("search-sidebar-selected"); 
    }else if(params["type"] == "user"){
      $("#search-sidebar ul li[filter='user_type']").addClass("search-sidebar-selected"); 
    } else {
      $("#search-sidebar ul li[filter='learning_object_type']").addClass("search-sidebar-selected"); 
    }

    //now if params["type"] has any kind of learning object, mark the option
    if(options.object_subtypes){
      object_subtypes = options.object_subtypes;
    } else {
      object_subtypes = ["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Officedoc", "Video", "Swf", "Audio", "Zipfile", "Picture"];
    }
    object_subtypes.forEach(function(item) {
      if(params["type"].indexOf(item)>-1){
        $("#resource_type").show();
        $("#search-sidebar ul li[filter='resource']").addClass("search-sidebar-selected"); 
      }
    });

    $.each( params, function(name, value_array){
        value_array.forEach(function(item) {
          $("#search-sidebar ul li[filter='"+item+"']").addClass("search-sidebar-selected");   
        });
    });
  };


  /*Returns an object with the URL parameters as arrays
    EXAMPLE: result = { "type": ["Excursion", "Resource"], "language":["es", "en"]}*/
  var _getUrlParameters = function(url)
  {
      var result = {};
      var the_url = url.toLowerCase();
      var searchIndex = the_url.indexOf("?");
      if (searchIndex == -1 ) return result;
      var sPageURL = the_url.substring(searchIndex +1);
      var sURLVariables = sPageURL.split('&');
      for (var i = 0; i < sURLVariables.length; i++)
      {       
          var sParameterName = sURLVariables[i].split('=');      
          result[sParameterName[0]] = sParameterName[1].split(",");
      }      
      return result;
  }  

  return {
    init : init,

          
  };

}) (Vish);