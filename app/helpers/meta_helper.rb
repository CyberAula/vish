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

	def alternate_urls url, item
		if url.nil? || url==""
			return ""
		end
		content_lang = ""
		urls = ""
		if item && !item.language.nil? && item.language !="independent"
			content_lang = "-" + item.language
		end
		locale_extension = url.include?("?") ? "&locale=" : "?locale=" 
		I18n.available_locales.each do |loc|
			urls += "<link rel='alternate' href='"+url +locale_extension+loc.to_s+"' hreflang='"+loc.to_s+content_lang+"' />"
		end
		return urls
	end
end
