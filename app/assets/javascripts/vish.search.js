/*
 * ViSH Search Module
 */
Vish.Search = (function(V,undefined){

  var _options;
  var _parsed_url;
  //js object like this: { tag1: occurrences_number, tag2: occurrences_number, ...}
  var _all_tags; 
  var NUMBER_OF_TAGS_TO_SHOW = 8;
  //js objects like this:
  //{ query1: datetime, query2: datetime, ...]
  var _queries_sent;
  var _queries_queue;
  var TIME_BETWEEN_QUERIES = 500; //in ms
  var TIME_LAST_QUERY_SENT = 0;
  var NUMBER_OF_CALLS = 0;

  /* options is an object like this:
      { object_types: ["Excursion", "Resource", "Event", "Workshop"],
        resource_types: [Webapp", "Scormfile", "Link", "Embed", "Writing", "Officedoc", "Video", "Swf", "Audio", "Zipfile", "Picture"],
        num_pages: 8,
        url: http://vishub.org/search?type=Webapp%2CScormfile&sort_by=updated_at,
        tags: "tag1,tag2,my_tag" 
      }  
  */
  var init = function(options){
    _options = options || {};
    _queries_sent = {};
    _queries_queue = {};

    if(!_options.object_types){      
      _options.object_types = ["Excursion", "Resource", "Event", "Workshop"];
    }
    if(!_options.resource_types){      
      _options.resource_types = ["Webapp", "Scormfile", "Link", "Embed", "Writing", "Officedoc", "Video", "Swf", "Audio", "Zipfile", "Picture"];
    }

    //take the params from the URL and mark them in the sidebar
    _parsed_url = _getUrlParameters();
    _recalculateTags(_options.tags, true);
    _fillSidebarWithParams();
    _loadUIEvents(_options);
  };


  var _loadUIEvents = function(options){
    //click on any filter
    $(document).on('click', "#search-sidebar ul li", function(e){
      _clickFilter($(this));
    });
    $(document).on('click', ".filter_box_x", function(e){
      _clickFilter($(this));
    });
    //for pageless
    $('#search-all ul').trigger("scroll.pageless");

    _applyPageless(options, false);    
  };


  var _applyPageless = function(options, stop_first){
    //console.log("reapplying pageless with url: " + options.url + " and num_pages: " + options.num_pages);
    //stop_first = typeof stop_first !== 'undefined' ? stop_first : false; //default value 
    if(stop_first){
      $.pagelessStop();
    }
    $('#search-all ul').pageless({
        totalPages: options.num_pages,
        url: options.url,
        currentPage: 1,
        loader: '.loader_pagination',
        end: function(){
          $('.loader_pagination').hide();
          $("#last_content_shown").show();
        },
        scrape: function(data){
          var parsed_html_return = $('<div></div>').html(data);
          //Recalculate the tags in the search sidebar
          var the_tags = parsed_html_return.find(".the_tags").val();
          _recalculateTags(the_tags, false);
          return data;
        },    
        complete: function(){
          //when we complete one page and there is no scroll, there cannot be another call
          //so we do a manual watch to bring all pages needed until we have a scroll
          $.pageless.watch();
        }
    });
  };


  var _clickFilter = function(filter_obj){    
    _toggleFilter(filter_obj.attr("filter_key"), filter_obj.attr("filter"), true);    
  };


  /*function that updates the tags shown in the sidebar
  initialize_tags indicates if we have to clean them*/
  var _recalculateTags = function(tags, initialize_tags){
    if(initialize_tags){
      _all_tags = {};
    }
    if(tags==""){
      return;
    }
    var array = tags.split(',');
    array.forEach(function(tag_item) {
        if(_all_tags[tag_item]){
          _all_tags[tag_item] = _all_tags[tag_item] + 1;
        } else {
          _all_tags[tag_item] = 1;
        }
      });
    //create a sortable array and remove the tags that are already selected
    var sortable = [];
    for (var t in _all_tags){
      if($("#selected_tags_ul").children("[filter='"+t+"']").length == 0){
        //the tag is not present in the selected_tags_ul
        sortable.push([t, _all_tags[t]]);
      }      
    }
    sortable.sort(function(a, b) {return  b[1] - a[1]});
    $("#tags_ul").html(""); //reset the content because we are going to add a new content
    var num = 0;
    for (var i = 0; i < sortable.length; i++) {
      if(num>NUMBER_OF_TAGS_TO_SHOW){
        break;
      }
      var tag_array = sortable[i];
      num +=1;
      $("#tags_ul").append('<li filter_key="tags" filter="'+tag_array[0]+'">'+tag_array[0]+ '</li>');
    }    
  };


  var _fillSidebarWithParams = function(){
    //remove all previous filters
    //$("#search-sidebar ul li").removeClass("search-sidebar-selected");

    //first the top level filter, type (All, user or learning object)
    if(!_parsed_url["type"] || _parsed_url["type"].indexOf("") > -1){
      _toggleFilter("type", "All");
    }else if(_parsed_url["type"] == "User"){
      _toggleFilter("type", "User");
    } else {
      _toggleFilter("type", "Learning_object");
      //in this case "type" can be, "excursion", "event", "workshop", i.e. anything in _options.object_types
      _options.object_types.forEach(function(item_type) {
        if(_parsed_url["type"].indexOf(item_type)>-1){
          _toggleFilter("type", item_type);
        }
      });

      //finally if _parsed_url["type"] can be anything in _options.resource_types, so we would have to mark the lo_type to "resource"
      _options.resource_types.forEach(function(item_subtype) {
        if(_parsed_url["type"].indexOf(item_subtype)>-1){          
          var filter_resource_obj = $("#search-sidebar ul li[filter_key='type'][filter='Resource']");
          _activateFilter(filter_resource_obj, false, false);
          $("#resource_type").show();
          _toggleFilter("type", item_subtype);
        }
      });
    }    

    //sort_by attribute
    if(_parsed_url["sort_by"]){
      var value = $("#order_by_selector_search .dropdown-menu [sort-by-key="+_parsed_url["sort_by"]+"]").html();
      $("#order_by_selector_search button").html(value + '<i class="icon-angle-down"></i>'); 
    }

    //the rest of the filters
    $.each( _parsed_url, function(name, value_array){
        if(name === 'q' || name === 'type' || name === 'sort_by' ||value_array.length===0 || value_array[0] === "") {
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
        if(filter_obj.attr("filter") != "All"){
          //do not allow to deactivate the "All" filter
          _deactivateFilter(filter_obj, update_url);          
        }
      } else {
        _activateFilter(filter_obj, update_url);
        
      }
    }    
  };

  /*function to deactivate a sidebar filter in the search
    filter_obj is the jquery object of the clicked filter
    update_url is to update or not the url, it is not updated when filling in the sidebar (because the url is already as is)
    follow_stack is to follow activating other filters in case of exclusivity (this happens with "all", "users", "learning_objects"), also used to call or not call the server, because if follow_stack the filters are applied automatically and not by user clicks
    */
  var _deactivateFilter = function(filter_obj, update_url, follow_stack){
      if(filter_obj.hasClass("search-sidebar-selected")){
        follow_stack = typeof follow_stack !== 'undefined' ? follow_stack : true;  //set default value
        var filter_name = filter_obj.attr("filter");
        var filter_key = filter_obj.attr("filter_key");

        filter_obj.removeClass("search-sidebar-selected");
        $("#applied_filters div[filter='"+filter_name+"']").parent().remove();

        //hide the related filters
        $("#search-sidebar div[opens_with='"+filter_name+"'] li.search-sidebar-selected").each(function(){
            _deactivateFilter($(this), update_url, false);
        });
        $("#search-sidebar div[opens_with='"+filter_name+"']").hide();
        
        //if it is a tag, we remove it from the ul selected_tags_ul
        if(filter_key==="tags"){
          filter_obj.remove();          
        }

        //see what happens with exclusivity, 
        //if the li has the attribute "exclusive" and we are deactivating it we have to activate the default
        if(follow_stack && filter_obj.attr("exclusive")==""){
          _activateFilter(filter_obj.siblings("[default]"), update_url, false);
        }

        if(update_url){
          _removeUrlParameter(filter_key, filter_name, follow_stack);
        }
      }
  };


  var _activateFilter = function(filter_obj, update_url, follow_stack){
      if(!filter_obj.hasClass("search-sidebar-selected")){
        follow_stack = typeof follow_stack !== 'undefined' ? follow_stack : true;  //set default value
        var filter_name = filter_obj.attr("filter");
        var filter_key = filter_obj.attr("filter_key");
        var filter_content = filter_obj.html();

        filter_obj.addClass("search-sidebar-selected");
        if(filter_name!="All"){
          var extra_class = "filter_box_" + filter_obj.closest("div.filter_set").attr("filter_type");
          $("#applied_filters").append("<div class='filter_box'><span class='filter_ball "+extra_class+"'>"+filter_content+"</span><div class='filter_box_x' filter_key='"+filter_key+"' filter='"+filter_name+"'>x</div></div>");
        }

        //show the related filters
        $("#search-sidebar div[opens_with='"+filter_name+"']").show();    

        //if it is a tag, we move it to the ul selected_tags_ul
        if(filter_key==="tags"){
          var tag_to_move = filter_obj.detach();
          $("#selected_tags_ul").append(tag_to_move);
        }

        //see what happens with exclusivity, check if the li has the attribute "exclusive"
        if(follow_stack && filter_obj.attr("exclusive")==""){
          filter_obj.siblings(".search-sidebar-selected").each(function() {
            _deactivateFilter($(this), update_url, false);
          });
        }

        if(update_url){
          _addUrlParameter(filter_key, filter_name, follow_stack);
        }
      }      
  };


  /*adds the parameter to the url
    also removes other params intelligently if needed
    for example when clicking on event we have to search for event and remove
    "learning_object"*/
  var _addUrlParameter = function(filter_key, filter_name, call_server){    
    if(_parsed_url[filter_key] == undefined){
      _parsed_url[filter_key] = [];
    }
    
    var filter_obj = $("#search-sidebar ul li[filter_key='"+filter_key+"'][filter='"+filter_name+"']");
    var opens_with_value = filter_obj.closest("div.filter_set").attr("opens_with");
    if(opens_with_value !=undefined && opens_with_value!=""){ 
      //remove that value from the url
      var index = _parsed_url[filter_key].indexOf(opens_with_value);
      if (index > -1) {
        _parsed_url[filter_key].splice(index, 1);
      }
    }
    _parsed_url[filter_key].push(filter_name);

    if(call_server){
      _composeFinalUrlAndCallServer(_parsed_url["sort_by"]);
    }
  };


  /*removes the parameter from the url
    also adds other params intelligently if needed*/
  var _removeUrlParameter = function(filter_key, filter_name, call_server){
    
    if(_parsed_url[filter_key] != undefined){
      //_parsed_url[filter_key] is an array that should contain "filter_name" and we have to remove it
      var index = _parsed_url[filter_key].indexOf(filter_name);
      if (index > -1) {
        _parsed_url[filter_key].splice(index, 1);
      }   
    }  

    //if this filter is the last one we have to add the param "opens_with" to the array
    var filter_obj = $("#search-sidebar ul li[filter_key='"+filter_key+"'][filter='"+filter_name+"']");
    var selected_siblings = filter_obj.siblings(".search-sidebar-selected").length;
    var opens_with_value = filter_obj.closest("div.filter_set").attr("opens_with");
    if(selected_siblings==0 && opens_with_value !=undefined && opens_with_value!=""){ 
      //add that value to the url
      _parsed_url[filter_key].push(opens_with_value);    
    }
    if(call_server){
      _composeFinalUrlAndCallServer(_parsed_url["sort_by"]);    
    }
  };


  var _composeFinalUrlAndCallServer = function(sort_by){
    var final_url = {};
    $.each( _parsed_url, function(key, value){ 
      //remove empty strings
      value = value.filter(function(e) { return e; });
      if(key==="type" && value.length==1 && value[0]==="All"){
        final_url[key] = "";
      } else {
        final_url[key] = value.join();
      }
    });   
    var new_url = "search?" + queryString.stringify(final_url);
    window.history.pushState("", "", new_url);
    _manageQuery(new_url, sort_by);
  };


  /*query is the URL to call the server
    sort_by_key is the key to stablish the sort_by drop down value when success
  */
  var _manageQuery = function(query, sort_by_key){
    _queries_sent[query] = Date.now();
    //cuando llega un success quito todas las queries que pedí antes? -> si. Y si llega un success y no está en _queries_sent no lo pinto.
    //puedo apuntar en una variable el tiempo de cuando pedi la última query y si llega otra y no ha pasado X tiempo a la cola
    //timeouts para ver la cola
    NUMBER_OF_CALLS +=1;
    //console.log("LLAMANDO AL SERVIDOR " + NUMBER_OF_CALLS);
    $.ajax({
          type : "GET",
          url : query,
          success : function(html_code) {
            //show the sort_by value that the user selected, if any
            if(sort_by_key){              
              var value = $("#order_by_selector_search .dropdown-menu [sort-by-key="+sort_by_key+"]").html();
              $("#order_by_selector_search button").html(value + '<i class="icon-angle-down"></i>');
            }
            //reapply pageless
            var options = {};
            var parsed_html_return = $('<div></div>').html(html_code);
            options.num_pages = parsed_html_return.find('.num_pages').val();
            options.url = query;
            _applyPageless(options, true);
            //Recalculate the tags in the search sidebar
            var the_tags = parsed_html_return.find(".the_tags").val();
            _recalculateTags(the_tags, true);
            var n_results = parsed_html_return.find(".n_results").val();
            $("#n_results").html(n_results);

            //enter the results in the designated area
            $("#search-all ul").html(html_code);
          },
          error: function(xhr, status, error) {
            $("#search-all ul").html("SERVER error with the query: " + query);
            $("#search-all ul").append(xhr.responseText);
         }
        });
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


  /*Function called when sort_by dropdown changes*/
  var launch_search_with_sort_by = function(sort_by){
    _parsed_url["sort_by"] = [sort_by];
    _composeFinalUrlAndCallServer(sort_by);
  }


  return {
    init : init,
    launch_search_with_sort_by: launch_search_with_sort_by
  };

}) (Vish);
