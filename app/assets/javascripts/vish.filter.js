//= require vish

Vish.Filter = function(V, $, undefined){
        var init = function(){
                $('#excursion-filter').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/filter",
                                data: { q: $('#excursion-filter')[0].value, scope: "net" },
                                success: function(data) {
                                        $('#excursions').empty();
                                        $('#excursions').html(data);
                                }
                        });
                });
        }

        return {
	        init: init
	};
}(Vish, jQuery);

