class FederatedSearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  skip_load_and_authorize_resource :only => [:search]

  # Enable CORS (http://www.tsheffler.com/blog/?p=428) for last_slide, and iframe_api methods
  before_filter :cors_preflight_check, :only => [:search]
  after_filter :cors_set_access_control_headers, :only => [:search]

  #############
  # CORS
  #############
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end


  #############
  # SEARCH API
  #############

  def search
    limit = [Integer(params[:l]),200].min rescue 20

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

    results = RecommenderSystem.search({:keywords=>params[:q], :n=>limit, :order => order, :models => type[:models], :subtypes => type[:subtypes], :startDate => params[:startDate], :endDate => params[:endDate], :language => params[:language], :qualityThreshold => params[:qualityThreshold]})

    respond_to do |format|
      format.any {
        render :json => results.map{|r| r.search_json(self)}, :content_type => 'json'
      }
    end
  end

  def processTypeParam(type)
    # Possible models
    # ["User", "Category", "Event", "Excursion", "Document", "Link", "Embed", "Webapp", "Scormfile"]
    # and the document subclasses also ["Picture","Audio","Video",...]

    models = []
    subtypes = []

    unless type.nil?
      acceptedSubtypes = {
        "Resource" => [Excursion,Document,Link,Embed,Webapp,Scormfile]
      }

      type.split(",").each do |type|
        if acceptedSubtypes[type].nil?
          #Find model
          model = type.singularize.classify.constantize rescue nil
          unless model.nil?
            models.push(model)
          end
        else
          #Is a subtype
          models.concat(acceptedSubtypes[type])
          subtypes.push(type)
        end
      end
    end

    if models.empty?
      #Default models
      models = [Excursion,Document,Link,Embed,Webapp,Scormfile]
      subtypes = []
    end

    return {
      :models => models,
      :subtypes => subtypes
    }
  end

end

          