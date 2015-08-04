/*
 * VISH Iframe Messenger API
 * Provides an API that allows web applications to communicate with ViSH Editor
 * @author GING
 * @version 2.0
 */

var VISH = VISH || {};


VISH.IframeAPI = (function(V,undefined){

	var _initialized = false;
	var _connected = false;
	var _options;
	var _mode = "EXTERNAL"; //default
	var _origin = "?";
	var _originId = "?";
	var _listeners;
	var _wapplisteners;
	// _listeners['event'] = callback;

	//Constants
	var VALID_TYPES = ["PROTOCOL","VE","WAPP"];


	///////////////
	// CORE
	//////////////

	var init = function(initOptions){
		_connected = false;

		if(_initialized===false){
			try {
				_origin = window.location.href;
			} catch (e){}
			_originId = _generateOriginId();

			if (window.addEventListener){
				window.addEventListener("message", _onIframeMessageReceived, false);
			} else if (window.attachEvent){
				window.attachEvent("message", _onIframeMessageReceived);
			}

			_defineVEConstants();
		}
		_initialized = true;

		_options = initOptions || {};

		if(["EXTERNAL","INTERNAL"].indexOf(_options.mode)!=-1){
			_mode = _options.mode;
		}

		if(_options.wapp===true){
			_mode = "INTERNAL";
		} else if(_options.ve===true){
			_mode = "EXTERNAL";
		}

		if((_options.tracking===true)&&(_mode = "INTERNAL")){
			enableTracker();
		}

		_listeners = new Array();
		_wapplisteners = new Array();

		registerCallback("onConnect", function(origin){

			//Communication stablished
			// _print(_originId + ": Communication stablished with: " + origin);

			if(_mode==="EXTERNAL"){
				_afterConnectExternal(origin);
			}

			if((_options)&&(typeof _options.callback === "function")){
				_options.callback(origin);
			}
		});

		_initHelloExchange();
	};


	// Messages

	function IframeMessage(type,data,destination,destinationId){
		this.IframeMessage = true;
		this.mode = _mode;
		this.type = type || _mode;
		this.data = data || {};
		this.origin = _origin;
		this.originId = _originId;
		this.destination = destination || "*";
		if(destinationId){
			this.destinationId = destinationId;
		}
	};

	var _createMessage = function(type,data,destination,destinationId){
		var iframeMessage = new IframeMessage(type,data,destination,destinationId);
		return JSON.stringify(iframeMessage);
	};

	var _validateWrapperedIframeMessage = function(wrapperedIframeMessage){
		if((typeof wrapperedIframeMessage != "object")||(typeof wrapperedIframeMessage.data != "string")){
			return false;
		}
		return _validateIframeMessage(wrapperedIframeMessage.data);
	};

	var _validateIframeMessage = function(iframeMessage){
		try {
			var iframeMessage = JSON.parse(iframeMessage);
			if((iframeMessage.IframeMessage!==true)||(VALID_TYPES.indexOf(iframeMessage.type)==-1)){
				return false;
			}
		} catch (e){
			return false;
		}

		return true;
	};


	// Events and callbacks

	var registerCallback = function(listenedEvent,callback){
		if(callback){
			_listeners[listenedEvent] = callback;
		}
	};

	var unRegisterCallback = function(listenedEvent){
		if((listenedEvent in _listeners)){
			_listeners[listenedEvent] = null;
		}
	};


	// Iframe communication methods

	var sendMessage = function(iframeMessage,iframeId){
		if(!_connected){
			return "Not connected";
		}

		return _sendMessage(iframeMessage,iframeId);
	};

	var _sendMessage = function(iframeMessage,iframeId){
		if(!_validateIframeMessage(iframeMessage)){
			return "Invalid message";
		}

		switch(_mode){
			case "EXTERNAL":
				return _sendInternalMessage(iframeMessage,iframeId);
			case "INTERNAL":
				return _sendExternalMessage(iframeMessage);
			default:
				return;
		}
	};

	var _sendExternalMessage = function(iframeMessage) {
		window.parent.postMessage(iframeMessage,'*');
	};

	var _sendInternalMessage = function(iframeMessage,iframeId){
		if(typeof iframeId == "undefined"){
			_broadcastInternalMessage(iframeMessage);
		} else {
			if(typeof iframeId === "string"){
				var iframe = document.getElementById(iframeId);
				_sendMessageToIframe(iframeMessage,iframe);
			} else if((iframeId instanceof Array)&&(iframeId.length > 0)){
				for(var i=0; i<iframeId.length; i++){
					if(typeof iframeId[i] == "string"){
						var iframe = document.getElementById(iframeId[i]);
						_sendMessageToIframe(iframeMessage,iframe);
					}
				}
			}
		}
	};

	var _broadcastInternalMessage = function(iframeMessage){
		var allVEIframes = document.querySelectorAll("iframe");
		for(var i=0; i<allVEIframes.length; i++){
			_sendMessageToIframe(iframeMessage,allVEIframes[i]);
		}
	};

	var _sendMessageToIframe = function(iframeMessage,iframe){
		if((iframe)&&(iframe.contentWindow)){
			iframe.contentWindow.postMessage(iframeMessage,'*');
		}
	};

	var _onIframeMessageReceived = function(wrapperedIframeMessage){

		if(_validateWrapperedIframeMessage(wrapperedIframeMessage)){

			var iframeMessage = JSON.parse(wrapperedIframeMessage.data);

			if((iframeMessage.destination!=_origin)&&(iframeMessage.destination!=="*")){
				return;
			}

			if((typeof iframeMessage.destinationId != "undefined")&&(iframeMessage.destinationId != _originId)){
				return;
			}

			//Do not process own messages
			if((iframeMessage.origin===_origin)&&(iframeMessage.originId===_originId)){
				return false;
			}

			switch(iframeMessage.type) {
				case "PROTOCOL":
					return _processProtocolMessage(iframeMessage);
				case "VE":
					return _processVEMessage(iframeMessage);
				case "WAPP":
					return _processWAPPMessage(iframeMessage);
				default:
					return;
			}
		}
	};

	var _generateOriginId = function(){
		var timestamp = ((new Date()).getTime()).toString();
		var random = (parseInt(Math.random()*1000000)).toString();
		return parseInt(timestamp.substr(timestamp.length-7,timestamp.length-1) + random);
	};


	///////////////
	// PROTOCOL
	//////////////

	var _helloAttempts;
	var MAX_HELLO_ATTEMPTS = 40;
	var _helloTimeout;

	var _initHelloExchange = function(){
		registerCallback("stopHelloExchange", function(){
			if(_helloTimeout){
				clearTimeout(_helloTimeout);
			}
		});

		_helloAttempts = 0;
		_helloTimeout = setInterval(function(){
			_sayHello();
		},1250);

		_sayHello();
	};

	var _sayHello = function(){
		var helloMessage = _createProtocolMessage("onIframeMessengerHello");
		_sendMessage(helloMessage);
		_helloAttempts++;
		if((_helloAttempts>=MAX_HELLO_ATTEMPTS)&&(_helloTimeout)){
			clearTimeout(_helloTimeout);
		}
	};

	var _createProtocolMessage = function(protocolMessage,destination,destinationId){
		var data = {};
		data.message = protocolMessage;
		return _createMessage("PROTOCOL",data,destination,destinationId);
	};

	var _processProtocolMessage = function(protocolMessage){
		if((protocolMessage.data)&&(protocolMessage.data.message === "onIframeMessengerHello")){
			if(!_connected){
				_connected = true;
				if(typeof _listeners["stopHelloExchange"] == "function"){
					_listeners["stopHelloExchange"]();
				}
				if(typeof _listeners["onConnect"] == "function"){
					_listeners["onConnect"](protocolMessage.origin);
				}
			}
		}
	};

	///////////////
	// VE Messages
	//////////////

	var _createVEMessage = function(VEevent,params,origin,destination,destinationId){
		var data = {};
		data.VEevent = VEevent;
		data.params = params;
		return _createMessage("VE",data,destination,destinationId);
	};

	var _defineVEConstants = function(){
		VISH.Constant = VISH.Constant || {};
		VISH.Constant.Event = VISH.Constant.Event || {};
		VISH.Constant.Event.onSendIframeMessage = "onSendIframeMessage";
		VISH.Constant.Event.onGoToSlide = "onGoToSlide";
		VISH.Constant.Event.onEnterSlide = "onEnterSlide";
		VISH.Constant.Event.onPlayVideo = "onPlayVideo";
		VISH.Constant.Event.onPauseVideo = "onPauseVideo";
		VISH.Constant.Event.onSeekVideo = "onSeekVideo";
		VISH.Constant.Event.onPlayAudio = "onPlayAudio";
		VISH.Constant.Event.onPauseAudio = "onPauseAudio";
		VISH.Constant.Event.onSeekAudio = "onSeekAudio";
		VISH.Constant.Event.onSubslideOpen = "onSubslideOpen";
		VISH.Constant.Event.onSubslideClosed = "onSubslideClosed";
		VISH.Constant.Event.onAnswerQuiz = "onAnswerQuiz";
		VISH.Constant.Event.onSetSlave = "onSetSlave";
		VISH.Constant.Event.allowExitWithoutConfirmation = "allowExitWithoutConfirmation";
		VISH.Constant.Event.exit = "exit";
		VISH.Constant.Event.onSelectedSlides = "onSelectedSlides";
		VISH.Constant.Event.onVEFocusChange = "onVEFocusChange";
		VISH.Constant.Event.onTrackedAction = "onTrackedAction";
	};

	var _afterConnectExternal = function(origin){
		if(_options){
			if(_options.preventDefault===true){
				_sendPreventDefaults(true,origin);
			}
		}
	};

	var _sendPreventDefaults = function(preventDefaults,destination){
		var preventDefaultVEMessage;
		if(preventDefaults===true){
			preventDefaultVEMessage = _createProtocolMessage("enablePreventDefault");
		} else {
			preventDefaultVEMessage = _createProtocolMessage("disablePreventDefault");
		}
		sendMessage(preventDefaultVEMessage);
	};

	var _processVEMessage = function(VEMessage){

		var data = VEMessage.data;

		//"onMessage" callback
		if(_listeners["onMessage"]){
			_listeners["onMessage"](JSON.stringify(VEMessage),VEMessage.origin);
		}

		var callback = _listeners[data.VEevent];
		if(!callback){
			//Nobody listen to this event
			return;
		}

		switch(data.VEevent){
			case VISH.Constant.Event.onGoToSlide:
				if(data.params){
					callback(data.params.slideNumber,VEMessage.origin);
				}
				break;
			case VISH.Constant.Event.onPlayVideo:
				if(data.params){
					callback(data.params.videoId,
							 data.params.currentTime,data.params.slideNumber,
							 VEMessage.origin);
				}
				break;
			case VISH.Constant.Event.onPauseVideo:
				if(data.params){
					callback(data.params.videoId,
							 data.params.currentTime,data.params.slideNumber,
							 VEMessage.origin);
				}
				break;
			case VISH.Constant.Event.onSeekVideo:
				if(data.params){
					callback(data.params.videoId,
							 data.params.currentTime,data.params.slideNumber,
							 VEMessage.origin);
				}
				break;
			case VISH.Constant.Event.onSubslideOpen:
				if(data.params){
					callback(data.params.slideId,
							 VEMessage.origin);
				}
				break;
			case VISH.Constant.Event.onSubslideClosed:
				if(data.params){
					callback(data.params.slideId,
							 VEMessage.origin);
				}
				break;
			case VISH.Constant.Event.onVEFocusChange:
				if(data.params){
					callback(data.params.focus,VEMessage.origin);
				}
				break;
			default:
				_print("VISH.Messenger.Proceesor Error: Unrecognized event: " + data.VEevent);
				break;
		}
	};

	
	////////////
	// VE API
	///////////	

	var goToSlide = function(slideNumber){
		var params = {};
		params.slideNumber = slideNumber;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onGoToSlide,params);
		sendMessage(VEMessage);
	};

	var playVideo = function(videoId,currentTime,videoSlideNumber){
		var params = {};
		params.videoId = videoId;
		params.currentTime = currentTime;
		params.slideNumber = videoSlideNumber;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onPlayVideo,params);
		sendMessage(VEMessage);
	};

	var pauseVideo = function(videoId,currentTime,videoSlideNumber){
		var params = {};
		params.videoId = videoId;
		params.currentTime = currentTime;
		params.slideNumber = videoSlideNumber;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onPauseVideo,params);
		sendMessage(VEMessage);
	};

	var seekVideo = function(videoId,currentTime,videoSlideNumber){
		var params = {};
		params.videoId = videoId;
		params.currentTime = currentTime;
		params.slideNumber = videoSlideNumber;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onSeekVideo,params);
		sendMessage(VEMessage);
	};

	var openSubslide = function(slideId){
		var params = {};
		params.slideId = slideId;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onSubslideOpen,params);
		sendMessage(VEMessage);
	};

	var closeSubslide = function(slideId){
		var params = {};
		params.slideId = slideId;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onSubslideClosed,params);
		sendMessage(VEMessage);
	};

	var setSlave = function(slave,iframeId){
		var params = {};
		params.slave = slave;
		var VEMessage = _createVEMessage(VISH.Constant.Event.onSetSlave,params);
		sendMessage(VEMessage,iframeId);
	};

	var setMaster = function(master){
		var params = {};
		var allVEIframes = document.querySelectorAll(".vishEditorIframe");
		for(var i=0; i<allVEIframes.length; i++){
			if(allVEIframes[i].id!==master){
				params.slave = true;
			} else {
				params.slave = false;
			}
			var iframeId = allVEIframes[i].id;
			var VEMessage = _createVEMessage(VISH.Constant.Event.onSetSlave,params);
			sendMessage(VEMessage,iframeId);
		}
	};

	var allowExitWithoutConfirmation = function(){
		var params = {};
		var VEMessage = _createVEMessage(VISH.Constant.Event.allowExitWithoutConfirmation,params);
		sendMessage(VEMessage);
	};


	///////////////
	// WAPP Messages
	//////////////

	var _createWAPPMessage = function(method,params,origin,destination,destinationId){
		var data = {};
		data.method = method;
		data.params = params;
		return _createMessage("WAPP",data,destination,destinationId);
	};

	var _processWAPPMessage = function(WAPPMessage){
		var data = WAPPMessage.data;

		if(typeof _wapplisteners[data.method] == "function"){
			_wapplisteners[data.method](data.params);
			_wapplisteners[data.method] = undefined;
		};
	};

	///////////////
	// WAPP API
	//////////////

	var getUser = function(callback){
		_callWAPPMethod("getUser",{},callback);
	};

	var getAuthToken = function(callback){
		_callWAPPMethod("getAuthToken",{},callback);
	};

	var setScore = function(score,callback){
		_callWAPPMethod("setScore",score,callback);
	};

	var setProgress = function(progress,callback){
		_callWAPPMethod("setProgress",progress,callback);
	};

	var setSuccessStatus = function(status,callback){
		_callWAPPMethod("setSuccessStatus",status,callback);
	};

	var setCompletionStatus = function(status,callback){
		_callWAPPMethod("setCompletionStatus",status,callback);
	};

	var _callWAPPMethod = function(methodName,params,callback){
		if(typeof params == "undefined"){
			params = {};
		}

		_wapplisteners[methodName] = callback;
		var WAPPMessage = _createWAPPMessage(methodName,params);
		sendMessage(WAPPMessage);
	};

	///////////////
	// Tracker
	//////////////

	_trackerEnabled = false;
	_trackerEventsLoaded = false;

	var enableTracker = function(){
		_trackerEnabled = true;
		_loadTrackerEvents();
	};

	var _loadTrackerEvents = function(){
		if(_trackerEventsLoaded){
			return;
		}
		_trackerEventsLoaded = true;

		$(document).bind('click', function(event){
			var params = {};
			params["x"] = event.clientX;
			params["y"] = event.clientY;

			if(event.target){
				if(event.target.tagName){
					params["tagName"] = event.target.tagName
				}
				if(event.target.id){
					params["id"] = event.target.id
				}
			}

			notifyTrackerAction("click",params);
		});

		$(document).bind('keydown', function(event){
			var params = {};
			params["keyCode"] = event.keyCode;
			notifyTrackerAction("keydown",params);
		});
		
	};

	var notifyTrackerAction = function(action,actionParams){
		var data = {};
		data.action = action;
		data.params = actionParams;
		var WAPPMessage = _createWAPPMessage("notifyTrackerAction",data);
		sendMessage(WAPPMessage);
	};


	///////////
	// Utils
	///////////

	var _print = function(objectToPrint){
		if((console)&&(console.log)){
			console.log(objectToPrint);
		}
	};

	var isConnected = function(){
		return _connected;
	};


	return {
			init 							: init,

			//VE methods
			registerCallback 				: registerCallback,
			unRegisterCallback 				: unRegisterCallback,
			sendMessage						: sendMessage,
			setSlave						: setSlave,
			setMaster						: setMaster,
			allowExitWithoutConfirmation 	: allowExitWithoutConfirmation,
			goToSlide 						: goToSlide,
			playVideo 						: playVideo,
			pauseVideo 						: pauseVideo,
			seekVideo 						: seekVideo,
			openSubslide					: openSubslide,
			closeSubslide					: closeSubslide,

			//WAPP methods
			getUser							: getUser,
			setScore						: setScore,
			setProgress						: setProgress,
			setSuccessStatus				: setSuccessStatus,
			setCompletionStatus				: setCompletionStatus,
			getAuthToken					: getAuthToken,

			//Tracking System
			enableTracker					: enableTracker,
			notifyTrackerAction				: notifyTrackerAction,

			//Utils
			isConnected						: isConnected
	};

}) (VISH);