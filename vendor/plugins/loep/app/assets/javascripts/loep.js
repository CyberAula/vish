/*
 * LOEP Iframe API
 * http://loep.global.dit.upm.es
 * Provides an API that allows to embed LOEP evaluation forms via iframe
 * @author Aldo Gordillo
 * @version 1.0
 */

var LOEP = LOEP || {};

LOEP.IframeAPI = (function(L,undefined){

  var instance = function(settings){
    var _settings;
    //action: Specifies the action of the API: ['form','representation']. Default is form.
    //domain: LOEP domain
    //app: Name of the Application in LOEP
    //loId: Identifier of the LO to be evaluated
    //evmethod: Evaluation method of the form
    //language: (Optional) Language of the form.
    //ajax: Set to false to disable ajax request. Default is true.
    //token: LOEP Session Token (if not defined, session token will be obtained from tokenURL)
    //tokenURL: URL to request the token (used if token is not specified)
    //containerDOM: container DOM element
    //loadCallback: callback triggered when the evaluation is loaded
    //submitCallback: callback triggered when the evaluation is succesfully submitted
    //errorCallback: callback triggered when an error prevent the iframe to be loaded
    //debug: Print console messages

    this.init = function(settings){
      //Check parameters
      _settings = settings || {};
      
      _settings.action = _settings.action || "form";
      if(["form","representation"].indexOf(_settings.action)===-1){
        return _onError("No valid action.");
      };

      //Check domain
      if(typeof _settings.domain != "string"){
        return _onError("No valid domain.");
      }
      
      try {
        var isLocalFile = (window.location.href.indexOf("file://")===0);
      } catch(e){
        var isLocalFile = false;
      }
      if(!isLocalFile){
        _settings.domain = _settings.domain.replace("http://","").replace("https://","").replace("//","");
        _settings.domain = "//" + _settings.domain;
      } else {
        if (_settings.domain.indexOf("//")===0){
          _settings.domain = _settings.domain.replace("//","");
          _settings.domain = "http://" + _settings.domain;
        }
      }

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
        return _onError("No LOEP session token available");
      }

      var url = _buildEmbededFormURL(token);
      if(typeof url != "string"){
        return _onError("URL could not be built. Incorrect or missing params.");
      }

      var container = $(_settings.containerDOM)[0];
      if(typeof container == "undefined"){
        return _onError("Container not found.");
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
            callback();
          }
        },
        error:function (xhr, ajaxOptions, thrownError){
            callback();
        }
      });
    };

    var _buildEmbededFormURL = function(token){
      var url;

      try {
        url = _settings.domain;

        switch(_settings.action){
          case "form":
            //e.g /evaluations/wbltses/embed?lo_id=Excursion:377
            url += "/evaluations/" + _settings.evmethod + "/embed?lo_id=" + _settings.loId;
            break;
          case "representation":
            //e.g /los/Excursion:377/representation?evmethods=wblts
            url += "/los/" + _settings.loId + "/representation?evmethods=" + _settings.evmethod;
            break;
          default:
            //Do nothing
            return;
        };

        url += "&app_name=" + _settings.app + "&session_token=" + token;
        
        if(_settings.ajax!==false){
          url += "&ajax=true"
        }

        if(typeof _settings.language == "string"){
          url += "&locale=" + _settings.language
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
              load:function(data){
                _print("Form loaded.");
                if(typeof _settings.loadCallback == "function"){
                  _settings.loadCallback();
                }
              },
              error:function(){
                //Not working for iframes loading...
              }
      });
      if(_settings.action=="representation"){
        //Prevent scroll
        $(iframe).attr("overflow","hidden");
        $(iframe).attr("scrolling","no");
      }
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
        }else if(LOEPdata.error===true){
          var errorCode = LOEPdata.error_code;
          _onError(errorCode);
        }
      }
    };

    ///////////
    // Helpers
    ///////////

    var _onError = function(msg){
      if(typeof msg != "string"){
        msg = "";
      }
      errorMsg = "[Error] " + msg;
      if(typeof _settings.errorCallback == "function"){
        _settings.errorCallback(errorMsg);
      }
      return _print(errorMsg);
    };

    var _print = function(msg){
      if((_settings.debug===true)&&(console)&&(console.log)){
        msg = "LOEP: " + msg.toString();
        console.log(msg);
      }
      return msg;
    };

    this.init(settings);
  };

  return {
    instance: instance
  };

})(LOEP);