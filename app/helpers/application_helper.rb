# encoding: utf-8

module ApplicationHelper

	def popular_entities(number=20,models)
		models = VishConfig.getAllResourceModels if models.nil?
		ActivityObject.getPopular(number,{:models=>models, :actor=>current_subject, :random=>true})
	end

	def entities_tagged_with(models,tag)
		models = VishConfig.getAvailableResourceModels if models.nil?
		ActivityObject.where("object_type in (?)", models).with_tag(tag).map{|ao| ao.object}
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

	# Common Utils
	def isAdmin?
		user_signed_in? and current_user.admin?
	end

	def resource_language_options_for_select(selected="")
		options_for_select(resource_languages,selected)
	end

	def resource_languages
		[[I18n.t('lang.languages.independent'), "independent"]] +
		[[I18n.t('lang.languages.de'), "de"], [I18n.t('lang.languages.en'), "en"], [I18n.t('lang.languages.es'), "es"], [I18n.t('lang.languages.fr'), "fr"], [I18n.t('lang.languages.it'), "it"], [I18n.t('lang.languages.hu'), "hu"], [I18n.t('lang.languages.nl'), "nl"], [I18n.t('lang.languages.pt'), "pt"], [I18n.t('lang.languages.ru'), "ru"]].sort_by{|l| l[0]} +
		[[I18n.t('lang.languages.other'), "ot"]]
	end

	def search_resource_languages
		[[I18n.t('lang.languages.independent'), "independent"]] +
		[[I18n.t('lang.languages.de'), "de"], [I18n.t('lang.languages.en'), "en"], [I18n.t('lang.languages.es'), "es"], [I18n.t('lang.languages.fr'), "fr"]] +
		[[I18n.t('lang.languages.other'), "ot"]]
	end

	#Configuration
	def available_models
		VishConfig.getAvailableMainModels
	end

	def available_resource_types
		VishConfig.getAvailableResourceModels
	end

	def home_models
		VishConfig.getHomeModels
	end

	def catalogue_models
		VishConfig.getCatalogueModels
	end

	def directory_models
		VishConfig.getDirectoryModels
	end

	def available_services
		VishConfig.getAvailableServices
	end

end
