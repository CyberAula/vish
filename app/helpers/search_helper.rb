module SearchHelper
  
  def too_short_query?
    return true if params[:q].blank?
    bare_query = strip_tags(params[:q]) || ""
    return bare_query.strip.size < SearchController::MIN_QUERY
  end
  
  def render_global_search_for model
    render_model_view model, "_global_search"   
  end
  
  def render_focus_search_for model
    render_model_view model, "_focus_search"    
  end
  
  def model_with_details model
    render_model_view model, "_with_details"
  end
  
  def render_model_view model, type
    model = model.model if model.is_a? Actor
    render :partial => model.class.to_s.pluralize.downcase + '/' + model.class.to_s.downcase + type,
           :locals => {model.class.to_s.downcase.to_sym => model}
  end

  def search_results?(key)
    begin
      SocialStream::Search.count(params[:q],
                                 current_subject,
                                 :key => key) > 0
    rescue
      true
    end
  end

  def extract_tags(search_results)
    search_results.map{|r| r.tags.map{|t| t.name}}.flatten.uniq.join(",")
  end

  def extract_types(search_results)
    search_results.map{|r| r.activity_object.object_type}.uniq.join(",")
  end

end
