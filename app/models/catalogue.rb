# encoding: utf-8

###############
# Catalogue
###############

class Catalogue

  def self.getCategoryResources(category,limit=100)
    if Vish::Application.config.catalogue['mode'] == "matchtag"
      #Mode matchtag
      RecommenderSystem.search({:category_ids=>[category], :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold => Vish::Application.config.catalogue["qualityThreshold"]})
    else
      #Mode matchany
      keywords = Vish::Application.config.catalogue["category_keywords"][category]
      RecommenderSystem.search({:keywords=>keywords, :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold => Vish::Application.config.catalogue["qualityThreshold"]})
    end
  end

  def self.getDefaultCategories
    default_categories = Hash.new
    for category in Vish::Application.config.catalogue["default_categories"]
      default_categories[category] = Catalogue.getCategoryResources(category,7)
    end
    default_categories
  end

end