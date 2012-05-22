// This modifies the functionality of social_stream.wall.js
//
//= require vish

Vish.Wall = (function(V, $, undefined){
  var init = function(){
    $("#input_activities_document").watermark(I18n.t('document.input'), "#666");

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
