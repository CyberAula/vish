/*
 * Local_API_SCORM_12
 * Mimics LMS Connectivity in Local Mode (i.e. standalone functionality) for SCORM 1.2
 *
 * Modifiyed by GING.
 *
 * Original provided by: 
 *
 * Copyright (c) 2011-2012 Mark Statkus <mark@cybercussion.com>
 * The MIT License
 * https://github.com/cybercussion/SCORM_API
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
function Local_API_SCORM_12(options){
  // Constructor
  "use strict";
  var defaults = {
    version:     "1.1",
    prefix:      "Local_API_SCORM_12",
    errorCode:   0,
    diagnostic:  '',
    initialized: 0,
    terminated:  0,
    debug: true,
    listeners: {},
    CMI: {
      _version:                "3.4",
      comments:                "",
      comments_from_lms:       "",
      launch_data:             "",
      suspend_data:            "",
      core: {
        entry:                 "ab-initio",
        credit:                "credit",
        lesson_status:         "not attempted",
        lesson_mode:           "normal",
        lesson_location:       "",
        student_id:            "100",
        student_name:          "Simulated User",
        student_preference: {
          _children:           "audio,language,speed,text",
          audio:               "0",
          language:            "",
          speed:               "0",
          text:                "0"
        },
        score: {
          _children:           "raw,min,max",
          raw:                 "",
          max:                 "",
          min:                 ""
        },
        total_time:            "0000:00:00.00",
        session_time:          "",
        exit:                  ""
      },
      student_data: {
        _children:           "mastery_score,time_limit_action,max_time_allowed",
        mastery_score:       "50",
        max_time_allowed:    "",
        time_limit_action:   "continue,no message"
      }
    }
  },

  // Settings merged with defaults and extended options */
  settings = deepMergeHash(defaults,options),
  cmi = {},

  /**
   * Completion Status's that are allowed
   */
  lesson_status = "|passed|completed|failed|incomplete|browsed|not attempted|unknown|",


  /**
   Read Only values -
   The hash following could of been much simpler had certain name spaces always been read-only in all areas.
   This would of allowed me to just evaluate the last item and perform that rule globally.  The following are issues -
   id -       This is read-only under adl.data.n.id, and read/write everywhere else
   comments_from_lms are entirely read-only (global rule)
   timestamp is RO for comments from LMS
   */
  read_only = "|_version|completion_threshold|credit|entry|launch_data|learner_id|learner_name|_children|_count|mode|maximum_time_allowed|scaled_passing_score|time_limit_action|total_time|comment|",

  /**
   * Write Only values
   */
  write_only = "|exit|session_time|",
  exit = "|time-out|suspend|logout|normal||",
  errors = {
    0:   "No error",
    101: "General exception",
    102: "General Initialization Failure",
    103: "Already Initialized",
    104: "Content Instance Terminated",
    111: "General Termination Failure",
    112: "Termination Before Initialization",
    113: "Termination After Termination",
    122: "Retrieve Data Before Initialization",
    123: "Retrieve Data After Termination",
    132: "Store Data Before Initialization",
    133: "Store Data After Termination",
    142: "Commit Before Initialization",
    143: "Commit After Termination",
    201: "General Argument Error",
    301: "General Get Failure",
    351: "General Set Failure",
    391: "General Commit Failure",
    401: "Undefined Data Model",
    402: "Unimplemented Data Model Element",
    403: "Data Model Element Value Not Initialized",
    404: "Data Model Element Is Read Only",
    405: "Data Model Element Is Write Only",
    406: "Data Model Element Type Mismatch",
    407: "Data Model Element Value Out Of Range",
    408: "Data Model Dependency Not Established"
  },
  self = this;

  // Private
  /**
   * Throw Vocabulary Error
   * This sets the errorCode and Diagnostic for the key and value attempted.
   * @param k {String} key
   * @param v {String} value
   * @returns {String} 'false'
   */
  function throwVocabError(k,v){
    settings.diganostic = "The " + k + " of " + v + " must be a proper vocabulary element.";
    settings.errorCode = 406;
    return 'false';
  };

  /**
   * Throw Unimplemented Error
   * 402 data model doesn't exist yet.
   * @param key {String}
   * @returns {String} 'false'
   */
  function throwUnimplemented(key){
    settings.errorCode = 402;
    settings.diagnostic = 'The value for key ' + key + ' has not been created yet.';
    return 'false';
  };

  /**
   * Throw Argument Error
   * 201 general argument error.
   * @param key {String}
   * @param argument {String}
   * @returns {String} 'false'
   */
  function throwArgumentError(key,argument){
    settings.errorCode = 201;
    settings.diagnostic = 'The value for key ' + key + ' is not valid.';
    return 'false';
  };

  /**
   * Throw General Set Error
   * This sets the errorCode and Diagnostic for the key and value attempted.
   * Note, messages differ too much for this to be genericized.  I think the SCORM Error, Message and Diagnostic needs to be bundled better.
   * @param k {String} key
   * @param v {String} value
   * @param o {String} optional
   * @returns {String} 'false'
   */
  function throwGeneralSetError(k,v,o){
    settings.errorCode = "351";
    settings.diagnostic = "The " + k + " element must be unique.  The value '" + v + "' has already been set in #" + o;
    return 'false';
  };

  /**
   * Set Data (Private)
   * This covers setting key's values against a object even when there are numbers as objects
   * It will chase thru the Object dot syntax to locate the key you request.  This worked out
   * better than doing a eval(param); which breaks when numbers are introduced.
   * @param key {String} Location of value in object
   * @param val {String} Value of the Key
   * @param obj {Object} Object to search and set
   */
  function setData(key,val,obj){
    //if (!obj) { obj = data;} //outside (non-recursive) call, use "data" as our base object
    var ka = key.split(/\./);
    //split the key by the dots
    if (ka.length < 2) {
      obj[ka[0]] = val;
      //only one part (no dots) in key, just set value
    } else {
      if (!obj[ka[0]]) {
        obj[ka[0]] = {};
      }//create our "new" base obj if it doesn't exist
      obj = obj[ka.shift()];
      //remove the new "base" obj from string array, and hold actual object for recursive call
      setData(ka.join("."),val,obj);
      //join the remaining parts back up with dots, and recursively set data on our new "base" obj
    }
  };

  /**
   * Get Data (Private)
   * This covers getting key's values against a object even when there are numbers as objects
   * It will chase thru the Object dot syntax to locate the key you request.  This worked out
   * better than doing a eval(param); which breaks when numbers are introduced.
   * @param key {String} Location of value in object
   * @param obj {Object} Object to search
   * @returns {String}
   */
  function getData(key,obj){
    //if (!obj) { obj = data;} //outside (non-recursive) call, use "data" as our base object
    //debug(settings.prefix + ": GetData Checking " + key,4);
    var ka = key.split(/\./), v;
    //split the key by the dots
    if(ka.length < 2){
      try {
        //debug(settings.prefix + ":  getData returning -   key:" + ka[0] + " value:" + obj[ka[0]],4);
        return obj[ka[0]];
      } catch (e) {
        throwUnimplemented(key);
        return 'false';
      }
      //only one part (no dots) in key, just set value
    } else {
      v = ka.shift();
      if (obj[v]) {
        return String(getData(ka.join("."),obj[v])); // just in case its undefined
      }
      throwUnimplemented(key);
      return 'false';
      //join the remaining parts back up with dots, and recursively set data on our new "base" obj
    }
  };

  /**
   * CMI Get Value (Private)
   * This covers getting CMI Keys and returning there values.
   * It will have mild error control against the CMI object for Write Only values.
   * @param key {String} Location of value in object
   * @returns {String}
   */
  function cmiGetValue(key){
    var r = "false";
    switch (key) {
      //Write Only
    case "cmi.core.exit":
    case "cmi.core.session_time":
      settings.errorCode = 405;
      settings.diagnostic = "Sorry, this has been specified as a read-only value for " + key;
      break;
    default:
      key = key.replace("cmi.","");
      r = getData(key,cmi);
      //debug(settings.prefix + ": cmiGetValue got " + r,4);
      // Filter
      if (r === 'undefined') {
        settings.errorCode = 401;
        settings.diagnostic = "Sorry, there was a undefined response from " + key;
        r = "false";
      }
      // debug(settings.prefix + ": GetValue " + key + " = " + r,4);
      break;
    }
    return r;
  };

  /**
   * Is Read Only?
   * I've placed several of the read-only items in a delimited string.  This is used to compare
   * the key, to known read-only values to keep you from changing something your not supposed to.
   * @param key {String} like cmi.core.lesson_location
   * @returns {Boolean} true or false
   */
  function isReadOnly(key){
    // See note above about read-only
    var tiers = key.split('.'),
        v = tiers[tiers.length - 1]; // last value
    if (tiers[0] === 'adl' && tiers[4] === 'id') {
        return true;
    }
    if (tiers[1] === 'comments_from_lms') {// entirely read only
        return true;
    }
    return read_only.indexOf('|' + v + '|') >= 0;
  };

  /**
   * Is Write Only?
   * I've placed several write-only items in a delimited string.  This is used to compare
   * the key, to known write-only values to keep you from reading things your not suppose to.
   * @param key {String}
   * @returns {Boolean} true or false
   */
  function isWriteOnly(key){
    var tiers = key.split("."),
        v = tiers[tiers.length - 1]; // last value
    return write_only.indexOf('|' + v + '|') >= 0;
  };

  /**
   * Round Value
   * Rounds to 2 decimal places
   * @param v {Number}
   * @returns {Number}
   */
  function roundVal(v){
    var dec = 2;
    return Math.round(v * Math.pow(10,dec)) / Math.pow(10,dec);
  };

  /**
   * Update Suspend Data Usage Statistics
   * Will update settings.suspend_date_usage with current % level
   */
  function suspendDataUsageStatistic(){
    return roundVal((cmi.suspend_data.length / 64000) * 100) + "%";
  };

   /**
   * Debug
   * Built-In Debug Functionality to output to console (Firebug, Inspector, Dev Tool etc ...)
   * @param msg {String} Debug Message
   * @param lvl {Integer} 1=Error, 2=Warning, 3=Log, 4=Info
   */
  function debug(msg,lvl){
    if (settings.debug) {// default is false
      if (!window.console) {// IE 7 probably 6 was throwing a error if 'console undefined'
        window.console = {};
        window.console.info = noconsole;
        window.console.log = noconsole;
        window.console.warn = noconsole;
        window.console.error = noconsole;
        window.console.trace = noconsole;
      }
      switch (lvl) {
      case 1:
        console.error(msg);
        break;
      case 2:
        console.warn(msg);
        break;
      case 4:
        console.info(msg);
        break;
      case 3:
        console.log(msg);
        break;
      default:
        console.log(msg);
        return false;
      }
      return true;
    }
    if (lvl < 3 && settings.throw_alerts) {
      alert(msg);
    }
    return false;
  };

  /**
   * callListener
   * Built-In Debug Functionality to output to console (Firebug, Inspector, Dev Tool etc ...)
   * @param name {String} Name of the listener
   * @param params {Object}
   */
  function callListener(name,params){
    if(typeof settings.listeners[name] == "function"){
        if(typeof params != "undefined"){
            settings.listeners[name](params);
        }
    }
  };

  function deepMergeHash(defaults,options){
    for(var key in options){
      if (options.hasOwnProperty(key)){
        if(typeof defaults[key] == "object"){
          if(typeof options[key] == "object"){
            defaults[key] = deepMergeHash(defaults[key],options[key]);
          }
        } else {
          defaults[key] = options[key];
        }
      }
    }
    return defaults;
  };

  function triggerHandler(eventName,eventParams){
    //CustomEvent polyfill 
    (function () {
      if (typeof window.CustomEvent === "function") return false;
      function CustomEvent(event,params){
        params = params || {bubbles:false, cancelable:false, detail:undefined};
        var evt = document.createEvent( 'CustomEvent' );
        evt.initCustomEvent(event,params.bubbles,params.cancelable,params.detail);
        return evt;
      }
      CustomEvent.prototype = window.Event.prototype;
      window.CustomEvent = CustomEvent;
    })();
    document.dispatchEvent(new CustomEvent(eventName,{'detail': eventParams}));
  };

  // Public
  /**
   * isRunning, Returns true if initialized is 1 and terminated is 0
   * @returns {Boolean} true or false
   */
  this.isRunning = function () {
    return settings.initialized === 1 && settings.terminated === 0;
  };

  /*jslint nomen: true */
  /**
   * Initialize Session (SCORM) only once!
   * @returns {String} "true" or "false" depending on if its been initialized prior
   */
  this.LMSInitialize = function() {
    debug(settings.prefix + ":  Initializing...",3);
     cmi = settings.CMI;
    
    // Clean CMI Object
    settings.initialized = 1;
    settings.terminated = 0;
    return 'true';
  };

  /**
   * GetValue (SCORM)
   * @param key {String}
   * @returns {String} "true" or "false" depending on if its been initialized prior
   */
  this.LMSGetValue = function(key){
    // debug(settings.prefix + ":  Running: " + this.isRunning() + " GetValue: " + key + "...",4);
    settings.errorCode = 0;
    var r = "false",
        k = key.toString(), // ensure string
        tiers = [];
    if (this.isRunning()) {
        if (isWriteOnly(k)) {
            // debug(settings.prefix + ": This " + k + " is write only",4);
            settings.errorCode = 405;
            return "false";
        }
        tiers = k.toLowerCase().split(".");
        switch (tiers[0]) {
        case "cmi":
            r = cmiGetValue(k);
            break;
        case "ssp":

            break;
        case "adl":

            break;
        }
        return r;
    }
    settings.errorCode = 123;
    return r;
  };

  /**
   * SetValue (SCORM)
   * @param key {String}
   * @param value {String}
   * @returns {String} "true" or "" depending on if its been initialized prior
   */
  this.LMSSetValue = function(key,value){
    debug(settings.prefix + ": SetValue: " + key + " = " + value,4);
    settings.errorCode = 0;
    var tiers = [],
        k = key.toString(), // ensure string
        v = value.toString(), // ensure string
        z = 0,
        count = 0,
        arr = [];

    if (this.isRunning()) {
        if (isReadOnly(k)) {
            // debug(settings.prefix + ": This " + k + " is read only",4);
            settings.errorCode = 404;
            return "false";
        }
        tiers = k.split(".");
        // debug(settings.prefix + ": Tiers " + tiers[1],4);

        switch (tiers[0]) {
        case "cmi":
            switch (key) {
            case "cmi.core.lesson_location":
                if (v.length > 1000) {
                    debug(settings.prefix + ": Some LMS's might truncate your bookmark as you've passed " + v.length + " characters of bookmarking data",2);
                }
                break;
            case "cmi.core.lesson_status":
                if (lesson_status.indexOf('|' + v + '|') === -1) {
                    // Invalid value
                    return throwVocabError(key,v);
                }
                callListener(key,v);
                break;
            case "cmi.core.exit":
                if (exit.indexOf('|' + v + '|') === -1) {
                    // Invalid value
                    return throwVocabError(key,v);
                }
                break;
            case "cmi.core.score.min":
                var scoreMin = parseFloat(v);
                if((typeof scoreMin == "number")&&(!isNaN(scoreMin))){
                    settings.CMI.core.score.min = scoreMin;
                } else {
                    return throwArgumentError(key,v);
                }
                break;
            case "cmi.core.score.max":
                var scoreMax = parseFloat(v);
                if((typeof scoreMax == "number")&&(!isNaN(scoreMax))){
                    settings.CMI.core.score.max = scoreMax;
                } else {
                    return throwArgumentError(key,v);
                }
                break;
            case 'cmi.core.score.raw':
                var rawScore = parseFloat(v);
                if((typeof rawScore == "number")&&(!isNaN(rawScore))){
                    var maxScore = parseFloat(settings.CMI.core.score.max);
                    maxScore = ((typeof maxScore == "number")&&(!isNaN(maxScore))) ? maxScore : 100;
                    var minScore = parseFloat(settings.CMI.core.score.min);
                    minScore = ((typeof minScore == "number")&&(!isNaN(minScore))) ? minScore : 0;

                    var diff = (maxScore - minScore);
                    if(diff <= 0){
                        diff = 100;
                    }

                    var scaledScore = Math.max(0,Math.min(1,(rawScore-minScore)/diff));
                    callListener("cmi.score.scaled",scaledScore);
                } else {
                    return throwArgumentError(key,v);
                }
                break;
            default:
                break;
            }
            // Rip off 'cmi.' before we add this to the model
            k = k.replace("cmi.","");
            setData(k,v,cmi);
            break;
        }
        return "true";
    }
    // Determine Error Code
    if (settings.terminated) {
        settings.errorCode = 133;
    } else {
        settings.errorCode = 132;
    }
    return "false";
  };

  /**
   * Commit (SCORM)
   * Typically empty, I'm unaware of anyone ever passing anything.
   * @returns {String} "true" or "false"
   */
  this.LMSCommit = function(){
    // debug(settings.prefix + ": Commit CMI Object:",4);
    // debug(cmi);
    // debug(settings.prefix + ": Suspend Data Usage " + suspendDataUsageStatistic());
    triggerHandler("StoreData",{
        runtimedata: cmi
    });
    return 'true';
  };

  /**
   * Terminate
   * @returns {String}
   */
  this.LMSTerminate = function() {
    // Could do things here like a LMS
    self.LMSCommit();
    settings.terminated = 1;
    settings.initialized = 0;
    return 'true';
  };

  /**
   * Terminate
   * @returns {String}
   */
  this.LMSFinish = function() {
    // Could do things here like a LMS
    self.LMSCommit();
    settings.terminated = 1;
    settings.initialized = 0;
    return 'true';
  };

  /**
   * GetErrorString (SCORM) - Returns the error string from the associated Number
   * @param param number
   * @returns string
   */
  this.LMSGetErrorString = function(param) {
    if (param !== "") {
        var nparam = parseInt(param,10);
        if (errors[nparam] !== undefined) {
            return errors[nparam];
        }
    }
    return "";
  };

  /**
   * GetLastError (SCORM) - Returns the error number from the last error
   * @returns {Number}
   */
  this.LMSGetLastError = function() {
    return settings.errorCode;
  };

  /**
   * Get Diagnostic
   * This would return further information from the lms about a error
   * @returns {String} description of error in more detail
   */
  this.LMSGetDiagnostic = function() {
    return settings.diagnostic;
  };

  this.setCMILMSValue = function(name,value){
    if(typeof name == "string"){
        settings.CMI[name] = value;
    }
  };

  /**
   * Add listener
   * Add listener to get event notifications
   * @returns {undefined}
   */
  this.addListener = function(event,listener) {
    if((typeof event == "string")&&(typeof listener == "function")){
        settings.listeners[event] = listener;
    }
  };
}