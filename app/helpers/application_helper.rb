# encoding: utf-8

module ApplicationHelper
	def categories_select(select_id, item)
	  categories = subject_categories(current_subject, {:scope => :me, :limit => 0})
	  subject_categories_array = categories.map { |category| [category.title, category.id] }.sort_by! {|cat| cat[0]} 
	  categories_selection_array = get_initial_categories(item)
	  select_tag(select_id, options_for_select(subject_categories_array, categories_selection_array), {:title=> t("categories.actions.verb") ,:multiple => true })
	end

	def get_initial_categories(item)	
		categories_selection_array = []
		item.holder_categories.map { |category| categories_selection_array << category.id }
		categories_selection_array
	end

	def popular_excursions(number=10)
		ActivityObject.getPopular(number,{:models=>["Excursion"], :actor=>current_subject, :random=>true})
	end

	def popular_resources(number=10)
		ActivityObject.getPopular(number,{:models=>["Excursion","Document", "Webapp", "Scormfile","Link","Embed"], :actor=>current_subject, :random=>true})
	end

	def excursions_with_tag(tag)
		ActivityObject.tagged_with(tag).sort{ |x,y| y.like_count <=> x.like_count }.map(&:object).select{|a| a.class==Excursion && a.draft == false}
	end

	def category_thumbnail(category)
		thumbs_array = []
		category.property_objects.each do |item|
			if item.object.class == Picture
				thumbs_array << item.object.file.to_s+"?style=500"
			elsif item.object.class == Excursion
				thumbs_array << excursion_raw_thumbail(item.object)
			elsif item.object.class == Event && !item.object.poster.file_file_name.nil?
				thumbs_array << item.object.poster.file.to_s
			end
		end
		
		result = "<div class='category_thumb'>"
		for i in 0..3
			if thumbs_array[i]
				result += "<div class='category_thumb_"+i.to_s+"'><img src='"+thumbs_array[i]+"'/></div>"
			else
				result += "<div class='category_thumb_"+i.to_s+"'></div>"
			end
		end			
		result += "</div>"
		return raw result
	end
	
	def new_category_thumbnail(category)
		thumbs_array = []
    	category.property_objects.each do |item|
	      	if item.object.class == Picture
	        	thumbs_array << item.object.file.to_s+"?style=500"
	      	elsif item.object.class == Excursion
	        	thumbs_array << excursion_raw_thumbail(item.object)
	      	elsif item.object.class == Event && !item.object.poster.file_file_name.nil?
	        	thumbs_array << item.object.poster.file.to_s
	      	end
    	end
    	thumbs_array
	end

	def isAdmin?
		user_signed_in? and current_user.admin?
	end

	def resource_language_options_for_select(selected="")
		options_for_select([[I18n.t('lang.independent'), ""], ['Deutsch', "de"], ['English', "en"], ['Español', "es"], ['Français', "fr"], ['Italiano', "it"], ['Magyar', "hu"], ['Nederlands', "nl"], ['Português', "pt"], ['Русский', "ru"], [I18n.t('lang.others'), "ot"]],selected)
	end

	#Configuration
	def available_models
		VishConfig.getAvailableMainModels
	end

	def home_models
		VishConfig.getHomeModels
	end

	def catalogue_models
		VishConfig.getCatalogueModels
	end

	def available_services
		VishConfig.getAvailableServices
	end

end
