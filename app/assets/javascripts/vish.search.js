//= require vish

Vish.Search = function(V, $, undefined){
	var index = function(options){
		$('#tab').children('li').each(function(){
			if ($(this).hasClass('disabled')) {
				return;
			}

			var anchor = $(this).find('a').attr('href').replace('#', '');
			if (anchor == 'all') {
				return;
			}

			$(this).click(function(){
				var indexPath = options['indexPath'];
				var typeParam = 'type=' + anchor;
				var query;

				if (indexPath.match(/type=/)) {
					query = indexPath.replace(/type=\w*/, typeParam);
				} else {
					if (indexPath.match(/\?/)) {
						query = indexPath + '&' + typeParam;
					} else {
						query = indexPath + '?' + typeParam;
					}
				}

				$.ajax({
					url: query,
					dataType: 'script'
				});
			});

		});
        }

	return {
		index: index
	}
}(Vish, jQuery);
