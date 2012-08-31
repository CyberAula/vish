SocialStream.Follow = (function(SS, $, undefined){
	var initButtons = function(){
		$(".following-button").off("mouseenter");
		$(".following-button").mouseenter(function(){
			$(this).hide();
			$(this).siblings(".unfollow-button").show();
		});

		$(".unfollow-button").off("mouseenter");
		$(".unfollow-button").mouseleave(function(){
			$(this).hide();
			$(this).siblings(".following-button").show();
		});

		$(".unfollow-button").hide();
	}

	$(function(){
		SocialStream.Follow.initButtons();
	});

	return {
		initButtons: initButtons
	};
})(SocialStream, jQuery);
