var QUERY_TIMEOUT = 6000;

$(document).ready(function(){
	//Set events
	$("#asearch_header .asearch_box").bind('keypress', function(e){
		var code = e.keyCode || e.which;
		if(code == 13) { //Enter keycode
			onSearch();
		}
	});

	$("#asearch_header button.search_button").bind('click', function(e){
		onSearch();
	});

	$("#asearch_header .settings_button").bind('click', function(e){
		var isSettignsOpen = $("#asearch_settings").is(":visible");
		if(isSettignsOpen){
			$("#asearch_settings").fadeOut();
		} else {
			$("#asearch_settings").fadeIn();
		}
	});

	$("#addInstanceButton").bind('click', function(e){
		var newInstance = $("#addInstanceInput").val();
		if(newInstance!=""){
			var el = $('<li><input type="checkbox"><span>'+$("#addInstanceInput").val()+'</span><span class="deleteEntity" title="delete">[X]</span></li>');
			$("#ViSHinstances").find("ul").append(el);
		}
	});

	$(document).on('click','span.deleteEntity', function(e){
		$(this).parent().remove();
	});

	$("#asearch_header, #asearch_results, #closeASearchSettings").bind('click', function(e){
		if($(e.target).hasClass("settings_button_img") || $(e.target).hasClass("settings_button")){
			//Allow
		} else {
			$("#asearch_settings").hide();
		}
	});

});


///////////
// UI Methods
///////////
var drawResultInDOM = function(JSONresult){
	var avatarURL = (typeof JSONresult.avatar_url == "string" ? JSONresult.avatar_url : "/assets/asearch/lo.png");
	_drawResultInDOM(avatarURL, JSONresult.url,JSONresult.title,JSONresult.author_profile_url,JSONresult.author,JSONresult.like_count,JSONresult.visit_count);
};

var _drawResultInDOM = function(avatarURL,resourceURL,resourceTitle,authorURL,authorName,nFavorites,nViews){
	var scaffold = $('<div class="result" id="box'+getId()+'"></div>');
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

var updateRange = function(val){
	$("#rangeValue").html(val);
};


///////////
// Search Methods
///////////

var queriesCounter = 0;
var queriesData = [];
var searchId = -1;
var sessionSearchs = {};

var onSearch = function(){
	$("#asearch_settings").hide();
	cleanResults();

	//1. Build Query
	var searchTerms = $("#asearch_header .asearch_box").val();
	var settings = getSettings();
	var query = buildQuery(searchTerms,settings);

	//2. Peform the search in the instances
	var instances = getInstances();
	var instancesL = instances.length;

	queriesCounter = 0;
	queriesData = [];
	searchId = getId();
	sessionSearchs[searchId] = {};

	if(instancesL>0){
		$("*").addClass("waiting");

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
					onFinishSearch(queriesData);
				}
			});
		}
	}
};

var onFinishSearch = function(results){
	cleanResults();

	$(results).each(function(index,result){
		drawResultInDOM(result);
	});
	$("*").removeClass("waiting");
};

var getInstances = function(){
	return $("#ViSHinstances").find("ul li input[type='checkbox']:checked").map(function(index,input){ return $(input).parent().find("span").html();});
};

var getSettings = function(){
	var settings = {};

	settings.n = $("#n").val();

	//Entities to search
	settings.entities_type = $("#entity_types").val().join(",");
	settings.sort_by = $("#sort_by").val();
	if(settings.sort_by=="Relevance"){
		delete settings.sort_by;
	}
	
	var startDate = $("#startDate").val().split("-").reverse().join("-");
	if(startDate.trim()!=""){
		settings.startDate = startDate;
	}
	var endDate = $("#endDate").val().split("-").reverse().join("-");
	if(endDate.trim()!=""){
		settings.endDate = endDate;
	}

	var language = $("#language").val();
	if(language.trim()!=""){
		settings.language = language;
	}

	settings.qualityThreshold = $("#qualityThreshold").val();

	return settings;
};

var buildQuery = function(searchTerms,settings){
	var query = "/apis/search?n="+settings.n+"&q="+searchTerms+"&type="+settings.entities_type

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

	query += "&qualityThreshold="+settings.qualityThreshold;

	return query;
};

var searchInViSHInstance = function(searchId,domain,query,callback){
	var ViSHSearchAPIURL = domain + query

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
			debug("Error connecting with the ViSH API of " + domain,true);
		}
	});

	setTimeout(function(){
		if(sessionSearchs[searchId][domain].completed == false){
			sessionSearchs[searchId][domain].completed = true;
			callback({success:false, searchId:searchId});
		}
	},QUERY_TIMEOUT);
};

///////////
// Utils
///////////

var _id = 0;
var getId = function(){
	_id += 1;
	return _id;
};

var debug = function(msg,isError){
	if(console){
		if(error){
			console.error(msg);
		} else {
			console.info(msg);
		}
	}
};