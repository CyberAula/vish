# encoding: utf-8

class VishConfig

  def self.getMainModels
    ["Excursion","Event","Category","Resource"]
  end

  def self.getFixedMainModels
    ["User"]
  end

  def self.getResourceModels
    ["Document","Webapp","Scormfile","Link","Embed"] + getMainModelsWhichActAsResources
  end

  def self.getMainModelsWhichActAsResources
    ["Excursion"]
  end

  def self.getAllModels
    processAlias(getMainModels)
  end

  def self.getAllPossibleModelValues
    (getMainModels + getResourceModels).uniq
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
      getInstances(processAlias(availableModels))
    else
      availableModels
    end
  end

  def self.getAvailableMainModelsWhichActAsResources(options={})
    aMainModelsWhichActAsResources = getAvailableMainModels & getMainModelsWhichActAsResources

    if options[:return_instances]
      getInstances(processAlias(aMainModelsWhichActAsResources))
    else
      aMainModelsWhichActAsResources
    end
  end

  def self.getHomeModels(options={})
    homeModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["home"].nil?
      homeModels = getResourceModels
    else
      homeModels = (Vish::Application.config.APP_CONFIG["models"]["home"] & getAllPossibleModelValues)
    end

    homeModels = processAlias(homeModels)

    if options[:return_instances]
      getInstances(homeModels)
    else
      homeModels
    end
  end

  def self.getCatalogueModels(options={})
    catalogueModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["catalogue"].nil?
      catalogueModels = getResourceModels
    else
      catalogueModels = (Vish::Application.config.APP_CONFIG["models"]["catalogue"] & getResourceModels)
    end

    catalogueModels = processAlias(catalogueModels)

    if options[:return_instances]
      getInstances(catalogueModels)
    else
      catalogueModels
    end
  end

  def self.getAvailableResourceModels(options={},filterMainModels=false)
    unless getAvailableMainModels.include? "Resource"
      return []
    end

    availableResourceModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["resources"].nil?
      availableResourceModels = getResourceModels
    else
      availableResourceModels = (Vish::Application.config.APP_CONFIG["models"]["resources"] & getResourceModels)
    end

    availableResourceModels += getAvailableMainModelsWhichActAsResources
    availableResourceModels.uniq!

    if filterMainModels
      mainModelsWhichActAsResources = getMainModelsWhichActAsResources
      availableResourceModels = availableResourceModels.reject{|m| mainModelsWhichActAsResources.include? m}
    end

    availableResourceModels = processAlias(availableResourceModels)

    if options[:return_instances]
      getInstances(availableResourceModels)
    else
      availableResourceModels
    end
  end

  def self.getAvailableNotMainResourceModels(options={})
    getAvailableResourceModels(options,true)
  end

  def self.getAvailableLikableModels(options={})
    getAllAvailableModels(options)
  end

  def self.getAllAvailableModels(options={})
     processAlias(getAvailableMainModels(options))
  end

  def self.getAllAvailableAndFixedModels(options={})
    allAvailableAndFixedModels = processAlias(getAvailableMainModels) + getFixedMainModels
    if options[:return_instances]
      getInstances(allAvailableAndFixedModels)
    else
      allAvailableAndFixedModels
    end
  end

  def self.getAllModelsIncludingFixedModels(options={})
    (processAlias(getMainModels) + getFixedMainModels).uniq
  end

  def self.processAlias(models=[])
    if models.include? "Resource"
      models.delete "Resource"
      models += getAvailableResourceModels
    end
    if models.include? "Document"
      models += Document.subclasses.map{|s| s.name}
    end
    models.uniq!
    return models
  end

  def self.getInstances(models=[])
    models.map{ |m|
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

  def self.getViSHInstances
    if Vish::Application.config.APP_CONFIG["advanced_search"].nil? or Vish::Application.config.APP_CONFIG["advanced_search"]["instances"].nil?
      []
    else
      ([Vish::Application.config.full_domain] + Vish::Application.config.APP_CONFIG["advanced_search"]["instances"]).uniq
    end
  end

end