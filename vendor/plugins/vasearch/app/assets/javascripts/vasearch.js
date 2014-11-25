/*
 * ViSH Advanced Search Module
 * Dependencies: JQuery
 */

VASearch = (function(){

  var init = function(options){
    VASearch.Utils.init(options);
    VASearch.Core.init(options);
    VASearch.UI.init(options);
  };

  return {
      init : init
  };

})();


/*
 * UI Module. Handles and updates the UI
 */
VASearch.UI = (function(V,undefined){

  var init = function(){
    _loadUIEvents();
  };

  var _loadUIEvents = function(){
    //Search on press enter
    $("#asearch_header .asearch_box").bind('keypress', function(e){
      var code = e.keyCode || e.which;
      if(code == 13) { //Enter keycode
        VASearch.Core.onSearch();
      }
    });

    //Search on click magnifying glass
    $("#asearch_header button.search_button").bind('click', function(e){
      VASearch.Core.onSearch();
    });

    //On click settings
    $("#asearch_header .settings_button").bind('click', function(e){
      var isSettignsOpen = $("#asearch_settings").is(":visible");
      if(isSettignsOpen){
        $("#asearch_settings").fadeOut();
      } else {
        $("#asearch_settings").fadeIn();
      }
    });

    //Add and remove instances
    $("#asearch_settings .addInstanceButton").bind('click', function(e){
      var instanceInput = $("#asearch_settings .addInstanceInput");
      var newInstance = $(instanceInput).val();
      if(newInstance!=""){
        var el = $('<li><input type="checkbox"><span>'+$(instanceInput).val()+'</span><span class="deleteEntity" title="delete">[X]</span></li>');
        $("#asearch_settings .ViSHinstances").find("ul").append(el);
      }
    });

    $(document).on('click','span.deleteEntity', function(e){
      $(this).parent().remove();
    });

    //Close settings on certain events
    $("#asearch_header, #asearch_results, #asearch_settings span.closeASearchSettings").bind('click', function(e){
      if($(e.target).hasClass("settings_button_img") || $(e.target).hasClass("settings_button")){
        //Allow
      } else {
        $("#asearch_settings").hide();
      }
    });

    //Events on settings
    $("#asearch_settings [asparam='qualityThreshold']").on("change", function(e){
      _updateRange(this.value);
    });

  };

  var _updateRange = function(val){
    $("#asearch_settings [asparam='rangeValue']").html(val);
  };

  var drawResult = function(avatarURL,resourceURL,resourceTitle,authorURL,authorName,nFavorites,nViews){
    var scaffold = $('<div class="result" id="vasearchbox_'+VASearch.Utils.getId()+'"></div>');
    if(avatarURL){
      $(scaffold).append('<div class="resultImageWrapper"><img class="resultImage" src="'+avatarURL+'"></div>');
    }
    if((resourceTitle)&&(resourceURL)){
      $(scaffold).append('<div class="resultTitle"><a target="_blank" href="'+resourceURL+'">'+resourceTitle+'</a></div>');
    }
    if((authorName)&&(authorURL)){
      $(scaffold).append('<div class="resultAuthor"><span class="by">by</span> <a target="_blank" href="'+authorURL+'">'+authorName+'</a></div>');
    };
    if((nFavorites)&&(nViews)){
      $(scaffold).append('<div class="resultBottom"><div class="likes"><span>'+nFavorites+'</span> <img class="inlineIcon" src="/assets/asearch/star.png"></div><div class="views"><span>'+nViews+'</span> <img class="inlineIcon" src="/assets/asearch/eye.png"></div></div>');
    };
    
    $("#asearch_results").append(scaffold);
  };

  var cleanResults = function(){
    $("#asearch_results").html("");
  };

  var getSearchTermsFromUI = function(){
    return $("#asearch_header .asearch_box").val();
  };

  var getSettingsFromUI = function(){
    var settings = {};

    settings.n = $("#asearch_settings [asparam='n']").val();

    //Entities to search
    settings.entities_type = $("#asearch_settings select.entity_types").val().join(",");
    settings.sort_by = $("#asearch_settings [asparam='sort_by']").val();
    if(settings.sort_by=="Relevance"){
      delete settings.sort_by;
    }
    
    var startDate = $("#asearch_settings [asparam='startDate']").val().split("-").reverse().join("-");
    if(startDate.trim()!=""){
      settings.startDate = startDate;
    }
    var endDate = $("#asearch_settings [asparam='endDate']").val().split("-").reverse().join("-");
    if(endDate.trim()!=""){
      settings.endDate = endDate;
    }

    var language = $("#asearch_settings [asparam='language']").val();
    if(language.trim()!=""){
      settings.language = language;
    }

    settings.qualityThreshold = $("#asearch_settings [asparam='qualityThreshold']").val();

    return settings;
  };

  var getInstancesFromUI = function(){
    return $("#asearch_settings .ViSHinstances").find("ul li input[type='checkbox']:checked").map(function(index,input){ return $(input).parent().find("span").html();});
  };

  var onStartSearch = function(){
    $("*").addClass("asearch_waiting");
  };

  var onFinishSearch = function(){
    $("*").removeClass("asearch_waiting");
  };

  return {
    init : init,
    getSearchTermsFromUI: getSearchTermsFromUI,
    getSettingsFromUI : getSettingsFromUI,
    getInstancesFromUI : getInstancesFromUI,
    onStartSearch: onStartSearch,
    onFinishSearch: onFinishSearch,
    drawResult : drawResult,
    cleanResults : cleanResults
  };

}) (VASearch);




