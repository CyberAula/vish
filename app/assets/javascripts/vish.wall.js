//= require vish

Vish.Wall = (function(V, $, undefined){
  var regexp = /^(<(embed|object|iframe).*<\/\2>).*$/i

  var hidden_embed_form = "This embedded object will be added to your repository<input type='hidden' name='embed[title]' value='Check out this embed!' />";

  var urlDetect = function() {
    this.currentValue = $("#input_activities").val();

    if(regexp.test($("#input_activities").val())) {
      $("#embed_fulltext").val( regexp.exec($("#input_activities").val())[1]);
      $("#new_post").attr("action", "/embeds");
      $("#embed_preview").html(hidden_embed_form);
      $("#embed_preview").show();
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

  return {
    init: init,
  };
}) (Vish, jQuery)
