var VISH = VISH || {};
VISH.Constant = VISH.Constant || {};
VISH.Constant.QZ_TYPE = VISH.Constant.QZ_TYPE || {};
VISH.Constant.QZ_TYPE.OPEN = "openAnswer";
VISH.Constant.QZ_TYPE.MCHOICE = "multiplechoice";
VISH.Constant.QZ_TYPE.TF = "truefalse";
VISH.Constant.QZ_TYPE.SORTING = "sorting";


VISH.QuizCharts = (function(V,$,undefined){
  
	var pieBackgroundColor = ["#F38630","#E0E4CC","#69D2E7","#FFF82A","#FF0FB4","#2A31FF","#FF6075","#00D043"];
	var pieLetterColor = ["#000"];

	//Translations
	var language = "en";
	var i18n = 
		{ "es":
			{
				"i.T"			: "V",
				"i.F"			: "F",
				"i.Correct"		: "Correctas",
				"i.Incorrect"	: "Incorrectas",
				"i.Responses"	: "Respuestas",
				"i.WaitingResponses"	: "Esperando respuestas..."
			},
		  "default":
			{
				"i.T"			: "T",
				"i.F"			: "F",
				"i.Correct"		: "Correct",
				"i.Incorrect"	: "Incorrect",
				"i.Responses"	: "Responses",
				"i.WaitingResponses"	: "Waiting for responses..."
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

		_insertCss("div.openQuizAnswersListWrapper{ overflow: auto; -moz-box-sizing: border-box; -webkit-box-sizing: border-box; box-sizing: border-box; padding: 15px;} ul.openQuizAnswersList{ padding: 0px; list-style: none; } ul.openQuizAnswersList li { font-family: 'Open Sans', arial, sans-serif; position: relative; font-style: italic; border-bottom: 1px solid #D7EEFF; padding: 3% 6% 2% 6%; font-size: 1.2rem; } ul.openQuizAnswersList li:first-child { padding-left: 10%; text-align: left; color: #838383; font-weight: bold; border-bottom: 1px solid #D8DAFF; padding-top: 0%; border-bottom: 1px solid #AFAFAF; font-style: normal; padding-bottom: 20px; font-size: 1.7rem; } ul.openQuizAnswersList li:last-child { -webkit-border-bottom-left-radius: 15px; -webkit-border-bottom-right-radius: 15px; -moz-border-radius-bottomleft: 15px; -moz-border-radius-bottomright: 15px; border-bottom-left-radius: 15px; border-bottom-right-radius: 15px; }");
		_insertCss("div.openQuizAnswerLeft{position: absolute; width: 5%; height: 70%; top: 15%; left: 3%; background-image: url('"+(VISH.ImagesPath||"")+"vicons/userAnswer.png'); background-position: center; background-size: contain; background-repeat: no-repeat;} div.openQuizAnswerRight{ margin-left: 5%; };");
	};

	var _getTrans = function(s,params){
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
	};


	/* Draw Methods */

	var drawQuizChart = function(canvas,quizJSON,results,options){
		var quizParams = _getQuizParams(quizJSON);
		var answersList = _getAnswers(results);

		switch(quizParams.quizType){
		case V.Constant.QZ_TYPE.OPEN:
			_drawOpenEndedQuizAnswers(canvas,quizParams,answersList,options);
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
		case V.Constant.QZ_TYPE.SORTING:
			_drawSortingQuizChart(canvas,quizParams,answersList,options);
			break;
		default:
			return null; 
			break;
		}
	};

	var _drawMcChoiceQuizChart = function(canvas,quizParams,answersList,options){
		var pieFragments = {};
		var data = [];
		var pBCL = pieBackgroundColor.length;
		var pLCL = pieLetterColor.length;

		var choicesQuantity = quizParams.choices.length;
		for(var i=0; i<choicesQuantity; i++){
			var choiceId = quizParams.choices[i].id;
			pieFragments[choiceId] = {};
			pieFragments[choiceId].value = 0;
			pieFragments[choiceId].label = String.fromCharCode(96+i+1);
			pieFragments[choiceId].color = pieBackgroundColor[i%pBCL];
			pieFragments[choiceId].labelColor = pieLetterColor[i%pLCL];
			pieFragments[choiceId].labelFontSize = '16';
			pieFragments[choiceId].tooltipLabel = _purgeString(quizParams.choices[i].value);
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var choiceId = answer.choiceId;

				if((answer.answer==="true")&&(pieFragments[choiceId])){
					pieFragments[choiceId].value++;
				}
			}
		}

		for(var l=0; l<choicesQuantity; l++){
			var choiceId = quizParams.choices[l].id;
			data.push(pieFragments[choiceId]);
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
	};

	var _drawMcChoiceMAnswerQuizChart = function(canvas,quizParams,answersList,options){
		var labels = {};
		var tooltipLabels = {};
		var dataValues = {};
		var maxValue = 0;
		var scaleSteps = 10;

		var choicesQuantity = quizParams.choices.length;
		for(var i=0; i<choicesQuantity; i++){
			var choiceId = quizParams.choices[i].id;
			labels[choiceId] = String.fromCharCode(96+i+1);
			tooltipLabels[choiceId] = _purgeString(quizParams.choices[i].value);
			dataValues[choiceId] = 0;
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var choiceId = answer.choiceId;
				if(answer.answer==="true"){
					dataValues[choiceId]++;
				}
			} 
		}

		for(var l=0; l<choicesQuantity; l++){
			var choiceId = quizParams.choices[l].id;
			if(dataValues[choiceId] > maxValue){
				maxValue = dataValues[choiceId];
			}
		}

		if(maxValue<10){
			scaleSteps = Math.max(1,maxValue);
		}

		var ctx = $(canvas).get(0).getContext("2d");
		var data = {
			labels : $.map(labels, function(v){return v;}),
			tooltipLabels: $.map(tooltipLabels, function(v){return v;}),
			datasets : [
				{
					fillColor : "#E2FFE3",
					strokeColor : "rgba(220,220,220,1)",
					data : $.map(dataValues, function(v){return v;})
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
	};


	var _drawTFQuizChart = function(canvas,quizParams,answersList,options){
		var labels = {};
		var tooltipLabels = {};
		var dataTrue = {};
		var dataFalse = {};
		var maxValue = 0;
		var scaleSteps = 10;

		var choicesQuantity = quizParams.choices.length;
		for(var i=0; i<choicesQuantity; i++){
			var choiceId = quizParams.choices[i].id;

			labels[choiceId] = _getTrans("i.T") + "       " + String.fromCharCode(96+i+1) + "       " + _getTrans("i.F");
			tooltipLabels[choiceId] = _purgeString(quizParams.choices[i].value);
			dataTrue[choiceId] = 0;
			dataFalse[choiceId] = 0;
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var choiceId = answer.choiceId;

				if(answer.answer==="true"){
					dataTrue[choiceId]++;
				} else {
					dataFalse[choiceId]++;
				}
			}
		}

		for(var l=0; l<choicesQuantity; l++){
			var choiceId = quizParams.choices[l].id;
			if(dataTrue[choiceId] > maxValue){
				maxValue = dataTrue[choiceId];
			}
			if(dataFalse[choiceId] > maxValue){
				maxValue = dataFalse[choiceId];
			}
		}

		if(maxValue<10){
			scaleSteps = Math.max(1,maxValue);
		}

		var ctx = $(canvas).get(0).getContext("2d");
		var data = {
			labels : $.map(labels, function(v){return v;}),
			tooltipLabels: $.map(tooltipLabels, function(v){return v;}),
			datasets : [
				{
					fillColor : "#E2FFE3",
					strokeColor : "rgba(220,220,220,1)",
					data : $.map(dataTrue, function(v){return v;})
				},
				{
					fillColor : "#FFE2E2",
					strokeColor : "rgba(220,220,220,1)",
					data : $.map(dataFalse, function(v){return v;})
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
	};

	var _drawSortingQuizChart = function(canvas,quizParams,answersList,options){
		var pieFragments = {};
		var data = [];
		var pBCL = pieBackgroundColor.length;
		var pLCL = pieLetterColor.length;

		for(var i=0; i<2; i++){
			var fragmentId = (i===0) ? "true" : "false";
			pieFragments[fragmentId] = {};
			pieFragments[fragmentId].value = 0;
			pieFragments[fragmentId].label = (i===0) ? _getTrans("i.Correct") : _getTrans("i.Incorrect");
			pieFragments[fragmentId].color = pieBackgroundColor[i%pBCL];
			pieFragments[fragmentId].labelColor = pieLetterColor[i%pLCL];
			pieFragments[fragmentId].labelFontSize = '16';
			pieFragments[fragmentId].tooltipLabel = (i===0) ? _getTrans("i.Correct") : _getTrans("i.Incorrect");
		}

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				if((answer.selfAssessment)&&(typeof answer.selfAssessment.result == "boolean")){
					if(answer.selfAssessment.result===true){
						pieFragments["true"].value++;
					} else {
						pieFragments["false"].value++;
					}
				}
			}
		}

		data.push(pieFragments["true"]);
		data.push(pieFragments["false"]);

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
	};

	var _drawOpenEndedQuizAnswers = function(canvas,quizParams,answersList,options){
		//Answer from open ended quizzes are not drawing in a canvas.
		//Instead, we will use a div

		var canvasWrapper = $(canvas).parent();
		var container = $(canvasWrapper).find("div.openQuizAnswersListWrapper");

		if($(container).length===0){
			//Create container
			var canvasWidth = $(canvas).width();
			var canvasHeight = $(canvas).height();

			if(canvasWidth===0){
				canvasWidth = $(canvas).attr("width");
			}
			if(canvasHeight===0){
				canvasHeight = $(canvas).attr("height");
			}

			container = $("<div class='openQuizAnswersListWrapper' style='width:"+canvasWidth+"px; height:"+canvasHeight+"px; display: block;'></div>");
			$(container).insertBefore(canvas);
		}

		$(canvas).hide();
		$(container).html("");
		$(container).append("<ul class='openQuizAnswersList'></ul>");
		var answersListDOM = $(container).find("ul.openQuizAnswersList");

		var alL = answersList.length;
		for(var j=0; j<alL; j++){
			//List of answers of a user
			var answers = answersList[j];

			var aL = answers.length;
			for(var k=0; k<aL; k++){
				var answer = answers[k];
				var userAnswer = answer.answer;
				$(answersListDOM).append("<li><div class='openQuizAnswerLeft'></div><div class='openQuizAnswerRight'>"+userAnswer+"</div></li>");
			} 
		}

		if($(answersListDOM).children().length===0){
			$(answersListDOM).append("<li>"+_getTrans("i.WaitingResponses")+"</li>");
		} else {
			$(answersListDOM).prepend("<li>"+_getTrans("i.Responses")+"</li>");
		}

		if(typeof options.callback == "function"){
			options.callback();
		}
	};

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
	};

	var _getQuizParams = function(quiz){
		var params = {};
		params.extras = {};
		try {
			var quizEls = quiz["slides"][0]["elements"];
			var quizElsL = quizEls.length;
			for(var i=0; i<quizElsL; i++){
				if (quizEls[i]["type"]==="quiz"){
					var quizEl = quizEls[i];
					params.quizType = quizEl["quiztype"];
					if(params.quizType==V.Constant.QZ_TYPE.MCHOICE){
						//Check for multiple answer
						if ((quizEl.extras) && (quizEl.extras.multipleAnswer==true)){
							params.extras.multipleAnswer = true;
						}
					}
					params.choices = quizEl["choices"];
					params.nAnswers = params.choices.length;
				}
			}
		} catch (e){}
		return params;
	};

	var _purgeString = function(str){
		if(typeof str != "string"){
			return str;
		}
		str = str.replace(/â€‹/g, '');
		return str.replace(/Â/g, '');
	};

	var _insertCss = function(code){
		var style = document.createElement('style');
		style.type = 'text/css';

		if (style.styleSheet) {
			// IE
			style.styleSheet.cssText = code;
		} else {
			// Other browsers
			style.innerHTML = code;
		}
		document.getElementsByTagName("head")[0].appendChild(style);
	};

	return {
		init                : init,
		drawQuizChart       : drawQuizChart
	};
	
}) (VISH, jQuery);



 