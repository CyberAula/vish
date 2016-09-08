# encoding: utf-8

class VishConfig

  def self.getMainModels
    ["Excursion","Event","Category","Resource","Workshop","Course"]
  end

  def self.getFixedMainModels
    ["User"]
  end

  def self.getResourceModels
    ["Document","Webapp","Scormfile","Imscpfile","Link","Embed","Writing"] + getMainModelsWhichActAsResources
  end

  def self.getMainModelsWhichActAsResources
    ["Excursion","Workshop"]
  end

  def self.getAllLanguages
    getAllDefinedLanguages + ["independent","other"]
  end

  def self.getAllDefinedLanguages
    ["en", "de", "es", "fr", "it", "pt", "ru", "hu", "nl"]
  end

  def self.getAllModels(options={})
    processAlias(getMainModels,options)
  end

  def self.getAllModelsInstances(options={})
    getInstances(processAlias(getMainModels,options))
  end

  def self.getAllPossibleModelValues
    (getMainModels + getResourceModels).uniq
  end

  def self.getAllContributionTypes
    ["Document","Writing","Resource"]
  end

  def self.getAllServices
    ["ARS","Catalogue","Contests","ASearch","MediaConversion","PrivateStudentGroups"]
  end

  def self.getAvailableMainModels(options={})
    availableModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["available"].nil?
      availableModels = getMainModels
    else
      availableModels = (Vish::Application.config.APP_CONFIG["models"]["available"] & getMainModels)
    end

    if options[:return_instances]
      getInstances(processAlias(availableModels,options))
    else
      availableModels
    end
  end

  def self.getSearchModels(options={})
    searchModels = getAvailableMainModels()
    #we do not want to search by courses 
    searchModels.delete("Course")  
    if !options.include?(:include_users) || options[:include_users]==true
      searchModels = searchModels + getFixedMainModels
    end
    if options[:return_instances]
      getInstances(processAlias(searchModels,options))
    else
      searchModels
    end
  end


  def self.getAvailableMainModelsWhichActAsResources(options={})
    aMainModelsWhichActAsResources = getAvailableMainModels & getMainModelsWhichActAsResources

    if options[:return_instances]
      getInstances(processAlias(aMainModelsWhichActAsResources,options))
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

    homeModels = processAlias(homeModels,options)

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

    catalogueModels = processAlias(catalogueModels,options)

    if options[:return_instances]
      getInstances(catalogueModels)
    else
      catalogueModels
    end
  end

  def self.getDirectoryModels(options={})
    directoryModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["directory"].nil?
      directoryModels = getResourceModels
    else
      directoryModels = (Vish::Application.config.APP_CONFIG["models"]["directory"] & getResourceModels)
    end

    directoryModels = processAlias(directoryModels,options)

    if options[:return_instances]
      getInstances(directoryModels)
    else
      directoryModels
    end
  end

  def self.getArchiveModels(options={})
    archiveModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["archive"].nil?
      archiveModels = getResourceModels
    else
      archiveModels = (Vish::Application.config.APP_CONFIG["models"]["archive"] & getResourceModels)
    end

    archiveModels = processAlias(archiveModels,options)

    if options[:return_instances]
      getInstances(archiveModels)
    else
      archiveModels
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

    availableResourceModels = processAlias(availableResourceModels,options)

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
     processAlias(getAvailableMainModels(options),options)
  end

  def self.getAllAvailableAndFixedModels(options={})
    allAvailableAndFixedModels = processAlias(getAvailableMainModels,options) + getFixedMainModels
    if options[:return_instances]
      getInstances(allAvailableAndFixedModels)
    else
      allAvailableAndFixedModels
    end
  end

  def self.getAllModelsIncludingFixedModels(options={})
    (processAlias(getMainModels,options) + getFixedMainModels).uniq
  end

  def self.getAvailableContributionTypes
    getAllContributionTypes
  end

  def self.processAlias(models=[],options={})
    if models.include? "Resource"
      models.delete "Resource"
      models += getAvailableResourceModels
    end
    if options[:include_subtypes] and models.include? "Document"
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
    instances = [Vish::Application.config.full_domain]
    if Vish::Application.config.APP_CONFIG["advanced_search"].nil? or Vish::Application.config.APP_CONFIG["advanced_search"]["instances"].nil?
      instances
    else
      (instances + Vish::Application.config.APP_CONFIG["advanced_search"]["instances"]).uniq
    end
  end

end