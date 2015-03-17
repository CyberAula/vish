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
    _loadUIEvents();
  };


  var _loadUIEvents = function(settings){    
    //click on any filter
    $("#search-sidebar ul li").on('click', function(e){
      _clickFilter($(this));
    });
  };


  var _clickFilter = function(filter_obj){
    _toggleFilter(filter_obj);
  };
   

  var _buildQuery = function(){

  };

  var _fillSidebarWithParams = function(options, params){
    var object_subtypes;
    //remove all previous filters
    $("#search-sidebar ul li").removeClass("search-sidebar-selected"); 

    //first the top level filter, type (all, user or learning object)
    if(!params["type"] || params["type"].indexOf("") > -1){
      _toggleFilter("all_type");      
    }else if(params["type"] == "user"){      
      _toggleFilter("user_type");  
    } else {
      _toggleFilter("learning_object_type");
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
        _toggleFilter("resource");
      }
    });

    $.each( params, function(name, value_array){
        value_array.forEach(function(item) {
          _toggleFilter(item); 
        });
    });
  };

  /*filter can be a jquery object with the filter or a string*/
  var _toggleFilter = function(filter) {
    var filter_obj;
    if(typeof filter === "string"){
      filter_obj = $("#search-sidebar ul li[filter='"+filter+"']");
    } else {
      filter_obj = filter;
    }
    if(filter_obj.hasClass("search-sidebar-selected")) {
      _deactivateFilter(filter_obj);
    } else {
      _activateFilter(filter_obj);
    }    
  };

  var _deactivateFilter = function(filter_obj, follow_stack){
      follow_stack = typeof follow_stack !== 'undefined' ? follow_stack : true;  //set default value
      var filter_name = filter_obj.attr("filter");

      filter_obj.removeClass("search-sidebar-selected"); 

      //hide the related filters
      $("#search-sidebar div[opens_with='"+filter_name+"'] li").each(function(){ 
          _deactivateFilter($(this));
      });
      $("#search-sidebar div[opens_with='"+filter_name+"']").hide();
      //finally see what happens with exclusivity, check that the li has the attribute "exclusive"
      if(follow_stack && filter_obj.attr("exclusive")==""){
        _activateFilter(filter_obj.siblings("[default]"));
      }
  };

  var _activateFilter = function(filter_obj, follow_stack){
      follow_stack = typeof follow_stack !== 'undefined' ? follow_stack : true;  //set default value
      var filter_name = filter_obj.attr("filter");

      filter_obj.addClass("search-sidebar-selected");

      //show the related filters
      $("#search-sidebar div[opens_with='"+filter_name+"']").show();
      
      //finally see what happens with exclusivity, check if the li has the attribute "exclusive"
      if(follow_stack && filter_obj.attr("exclusive")==""){
        filter_obj.siblings().each(function() {
          _deactivateFilter($(this), false); 
        });
      }
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
  };

  return {
    init : init,

          
  };

}) (Vish);