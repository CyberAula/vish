//= require vish

Vish.Wall = (function(V, $, undefined){
  var regexpEmbed = /^(<(embed|object|iframe).*<\/\2>).*$/i
  var regexpLink = /^(http|ftp|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&;:\/~+#-]*[\w@?^=%&;\/~+#-])?$/

  var hidden_embed_form = "This embedded object will be added to your repository<br/>Title: <input type='text' name='embed[title]' value='Check out this embed!' /><br/>Description:<input type='textarea' name='embed[description]'>";

  var urlDetect = function() {
    this.currentValue = $("#input_activities").val();

    if(regexpEmbed.test($("#input_activities").val())) {
      $("#embed_fulltext").val( regexpEmbed.exec($("#input_activities").val())[1]);
      $("#new_post").attr("action", "/embeds");
      $("#embed_preview").html(hidden_embed_form);
      $("#embed_preview").show();
    } else if(regexpLink.test($("#input_activities").val())) {
      $("#link_url").val($("#input_activities").val());
      $("#link_loaded").val(false);
      $("#new_post").attr("action", "/links");

      if(this.currentValue != this.lastValue) {
        $("#link_preview").html($('<img>').attr('src', 'assets/images/loading.gif').addClass('loading'));

        this.lastValue = this.currentValue;
        var url = this.currentValue;
        var urlDetect = this;

        $.ajax({
          type : "GET",
          url : "/linkser_parse?url=" + url,
          dataType: 'html',
          success : function(html) {
            if($("#input_activities").val() == url) {//Only show if input value is still the same
              $("#link_preview").html(html);
              $("#link_loaded").val(true);
            }
          },
          error : function(xhr, ajaxOptions, thrownError) {
            if($("#input_activities").val() == url) {//Only show if input value is still the same
              $("#link_preview").html($('<div>').addClass('loading').html(I18n.t('link.errors.loading') + " " + url));
            }
          }
        });
      }

      $("#link_preview").show();

    } else {
      $("#new_post").attr("action", "/posts");
      $("#embed_preview").hide();
      $("#embed_preview").html("");
      $("#embed_fulltext").val("");
    }
  }

  var init = function(){
    $('section.wall .nav-tabs li a.load-me-on-show').on('show', function(e) {
      $('#wall-me').empty();
      $.getScript("?active_tab=me&page_me=1");
      $(this).off('show');
    });

    $('section.wall .nav-tabs li a.load-net-on-show').on('show', function(e) {
      $('#wall').empty();
      $.getScript("?active_tab=net&page_net=1");
      $(this).off('show');
    });

    $("#input_activities_document").watermark(I18n.t('document.input'), "#666");

    if($("#new_post").length) {
      $("#input_activities").unbind();
      $("#input_activities").change(urlDetect).keyup(urlDetect);
      $("#new_post").append($('<input>').attr('type', 'hidden').attr('name', 'embed[owner_id]').attr('id', 'embed_owner_id').val($("#post_owner_id").val()));
      $("#new_post").append($('<input>').attr('type', 'hidden').attr('name', 'embed[fulltext]').attr('id', 'embed_fulltext'));
      $("#new_post").append($('<div>').attr('id', 'embed_preview').css('display', 'none'));

    }

    $('#masterSubmitButton').click(function(){
      $('#wall-input form:visible').submit();
    });
                

    $('#attachFileButton').click(function(){
      $('#attachFileButton').toggleClass("selected");
      $('#activities_header form').toggle();
      var post_text = $('#input_activities').val();
      var document_text = $('#input_activities_document').val();
      $('#input_activities').val(document_text);
      $('#input_activities_document').val(post_text);
      if($('#document_file').is(":visible")) {
        $('#document_file').trigger('click');
      }
    });

  }

  var initModals = function() {
    $('.modal-slide-prev').off("click");
    $('.modal-slide-prev').on("click", function(){
      $('.modal').modal('hide');
      my_pivot = $(this).parents('.modal').first().attr('data-modal-pivot'); // modal-pivot NEEDS to have an id
      all_modals = $(my_pivot).find('.modal-trigger');
      my_target = '#' + this.href.split('#',2)[1];
      next_target = '#' + $(this).parents('.modal')[0].id;
      prev_target = my_target;
      next_index = parseInt($(this).parents('.modal').first().attr('data-modal-index'));
      my_index = next_index;
      while(my_index >= 0 && my_target != ('#' + all_modals[my_index].href.split('#',2)[1])) my_index--;
      prev_index = my_index;
      while(prev_index >= 0) {
        prev_target = '#' + all_modals[prev_index].href.split('#',2)[1];
        if(my_target == prev_target) {
          prev_index-=1;
        } else {
          break;
        }
      }

      $(my_target).attr('data-modal-pivot', my_pivot);
      $(my_target).attr('data-modal-index', prev_index);
      $(my_target + ' .next_modal').show();
      $(my_target + ' .next_modal a').attr('href', next_target);

      if(my_index < 0 || my_target == prev_target) {
        $(my_target + ' .prev_modal').hide();
      } else {
        $(my_target + ' .prev_modal').show();
        $(my_target + ' .prev_modal a').attr('href', prev_target);
      }
    });

    $('.modal-slide-next').off("click");
    $('.modal-slide-next').on("click", function(){
      $('.modal').modal('hide');
      my_pivot = $(this).parents('.modal').first().attr('data-modal-pivot'); // modal-pivot NEEDS to have an id
      all_modals = $(my_pivot).find('.modal-trigger');
      my_target = '#' + this.href.split('#',2)[1];
      prev_target = '#' + $(this).parents('.modal')[0].id;
      next_target = my_target;
      prev_index = parseInt($(this).parents('.modal').first().attr('data-modal-index'));
      my_index = prev_index;
      while(my_index < all_modals.length && my_target != ('#' + all_modals[my_index].href.split('#',2)[1])) my_index++;
      next_index = my_index;

      while(next_index < all_modals.length) {
        next_target = '#' + all_modals[next_index].href.split('#',2)[1];
        if(my_target == next_target) {
          next_index+=1;
        } else {
          break;
        }
      }

      $(my_target).attr('data-modal-pivot', my_pivot);
      $(my_target).attr('data-modal-index', next_index);
      $(my_target + ' .prev_modal').show();
      $(my_target + ' .prev_modal a').attr('href', prev_target);

      if(my_index < 0 || my_target == next_target) {
        $(my_target + ' .next_modal').hide();
      } else {
        $(my_target + ' .next_modal').show();
        $(my_target + ' .next_modal a').attr('href', next_target);
      }
    });

    $('.modal-no-trigger').off("click");
    $('.modal-no-trigger').on("click", function(){
      my_target = '#' + this.href.split('#',2)[1];
      $(my_target + ' .prev_modal').hide();
      $(my_target + ' .next_modal').hide();
    });

    $('.modal-trigger').off("click");
    $('.modal-trigger').on("click", function(){
      my_pivot = '#' + $(this).parents('.modal-pivot')[0].id; // modal-pivot NEEDS to have an id
      all_modals = $(this).parents('.modal-pivot').find('.modal-trigger');
      my_target = '#' + this.href.split('#',2)[1];

      if(my_pivot == '#') {
        $(my_target + ' .prev_modal').hide();
        $(my_target + ' .next_modal').hide();
        return;
      }

      next_target = prev_target = my_target;
      my_index = $.inArray(this, all_modals);
      next_index = my_index+1;
      prev_index = my_index-1;

      while(next_index < all_modals.length) {
        next_target = '#' + all_modals[next_index].href.split('#',2)[1];
        if(my_target == next_target) {
          next_index+=1;
        } else {
          break;
        }
      }

      while(prev_index >= 0) {
        prev_target = '#' + all_modals[prev_index].href.split('#',2)[1];
        if(my_target == prev_target) {
          prev_index-=1;
        } else {
          break;
        }
      }

      $(my_target).attr('data-modal-pivot', my_pivot);
      $(my_target).attr('data-modal-index', my_index);
      if(my_index < 0 || my_target == prev_target) {
        $(my_target + ' .prev_modal').hide();
      } else {
        $(my_target + ' .prev_modal').show();
        $(my_target + ' .prev_modal a').attr('href', prev_target);
      }
      if(my_index < 0 || my_target == next_target) {
        $(my_target + ' .next_modal').hide();
      } else {
        $(my_target + ' .next_modal').show();
        $(my_target + ' .next_modal a').attr('href', next_target);
      }
    });
  }

  var modalPayload = function(klass, id) { /* TODO: video, audio.... other payloads? */
    if (klass == "video") {
      return '<div id="full_video_'+id+'" class="jp-video jp-video-270p"><div class="jp-type-single"><div id="jpId'+id+'" class="jp-jplayer"></div><div id="jp_interface_'+id+'" class="jp-interface"><div class="jp-video-play"></div><ul class="jp-controls"><li><a href="#" class="jp-play" tabindex="1">play</a></li><li><a href="#" class="jp-pause" tabindex="1">pause</a></li><li><a href="#" class="jp-stop" tabindex="1">stop</a></li><li><a href="#" class="jp-mute" tabindex="1">mute</a></li><li><a href="#" class="jp-unmute" tabindex="1">unmute</a></li></ul><div class="jp-progress"><div class="jp-seek-bar"><div class="jp-play-bar"></div></div></div><div class="jp-volume-bar"><div class="jp-volume-bar-value"></div></div><div class="jp-current-time"></div><div class="jp-duration"></div></div><div id="jp_playlist_'+id+'" class="jp-playlist"></div></div><div id="inspector"></div></div>';
    } else if (klass == "audio") {
      return '<div id="full_audio_'+id+'" class="audio-full jp-audio"><div id="jpId'+id+'" class="jpId_size0 jp-jplayer"></div><div class="jp-audio"><div class="jp-type-single"><div id="jp_interface_'+id+'" class="jp-interface"><ul class="jp-controls"><li><a href="#" class="jp-play" tabindex="1">play</a></li><li><a href="#" class="jp-pause" tabindex="1">pause</a></li><li><a href="#" class="jp-stop" tabindex="1">stop</a></li><li><a href="#" class="jp-mute" tabindex="1">mute</a></li><li><a href="#" class="jp-unmute" tabindex="1">unmute</a></li></ul><div class="jp-progress"><div class="jp-seek-bar"><div class="jp-play-bar"></div></div></div><div class="jp-volume-bar"><div class="jp-volume-bar-value"></div></div><div class="jp-current-time"></div><div class="jp-duration"></div></div><div id="jp_playlist_'+id+'" class="jp-playlist"></div></div></div></div>';
    } else {
      return '<img alt="Loading" class="loading" src="/assets/images/loading.gif" />';
    }
  }

  var modalLikeBtn = function(signed_in, activity_id, is_fav){
    if(signed_in) {
      return '<div class="btn-gray"><div class="verb_like" id="like_' + activity_id + '"><a href="/activities/'+ activity_id +'/like" class="verb_like like_size_big like_activity_' + activity_id + '" data-method="' + (is_fav?"delete":"post") + '" data-remote="true" rel="nofollow"><img alt="Star-' + (is_fav?'on':'off') + '" class="menu_icon" src="/assets/icons/star-'+ (is_fav?'on':'off') +'.png" /></a></div></div>';
    } else {
      return ""; /* TODO: add button that leads to login? */
    }
  }

  var modalNavBtns = function(){
    prev_btn = '<div class="btn-gray link_gray prev_modal"><a class="modal-slide-prev" href="#" data-toggle="modal">&larr;</a></div>';
    next_btn = '<div class="btn-gray link_gray next_modal"><a class="modal-slide-next" href="#" data-toggle="modal">&rarr;</a></div>';
    return prev_btn + next_btn;
  }

  var modalFollowBtn = function(signed_in, contact_link){
    if(signed_in) {
      return '<div class="send_message size10 red-2 upfoll">' + $("<div/>").html(contact_link).html() + '</div>'
    } else {
      return ""; /* TODO: add button that leads to login? */
    }
  }

  var getModal = function(klass, id, signed_in, activity_id, is_fav, title) {

    var modal = $('#' + klass + '-modal-' + id);

    
    if (modal.length) {
      return "";
    } else {
      if(klass == 'officedoc'){
        var var1= 'resize';
        var var2= 'footar';
        var var3= 'sticky';

      }else{
        var1= '';
        var2= '';
        var3= '';
      }
      return $('<div class="' + var1 +  ' ajuste modal hide' + '" id="' + klass + '-modal-' + id + '"><div class="modal-header"><h3 class="text-center">' + title + '</h3></div><div id="'+klass+'-modal-body-'+id+'" <div class="' + var2 +  ' modal-body text-center' + '">'+ modalPayload(klass, id) +'</div><div id="' + klass + '-footer-' + id + '"    <div class="' + var3 +  ' modal-footer' + '">' + modalLikeBtn(signed_in, activity_id, is_fav) + '</div><div class="btn-modal-footer">' + modalNavBtns() + '<a href="#" class="btn btn-danger ' + klass + '-modal-close-' + id + '" data-dismiss="modal">'+ I18n.t('close') +'</a><a href="/' + klass + 's/' + id + '" class="btn btn-success">' + I18n.t('details.msg') + '</a></div></div></div>').appendTo($('body'));
    }
  }

  var getUserModal = function(id, signed_in, name, contact_link) {
    var modal = $('#user-modal-' + id);
    if (modal.length) {
      return "";
    } else {
      return $('<div class="modal hide" id="user-modal-' + id + '"><div class="modal-header"><h3 class="text-center">' + name + '</h3></div><div id="user-modal-body-'+id+'" class="modal-body text-center"><img alt="Loading" class="loading" src="/assets/loading.gif" /></div><div class="modal-footer"><div class="pull-left">' + modalFollowBtn(signed_in, contact_link) + '</div><div class="btn-modal-footer">' + modalNavBtns() + '<a href="#" class="btn btn-danger user-modal-close-' + id + '" data-dismiss="modal">'+ I18n.t('close') +'</a><a href="/users/' + id + '" class="btn btn-success">' + I18n.t('details.msg') + '</a></div></div></div>').appendTo($('body'));
    }
  }

  return {
    init: init,
    initModals: initModals,
    getModal: getModal,
    getUserModal: getUserModal,
  };
}) (Vish, jQuery)
