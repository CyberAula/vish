/*
 * ViSH Advanced Search Module
 * Dependencies: JQuery
 */

VASearch = (function(){

  var _settings;

  var init = function(options){
    _setSettings(options);

    VASearch.Utils.init(_settings);
    VASearch.Core.init(_settings);
    VASearch.UI.init(_settings);
  };

  var _setSettings = function(options){
    options = options || {};
    _settings = options;
    if(typeof _settings.locale == "undefined"){
      _settings.locale = "default";
    }
  };

  var getSettings = function(){
    return _settings;
  };

  return {
      init : init,
      getSettings: getSettings
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
        V.Core.onSearch();
      }
    });

    //Search on click magnifying glass
    $("#asearch_header button.search_button").bind('click', function(e){
      V.Core.onSearch();
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

  var drawResult = function(result){
    var targetAttr = (typeof result.instance != "undefined" && result.instance == V.getSettings().current_instance) ? "_self" : "_blank";
    
    var scaffold = $('<div class="result" id="vasearchbox_'+V.Utils.getId()+'"></div>');
    if((result.avatar_url)&&(result.url)){
      $(scaffold).append('<div class="resultImageWrapper"><a target="'+targetAttr+'" href="'+result.url+'"><img class="resultImage" src="'+result.avatar_url+'"></a></div>');
    }
    if((result.title)&&(result.url)){
      $(scaffold).append('<div class="resultTitle"><a target="'+targetAttr+'" href="'+result.url+'">'+result.title+'</a></div>');
    }
    if((result.author)&&(result.author_profile_url)){
      $(scaffold).append('<div class="resultAuthor"><span class="by">'+V.Utils.getTrans("i.by")+'</span> <a target="'+targetAttr+'" href="'+result.author_profile_url+'">'+result.author+'</a><br/>' + V.Utils.getTrans("i.in") +' <a target="'+targetAttr+'" href="'+result.instance+'">' + result.instance + '</a></div>');
    };
    if((result.like_count)&&(result.visit_count)&&(result.url)){
      $(scaffold).append('<div class="resultBottom"><div class="likes"><span>'+result.like_count+'</span> <a target="'+targetAttr+'" href="'+result.url+'"><img class="inlineIcon" src="/assets/asearch/star.png"></a></div><div class="views"><span>'+result.visit_count+'</span> <img class="inlineIcon" src="/assets/asearch/eye.png"></div></div>');
    };
    
    $("#asearch_results").append(scaffold);
  };

  var drawNoResults = function(){
    $("#asearch_results").append("<div class='noResults'>"+V.Utils.getTrans("i.noResults")+"</div>");
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
    drawNoResults : drawNoResults,
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
    V.UI.cleanResults();

    //1. Build Query
    var searchTerms = V.UI.getSearchTermsFromUI();
    var settings = V.UI.getSettingsFromUI();
    var query = _buildQuery(searchTerms,settings);

    //2. Peform the search in the instances
    var instances = V.UI.getInstancesFromUI();
    var instancesL = instances.length;

    queriesCounter = 0;
    queriesData = [];
    searchId = V.Utils.getId();
    sessionSearchs[searchId] = {};

    if(instancesL>0){
      V.UI.onStartSearch();

      for(var i=0; i<instancesL; i++){
        var instanceDomain = instances[i];
        sessionSearchs[searchId][instanceDomain] = {completed: false};
        searchInViSHInstance(searchId,instanceDomain,query,function(data){
          if((typeof data.searchId == "undefined")||(data.searchId != searchId)){
            //Result of an old search
            return;
          }

          queriesCounter += 1;
          if((data.success===true)&&(typeof data.response != "undefined")&&(typeof data.response.results != "undefined")&&(typeof data.instanceDomain != "undefined")){
            queryResults = [];
            $(data.response.results).each(function(index,result){
              result.instance = data.instanceDomain;
              result.sorting_weight = (typeof result.weights != "undefined" && typeof result.weights.sorting_weight == "number") ? result.weights.sorting_weight : 0;
              queryResults.push(result);
            });
            queriesData = queriesData.concat(queryResults);
          }

          if(queriesCounter===instancesL){
            //All searches finished

            //Sort the results from different instances
            if(instancesL>1){
              queriesData = queriesData.sort(function(a,b){
                return b.sorting_weight-a.sorting_weight;
              });
            }
            
            //Notify UI and redraw
            _onFinishSearch(queriesData);
          }
        });
      }
    }
  };

  var _onFinishSearch = function(results){
    V.UI.cleanResults();

    if(results.length === 0){
      V.UI.drawNoResults();
    } else {
      $(results).each(function(index,result){
        result.avatar_url = (typeof result.avatar_url == "string" ? result.avatar_url : "/assets/asearch/lo.png");
        V.UI.drawResult(result);
      });
    }

    V.UI.onFinishSearch();
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
    ViSHSearchAPIURL = ViSHSearchAPIURL.replace("//apis","/apis");

    $.ajax({
      type    : 'GET',
      url     : ViSHSearchAPIURL,
      success : function(data) {
        if(sessionSearchs[searchId][domain].completed == false){
          sessionSearchs[searchId][domain].completed = true;
          callback({success:true, searchId:searchId, instanceDomain:domain, response:data});
        }
      },
      error: function(error){
        if(sessionSearchs[searchId][domain].completed == false){
          sessionSearchs[searchId][domain].completed = true;
          callback({success:false, searchId:searchId, instanceDomain:domain});
        }
        V.Utils.debug("Error connecting with the ViSH API of " + domain,true);
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
  var _translations;
  var ALL_TRANSLATIONS = {
      "default":
        //English
        {
          "i.by"            : "by",
          "i.in"            : "in",
          "i.noResults"     : "No results were found. Try with other search criteria"
        },
      "es":
        {
          "i.by"            : "por",
          "i.in"            : "en",
          "i.noResults"     : "No se encontraron resultados. Prueba con otros criterios de búsqueda"
        }
  };

  var init = function(){
    var locale = V.getSettings().locale;
    _translations = ALL_TRANSLATIONS[locale];
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

  /*
   * I18n
   */
  var getTrans = function(s,params){
    if(typeof(_translations)!= 'undefined' && _translations[s]){
      return _getTrans(_translations[s],params);
    }

    //Search in default language
    var dtrans = ALL_TRANSLATIONS["default"][s];
    if(dtrans){
      return _getTrans(dtrans,params);
    }

    //Don't return s if s is a key.
    var key_pattern =/^i\./g;
    if(key_pattern.exec(s)!=null){
      return null;
    } else {
      return s;
    }
  };

  /*
   * Replace params (if they are provided) in the translations keys. Example:
   * // "i.dtest" : "by #{author} in Instance",
   * // V.Utils.getTrans("i.dtest", {author: "Aldo"}) -> "by Aldo in Instance"
   */
  var _getTrans = function(trans, params){
    if(typeof params != "object"){
      return trans;
    }

    for(var key in params){
      var stringToReplace = "#{" + key + "}";
      if(trans.indexOf(stringToReplace)!=-1){
        trans = _replaceAll(trans,stringToReplace,params[key]);
      }
    };

    return trans;
  };

  var _replaceAll = function(string,find,replace){
    return string.replace(new RegExp(find.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'g'), replace);
  };

  return {
      init : init,
      getId: getId,
      getTrans: getTrans,
      debug: debug
  };

}) (VASearch);