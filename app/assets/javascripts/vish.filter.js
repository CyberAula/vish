//= require vish

Vish.Filter = function(V, $, undefined){
        var init = function(){
                $('#excursion-filter').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#excursion-filter')[0].value, scope: "net" },
                                success: function(data) { $('#excursions').html(data); }
                        });
                });

                $('#excursion-filter-more').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#excursion-filter-more')[0].value, scope: "more" },
                                success: function(data) { $('#more').html(data); }
                        });
                });

                $('#excursion-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#excursion-filter-me')[0].value, scope: "me", user_id: $('#excursion-filter-me-user').val() },
                                success: function(data) { $('#excursions').html(data); }
                        });
                });

                $('#document-filter').on("keyup", function() {
                        $.ajax({
                                url: "/documents/search",
                                data: { q: $('#document-filter')[0].value, scope: "net" },
                                success: function(data) { $('#repository').html(data); }
                        });
                });

                $('#document-filter-more').on("keyup", function() {
                        $.ajax({
                                url: "/documents/search",
                                data: { q: $('#document-filter-more')[0].value, scope: "more" },
                                success: function(data) { $('#repository-more').html(data); }
                        });
                });
        }

        return {
	        init: init
	};
}(Vish, jQuery);

