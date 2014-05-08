$(document).ready(function(){
	checkDocument(600,document);
	checkDocument(1000,document);
});

var checkDocument = function(timeout,document){
	setTimeout(function(){
		try {
			checkElement(document);
		} catch(e){}
	},timeout);
};

var checkElement = function(el){
	var iframes = $(el).find("iframe");
	$(iframes).each(function(index,iframe){
		checkElement($(iframe).contents());
	});

	var frames = $(el).find("frame");
	$(frames).each(function(index,frame){
		checkElement(frame.contentDocument);
	});

	_checkElement(el);
};

var _checkElement = function(el){
	var objects = $(el).find("object");
	$(objects).each(function(index,object){
		_checkObjectTag(object);
	});

	var embeds = $(el).find("embed");
	$(embeds).each(function(index,embed){
		_checkEmbedTag(embed);
	});
};

var _checkObjectTag = function(objectTag){
	var _isFlashObject = false;
	var _wmodeUpdated = false;

	//Look for wmode param
	var wmodeParam = $(objectTag).find("param[name='wmode']")[0];
	if(typeof wmodeParam != "undefined"){
		var wmodeParamValue = $(wmodeParam).attr("value");
		if(wmodeParamValue != "opaque"){
			$(wmodeParam).attr("value","opaque");
		}
	} else {
		$(objectTag).append('<param name="wmode" value="opaque">');
	}

	//Look for wmode in the embeds contained in the object
	var embeds = $(objectTag).find("embed");
	$(embeds).each(function(index,embed){
		if($(embed).attr("type")=="application/x-shockwave-flash"){
			_isFlashObject = true;
		}
		if($(embed).attr("wmode").toLowerCase()!="opaque"){
			_wmodeUpdated = true;
		}
		_checkEmbedTag(embed);
	});

	if(_isFlashObject && _wmodeUpdated){
		//Reload object
		// objectTag.innerHTML = objectTag.innerHTML
		$(objectTag).hide().show();
	}
};

var _checkEmbedTag = function(embedTag){
	//Set wmode param
	$(embedTag).attr("wmode","opaque");
};