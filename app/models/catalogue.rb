# encoding: utf-8

###############
# Catalogue
###############

class Catalogue

  def self.getCategoryResources(category,limit=100)
    if Vish::Application.config.catalogue['mode'] == "matchtag"
      #Mode matchtag
      Search.search({:category_ids=>[category], :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold => Vish::Application.config.catalogue["qualityThreshold"]})
    else
      #Mode matchany
      keywords = Vish::Application.config.catalogue["category_keywords"][category]
      Search.search({:query=>keywords, :n=>limit, :models => VishConfig.getCatalogueModels({:return_instances => true}), :order => 'ranking DESC', :qualityThreshold => Vish::Application.config.catalogue["qualityThreshold"]})
    end
  end

end