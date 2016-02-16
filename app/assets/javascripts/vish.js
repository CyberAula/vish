var Vish = Vish || {};

//tooltip function
document.addEventListener("DOMContentLoaded", function(){
  $("[rel=tooltip]").tooltip({ placement: 'bottom', container:'body'});
});

$(document).ready(function(){
    $('textarea').autosize();
});
