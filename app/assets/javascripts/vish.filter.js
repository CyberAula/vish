//= require vish

Vish.Filter = function(V, $, undefined){
        var loaded = false;
        var init = function(){
	        Vish.Filter.loaded=true;

		/* Filters for home-excursions */
                $('#home-excursion-filter-net').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#home-excursion-filter-net')[0].value, scope: "net", per_page: 4 },
                                success: function(data) { $('#home-excursions-net').html(data); }
                        });
                });

                $('#home-excursion-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#home-excursion-filter-me')[0].value, scope: "me", per_page: 4 },
                                success: function(data) { $('#home-excursions-me').html(data); }
                        });
                });

                $('#home-excursion-filter-more').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#home-excursion-filter-more')[0].value, scope: "other", per_page: 4 },
                                success: function(data) { $('#home-excursions-more').html(data); }
                        });
                });

                $('#home-excursion-filter-fav').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#home-excursion-filter-fav')[0].value, scope: "like", per_page: 4 },
                                success: function(data) { $('#home-excursions-fav').html(data); }
                        });
                });


		/* Filters for home-resources */
                $('#home-resource-filter-net').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#home-resource-filter-net')[0].value, scope: "net", per_page: 6 },
                                success: function(data) { $('#home-resources-net').html(data); }
                        });
                });

                $('#home-resource-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#home-resource-filter-me')[0].value, scope: "me", per_page: 6 },
                                success: function(data) { $('#home-resources-me').html(data); }
                        });
                });

                $('#home-resource-filter-more').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#home-resource-filter-more')[0].value, scope: "other", per_page: 6 },
                                success: function(data) { $('#home-resources-more').html(data); }
                        });
                });

                $('#home-resource-filter-fav').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#home-resource-filter-fav')[0].value, scope: "like", per_page: 6 },
                                success: function(data) { $('#home-resources-fav').html(data); }
                        });
                });


		/* Filters for profile-excursions */
                $('#profile-excursion-filter-net').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#profile-excursion-filter-net')[0].value, scope: "net", per_page: 4 },
                                success: function(data) { $('#profile-excursions-net').html(data); }
                        });
                });

                $('#profile-excursion-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#profile-excursion-filter-me')[0].value, scope: "me", per_page: 4 },
                                success: function(data) { $('#profile-excursions-me').html(data); }
                        });
                });

                $('#profile-excursion-filter-fav').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#profile-excursion-filter-fav')[0].value, scope: "like", per_page: 4 },
                                success: function(data) { $('#profile-excursions-fav').html(data); }
                        });
                });


		/* Filters for profile-resources */
                $('#profile-resource-filter-net').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#profile-resource-filter-net')[0].value, scope: "net", per_page: 4 },
                                success: function(data) { $('#profile-resources-net').html(data); }
                        });
                });

                $('#profile-resource-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#profile-resource-filter-me')[0].value, scope: "me", per_page: 4 },
                                success: function(data) { $('#profile-resources-me').html(data); }
                        });
                });

                $('#profile-resource-filter-fav').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#profile-resource-filter-fav')[0].value, scope: "like", per_page: 4 },
                                success: function(data) { $('#profile-resources-fav').html(data); }
                        });
                });


		/* Filters for repo-excursions */
                $('#repo-excursion-filter-net').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#repo-excursion-filter-net')[0].value, scope: "net", per_page: 20 },
                                success: function(data) { $('#repo-excursions-net').html(data); }
                        });
                });

                $('#repo-excursion-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#repo-excursion-filter-me')[0].value, scope: "me", per_page: 20 },
                                success: function(data) { $('#repo-excursions-me').html(data); }
                        });
                });

                $('#repo-excursion-filter-fav').on("keyup", function() {
                        $.ajax({
                                url: "/excursions/search",
                                data: { q: $('#repo-excursion-filter-fav')[0].value, scope: "like", per_page: 20 },
                                success: function(data) { $('#repo-excursions-fav').html(data); }
                        });
                });


		/* Filters for repo-resources */
                $('#repo-resource-filter-net').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#repo-resource-filter-net')[0].value, scope: "net", per_page: 20 },
                                success: function(data) { $('#repo-resources-net').html(data); }
                        });
                });

                $('#repo-resource-filter-me').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#repo-resource-filter-me')[0].value, scope: "me", per_page: 20 },
                                success: function(data) { $('#repo-resources-me').html(data); }
                        });
                });

                $('#repo-resource-filter-fav').on("keyup", function() {
                        $.ajax({
                                url: "/resources/search",
                                data: { q: $('#repo-resource-filter-fav')[0].value, scope: "like", per_page: 20 },
                                success: function(data) { $('#repo-resources-fav').html(data); }
                        });
                });


		/* Followers filter in full view */
                $('#follower-filter').on("keyup", function() {
                        $.ajax({
                                url: "/followers/search",
                                data: { q: $('#follower-filter')[0].value, per_page: 20 },
                                success: function(data) { $('#repo-resources-net').html(data); }
                        });
                });

                $('#following-filter').on("keyup", function() {
                        $.ajax({
                                url: "/followings/search",
                                data: { q: $('#following-filter')[0].value, per_page: 20 },
                                success: function(data) { $('#repo-resources-me').html(data); }
                        });
                });

        }

        return {
	        loaded: loaded,
	        init: init
	};
}(Vish, jQuery);

