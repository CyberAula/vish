Vish.Officedoc = (function(V,undefined){

  var calculate = function(anch){
  	return -($(anch).width() / 2);
  } 


  var redim = function(anch){
     console.log("he llamado a redim");
    $('.resize').css({
      width: 'auto',
     'margin-left': calculate(anch)
     });
  }


  var googdoc = function(){
    console.log("he entrado en googdoc");
     
    	var height = ($('.resize').height())*(8/10);
    	setTimeout(function(){
    	$('#gdoc').css("height", height);
  	},500);
  }

  var rwindow = function(){
    console.log("he entrado en rwindow");
    
  	var height = ($('.resize').height())*(9/10);
    	$(window).resize(function () {
    	var height = ($('.resize').height())*(8/10);
    	$('#gdoc').css("height", height);

  });

  }

  return {
    redim : redim,
    rwindow : rwindow,
    googdoc : googdoc
    
  }

}) (Vish);
