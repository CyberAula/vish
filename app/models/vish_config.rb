# encoding: utf-8

class VishConfig

  def self.getAllModels
    ["Excursion","Event","Category","Resource"]
  end

  def self.getAllResourceModels
    ["Excursion", "Document", "Webapp", "Scormfile","Link","Embed"]
  end

  def self.getAllServices
    ["ARS","Catalogue","Competitions2013"]
  end

  def self.getAvailableModels(options={})
    availableModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["available"].nil?
      availableModels = getAllModels
    else
      availableModels = (Vish::Application.config.APP_CONFIG["models"]["available"] & getAllModels)
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
      homeModels = getAllModels
    else
      homeModels = (Vish::Application.config.APP_CONFIG["models"]["home"] & getAllModels)
    end

    if options[:return_instances]
      getInstances(homeModels)
    else
      homeModels
    end
  end

  def self.getAvailableResourceModels(options={})
    unless getAvailableModels.include? "Resource"
      return []
    end

    availableResourceModels = []
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["resources"].nil?
      availableResourceModels = getAllResourceModels
    else
      availableResourceModels = (Vish::Application.config.APP_CONFIG["models"]["resources"] & getAllResourceModels)
    end

    if options[:return_instances]
      getInstances(availableResourceModels)
    else
      availableResourceModels
    end
  end



  def self.getAvailableServices(options={})
    if Vish::Application.config.APP_CONFIG["services"].nil?
      return getAllServices
    else
      return (Vish::Application.config.APP_CONFIG["services"] & getAllServices)
    end
  end

  def self.getInstances(models=[])
    if models.include? "Resource"
      models.delete "Resource"
      models += getAvailableResourceModels
    end
    models.uniq!

    models.map{|m| 
      begin
        m.constantize
      rescue
        nil
      end
    }.compact
  end

end