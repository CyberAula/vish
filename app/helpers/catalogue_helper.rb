module CatalogueHelper
	def getDefaultCategories
		@default_categories = Hash.new
		for category in Vish::Application.config.default_categories
			@default_categories[category] = getCategoryResources(category,7)
		end
		@default_categories
	end

	def getCategoryResources(category,limit=100)
		keywords = Vish::Application.config.catalogue[category]
		RecommenderSystem.search({:keywords=>keywords, :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold=>5})
	end
end