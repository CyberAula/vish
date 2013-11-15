SocialStream.Follow = (function(SS, $, undefined){
	var initButtons = function(){
		$(".btn-following").off("mouseenter");
		$(".btn-following").mouseenter(function(){
			$(this).hide();
			$(this).siblings(".btn-unfollow").show();
		});

		$(".btn-unfollow").off("mouseleave");
		$(".btn-unfollow").mouseleave(function(){
			$(this).hide();
			$(this).siblings(".btn-following").show();
		});

		$(".btn-unfollow").hide();
	}

	$(function(){
		SocialStream.Follow.initButtons();
	});

	return {
		initButtons: initButtons
	};
})(SocialStream, jQuery);
