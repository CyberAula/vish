var VISH = VISH || {};
VISH.Constant = VISH.Constant || {};
VISH.Constant.QZ_TYPE = VISH.Constant.QZ_TYPE || {};
VISH.Constant.QZ_TYPE.OPEN = "open";
VISH.Constant.QZ_TYPE.MCHOICE = "multiplechoice";
VISH.Constant.QZ_TYPE.TF = "truefalse";


VISH.QuizCharts = (function(V,$,undefined){
  
	var pieBackgroundColor = ["#F38630","#E0E4CC","#69D2E7","#FFF82A","#FF0FB4","#2A31FF","#FF6075","#00D043"];
	var pieLetterColor = ["#000"];
	var choices = {};

	//Translations
	var language = "en";
	var i18n = 
		{ "es":
			{
				"i.T"	: "V",
				"i.F"	: "F"
			},
		  "default":
			{
				"i.T"	: "T",
				"i.F"	: "F"
			}
		};
	var translations = i18n["default"];

	var init = function(options){
		if((options)&&(options.lang)){
			language = options.lang;
		}

		if(i18n[language]){
			translations = i18n[language];
		}
	};

	var _getTrans = function(s, params) {
		if (translations[s]){
			return _getTransWithParams(translations[s],params);
		}
		
		//Search in default language
		return _getTransWithParams(i18n["default"][s],params);
	};

	/*
	 * Replace params (if they are provided) in the translations keys. See VISH.I18n for details.
	 */
	var _getTransWithParams = function(trans, params){
		if(typeof params != "object"){
			return trans;
		}

		for(var key in params){
			var stringToReplace = "#{" + key + "}";
			if(trans.indexOf(stringToReplace)!=-1){
				trans = trans.replaceAll(stringToReplace,params[key]);
			}
		};

		return trans;
	}


	/* Draw Methods */

	var drawQuizChart = function(canvas,quizJSON,results,options){
		var quizParams = _getQuizParams(quizJSON);
		var answersList = _getAnswers(results);
		switch (quizParams.quizType) {
			case V.Constant.QZ_TYPE.OPEN:
			break;
		case V.Constant.QZ_TYPE.MCHOICE:
			if(quizParams.extras.multipleAnswer==true){
				_drawMcChoiceMAnswerQuizChart(canvas,quizParams,answersList,options);
			} else {
				_drawMcChoiceQuizChart(canvas,quizParams,answersList,options);
			}
			break;
		case V.Constant.QZ_TYPE.TF:
			_drawTFQuizChart(canvas,quizParams,answersList,options);
			break;
		default:
			return null; 
			break;
		}
	}

	var _drawMcChoiceQuizChart = function(canvas,quizParams,answersList,options){
		var pieFragments = [];
		var data = [];
		var choicesQuantity = quizParams.choices.length;

		var pBCL = pieBackgroundColor.length;
		var pLCL = pieLetterColor.length;

		for(var i=0; i<choicesQuantity; i++){
			pieFragments[i] = {};
			pieFragments[i].value = 0;
			pieFragments[i].label = String.fromCharCode(96+i+1);
			pieFragments[i].color = pieBackgroundColor[i%pBCL];
			pieFragments[i].labelColor = pieLetterColor[i%pLCL];
			pieFragments[i].labelFontSize = '16';
			pieFragments[i].tooltipLabel = _purgeString(quizParams.choices[i].value);
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var index = answer.no-1;

				if((answer.answer==="true")&&(pieFragments[index])){
					pieFragments[index].value++;
				}
			}
		}

		for(var i=0; i<choicesQuantity; i++){
			data.push(pieFragments[i]);
		}

		var ctx = $(canvas).get(0).getContext("2d");

		var chartOptions = {
			showTooltips: true,
			animation: false
		}

		if((options)&&(options.animation===true)){
			//Include animation
			chartOptions.animation = true;
			chartOptions.onAnimationComplete = function(){
				if(typeof options.callback == "function"){
					options.callback();
				}
			}
		}

		var myNewChart = new Chart(ctx).Pie(data,chartOptions);

		if((options)&&(options.animation!=true)&&(typeof options.callback == "function")){
			options.callback();
		}
	}

	var _drawMcChoiceMAnswerQuizChart = function(canvas,quizParams,answersList,options){
		var labels = [];
		var tooltipLabels = [];
		var data = [];
		var choicesQuantity = quizParams.choices.length;
		var maxValue = 0;
		var scaleSteps = 10;

		for(var i=0; i<choicesQuantity; i++){
			labels[i] = String.fromCharCode(96+i+1);
			tooltipLabels[i] = _purgeString(quizParams.choices[i].value);
			data[i] = 0;
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var index = answer.no-1;
				if(answer.answer==="true"){
					data[index]++;
				}
			} 
		}

		for(var l=0; l<choicesQuantity; l++){
			if(data[l] > maxValue){
				maxValue = data[l];
			}
		}

		if(maxValue<10){
			scaleSteps = Math.max(1,maxValue);
		}

		var ctx = $(canvas).get(0).getContext("2d");
		var data = {
			labels : labels,
			tooltipLabels: tooltipLabels,
			datasets : [
				{
				fillColor : "#E2FFE3",
				strokeColor : "rgba(220,220,220,1)",
				data : data
				}
			]
		};

		var chartOptions = {
			showTooltips: true,
			animation: false,
			scaleOverride: true,
			scaleStepWidth: Math.max(1,Math.ceil(maxValue/10)),
			scaleSteps: scaleSteps
		}

		if((options)&&(options.animation===true)){
			//Include animation
			chartOptions.animation = true;
			chartOptions.onAnimationComplete = function(){
				if(typeof options.callback == "function"){
					options.callback();
				}
			}
		}

		var myNewChart = new Chart(ctx).Bar(data,chartOptions);

		if((options)&&(options.animation!=true)&&(typeof options.callback == "function")){
			options.callback();
		}
	}


	var _drawTFQuizChart = function(canvas,quizParams,answersList,options){
		var labels = [];
		var tooltipLabels = [];
		var dataTrue = [];
		var dataFalse = [];
		var choicesQuantity = quizParams.choices.length;
		var maxValue = 0;
		var scaleSteps = 10;

		for(var i=0; i<choicesQuantity; i++){
			labels[i] = _getTrans("i.T") + "       " + String.fromCharCode(96+i+1) + "       " + _getTrans("i.F");
			tooltipLabels[i] = _purgeString(quizParams.choices[i].value);
			dataTrue[i] = 0;
			dataFalse[i] = 0;
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var index = answer.no-1;
				if(answer.answer==="true"){
					dataTrue[index]++;
				} else {
					dataFalse[index]++;
				}
			}
		}

		for(var l=0; l<choicesQuantity; l++){
			if(dataTrue[l] > maxValue){
				maxValue = dataTrue[l];
			}
			if(dataFalse[l] > maxValue){
				maxValue = dataFalse[l];
			}
		}

		if(maxValue<10){
			scaleSteps = Math.max(1,maxValue);
		}

		var ctx = $(canvas).get(0).getContext("2d");
		var data = {
			labels : labels,
			tooltipLabels: tooltipLabels,
			datasets : [
			{
				fillColor : "#E2FFE3",
				strokeColor : "rgba(220,220,220,1)",
				data : dataTrue
			},
			{
				fillColor : "#FFE2E2",
				strokeColor : "rgba(220,220,220,1)",
				data : dataFalse
			}
			]
		};

		var chartOptions = {
			showTooltips: true,
			animation: false,
			scaleOverride: true,
			scaleStepWidth: Math.max(1,Math.ceil(maxValue/10)),
			scaleSteps: scaleSteps
		}

		if((options)&&(options.animation===true)){
			//Include animation
			chartOptions.animation = true;
			chartOptions.onAnimationComplete = function(){
				if(typeof options.callback == "function"){
					options.callback();
				}
			}
		}

		var myNewChart = new Chart(ctx).Bar(data,chartOptions);

		if((options)&&(options.animation!=true)&&(typeof options.callback == "function")){
			options.callback();
		}
	}

	/**
	* Helpers
	*/
	var _getAnswers = function(results){
		var answers = [];
		var rL = results.length;
		for(var i=0; i<rL; i++){
			answers.push(JSON.parse(results[i].answer));
		}
		return answers;
	}

	var _getQuizParams = function(quiz){
		var params = {};
		params.extras = {};
		try {
			var quizEl = quiz["slides"][0]["elements"][0];
			params.quizType = quizEl["quiztype"];
			if(params.quizType==V.Constant.QZ_TYPE.MCHOICE){
				//Check for multiple answer
				if ((quizEl.extras) && (quizEl.extras.multipleAnswer==true)){
					params.extras.multipleAnswer = true;
				}
			}
			params.choices = quiz["slides"][0]["elements"][0]["choices"];
			params.nAnswers = params.choices.length;
		} catch (e){}
		return params;
	}

	var _purgeString = function(str){
		if(typeof str != "string"){
			return str;
		}
		return str.replace(/Â/g, '');
	}

	return {
		init                : init,
		drawQuizChart       : drawQuizChart
	};
	
}) (VISH, jQuery);



 