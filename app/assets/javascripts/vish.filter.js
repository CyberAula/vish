//= require vish

Vish.Filter = function(V, $, undefined){
        var loaded = false;
	var isReturn = function(e){
	  c = e.which ? e.which : e.keyCode;
	  return c == 13
	}
        var init = function(){
	        Vish.Filter.loaded=true;

		/* Filters for home-excursions */
		if (! $('#home-excursion-filter-net').data('events')) {
                  $('#home-excursion-filter-net').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#home-excursion-filter-net')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#home-excursion-filter-net')[0].value, scope: "net", per_page: 4 },
                        success: function(data) { $('#home-excursions-net').html(data); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#home-excursion-filter-me').data('events')) {
                  $('#home-excursion-filter-me').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#home-excursion-filter-me')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#home-excursion-filter-me')[0].value, scope: "me", per_page: 4 },
                        success: function(data) { $('#home-excursions-me').html(data); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#home-excursion-filter-fav').data('events')) {
                  $('#home-excursion-filter-fav').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#home-excursion-filter-fav')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#home-excursion-filter-fav')[0].value, scope: "like", per_page: 4 },
                        success: function(data) { $('#home-excursions-fav').html(data); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}


		/* Filters for home-resources */
		if (! $('#home-resource-filter-net').data('events')) {
                  $('#home-resource-filter-net').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#home-resource-filter-net')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#home-resource-filter-net')[0].value, scope: "net", per_page: 6 },
                        success: function(data) { $('#home-resources-net').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#home-resource-filter-me').data('events')) {
                  $('#home-resource-filter-me').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#home-resource-filter-me')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#home-resource-filter-me')[0].value, scope: "me", per_page: 6 },
                        success: function(data) { $('#home-resources-me').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#home-resource-filter-fav').data('events')) {
                  $('#home-resource-filter-fav').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#home-resource-filter-fav')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#home-resource-filter-fav')[0].value, scope: "like", per_page: 6 },
                        success: function(data) { $('#home-resources-fav').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}


		/* Filters for profile-excursions */
		if (! $('#profile-excursion-filter-net').data('events')) {
                  $('#profile-excursion-filter-net').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#profile-excursion-filter-net')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#profile-excursion-filter-net')[0].value, scope: "net", per_page: 4 },
                        success: function(data) { $('#profile-excursions-net').html(data); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#profile-excursion-filter-me').data('events')) {
                  $('#profile-excursion-filter-me').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#profile-excursion-filter-me')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#profile-excursion-filter-me')[0].value, scope: "me", per_page: 4 },
                        success: function(data) { $('#profile-excursions-me').html(data); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#profile-excursion-filter-fav').data('events')) {
                  $('#profile-excursion-filter-fav').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#profile-excursion-filter-fav')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#profile-excursion-filter-fav')[0].value, scope: "like", per_page: 4 },
                        success: function(data) { $('#profile-excursions-fav').html(data); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}


		/* Filters for profile-resources */
		if (! $('#profile-resource-filter-net').data('events')) {
                  $('#profile-resource-filter-net').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#profile-resource-filter-net')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#profile-resource-filter-net')[0].value, scope: "net", per_page: 4 },
                        success: function(data) { $('#profile-resources-net').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#profile-resource-filter-me').data('events')) {
                  $('#profile-resource-filter-me').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#profile-resource-filter-me')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#profile-resource-filter-me')[0].value, scope: "me", per_page: 4 },
                        success: function(data) { $('#profile-resources-me').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#profile-resource-filter-fav').data('events')) {
                  $('#profile-resource-filter-fav').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#profile-resource-filter-fav')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#profile-resource-filter-fav')[0].value, scope: "like", per_page: 4 },
                        success: function(data) { $('#profile-resources-fav').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}


		/* Filters for repo-excursions */
		if (! $('#repo-excursion-filter-net').data('events')) {
                  $('#repo-excursion-filter-net').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#repo-excursion-filter-net')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#repo-excursion-filter-net')[0].value, scope: "net", per_page: 20 },
                        success: function(data) { $('#repo-excursions-net').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#repo-excursion-filter-me').data('events')) {
                  $('#repo-excursion-filter-me').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#repo-excursion-filter-me')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#repo-excursion-filter-me')[0].value, scope: "me", per_page: 20 },
                        success: function(data) { $('#repo-excursions-me').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#repo-excursion-filter-fav').data('events')) {
                  $('#repo-excursion-filter-fav').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=excursion&q=' + escape($('#repo-excursion-filter-fav')[0].value)
		    } else {
                      $.ajax({
                        url: "/excursions/search",
                        data: { q: $('#repo-excursion-filter-fav')[0].value, scope: "like", per_page: 20 },
                        success: function(data) { $('#repo-excursions-fav').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}


		/* Filters for repo-resources */
		if (! $('#repo-resource-filter-net').data('events')) {
                  $('#repo-resource-filter-net').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#repo-resource-filter-net')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#repo-resource-filter-net')[0].value, scope: "net", per_page: 20 },
                        success: function(data) { $('#repo-resources-net').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#repo-resource-filter-me').data('events')) {
                  $('#repo-resource-filter-me').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#repo-resource-filter-me')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#repo-resource-filter-me')[0].value, scope: "me", per_page: 20 },
                        success: function(data) { $('#repo-resources-me').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#repo-resource-filter-fav').data('events')) {
                  $('#repo-resource-filter-fav').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=resource&q=' + escape($('#repo-resource-filter-fav')[0].value)
		    } else {
                      $.ajax({
                        url: "/resources/search",
                        data: { q: $('#repo-resource-filter-fav')[0].value, scope: "like", per_page: 20 },
                        success: function(data) { $('#repo-resources-fav').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}


		/* Followers filter in full view */
		if (! $('#follower-filter').data('events')) {
                  $('#follower-filter').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=user&q=' + escape($('#follower-filter')[0].value)
		    } else {
                      $.ajax({
                        url: "/followers/search",
                        data: { q: $('#follower-filter')[0].value, per_page: 20 },
                        success: function(data) { $('#followers').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

		if (! $('#following-filter').data('events')) {
                  $('#following-filter').on("keyup", function(e) {
		    if(isReturn(e)) {
		      window.location.href = '/search?type=user&q=' + escape($('#following-filter')[0].value)
		    } else {
                      $.ajax({
                        url: "/followings/search",
                        data: { q: $('#following-filter')[0].value, per_page: 20 },
                        success: function(data) { $('#followings').html(data); Vish.Wall.initModals(); SocialStream.Follow.initButtons(); }
                      });
		    }
                  });
		}

        }

        return {
	        loaded: loaded,
	        init: init
	};
}(Vish, jQuery);

