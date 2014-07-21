// =======================================================================
// PageLess - endless page
//
// Pageless is a jQuery plugin. 
// MODIFIED BY KIKE. THAT IS WHY IT IS HERE AND NOT IN VENDOR
//
//
//
// As you scroll down you see more results coming back at you automatically.
// It provides an automatic pagination in an accessible way : if javascript
// is disabled your standard pagination is supposed to work.
//
// Licensed under the MIT:
// http://www.opensource.org/licenses/mit-license.php
//
// Parameters:
//    currentPage: current page (string or function; e.g. <%= params[:page] %>)
//    distance: distance to the end of page in px when ajax query is fired
//    loader: selector of the loader div (ajax activity indicator)
//    loaderHtml: html code of the div if loader not used
//    loaderImage: image inside the loader
//    loaderMsg: displayed ajax message
//    pagination: selector of the paginator divs.
//                if javascript is disabled paginator is provided
//    params: paramaters for the ajax query (hash or function), you can pass auth_token here
//    totalPages: total number of pages (integer or function)
//    url: URL used to request more data (string or function)
//    method: HTML method for call URL, default - get
//
// Callback Parameters:
//    scrape: A function to modify the incoming data.
//    finishedAddingHiddenElem(hidden_elem): function created by KIKE XXX. All the elements are added as hidden. And then this function decides if they should be shown or not.
//                              if this function does not exist the elements are shown with a fadeIn() by default
//    complete: A function to call when a new page has been loaded (optional)
//    end: A function to call when the last page has been loaded (optional)
//
// Usage:
//   $('#results').pageless({ totalPages: 10
//                          , url: '/articles/'
//                          , loaderMsg: 'Loading more results'
//                          });
//
// Requires: jquery
//
// Author: Jean-Sébastien Ney (https://github.com/jney)
//
// Contributors:
//   Alexander Lang (https://github.com/langalex)
//   Lukas Rieder (https://github.com/Overbryd)
//   Kathryn Reeve (https://github.com/BinaryKitten)
//
// Thanks to:
//  * codemonky.com/post/34940898
//  * www.unspace.ca/discover/pageless/
//  * famspam.com/facebox
// =======================================================================
//MODIFIED BY KIKE
//XXX

/*global document:true, jQuery:true, location:true, window:true*/

