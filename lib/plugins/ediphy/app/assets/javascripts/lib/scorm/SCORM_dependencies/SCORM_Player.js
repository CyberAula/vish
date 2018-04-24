/*
 * SCORM Player
 * Requires JQuery
 * @version 1.2
 */
/* eslint-disable */
function SCORM_Player(options) {

    let status = {};
    let currentLo = 1;
    let totalLos = 1;

    let defaults = {
        version: "1.2",
        debug: true,
        SCORM_VERSION: undefined,
        SCORM_PACKAGE_URL: undefined,
        SCORM_RESOURCE_URLS: undefined,
        NAVBAR: undefined,
        LMS_API: undefined,
        LOCALE: undefined,
        IFRAME_API: undefined,
    };

    // Settings merged with defaults and extended options */
    let settings = Object.assign({}, defaults, options);

    debug("SCORM player loading with settings:");
    debug(settings);

    if(typeof settings.SCORM_PACKAGE_URL === "undefined") {
        settings.SCORM_PACKAGE_URL = getScormPackageUrlFromUrl();
    }

    if(typeof settings.SCORM_PACKAGE_URL === "string") {
        settings.SCORM_PACKAGE_URL = checkUrlProtocol(settings.SCORM_PACKAGE_URL);
    }

    if(settings.SCORM_RESOURCE_URLS instanceof Array) {
        for(let i = 0; i < settings.SCORM_RESOURCE_URLS.length; i++) {
            if(typeof settings.SCORM_RESOURCE_URLS[i] === "string") {
                settings.SCORM_RESOURCE_URLS[i] = checkUrlProtocol(settings.SCORM_RESOURCE_URLS[i]);
            } else {
                settings.SCORM_RESOURCE_URLS.splice(i, 1);
            }
        }
    } else {
        settings.SCORM_RESOURCE_URLS = [];
    }

    if(settings.SCORM_RESOURCE_URLS.length < 1) {
        settings.SCORM_RESOURCE_URLS = [settings.SCORM_PACKAGE_URL];
    }

    totalLos = settings.SCORM_RESOURCE_URLS.length;

    if(typeof settings.NAVBAR === "undefined") {
        settings.NAVBAR = (settings.SCORM_RESOURCE_URLS.length > 1);
    }

    if(!isValidLanguage(settings.LOCALE)) {
        let uL = getUserLanguage();
        if(isValidLanguage(uL)) {
            settings.LOCALE = uL;
        } else {
            settings.LOCALE = "en"; // Default language
        }
    }

    if((typeof settings.LMS_API !== "undefined") && (typeof settings.IFRAME_API !== "undefined")) {
        setSCORMGateway();
    }

    adaptContentWrapper();

    // Public

    this.loadScormContent = function(callback, currentIframe) {
        $(document).ready(function() {
            let timeoutToLoadScormContent = 500;

            if((typeof settings.IFRAME_API !== "undefined") && (isIframe())) {
                settings.IFRAME_API.init(
                    {
                        mode: "INTERNAL",
                        callback: function(origin) {
                            debug("WAPP connnected with " + origin);
                            settings.IFRAME_API.getUser(function(user) {
                                if(typeof user === "object") {
                                    if((typeof user.username === "string") && (typeof settings.LMS_API !== "undefined")) {
                                        if(typeof settings.LMS_API.setCMILMSValue === "function") {
                                            settings.LMS_API.setCMILMSValue("learner_name", user.username);
                                        }
                                    }
                                    if((typeof user.language === "string") && (isValidLanguage(user.language))) {
                                        settings.LOCALE = user.language;
                                    }
                                }
                                loadScormContentOnIframe(callback);
                            });
                        },
                    }
                );
            } else {
                timeoutToLoadScormContent = 0;
            }

            // Ensure that SCORM content is loaded although Iframe_API connection fails
            setTimeout(function() {
                loadScormContentOnIframe(callback, currentIframe);
            }, timeoutToLoadScormContent);
        });
    };

    this.getSettings = function() {
        return settings;
    };

    this.updateSettings = function(key, value) {
        if(typeof key === "string") {
            settings[key] = value;
        }
    };

    // Private

    function loadScormContentOnIframe(callback, currentIframe ) {
        if($("#scormcontent").length > 0) {
            // Already loaded
            return;
        }
        let iframe = currentIframe || $('<iframe id="scormcontent" style="width:100%; height:100%; border: none" webkitAllowFullScreen="true" allowfullscreen="true" mozallowfullscreen="true"></iframe>');
        if(settings.NAVBAR === true) {
            $(iframe).css("height", "94%");
            $("body").append(createNavBar());
            loadNavBarEvents();
            updateNavBar();
        }
        if (!currentIframe) {
            $("body").prepend(iframe);
        }

        loadCurrentLo(callback);
    }

    function loadCurrentLo(callback) {
        document.getElementById('scormcontent').onload = function() {
            if(typeof $("#scormcontent").attr("src") !== "undefined") {
                adaptContent();
                debug("SCORM content loaded");
                if(typeof callback === "function") {
                    callback();
                }
            }
        };

        if(typeof settings.SCORM_RESOURCE_URLS[currentLo - 1] === "string") {
            $("#scormcontent").attr("src", settings.SCORM_RESOURCE_URLS[currentLo - 1]);
        }

        updateNavBar();
    }

    function createNavBar() {
        let navbar = $('<div id="scormnavbar"><div id="scormnavbar_prev"></div><div id="scormnavbar_title"></div><div id="scormnavbar_next"></div></div>');

        let prevText = getTransFromLocales(SCORM_PLAYER_LOCALES, "i.prevText");
        let nextText = getTransFromLocales(SCORM_PLAYER_LOCALES, "i.nextText");

        $(navbar).find("#scormnavbar_prev").html(prevText);
        $(navbar).find("#scormnavbar_next").html(nextText);

        $(navbar).css("position", "absolute");
        $(navbar).css("bottom", "0px");
        $(navbar).css("height", "6%");
        $(navbar).css("width", "100%");
        $(navbar).css("border-top", "1px solid black");

        $(navbar).find("#scormnavbar_title, #scormnavbar_prev, #scormnavbar_next").css("display", "inline-block");
        $(navbar).find("#scormnavbar_title, #scormnavbar_prev, #scormnavbar_next").css("position", "absolute");
        $(navbar).find("#scormnavbar_title, #scormnavbar_prev, #scormnavbar_next").css("top", "30%");
        $(navbar).find("#scormnavbar_title, #scormnavbar_prev, #scormnavbar_next").css("user-select", "none");

        $(navbar).find("#scormnavbar_prev, #scormnavbar_next").css("cursor", "pointer");
        $(navbar).find("#scormnavbar_prev, #scormnavbar_next").css("z-index", 2);
        $(navbar).find("#scormnavbar_prev").css("left", "1.5%");
        $(navbar).find("#scormnavbar_next").css("right", "1.5%");

        $(navbar).find("#scormnavbar_title").css("width", "100%");
        $(navbar).find("#scormnavbar_title").css("text-align", "center");
        $(navbar).find("#scormnavbar_title").css("cursor", "default");

        return navbar;
    }

    function loadNavBarEvents() {
        $("#scormnavbar_prev").on("click", function() {
            if(currentLo > 1) {
                currentLo = currentLo - 1;
                loadCurrentLo();
            }
        });
        $("#scormnavbar_next").on("click", function() {
            if(totalLos > currentLo) {
                currentLo = currentLo + 1;
                loadCurrentLo();
            }
        });
    }

    function updateNavBar() {
        if(settings.NAVBAR !== true) {
            return;
        }
        $("#scormnavbar_title").html(currentLo + '/' + totalLos);
        if(currentLo > 1) {
            $("#scormnavbar_prev").css("visibility", "visible");
        } else {
            $("#scormnavbar_prev").css("visibility", "hidden");
        }
        if(totalLos > currentLo) {
            $("#scormnavbar_next").css("visibility", "visible");
        } else {
            $("#scormnavbar_next").css("visibility", "hidden");
        }
    }

    function isIframe() {
        let _isInIframe = ((window.location != window.parent.location));
        return _isInIframe;
    }

    function getScormPackageUrlFromUrl() {
        let urlParams = readURLparams();
        if(typeof urlParams.url === "string") {
            return urlParams.url;
        }
        return undefined;

    }

    function readURLparams() {
        let params = {};
        try {
            let location = window.location;
            if(typeof location === "undefined") {
                return params;
            }
            let URLparams = location.search;
            URLparams = URLparams.substr(1, URLparams.length - 1);
            let URLparamsArray = URLparams.split("&");
            for(let i = 0; i < URLparamsArray.length; i++) {
                try {
                    let paramData = URLparamsArray[i].split("=");
                    if(typeof paramData[1] === "string") {
                        params[paramData[0]] = paramData[1];
                    }
                } catch(e) {}
            }
        } catch (e) {}

        return params;
    }

    function getProtocol() {
        let protocol;
        try {
            protocol = document.location.protocol;
        } catch(e) {}
        if(typeof protocol === "string") {
            let protocolMatch = protocol.match(/[\w]+/);
            if((protocolMatch instanceof Array) && (typeof protocolMatch[0] === "string")) {
                protocol = protocolMatch[0];
            } else {
                protocol = undefined;
            }
        }
        if(typeof protocol !== "string") {
            protocol = "unknown";
        }
        return protocol;
    }

    function checkUrlProtocol(url) {
        if(typeof url === "string") {
            let protocolMatch = (url).match(/^https?:\/\//);
            if((protocolMatch instanceof Array) && (protocolMatch.length === 1)) {
                let urlProtocol = protocolMatch[0].replace(":\/\/", "");
                let documentProtocol = getProtocol();
                if(urlProtocol != documentProtocol) {
                    switch(documentProtocol) {
                    case "https":
                        // Try to load HTTP url over HTTPs
                        url = "https" + url.replace(urlProtocol, ""); // replace first
                        break;
                    case "http":
                        // Try to load HTTPs url over HTTP
                        // Do nothing
                        break;
                    default:
                        // Document is not loaded over HTTP or HTTPs
                        break;
                    }
                }
            }
        }
        return url;
    }

    function getUserLanguage() {
        // Locale in URL
        let urlParams = readURLparams();
        if(isValidLanguage(urlParams.locale)) {
            return urlParams.locale;
        }
        // Browser language
        let browserLang = (navigator.language || navigator.userLanguage);
        if(isValidLanguage(browserLang)) {
            return browserLang;
        }
        return undefined;
    }

    function isValidLanguage(language) {
        return ((typeof language === "string") && (["en", "es"].indexOf(language) != -1));
    }

    function getTransFromLocales(locales, s, params) {
        // First language
        if((typeof locales[settings.LOCALE] !== "undefined") && (typeof locales[settings.LOCALE][s] === "string")) {
            return getTransWithParams(locales[settings.LOCALE][s], params);
        }

        // Default language
        if((settings.LOCALE != "en") && (typeof locales.en !== "undefined") && (typeof locales.en[s] === "string")) {
            return getTransWithParams(locales.en[s], params);
        }

        return undefined;
    }

    /*
	 * Replace params (if they are provided) in the translations keys. Example:
	 * // "i.dtest"	: "Download #{name}",
	 * // getTrans("i.dtest", {name: "SCORM package"}) -> "Download SCORM package"
	 */
    function getTransWithParams(trans, params) {
        if(typeof params !== "object") {
            return trans;
        }

        for(let key in params) {
            let stringToReplace = "#{" + key + "}";
            if(trans.indexOf(stringToReplace) != -1) {
                trans = trans.replaceAll(stringToReplace, params[key]);
            }
        }

        return trans;
    }

    var SCORM_PLAYER_LOCALES = {
        "en": {
            "i.prevText": "Previous",
            "i.nextText": "Next",
        },
        "es": {
            "i.prevText": "Anterior",
            "i.nextText": "Siguiente",
        },
    };

    function setSCORMGateway() {
        if((typeof settings.LMS_API !== "object") || (typeof settings.LMS_API.addListener !== "function")) {
            return;
        }

        if(settings.SCORM_VERSION === "1.2") {
            settings.LMS_API.addListener("cmi.core.lesson_status", function(value) {
                if(settings.IFRAME_API.isConnected()) {
                    // Completion status and success status are not considered in SCORM 1.2, but can be inferred from lesson_status
                    // lesson_status = "|passed|completed|failed|incomplete|browsed|not attempted|unknown|"
                    // completion_status = "|completed|incomplete|not attempted|unknown|"
                    // success_status = "|passed|failed|unknown|"
                    let completionValue;
                    let successValue;

                    switch(value) {
                    case "passed":
                        completionValue = "completed";
                        successValue = value;
                        break;
                    case "failed":
                        successValue = value;
                        break;
                    case "completed":
                    case "incomplete":
                    case "not attempted":
                        completionValue = value;
                        break;
                    case "browsed":
                        completionValue = "not attempted";
                        break;
                    case "unknown":
                        completionValue = value;
                        successValue = value;
                        break;
                    }

                    if((typeof completionValue === "string") && (completionValue != status.completionStatus)) {
                        if(status.completionStatus != "completed") {
                            // Do not allow to undo "completed" lesson_status.
                            settings.IFRAME_API.setCompletionStatus(completionValue);
                            status.completionStatus = completionValue;
                        }
                    }
                    if((typeof successValue === "string") && (successValue != status.successStatus)) {
                        if(status.completionStatus != "passed") {
                            settings.IFRAME_API.setSuccessStatus(successValue);
                            status.successStatus = successValue;
                        }
                    }
                }
            });

            settings.LMS_API.addListener("cmi.score.scaled", function(value) {
                if(settings.IFRAME_API.isConnected()) {
                    settings.IFRAME_API.setScore(value * 100);
                }
            });

        } else if((settings.SCORM_VERSION === "2004") || (typeof settings.SCORM_VERSION !== "string")) {
            settings.LMS_API.addListener("cmi.progress_measure", function(value) {
                if(settings.IFRAME_API.isConnected()) {
                    settings.IFRAME_API.setProgress(value * 100);
                }
            });

            settings.LMS_API.addListener("cmi.completion_status", function(value) {
                if(settings.IFRAME_API.isConnected()) {
                    settings.IFRAME_API.setCompletionStatus(value);
                }
            });

            settings.LMS_API.addListener("cmi.score.scaled", function(value) {
                if(settings.IFRAME_API.isConnected()) {
                    settings.IFRAME_API.setScore(value * 100);
                }
            });

            settings.LMS_API.addListener("cmi.success_status", function(value) {
                if(settings.IFRAME_API.isConnected()) {
                    settings.IFRAME_API.setSuccessStatus(value);
                }
            });
        }
    }

    function adaptContentWrapper() {
        let contentWrappers = $("html,body");
        $(contentWrappers).attr("style", "margin: 0px !important; padding: 0px !important; overflow: hidden !important; height:100%");
    }

    function adaptContent() {

        var checkElement = function(el) {
            let iframes = $(el).find("iframe");
            $(iframes).each(function(index, iframe) {
                iframe.onload = function() {
                    checkElement($(iframe).contents());
                };
            });

            let frames = $(el).find("frame");
            $(frames).each(function(index, frame) {
                frame.onload = function() {
                    checkElement(frame.contentDocument);
                };
            });

            _checkElement(el);
        };

        var _checkElement = function(el) {
            let objects = $(el).find("object");
            $(objects).each(function(index, object) {
                _checkObjectTag(object);
            });

            let embeds = $(el).find("embed");
            $(embeds).each(function(index, embed) {
                _checkEmbedTag(embed);
            });
        };

        var _checkObjectTag = function(objectTag) {
            let _isFlashObject = false;
            let _wmodeUpdated = false;

            // Look for wmode param
            let wmodeParam = $(objectTag).find("param[name='wmode']")[0];
            if(typeof wmodeParam !== "undefined") {
                let wmodeParamValue = $(wmodeParam).attr("value");
                if(wmodeParamValue != "opaque") {
                    $(wmodeParam).attr("value", "opaque");
                }
            } else {
                $(objectTag).append('<param name="wmode" value="opaque">');
            }

            // Look for wmode in the embeds contained in the object
            let embeds = $(objectTag).find("embed");
            $(embeds).each(function(index, embed) {
                if($(embed).attr("type") == "application/x-shockwave-flash") {
                    _isFlashObject = true;
                }
                if($(embed).attr("wmode").toLowerCase() != "opaque") {
                    _wmodeUpdated = true;
                }
                _checkEmbedTag(embed);
            });

            if(_isFlashObject && _wmodeUpdated) {
                // Reload object
                // objectTag.innerHTML = objectTag.innerHTML
                $(objectTag).hide().show();
            }
        };

        var _checkEmbedTag = function(embedTag) {
            // Set wmode param
            $(embedTag).attr("wmode", "opaque");
        };

        // adapt content
        checkElement(document);
    }

    function debug(msg) {
        if((settings.debug) && (console) && (console.log)) {
            if(typeof msg !== "object") {
                console.log("SCORM_PLAYER[v" + settings.version + "]: " + msg);
            } else {
                console.log("SCORM_PLAYER[v" + settings.version + "]: " + "Object printed below");
                console.log(msg);
            }
        }
    }
}
/* eslint-enable */
