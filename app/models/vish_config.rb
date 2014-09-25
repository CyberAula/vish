# encoding: utf-8

class VishConfig

  def self.getAllModels
    ["Excursion","Event","Category","Resource"]
  end

  def self.getAvailableModels
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["available"].nil?
      return getAllModels
    else
      return (Vish::Application.config.APP_CONFIG["models"]["available"] & getAllModels)
    end
  end

  def self.getHomeModels
    if Vish::Application.config.APP_CONFIG["models"].nil? or Vish::Application.config.APP_CONFIG["models"]["home"].nil?
      return getAllModels
    else
      return (Vish::Application.config.APP_CONFIG["models"]["home"] & getAllModels)
    end
  end

  def self.getAllServices
    ["ARS","Catalogue","Competitions2013"]
  end

  def self.getAvailableServices
    if Vish::Application.config.APP_CONFIG["services"].nil?
      return getAllServices
    else
      return (Vish::Application.config.APP_CONFIG["services"] & getAllServices)
    end
  end

end