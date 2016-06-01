/*
 * IMS CP Player
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

function IMSCP_Player(options){

	var defaults = {
		version: "1.0",
		debug: true,
		navigation: false,
		language: undefined,
		IMSCP_VERSION: undefined,
		IMSCP_PACKAGE_URL: undefined,
		IMSCP_PACKAGE_NAVIGATION: undefined,
		VISH_IFRAME_API: undefined
	};

	// Settings merged with defaults and extended options */
	var settings = $.extend(defaults, options);

	debug("IMS CP player loading with settings:");
	debug(settings);

	if(!isValidLanguage(settings.language)){
		var uL = getUserLanguage();
		if(isValidLanguage(uL)){
			settings.language = uL;
		} else {
			settings.language = "en"; //Default language
		}
	}

	if((settings.IMSCP_PACKAGE_NAVIGATION instanceof Array)&&(settings.IMSCP_PACKAGE_NAVIGATION.length > 1)){
		settings.navigation = true;
	}

	if(typeof settings.IMSCP_PACKAGE_URL == "undefined"){
		settings.IMSCP_PACKAGE_URL = getIMSCPPackageUrlFromUrl();
	}

	if(typeof settings.IMSCP_PACKAGE_URL == "string"){
		settings.IMSCP_PACKAGE_URL = checkUrlProtocol(settings.IMSCP_PACKAGE_URL);
	}

	adaptContentWrapper();


    //Public

	this.loadIMSCPContent = function(callback){
		$(document).ready(function(){
			var timeoutToloadIMSCPContent = 0;
			setTimeout(function(){
				loadIMSCPContentOnIframe(callback);
			},timeoutToloadIMSCPContent);
		});
	};

	this.getSettings = function(){
		return settings;
	};

	this.updateSettings = function(key,value){
		if(typeof key == "string"){
			settings[key] = value;
		}
	};


	//Private

	function loadIMSCPContentOnIframe(callback){
		if($("#imscpcontent").length > 0){
			//Already loaded
			return;
		}

		if(settings.navigation){
			//Add navigation panel
			var navPanel = $('<div id="imscpnav" status="maximized" style="width: 20%; height:100%; border: 1px solid black; box-sizing: border-box; float: left; font-family: Arial, Helvetica, sans-serif; background: #f3f3f3;"><header style="position: relative; width: 90%; height: 10%; padding: 5%; background: #ccc;  font-size: 1.2rem; cursor: default;"></header><ul style="padding: 5% 5% 5% 5%; overflow-y: auto; height: 80%;"></ul></div>');
			
			//Nav header
			$(navPanel).find("header").append("<p>" + getTransFromLocales(IMSCP_PLAYER_LOCALES,"i.header_title") + "<p>");
			$(navPanel).find("header").append('<div id="toggle_imscpnav" style="position: absolute; top: 2%; right: 1%; cursor: pointer; padding: 2%; border: 1px solid black; background: #f3f3f3; text-align: center;"><<div>');

			//Nav Items
			var navElements = settings.IMSCP_PACKAGE_NAVIGATION.length;
			for(var i=0; i<navElements; i++){
				var navElement = settings.IMSCP_PACKAGE_NAVIGATION[i];
				if(typeof navElement["href"] == "string"){
					var title = (typeof navElement["title"] == "string") ? navElement["title"] : "Untitled";
					$(navPanel).find("ul").append('<li style="list-style: none; padding: 5px 0px 5px 0px; cursor: pointer;" href="' + navElement["href"] + '" index="' + i + '">' + title + '</li>');
				}
			}
			$("body").append(navPanel);
			$("div#imscpnav ul li:first").addClass("active");

			//Nav css
			var navStyle="<style> div#imscpnav ul li.active { font-weight: bold }</style>";
			$("head").append(navStyle);

			//Nav events
			//Nav toggle
			$("div#imscpnav div#toggle_imscpnav").on("click",function(event){
				var status = $("div#imscpnav").attr("status");
				if(status=="maximized"){
					//Minimize
					$(this).html(">");
					$("#imscpnav").css("width","2%");
					$("iframe#imscpcontent").css("width","98%");
					$("#imscpnav header").css("background","rgb(243, 243, 243)");
					$("#imscpnav header p").hide();
					$("#imscpnav ul").hide();
					$(this).css("width","90%");
					$(this).css("top","auto");
					$(this).css("right","auto");
					$(this).css("padding","0%");
					$(this).css("border","none");
					$("div#imscpnav").attr("status","minimized");
				} else {
					//Maximimize
					$(this).html("<");
					$("iframe#imscpcontent").css("width","80%");
					$("#imscpnav").css("width","20%");
					$("#imscpnav header").css("background","#ccc");
					$("#imscpnav header p").show();
					$("#imscpnav ul").show();
					$(this).css("width","auto");
					$(this).css("top","2%");
					$(this).css("right","1%");
					$(this).css("padding","2%");
					$(this).css("border","1px solid black");
					$("div#imscpnav").attr("status","maximized");
				}
			});
			
			//Nav items
			$("div#imscpnav ul li").on("click",function(event){
				var href = $(this).attr("href");
				if(typeof href=="string"){
					$("div#imscpnav ul li").removeClass("active");
					$(this).addClass("active");
					$("#imscpcontent").attr("src",href);
				}
			});
		}

		var iframeStyleWithNavigation = "width:80%; height:100%; border: 1px solid black; box-sizing: border-box;";
		var iframeStyleWithoutNavigation = "width:100%; height:100%; border: none";
		var iframe = $('<iframe id="imscpcontent" style="' + (settings.navigation ? iframeStyleWithNavigation : iframeStyleWithoutNavigation) + '" webkitAllowFullScreen="true" allowfullscreen="true" mozallowfullscreen="true"></iframe>');
		$("body").append(iframe);

		document.getElementById('imscpcontent').onload = function(){
			if(typeof $("#imscpcontent").attr("src") != "undefined"){
				adaptContent();
				debug("IMS CP content loaded");
				if(typeof callback == "function"){
					callback();
				}
			}
		};

		if(typeof settings.IMSCP_PACKAGE_URL == "string"){
			$("#imscpcontent").attr("src",settings.IMSCP_PACKAGE_URL);
		}
	};

	function isIframe(){
		var _isInIframe = ((window.location != window.parent.location) ? true : false);
		return _isInIframe;
	};

	function getIMSCPPackageUrlFromUrl(){
		var urlParams = readURLparams();
		if(typeof urlParams["url"] == "string"){
			return urlParams["url"];
		} else {
			return undefined;
		}
	};

	function readURLparams(){
		var params = {};
		try {
			var location = window.location;
			if(typeof location === "undefined"){
				return params;
			}
			var URLparams = location.search;
			URLparams = URLparams.substr(1,URLparams.length-1);
			var URLparamsArray = URLparams.split("&");
			for(var i=0; i<URLparamsArray.length; i++){
				try {
					var paramData = URLparamsArray[i].split("=");
					if(typeof paramData[1] === "string"){
						params[paramData[0]] = paramData[1];
					}
				} catch(e){}
			}
		} catch (e) {}

		return params;
	};

	function getProtocol(){
		var protocol;
		try {
			protocol = document.location.protocol;
		} catch(e){}
		if(typeof protocol == "string"){
			var protocolMatch = protocol.match(/[\w]+/);
			if((protocolMatch instanceof Array)&&(typeof protocolMatch[0] == "string")){
				protocol = protocolMatch[0];
			} else {
				protocol = undefined;
			}
		}
		if(typeof protocol != "string"){
			protocol = "unknown";
		}
		return protocol;
	};

	function checkUrlProtocol(url){
		if(typeof url == "string"){
			var protocolMatch = (url).match(/^https?:\/\//);
			if((protocolMatch instanceof Array)&&(protocolMatch.length === 1)){
				var urlProtocol = protocolMatch[0].replace(":\/\/","");
				var documentProtocol = getProtocol();
				if(urlProtocol != documentProtocol){
					switch(documentProtocol){
						case "https":
							//Try to load HTTP url over HTTPs
							url = "https" + url.replace(urlProtocol,""); //replace first
							break;
						case "http":
							//Try to load HTTPs url over HTTP
							//Do nothing
							break;
						default:
							//Document is not loaded over HTTP or HTTPs
							break;
					}
				}
			}
		}
		return url;
	};

	function getUserLanguage(){
		//Locale in URL
		var urlParams = readURLparams();
		if(isValidLanguage(urlParams["locale"])){
			return urlParams["locale"];
		}
		//Browser language
		var browserLang = (navigator.language || navigator.userLanguage);
		if(isValidLanguage(browserLang)){
			return browserLang;
		}
		return undefined;
	};

	function isValidLanguage(language){
		return ((typeof language == "string")&&(["en","es"].indexOf(language)!=-1));
	};

	function getTransFromLocales(locales,s,params){
		//First language
		if((typeof locales[settings.language] != "undefined")&&(typeof locales[settings.language][s] == "string")) {
			return getTransWithParams(locales[settings.language][s],params);
		}

		//Default language
		if((_language != "en")&&(typeof locales["en"] != "undefined")&&(typeof locales["en"][s] == "string")){
			return getTransWithParams(locales["en"][s],params);
		}

		return undefined;
	};

	var IMSCP_PLAYER_LOCALES = {
		"en": {
			"i.header_title": "Navigation"
		},
		"es": {
			"i.header_title": "Navegación"
		}
	}

	/*
	 * Replace params (if they are provided) in the translations keys. Example:
	 * // "i.dtest"	: "Download #{name}",
	 * // getTrans("i.dtest", {name: "IMS CP"}) -> "Download IMS CP"
	 */
	function getTransWithParams(trans,params){
		if(typeof params != "object"){
			return trans;
		}

		for(var key in params){
			var stringToReplace = "#{" + key + "}";
			if(trans.indexOf(stringToReplace)!=-1){
				trans = trans.replaceAll(stringToReplace,params[key]);
			}
		};

		return trans;
	};


	function adaptContentWrapper(){
		var contentWrappers = $("html,body");
		$(contentWrappers).attr("style","margin: 0px !important; padding: 0px !important; overflow: hidden !important");
	};

	function adaptContent(){
		
		var checkElement = function(el){
			var iframes = $(el).find("iframe");
			$(iframes).each(function(index,iframe){
				iframe.onload=function(){
					checkElement($(iframe).contents());
				};
			});

			var frames = $(el).find("frame");
			$(frames).each(function(index,frame){
				frame.onload=function(){
					checkElement(frame.contentDocument);
				}
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

		//adapt content
		checkElement(document);
	};

	function debug(msg){
		if((settings.debug)&&(console)&&(console.log)){
			if(typeof msg != "object"){
				console.log("ISMCP_PLAYER[v" + settings.version + "]: " + msg);
			} else {
				console.log("IMSCP_PLAYER[v" + settings.version + "]: " + "Object printed below");
				console.log(msg);
			}
		}
	};
}