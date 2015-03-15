module CatalogueHelper
	def getDefaultCategories
		@default_categories = Hash.new
		for category in Vish::Application.config.catalogue["default_categories"]
			@default_categories[category] = getCategoryResources(category,7)
		end
		@default_categories
	end

	def getCategoryResources(category,limit=100)
		if Vish::Application.config.catalogue['mode'] == "matchtag"
			#Mode matchtag
			tag_ids = Vish::Application.config.catalogue["category_tag_ids"][category]
			RecommenderSystem.search({:category_tag_ids=>tag_ids, :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold=>5})
		else
			#Mode matchany
			keywords = Vish::Application.config.catalogue["category_keywords"][category]
			RecommenderSystem.search({:keywords=>keywords, :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold=>5})
		end
	end
end