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

  var removeM = function(){
    console.log("he entrado en removeM");
        var divs_tmp2 = $("div[id^='picture-modal-']");  //resize
        var divs_tmp1 = $("div[id^='picture-modal-body']");     //footar  
        var divs_tmp3 = $("div[id^='modyfooter']");           //sticky
        
            console.log(divs_tmp3); //sticky
            console.log(divs_tmp2); //resize
            console.log(divs_tmp1); //footar  

             divs_tmp1.removeClass('footar')
             divs_tmp2.removeClass('resize')
             divs_tmp3.removeClass('sticky')

  }

  return {
    removeM : removeM,
    redim : redim,
    rwindow : rwindow,
    googdoc : googdoc
    
  }

}) (Vish);
