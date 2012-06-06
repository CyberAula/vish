//= require vish

Vish.Wall = (function(V, $, undefined){
  var regexpEmbed = /^(<(embed|object|iframe).*<\/\2>).*$/i
  var regexpLink = /^(http|ftp|https):\/\/[\w-]+(\.[\w-]+)+([\w.,@?^=%&;:\/~+#-]*[\w@?^=%&;\/~+#-])?$/

  var hidden_embed_form = "This embedded object will be added to your repository<br/>Title: <input type='text' name='embed[title]' value='Check out this embed!' /><br/>Description:<input type='textarea' name='embed[description]'>";

  var urlDetect = function() {
    this.currentValue = $("#input_activities").val();

    if(regexpEmbed.test($("#input_activities").val())) {
      $("#embed_fulltext").val( regexp.exec($("#input_activities").val())[1]);
      $("#new_post").attr("action", "/embeds");
      $("#embed_preview").html(hidden_embed_form);
      $("#embed_preview").show();
    } else if(regexpLink.test($("#input_activities").val())) {
      $("#link_url").val($("#input_activities").val());
      $("#link_loaded").val(false);
      $("#new_post").attr("action", "/links");

      if(this.currentValue != this.lastValue) {
        $("#link_preview").html($('<img>').attr('src', '<%= asset_path('loading.gif') %>').addClass('loading'));

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
