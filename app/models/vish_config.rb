# encoding: utf-8

class VishConfig

  def self.getMainModels
    ["Excursion","Event","Category","Resource","Workshop"]
  end

  def self.getResourceModels
    ["Document","Webapp","Scormfile","Link","Embed","Writing"]
  end

  def self.getAllModels
    processAlias(getMainModels)
  end

  def self.getAllPossibleModelValues
    getMainModels + getResourceModels
  end

  def self.getModelsWhichActAsResources
    ["Excursion","Workshop"]
  end

  def self.getAllResourceModels
    getResourceModels + getModelsWhichActAsResources
  end

  def self.getAllContributionTypes
    ["Document","Writing","Excursion","Link"]
  end

  def self.getAllServices
    ["ARS","Catalogue","Competitions2013"]
  end

  def self.getAvailableMainModels(options={})
    availableModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["available"].nil?
      availableModels = getMainModels
    else
      availableModels = (Vish::Application.config.APP_CONFIG["models"]["available"] & getMainModels)
    end

    if options[:return_instances]
      getInstances(availableModels)
    else
      availableModels
    end
  end

  def self.getHomeModels(options={})
    homeModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["home"].nil?
      homeModels = getAllResourceModels
    else
      homeModels = (Vish::Application.config.APP_CONFIG["models"]["home"] & getAllPossibleModelValues)
    end

    if options[:return_instances]
      getInstances(homeModels)
    else
      homeModels
    end
  end

  def self.getCatalogueModels(options={})
    catalogueModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["catalogue"].nil?
      catalogueModels = getAllResourceModels
    else
      catalogueModels = (Vish::Application.config.APP_CONFIG["models"]["catalogue"] & getAllPossibleModelValues)
    end

    if options[:return_instances]
      getInstances(catalogueModels)
    else
      catalogueModels
    end
  end

  def self.getAvailableResourceModels(options={})
    unless getAvailableMainModels.include? "Resource"
      return []
    end

    availableResourceModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["resources"].nil?
      availableResourceModels = getResourceModels
    else
      availableResourceModels = (Vish::Application.config.APP_CONFIG["models"]["resources"] & getResourceModels)
    end

    if options[:return_instances]
      getInstances(availableResourceModels)
    else
      availableResourceModels
    end
  end

  def self.getAvailableAllResourceModels(options={})
    availableItemModels = getAvailableResourceModels + getAvailableMainModels.select{|m| getModelsWhichActAsResources.include? m}

    if options[:return_instances]
      getInstances(availableItemModels)
    else
      availableItemModels
    end
  end

  def self.getAvailableContributionTypes
    getAllContributionTypes
  end

  def self.processAlias(models=[])
    if models.include? "Resource"
      models.delete "Resource"
      models += getAvailableResourceModels
    end
    models.uniq!
    return models
  end

  def self.getInstances(models=[])
    processAlias(models).map{ |m|
      begin
        m.constantize
      rescue
        nil
      end
    }.compact
  end

  def self.getAvailableServices(options={})
    if Vish::Application.config.APP_CONFIG["services"].nil?
      return getAllServices
    else
      return (Vish::Application.config.APP_CONFIG["services"] & getAllServices)
    end
  end



end