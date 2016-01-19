var MASHME = MASHME || {};
MASHME.API = MASHME.API || {};

MASHME.API.iFrame = function(){

	var params = {};

	var init = function(app_id, app_secret, yourcallback){
		params.app_id = app_id;
		params.app_secret = app_secret;

		window.addEventListener("message", yourcallback, false);
	};

	var broadcast = function(message){
		window.parent.postMessage(message,'*');
	};

	return {
		init: init,
		broadcast: broadcast
	};

} (MASHME);