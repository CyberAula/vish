var Vish = Vish || {};

//tooltip function
$(document).ready(function(){
$("[rel=tooltip]").tooltip({ placement: 'bottom'});
});


//dropdown function
$(document).ready(function(){
$("[rel=dropdown]").tooltip({ placement: 'bottom'});
});

$(document).ready(function(){
$("select").select2({
    allowClear: true
    });
});

$(document).ready(function(){
    $('textarea').autosize();    
});