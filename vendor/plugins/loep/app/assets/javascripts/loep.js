/*
 * LOEP Iframe API
 * Provides an API that allows to embed LOEP evaluation forms via iframe
 * @author Aldo Gordillo
 * @version 1.0
 */

var LOEP = LOEP || {};

LOEP.IframeAPI = (function(L,undefined){

  var _settings;
  //domain: LOEP domain
  //app: Name of the Application in LOEP
  //loId: Identifier of the LO to be evaluated
  //evmethod: Evaluation method of the form
  //language: (Optional) Language of the form.
  //ajax: Set to false to disable ajax request. Default is true.
  //token: LOEP Session Token (if not defined, session token will be obtained from tokenURL)
  //tokenURL: URL to request the token (used if token is not specified)
  //containerDOM: container DOM element
  //successCallback: callback triggered when the evaluation is succesfully loaded
  //submitCallback: callback triggered when the evaluation is succesfully submitted
  //debug: Print console messages


  var init = function(settings){
    _settings = settings || {};
    window.addEventListener("message", _onLOEPMessage, false);

    if(typeof _settings.token == "string"){
      _initWithToken(_settings.token);
    } else {
      _requestLOEPToken(function(token){
        _initWithToken(token);
      });
    }
  };

  var _initWithToken = function(token){
    if(typeof token != "string"){
      return _print("No LOEP session token available");
    }

    var url = _buildEmbededFormURL(token);
    if(typeof url != "string"){
      return _print("URL could not be built. Incorrect or missing params.");
    }

    var container = $(_settings.containerDOM)[0];
    if(typeof container == "undefined"){
      return _print("Container not found.");
    }

    _insertIframe(container,url);
  };

  var _requestLOEPToken = function(callback){
    var urlToRequestToken;
    if(typeof _settings.tokenURL == "string"){
      urlToRequestToken = _settings.tokenURL;
    } else {
      //Default value
      urlToRequestToken = "/loep/session_token.json"
    }

    $.ajax({
      type: "POST",
      url: urlToRequestToken,
      dataType:"json",
      success:function(response){
        if(typeof response == "string"){
          callback(response);
        } else if((typeof response == "object")&&(typeof response["auth_token"]=="string")){
          callback(response["auth_token"]);
        } else {
          callback(true);
        }
      },
      error:function (xhr, ajaxOptions, thrownError){
          callback(false);
      }
    });
  };

  var _buildEmbededFormURL = function(token){
    var url;
    try {
      //http://localhost:8080/evaluations/wbltses/embed?lo_id=Excursion:377&app_name=ViSH&session_token=GO7_TyuktFuErm-QDDPHAk24NtMGC6w8KpXj5RgWD-6pgUBd5Wg_No3CrGCC0PTqxEPJ8sEGuOVpDTvv
      url = "//" + _settings.domain + "/evaluations/" + _settings.evmethod + "/embed?lo_id=" + _settings.loId + "&app_name=" + _settings.app + "&session_token=" + token
      if(_settings.ajax!==false){
        url = url + "&ajax=true"
      }
      if(typeof _settings.language == "string"){
        url = url + "&locale=" + _settings.language
      }
    } catch (e){}
    return url;
  };

  var _insertIframe = function(container,url){
    var iframe=$('<iframe/>', {
            style:'width:100%; height:100%; border:0;',
            iframeborder: '0',
            frameborder: '0',
            src: url,
            load:function(){
              _print("Form loaded successfuly.");
              if(typeof _settings.successCallback == "function"){
                _settings.successCallback();
              }
            }
    });
    $(container).append(iframe);
  };

  var _onLOEPMessage = function(msg){
    if((msg)&&(msg.data)&&(msg.data.type=="LOEPMessage")){
      //LOEP message received
      _print("Message received.");
      var LOEPdata = msg.data;
      if(LOEPdata.success===true){
        //Form submited successfuly. We can close the iframe.
        _print("Form submited successfuly.");
        if(typeof _settings.submitCallback == "function"){
          _settings.submitCallback(LOEPdata);
        }
      }
    }
  };

	///////////
	// Helpers
	///////////

  var _print = function(msg){
    if((_settings.debug===true)&&(console)&&(console.log)){
      msg = "LOEP: " + msg.toString();
      console.log(msg);
    }
    return msg;
  };

  return {
    init: init,
  };

})(LOEP);



