class FederatedSearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  skip_load_and_authorize_resource :only => [:search]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:search]
  after_filter :cors_set_access_control_headers, :only => [:search]


  #############
  # SEARCH API
  #############

  def search
    unless params[:id].nil?
      response = search_by_id
    else
      limit = [1,[Integer(params[:n]),200].min].max rescue 20

      case params[:sort_by]
      when 'ranking'
        order = 'ranking DESC'
      when 'popularity'
        order = 'popularity DESC'
      when 'modification'
        order = 'updated_at DESC'
      when 'creation'
        order = 'created_at DESC'
      when 'visits'
        order = 'visit_count DESC'
      when 'favorites'
        order = 'like_count DESC'
      when 'quality'
        order = 'qscore DESC'
      else
        #order by relevance
        order = nil
      end

      type = processTypeParam(params[:type])

      searchEngineResults = RecommenderSystem.search({:keywords=>params[:q], :n=>limit, :page => params[:page], :order => order, :models => type[:models], :subtypes => type[:subtypes], :startDate => params[:startDate], :endDate => params[:endDate], :language => params[:language], :qualityThreshold => params[:qualityThreshold]})

      response = Hash.new
      response["total_results"] = [searchEngineResults.total_entries,5000].min
      response["total_results_delivered"] = searchEngineResults.length
      unless params[:page].nil?
        response["total_pages"] = searchEngineResults.total_pages
        response["page"] = searchEngineResults.current_page
        response["results_per_page"] = searchEngineResults.per_page
      end
      matchWeights = searchEngineResults.results[:matches].map{|m| m[:weight]}
      response["results"] = searchEngineResults.map.with_index{|r,i|
        json = r.search_json(self)
        json[:weights] = {}
        json[:weights][:relevance_weight] = matchWeights[i]

        case params[:sort_by]
        when 'ranking'
          json[:weights][:sorting_weight] = r.ranking
        when 'popularity'
          json[:weights][:sorting_weight] = r.popularity
        when 'modification'
          json[:weights][:sorting_weight] = r.updated_at.utc.to_i
        when 'creation'
          json[:weights][:sorting_weight] = r.created_at.utc.to_i
        when 'visits'
          json[:weights][:sorting_weight] = r.visit_count
        when 'favorites'
          json[:weights][:sorting_weight] = r.like_count
        when 'quality'
          json[:weights][:sorting_weight] = r.qscore
        else
          json[:weights][:sorting_weight] = json[:weights][:relevance_weight]
        end

        json
      }
    end

    respond_to do |format|
      format.any {
        render :json => response, :content_type => 'json'
      }
    end
  end

  def processTypeParam(type)
    models = []
    subtypes = []

    unless type.blank?
      allAvailableModels = VishConfig.getAllAvailableAndFixedModels(:include_subtypes => true)
      # Available Types: all available models and the alias 'Resource'
      allAvailableTypes = allAvailableModels + ["Resource"]

      types = type.split(",") & allAvailableTypes

      if types.include? ["Resource"]
        types.concat(VishConfig.getAvailableResourceModels(:include_subtypes))
      end

      types = types & allAvailableModels
      types.uniq!

      types.each do |type|
        #Find model
        model = type.singularize.classify.constantize rescue nil
        unless model.nil?
          models.push(model)
        end
      end
    end

    if models.empty?
      #Default models
      models = VishConfig.getAvailableResourceModels({:return_instances => true})
      subtypes = []
    end

    models.uniq!
    subtypes.uniq!

    return {
      :models => models,
      :subtypes => subtypes
    }
  end

  #Search elements by universal Ids
  def search_by_id
    object = ActivityObject.getObjectFromUniversalId(params[:id])
    unless object.nil?
      object.search_json(self)
    else
      {}
    end
  end

end

          