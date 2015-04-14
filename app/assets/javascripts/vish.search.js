/*
 * ViSH Search Module
 */
Vish.Search = (function(V,undefined){

  var _options;
  var _parsed_url;


  /* options is an object like this:
      { object_types: ["Excursion", "Resource", "Event", "Workshop"],
        resource_types: ["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Officedoc", "Video", "Swf", "Audio", "Zipfile", "Picture"],
      }  
  */
  var init = function(options){
    _options = options || {};
    
    if(!_options.object_types){      
      _options.object_types = ["Excursion", "Resource", "Event", "Workshop"];
    }
    if(!_options.resource_types){      
      _options.resource_types = ["Document", "Webapp", "Scormfile", "Link", "Embed", "Writing", "Officedoc", "Video", "Swf", "Audio", "Zipfile", "Picture"];
    }

    //take the params from the URL and mark them in the sidebar
    _parsed_url = _getUrlParameters();
    //default type, array with only one value, all_entities
    _fillSidebarWithParams();
    _loadUIEvents();
  };


  var _loadUIEvents = function(settings){
    //click on any filter
    $(document).on('click', "#search-sidebar ul li", function(e){
      _clickFilter($(this));
    });
    $(document).on('click', ".filter_box_x", function(e){
      _clickFilter($(this));
    });
  };


  var _clickFilter = function(filter_obj){    
    _toggleFilter(filter_obj.attr("filter_key"), filter_obj.attr("filter"), true);    
  };


  var _fillSidebarWithParams = function(){
    //remove all previous filters
    //$("#search-sidebar ul li").removeClass("search-sidebar-selected");

    //first the top level filter, type (all, user or learning object)
    if(!_parsed_url["type"] || _parsed_url["type"].indexOf("") > -1){
      _toggleFilter("type", "all_type");
    }else if(_parsed_url["type"] == "user"){
      _toggleFilter("type", "user_type");
    } else {
      _toggleFilter("type", "learning_object_type");
      //in this case "type" can be, "excursion", "event", "workshop", i.e. anything in _options.object_types
      _options.object_types.forEach(function(item_type) {
        if(_parsed_url["type"].indexOf(item_type)>-1){
          _toggleFilter("type", item_type);
        }
      });

      //finally if _parsed_url["type"] can be anything in _options.resource_types, so we would have to mark the lo_type to "resource"
      _options.resource_types.forEach(function(item_subtype) {
        if(_parsed_url["type"].indexOf(item_subtype)>-1){          
          _toggleFilter("type", "resource");
          $("#resource_type").show();
          _toggleFilter("type", item_subtype);
        }
      });
    }    

    $.each( _parsed_url, function(name, value_array){
        if(name === 'q' || name === 'type' || value_array.length===0 || value_array[0] === "") {
          return true;//next iteration, q is the query so not a filter, "type" has already been manually treated, or maybe the param is present but not filled
        }
        value_array.forEach(function(item) {
          _toggleFilter(name, item);
        });
    });
  };


  var _toggleFilter = function(filter_key, filter_name, update_url) {
    update_url = typeof update_url !== 'undefined' ? update_url : false;  //set default value
    var filter_obj = $("#search-sidebar ul li[filter_key='"+filter_key+"'][filter='"+filter_name+"']");
    
    if(filter_obj.length>0){
      if(filter_obj.hasClass("search-sidebar-selected")) {
        if(filter_obj.attr("filter") != "all_type"){
          //do not allow to deactivate the "all_type" filter
          _deactivateFilter(filter_obj, update_url);          
        }
      } else {
        _activateFilter(filter_obj, update_url);
        
      }
    }    
  };


  var _deactivateFilter = function(filter_obj, update_url, follow_stack){
      follow_stack = typeof follow_stack !== 'undefined' ? follow_stack : true;  //set default value
      var filter_name = filter_obj.attr("filter");
      var filter_key = filter_obj.attr("filter_key");

      filter_obj.removeClass("search-sidebar-selected");
      $("#applied_filters div[filter='"+filter_name+"']").parent().remove();

      //hide the related filters
      $("#search-sidebar div[opens_with='"+filter_name+"'] li").each(function(){
          _deactivateFilter($(this), update_url);
      });
      $("#search-sidebar div[opens_with='"+filter_name+"']").hide();
      if(update_url){
        _removeUrlParameter(filter_key, filter_name);
      }

      //finally see what happens with exclusivity, 
      //if the li has the attribute "exclusive" and we are deactivating it we have to activate the default
      if(follow_stack && filter_obj.attr("exclusive")==""){
        _activateFilter(filter_obj.siblings("[default]"), update_url);
      }
  };


  var _activateFilter = function(filter_obj, update_url, follow_stack){
      follow_stack = typeof follow_stack !== 'undefined' ? follow_stack : true;  //set default value
      var filter_name = filter_obj.attr("filter");
      var filter_key = filter_obj.attr("filter_key");
      var filter_content = filter_obj.html();

      filter_obj.addClass("search-sidebar-selected");
      if(filter_name!="all_type"){
        var extra_class = "filter_box_" + filter_obj.closest("div.filter_set").attr("filter_type");
        $("#applied_filters").append("<div class='filter_box'><span class='filter_ball "+extra_class+"'>"+filter_content+"</span><div class='filter_box_x' filter_key='"+filter_key+"' filter='"+filter_name+"'>x</div></div>");
      }

      //show the related filters
      $("#search-sidebar div[opens_with='"+filter_name+"']").show();
      
      if(update_url){
          _addUrlParameter(filter_key, filter_name);
      }

      //finally see what happens with exclusivity, check if the li has the attribute "exclusive"
      if(follow_stack && filter_obj.attr("exclusive")==""){
        filter_obj.siblings().each(function() {
          _deactivateFilter($(this), update_url, false);
        });
      }
  };


  /*adds the parameter to the url*/
  var _addUrlParameter = function(key, value){
    if(_parsed_url[key] == undefined){
      _parsed_url[key] = [];
    } 
    _parsed_url[key].push(value);
    var final_url = {};
    $.each( _parsed_url, function(key, value){ 
      final_url[key] = value.join();
    });
    var new_url = "search?" + queryString.stringify(final_url);
    window.history.pushState("", "", new_url);
  };


  /*removes the parameter from the url*/
  var _removeUrlParameter = function(key, value){
    if(_parsed_url[key] != undefined){
      //_parsed_url[key] is an array that should contain "value" and we have to remove it
      var index = _parsed_url[key].indexOf(value);
      if (index > -1) {
        _parsed_url[key].splice(index, 1);
      }   
    }  
    var final_url = {};
    $.each( _parsed_url, function(key, value){ 
      final_url[key] = value.join();
    });   
    var new_url = "search?" + queryString.stringify(final_url);
    window.history.pushState("", "", new_url);
  };


  /*Returns an object with the URL parameters as arrays
    EXAMPLE: result = { type: ["Excursion", "Resource"], language:["es", "en"]}*/
  var _getUrlParameters = function()
  {
      var parsed = queryString.parse(location.search);
      $.each( parsed, function(key, value){
        var commaIndex = value.indexOf(",");
        //if contains comma, split it in an array, if not returns an array with one value (easier to iterate)
        parsed[key] = value.split(",");        
      });
      //console.log(parsed);
      return parsed;
  };


  return {
    init : init
  };

}) (Vish);