/*
 * Core Module. Handles the search queries to the ViSH instances.
 */

VASearch.Core = (function(V,undefined){

  //Constants
  var QUERY_TIMEOUT = 6000;
  var queriesCounter = 0;
  var queriesData = [];
  var searchId = -1;
  var sessionSearchs = {};

  var init = function(){
  };

  var onSearch = function(){
    $("#asearch_settings").hide();
    VASearch.UI.cleanResults();

    //1. Build Query
    var searchTerms = VASearch.UI.getSearchTermsFromUI();
    var settings = VASearch.UI.getSettingsFromUI();
    var query = _buildQuery(searchTerms,settings);

    //2. Peform the search in the instances
    var instances = VASearch.UI.getInstancesFromUI();
    var instancesL = instances.length;

    queriesCounter = 0;
    queriesData = [];
    searchId = VASearch.Utils.getId();
    sessionSearchs[searchId] = {};

    if(instancesL>0){
      VASearch.UI.onStartSearch();

      for(var i=0; i<instancesL; i++){
        sessionSearchs[searchId][instances[i]] = {completed: false};
        searchInViSHInstance(searchId,instances[i],query,function(data){
          if((typeof data.searchId == "undefined")||(data.searchId != searchId)){
            //Result of an old search
            return;
          }

          queriesCounter += 1;
          if((data.success===true)&&(typeof data.response != "undefined")&&(typeof data.response.results != "undefined")){
            queriesData = queriesData.concat(data.response.results)
          }

          if(queriesCounter===instancesL){
            //All searches finished
            _onFinishSearch(queriesData);
          }
        });
      }
    }
  };

  var _onFinishSearch = function(results){
    VASearch.UI.cleanResults();

    $(results).each(function(index,result){
      result.avatar_url = (typeof result.avatar_url == "string" ? result.avatar_url : "/assets/asearch/lo.png");
      VASearch.UI.drawResult(result.avatar_url,result.url,result.title,result.author_profile_url,result.author,result.like_count,result.visit_count);
    });

    VASearch.UI.onFinishSearch();
  };

  var _buildQuery = function(searchTerms,settings){
    searchTerms = (typeof searchTerms == "string" ? searchTerms : "");

    var query = "/apis/search?n="+settings.n+"&q="+searchTerms+"&type="+settings.entities_type;

    if(settings.sort_by){
      query += "&sort_by="+settings.sort_by;
    }

    if(settings.startDate){
      query += "&startDate="+settings.startDate;
    }

    if(settings.endDate){
      query += "&endDate="+settings.endDate;
    }

    if(settings.language){
      query += "&language="+settings.language;
    }

    if(settings.qualityThreshold){
      query += "&qualityThreshold="+settings.qualityThreshold;
    }

    return query;
  };

  var searchInViSHInstance = function(searchId,domain,query,callback){
    var ViSHSearchAPIURL = domain + query;

    $.ajax({
      type    : 'GET',
      url     : ViSHSearchAPIURL,
      success : function(data) {
        if(sessionSearchs[searchId][domain].completed == false){
          sessionSearchs[searchId][domain].completed = true;
          callback({success:true, response: data, searchId:searchId});
        }
      },
      error: function(error){
        if(sessionSearchs[searchId][domain].completed == false){
          sessionSearchs[searchId][domain].completed = true;
          callback({success:false, searchId:searchId});
        }
        VASearch.Utils.debug("Error connecting with the ViSH API of " + domain,true);
      }
    });

    setTimeout(function(){
      if(sessionSearchs[searchId][domain].completed == false){
        sessionSearchs[searchId][domain].completed = true;
        callback({success:false, searchId:searchId});
      }
    },QUERY_TIMEOUT);
  };

  return {
      init : init,
      onSearch : onSearch,
      searchInViSHInstance : searchInViSHInstance
  };

}) (VASearch);



VASearch.Utils = (function(V,undefined){

  //Constants
  var _id = 0;

  var init = function(){
  };

  var getId = function(){
    _id += 1;
    return _id;
  };

  var debug = function(msg,isError){
    if(console){
      if(isError){
        console.error(msg);
      } else {
        console.info(msg);
      }
    }
  };

  return {
      init : init,
      getId: getId,
      debug: debug    
  };

}) (VASearch);