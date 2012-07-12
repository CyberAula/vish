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
    $("#input_activities_document").watermark(I18n.t('document.input'), "#666");

    if($("#new_post").length) {
      $("#input_activities").unbind();
      $("#input_activities").change(urlDetect).keyup(urlDetect);
      $("#new_post").append($('<input>').attr('type', 'hidden').attr('name', 'embed[owner_id]').attr('id', 'embed_owner_id').val($("#post_owner_id").val()));
      $("#new_post").append($('<input>').attr('type', 'hidden').attr('name', 'embed[fulltext]').attr('id', 'embed_fulltext'));
      $("#new_post").append($('<div>').attr('id', 'embed_preview').css('display', 'none'));

    }

    $('#attachFileButton').click(function(){
      $('#attachFileButton').toggleClass("selected");
      $('#wrapper_activities_header form').toggle();
      var post_text = $('#input_activities').val();
      var document_text = $('#input_activities_document').val();
      $('#input_activities').val(document_text);
      $('#input_activities_document').val(post_text);
      if($('#document_file').is(":visible")) {
        $('#document_file').trigger('click');
      }
    });
  }

  var modalPayload = function(klass, id) { /* TODO: video, audio.... other payloads? */
    if (klass == "video") {
      return '<div id="full_video_'+id+'" class="jp-video jp-video-270p"><div class="jp-type-single"><div id="jpId'+id+'" class="jp-jplayer"></div><div id="jp_interface_'+id+'" class="jp-interface"><div class="jp-video-play"></div><ul class="jp-controls"><li><a href="#" class="jp-play" tabindex="1">play</a></li><li><a href="#" class="jp-pause" tabindex="1">pause</a></li><li><a href="#" class="jp-stop" tabindex="1">stop</a></li><li><a href="#" class="jp-mute" tabindex="1">mute</a></li><li><a href="#" class="jp-unmute" tabindex="1">unmute</a></li></ul><div class="jp-progress"><div class="jp-seek-bar"><div class="jp-play-bar"></div></div></div><div class="jp-volume-bar"><div class="jp-volume-bar-value"></div></div><div class="jp-current-time"></div><div class="jp-duration"></div></div><div id="jp_playlist_'+id+'" class="jp-playlist"></div></div><div id="inspector"></div></div>';
    } else if (klass == "audio") {
      return '<div id="full_audio_'+id+'" class="audio-full jp-audio"><div id="jpId'+id+'" class="jpId_size0 jp-jplayer"></div><div class="jp-audio"><div class="jp-type-single"><div id="jp_interface_'+id+'" class="jp-interface"><ul class="jp-controls"><li><a href="#" class="jp-play" tabindex="1">play</a></li><li><a href="#" class="jp-pause" tabindex="1">pause</a></li><li><a href="#" class="jp-stop" tabindex="1">stop</a></li><li><a href="#" class="jp-mute" tabindex="1">mute</a></li><li><a href="#" class="jp-unmute" tabindex="1">unmute</a></li></ul><div class="jp-progress"><div class="jp-seek-bar"><div class="jp-play-bar"></div></div></div><div class="jp-volume-bar"><div class="jp-volume-bar-value"></div></div><div class="jp-current-time"></div><div class="jp-duration"></div></div><div id="jp_playlist_'+id+'" class="jp-playlist"></div></div></div></div>';
    } else {
      return '<img alt="Loading" class="loading" src="/assets/loading.gif" />';
    }
  }

  var areasOfInterest = function(tags) {
    if(tags) {
      var tag_a = tags.split(", ");
      var tag_str = '';
      for (i in tag_a) {
        tag_str+='<li class="tagit-choice"><a style="color: white;" href="/search?q=' + encodeURI(tag_a[i]) + '">' + tag_a[i] + '</a></li>';
      }
      return '<div class="text-center">' + I18n.t('profile.tags.other') + ': <ul class="tagit-suggestions">' + tag_str + '<br/><br/></ul></div><hr/>';
    } else {
      return '';
    }
  }

  var userModalPayload = function(id, avatar, followers, followings, excursions, resources, tags, organization, bio) {
    return '<div class="row-fluid"><div class="span3"><a href="/users/' + id + '">' + $("<div/>").html(avatar).text() + '</a><br/>' + I18n.t('follow.followers')+': <a href="/users/' + id + '/followers">' + followers + '</a><br/>'+I18n.t('follow.followings')+': <a href="/users/' + id + '/followings">' + followings + '</a></div><div class="span9">' + (organization ? '<div>' + organization + '</div><hr/>': '') + '<div class="text-center">' + I18n.t('published') + ': <a href="/users/' + id + '/excursions">' + excursions + '</a> ' + I18n.t('excursion.other')+ ' & <a href="/users/' + id + '/documents">' + resources + '</a> ' + I18n.t('resource.title.other') + '</div><hr/>' + areasOfInterest(tags) + '<div><em>' + (bio ? bio : I18n.t('no_bio')) + '</em></div></div></div>';
  }

  var modalLikeBtn = function(signed_in, activity_id, is_fav){
    if(signed_in) {
      return '<div class="menu_resources"><div class="verb_like" id="like_' + activity_id + '"><a href="/activities/'+ activity_id +'/like" class="verb_like like_size_big like_activity_' + activity_id + '" data-method="' + (is_fav?"delete":"post") + '" data-remote="true" rel="nofollow"><img alt="Star-' + (is_fav?'on':'off') + '" class="menu_icon" src="/assets/star-'+ (is_fav?'on':'off') +'.png" /></a></div></div>';
    } else {
      return ""; /* TODO: add button that leads to login? */
    }
  }

  var modalFollowBtn = function(signed_in, contact_link){
    if(signed_in) {
      return '<div class="send_message size10 red-2 upfoll">' + $("<div/>").html(contact_link).text() + '</div>'
    } else {
      return ""; /* TODO: add button that leads to login? */
    }
  }

  var getModal = function(klass, id, signed_in, activity_id, is_fav, title) {
    var modal = $('#' + klass + '-modal-' + id);
    if (modal.length) {
      return modal;
    } else {
      return $('<div class="modal hide" id="' + klass + '-modal-' + id + '"><div class="modal-header"><h3 class="text-center">' + title + '</h3></div><div id="'+klass+'-modal-body-'+id+'" class="modal-body text-center">'+ modalPayload(klass, id) +'</div><div class="modal-footer"><div class="pull-left">' + modalLikeBtn(signed_in, activity_id, is_fav) + '</div><div class="pull-right"><a href="#" class="btn btn-danger ' + klass + '-modal-close-' + id + '" data-dismiss="modal">'+ I18n.t('close') +'</a><a href="/' + klass + 's/' + id + '" class="btn btn-success">' + I18n.t('details.msg') + '</a></div></div></div>').appendTo($('body'));
    }
  }

  var getUserModal = function(id, signed_in, name, avatar, followers, followings, excursions, resources, contact_link, tags, organization, bio) {
    var modal = $('#user-modal-' + id);
    if (modal.length) {
      return modal;
    } else {
      return $('<div class="modal hide" id="user-modal-' + id + '"><div class="modal-header"><h3 class="text-center">' + name + '</h3></div><div id="user-modal-body-'+id+'" class="modal-body text-center">'+ userModalPayload(id, avatar, followers, followings, excursions, resources, tags, organization, bio) + '</div><div class="modal-footer"><div class="pull-left">' + modalFollowBtn(signed_in, contact_link) + '</div><div class="pull-right"><a href="#" class="btn btn-danger user-modal-close-' + id + '" data-dismiss="modal">'+ I18n.t('close') +'</a><a href="/users/' + id + '" class="btn btn-success">' + I18n.t('details.msg') + '</a></div></div></div>').appendTo($('body'));
    }
  }

  return {
    init: init,
    getModal: getModal,
    getUserModal: getUserModal,
  };
}) (Vish, jQuery)
