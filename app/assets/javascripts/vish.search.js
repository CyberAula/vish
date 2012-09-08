//= require vish

Vish.Search = function(V, $, undefined){
	var index = function(options){
		$('#tab').children('li').each(function(){
			if ($(this).hasClass('disabled')) {
			        $(this).off('click');
				return;
			}

			var anchor = $(this).find('a').attr('href').replace('#', '');

			$(this).off('click');
			$(this).on('click', function(){
				var indexPath = options['indexPath'];
				var typeParam = (anchor == 'all' ? '' : 'type=' + anchor);
				var query;

				if (indexPath.match(/type=/)) {
					query = indexPath.replace(/type=\w*/, typeParam);
				} else if (anchor != 'all') {
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
