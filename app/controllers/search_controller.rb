class SearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  RESULTS_SEARCH_PER_PAGE=24

  def index
    params[:page] = params[:page] || 1

    @search_result =
      if params[:q].blank?
        search :extended
      elsif params[:mode] == "quick"
        search :quick
      else
        search :extended
      end

    respond_to do |format|
      format.html {
        if request.xhr?
          if params[:mode] == "quick"
            render partial: "quick"
          else
            render partial: 'results'            
          end
        end
      }

      format.json {
        json_obj = (
          params[:type].present? ?
          { params[:type].pluralize => @search_result.compact } :
          @search_result.compact
        )

        render :json => json_obj.to_json(helper: self)
      }

      format.js
    end
  end

  def advanced
    respond_to do |format|
      format.html {
        render
      }
    end
  end


  private

  def search mode
    page =  ( mode == :quick ? 1 : params[:page] )
    limit = ( mode == :quick ? 7 : RESULTS_SEARCH_PER_PAGE )

    if params[:catalogue] || params[:directory]
      params[:sort_by] = "quality"
    end

    case params[:sort_by]
    when 'ranking'
      order = 'ranking DESC'
    when 'popularity'
      #Use ranking instead of popularity
      order = 'ranking DESC'
      # order = 'popularity DESC'
    when "quality"
      order = 'qscore DESC'
    when 'updated_at'
      order = 'updated_at DESC'
    when 'created_at'
      order = 'created_at DESC'
    when 'visits'
      order = 'visit_count DESC'
    when 'favorites'
      order = 'like_count DESC'
    else
      #order by relevance
      order = nil
    end

    unless params[:ids_to_avoid].nil?
      params[:ids_to_avoid] = params[:ids_to_avoid].split(",")
    end

    #remove empty params   
    params.delete_if { |k, v| v == "" }

    if !params[:type]
      if params[:catalogue]
        #default models for catalogue without "type" filter applied
        params[:type] = VishConfig.getCatalogueModels().join(",")
      elsif params[:directory]
        params[:type] = VishConfig.getDirectoryModels().join(",")
      end
    end

    models = ( mode == :quick ? SocialStream::Search.models(mode, params[:type]) : processTypeParam(params[:type]) )

    keywords = params[:q]

    #Check catalogue category
    categories = nil
    if params[:category_ids].is_a? String
      if Vish::Application.config.catalogue['mode'] == "matchtag"
          #Mode matchtag
          categories = params[:category_ids]
      else
        #Mode matchany
        keywords = []
        params[:category_ids].split(",").each do |category|
          keywords.push(Vish::Application.config.catalogue["category_keywords"][category])
        end
        keywords = keywords.flatten.uniq
      end
    end

    RecommenderSystem.search({:category_ids => categories, :keywords=>keywords, :n=>limit, :page => page, :order => order, :models => models, :ids_to_avoid=>params[:ids_to_avoid], :startDate => params[:startDate], :endDate => params[:endDate], :language => params[:language], :qualityThreshold => params[:qualityThreshold], :tags => params[:tags], :tag_ids => params[:tag_ids], :age_min => params[:age_min], :age_max => params[:age_max] })
  end

  def processTypeParam(type)
    models = []    
    
    unless type.blank?
      allAvailableModels = VishConfig.getAllAvailableAndFixedModels(:include_subtypes => true).reject!{|m| m=="Category"}
      # Available Types: all available models and the alias 'Resource' and 'learning_object'
      allAvailableTypes = allAvailableModels + ["Resource", "Learning_object"]

      types = type.split(",") & allAvailableTypes

      if types.include? "Learning_object"
        types.concat(["Excursion", "Resource", "Event", "Workshop"])
      end

      if types.include? "Resource"
        types.concat(VishConfig.getAvailableResourceModels(:include_subtypes => true).reject!{|e| e=="Excursion" || e=="Workshop" })
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
      #Default models, all
      models = VishConfig.getAllAvailableAndFixedModels({:return_instances => true, :include_subtypes => true}).reject!{|m| m==Category}
    end

    models.uniq!

    return models
  end
end

          