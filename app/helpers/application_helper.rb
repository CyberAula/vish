# encoding: utf-8

module ApplicationHelper

	def popular_entities(number=20,models)
		models = VishConfig.getAllResourceModels if models.nil?
		ActivityObject.getPopular(number,{:models=>models, :actor=>current_subject, :random=>true})
	end

	def entities_tagged_with(models,tag)
		models = VishConfig.getAvailableAllResourceModels if models.nil?
		ActivityObject.where("object_type in (?)", models).with_tag(tag).map{|ao| ao.object}
	end

	# Common Utils
	def isAdmin?
		user_signed_in? and current_user.admin?
	end

	def resource_language_options_for_select(selected="")
		options_for_select([[I18n.t('lang.independent'), "independent"], ['Deutsch', "de"], ['English', "en"], ['Español', "es"], ['Français', "fr"], ['Italiano', "it"], ['Magyar', "hu"], ['Nederlands', "nl"], ['Português', "pt"], ['Русский', "ru"], [I18n.t('lang.others'), "ot"]],selected)
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
