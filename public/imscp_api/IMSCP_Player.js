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
		IMSCP_VERSION: undefined,
		IMSCP_PACKAGE_URL: undefined,
		VISH_IFRAME_API: undefined
	};

	// Settings merged with defaults and extended options */
	var settings = $.extend(defaults, options);

	debug("IMS CP player loading with settings:");
	debug(settings);

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

		var iframe = $('<iframe id="imscpcontent" style="width:100%; height:100%; border: none" webkitAllowFullScreen="true" allowfullscreen="true" mozallowfullscreen="true"></iframe>');
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