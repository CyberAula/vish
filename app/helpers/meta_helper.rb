module MetaHelper

	#helpers for user profile
	def profile_title user, tab
		if tab.nil?
			user.name + " - " + t("site.meta_title.profile")
		else
			user.name + " - " + t("search.models."+tab.singularize, :default => "")
		end
	end	

	def profile_desc user, tab
		if tab.nil?
			t("site.meta_desc.profile") + user.name + ". " + t("site.meta_desc.profile2")
		else
			t("site.meta_desc.tab_"+tab, :default => "") + user.name
		end
	end	
end
