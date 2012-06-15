//= require vish

Vish.Filter = function(V, $, undefined){
        var loaded = false;
        var init = function(){
	        Vish.Filter.loaded=true;

                $('#excursion-filter').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#excursion-filter')[0].value, scope: "net", per_page: 4 },
                                success: function(data) { $('#excursions').html(data); }
                        });
                });

                $('#excursion-filter-more').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#excursion-filter-more')[0].value, scope: "other", per_page: 4 },
                                success: function(data) { $('#more').html(data); }
                        });
                });

                $('#excursion-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#excursion-filter-me')[0].value, scope: "me", per_page: 4 },
                                success: function(data) { $('#excursions-me').html(data); }
                        });
                });

                $('#document-filter').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#document-filter')[0].value, scope: "net", per_page: 8 },
                                success: function(data) { $('#repository').html(data); }
                        });
                });

                $('#document-filter-more').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#document-filter-more')[0].value, scope: "other", per_page: 8 },
                                success: function(data) { $('#repository-more').html(data); }
                        });
                });

                $('#document-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#document-filter-me')[0].value, scope: "me", per_page: 8 },
                                success: function(data) { $('#repository-me').html(data); }
                        });
                });

                $('#repository-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#repository-filter-me')[0].value, scope: "me", per_page: 16, print_format: "repo" },
                                success: function(data) { $('#repository-me').html(data); }
                        });
                });
        }

        return {
	        loaded: loaded,
	        init: init
	};
}(Vish, jQuery);