(function ($, window) {

  var element;
  var isLoading = false;
  var loader;
  var namespace = '.pageless';
  var SCROLL = 'scroll' + namespace;
  var RESIZE = 'resize' + namespace;
  var settings = {
    container: window,
    currentPage: 1,
    distance: 100,
    pagination: '.pagination',
    params: {},
    url: location.href,
    loaderImage: "/images/load.gif",
    method: 'get'
  };
  var container;
  var $container;

  //changed by KIKE XXX it was a function before
  //now we can access watch function
  $.pageless = {
    watch: function(){
      watch();
    }
  };

  $.pagelessReset = function () {
    settings = {
      container: window,
      currentPage: 1,
      distance: 100,
      pagination: '.pagination',
      params: {},
      url: location.href,
      loaderImage: "/images/load.gif",
      method: 'get'
    };
    stopListener();
      // if there is a afterStopListener callback we call it
    if (settings.end) {
      settings.end.call();
    }
  };

  $.pagelessStop = function () {
    if(settings.inited===true){
      settings.inited = false;
      stopListener();
    }
    
  }

  var loaderHtml = function () {
    return settings.loaderHtml ||
      '<div id="pageless-loader" style="display:none;text-align:center;width:100%;">' +
      '<div class="msg" style="color:#e9e9e9;font-size:2em"></div>' +
      '<img src="' + settings.loaderImage + '" alt="loading more results" style="margin:10px auto" />' +
      '</div>';
  };

  // settings params: totalPages
  function init(opts) {
    if (settings.inited) {
      return;
    }

    settings.inited = true;

    if (opts) {
      $.extend(settings, opts);
    }

    container = settings.container;
    $container = $(container);

    // for accessibility we can keep pagination links
    // but since we have javascript enabled we remove pagination links
    if (settings.pagination) {
      $(settings.pagination).remove();
    }

    // start the listener
    startListener();
  }

  $.fn.pageless = function (opts) {
    var $el = $(this);
    //MODIFIED BY KIKE
    //XXX
    //var $loader = $(opts.loader, $el);
    var $loader = $(opts.loader);

    element = $el;  
    init(opts);  

    // loader element
    if (opts.loader && $loader.length) {
      loader = $loader;
    } else {
      loader = $(loaderHtml());
      $el.append(loader);
      // if we use the default loader, set the message
      if (!opts.loaderHtml) {
        $('#pageless-loader .msg').html(opts.loaderMsg).css(opts.msgStyles || {});
      }
    }
  };

  //
  function loading(bool) {
    isLoading = bool;
    if (loader) {
      if (isLoading) {
        loader.fadeIn('normal');
      } else {
        loader.fadeOut('normal');
      }
    }
  }

  // distance to end of the container
  function distanceToBottom() {
    return (container === window)
         ? $(document).height()
         - $container.scrollTop()
         - $container.height()
         : $container[0].scrollHeight
         - $container.scrollTop()
         - $container.height();
  }

  function settingOrFunc(name) {
    var ret = settings[name];
    return $.isFunction(settings[name]) ? ret() : ret;
  }

  function stopListener() {
    $container.unbind(namespace);
  }

  // * bind a scroll event
  // * trigger is once in case of reload
  function startListener() {
    my_num = 0;
    $container
      .bind(SCROLL + ' ' + RESIZE, watch)
      .trigger(SCROLL);
  }

  /*
   * Function created by KIKE to append one element at a time and with an animation
   * also show the element or hide it depending on the tab selected
   * xxx
   */
  function animateSlowAppendAndFinishLoading(my_element, arr){ 
    var tmp_elem = arr.pop();
   
    var hidden_elem = $(tmp_elem).hide().appendTo($(my_element));
    
    if ($.isFunction(settings.finishedAddingHiddenElem)) {
      settings.finishedAddingHiddenElem(hidden_elem);
    }
    else{
      hidden_elem.fadeIn();
      var array_matches = hidden_elem.find('div[bs-img]');
      if(array_matches.length>0){ 
        $(array_matches[0]).backstretch($(array_matches[0]).attr("bs-img"));
      }
    }
    
    if(arr.length>0){
      window.setTimeout(function(){animateSlowAppendAndFinishLoading(my_element, arr)}, 20);
    }
    else{
      loading(false);
      // if there is a complete callback we call it
      if (settings.complete) {
        settings.complete.call();
      }
    }
  }

  function watch() {
    my_num++;
    var currentPage = settingOrFunc('currentPage');
    var totalPages = settingOrFunc('totalPages');
    // listener was stopped or we've run out of pages
    //MODIFIED BY KIKE. Added !isLoading to still wait for the last page, this was a bug
    //XXX
    if (totalPages <= currentPage && !isLoading) {
      if (!$.isFunction(settings.currentPage) && !$.isFunction(settings.totalPages)) {
        stopListener();
        // if there is a afterStopListener callback we call it          
        if (settings.end) {
          settings.end.call();
        } 
      }
      return;
    }

    // if slider past our scroll offset, then fire a request for more data
    if (!isLoading && (distanceToBottom() < settings.distance)) {
      var url = settingOrFunc('url');
      var requestParams = settingOrFunc('params');

      loading(true);
      // move to next page
      currentPage++;
      if (!$.isFunction(settings.currentPage)) {
        settings.currentPage = currentPage;
      }

      var parent_to_append = element;  //saved because with several tabs, we can start another pageless and it changes the var "element"
      // set up ajax query params
      $.extend(requestParams, { page: currentPage });
      // finally ajax query
      $.ajax({
        data: requestParams,
        dataType: 'html',
        url: url,
        async: true,
        method: settings.method,
        success: function (data) {
          if ($.isFunction(settings.scrape)) {
            data = settings.scrape(data);
          }
          //MODIFIED BY KIKE. It appended the results before the loader. We want them in their place
          //XXX
          //if (loader) {
          //   loader.before(data);
          //} else {
            animateSlowAppendAndFinishLoading(parent_to_append, jQuery.makeArray($(data)) );
          //}
          

          //MODIFIED BY KIKE. Added next 5 lines to call end function only when success of last page load
          //XXX            
          if (totalPages <= currentPage) {
            if (settings.end) {
              settings.end.call();
            }
          }
        }
      });
    }
  }
})(jQuery, window);
