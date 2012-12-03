$(document).ready(function(){
 	VishCache.init();
 	// VishCache.Renderer.renderUsers($(".users_btn_follow-sugestion")[0]);
});

VishCache = (function(undefined){
	
	var TIMESTAMP_KEY = "Timestamp";
	var USERS_KEY = "Users";
	var LOS_KEY = "LearningObjects";

	var init = function(){
		if(Unistorage){
			Unistorage.init();
		}

		//Check Timestamp
		$.ajax({
	        type: "GET",
	        url: "/recSys/timestamp.json",
	        dataType:"html",
	        success:function(response){
				var currentTimestamp = JSON.parse(response)["timestamp"];

				//Get previous timestamp
				Unistorage.get(TIMESTAMP_KEY, function(timestamp){
					//Compare
					if((!timestamp)||(_timestampComparison(timestamp,currentTimestamp)===-1)){
						//Update timestamp needed
						Unistorage.store(TIMESTAMP_KEY,currentTimestamp);
						requestData();
					}
				});
	        }
   		 });
	}

	var requestData = function(){
		$.ajax({
	        type: "GET",
	        url: "/recSys/data.json",
	        dataType:"html",
	        success:function(response){
	            var data = JSON.parse(response);
	            Unistorage.storeJSON(USERS_KEY,data["rec_users"]);
	            Unistorage.storeJSON(LOS_KEY,data["rec_los"]);
	        }
   		 });
	}

	/**
		Compare two timestamps
		-1 		if t1 < t2
		0 		if t1 = t2
		1 		if t1 > t2
		null 	if t1 or t2 is an illegal date
	*/
	var _timestampComparison = function(t1,t2){
		try {
			var d1 = new Date(t1).getTime();
			var d2 = new Date(t2).getTime();
		} catch(thrownError){
			return null;
		}

		if(d1>d2){
			return 1;
		} else if(d1===d2){
			return 0;
		} else {
			return -1;
		}
	}

    return {
		init 		: init,
		USERS_KEY 	: USERS_KEY,
		LOS_KEY		: LOS_KEY
    };

}) ();



VishCache.Renderer = (function(undefined){

	var renderUsers = function(container){
		Unistorage.getJSON(VishCache.USERS_KEY, function(users){
			if(users){
				$.each(users, function(index, user) {
				    if(index<3){
				    	$(container).prepend(_renderUserRow(user));
				    }
				});
			}
		});
	}

	var renderLOs = function(container){
		//TODO...
	}

	var _renderUserRow = function(user){
		var slug = user.name;
		return '<div class="contact pull-left" id="'+user.contact_id+'">'			+
		'<div class="row"><ul class="thumbnails span3"><li class="span1">'			+
		'<a data-toggle="modal" href="#user-modal-'+slug+'" class="user-modal-button-'+slug+' container modal-trigger">' +
		'        <img alt="Images20121128-15469-r6lqkf" src="'+user.avatar+'"></a>'	+
		'      </li>' 																+
		'      <li class="span">'													+
		'        <div class="caption ">'											+
		'       <div class="title_suggestion">'										+
		'          <h4 class="ellipsis percent95"><a data-toggle="modal" href="#user-modal-'+slug+'" class="user-modal-button-'+slug+' contact_link modal-trigger">'+user.name+'</a></h4>'			+
		'        </div>'															+
		'          <a class="close_suggestion"> </a><a href="/contacts/'+user.contact_id+'" data-method="delete" data-remote="true" rel="nofollow"><i class="icontool16-tool16_close_2"></i> </a>'			+
		'        <div class="follwrs-ing">'											+
		'          <div class="follwrs upfoll">seguidores: <a href="/users/jessica-graham/followers">'+user.followers+'</a></div>'			+
		'          <div class="folling upfoll">siguiendo: <a href="/users/jessica-graham/followings">'+user.following+'</a></div>'			+
		'        </div>'															+
		'        <div class="send_messag size10 red-2 upfoll users_btn_follow"><div class="follow-link-contact_'+user.contact_id+'">'			+
		'    <div class="btn btn-primary follow btn-follow">'						+
		'      <a href="/followers/'+user.contact_id+'" data-method="put" data-remote="true" rel="nofollow">Seguir</a>'			+
		'    </div>'																+
		'</div>'																	+
		'</div>'																	+
		'        </div>'															+
		'      </li>'																+
		'    </ul>'																	+
		'  </div>'																	+
		'  <div class="space_center">'												+
		'  </div>'																	+
		'</div>';
	}

    return {
		renderUsers : renderUsers,
		renderLOs	: renderLOs
    };

}) ();

