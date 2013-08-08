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
  
  def get_search_query_words
    bare_query = strip_tags(params[:q]) || ""
    return bare_query.strip.split
  end

  def vish_search_options mode, key=nil, per_page=12, page=1
    options = {:with => { :relation_ids => Relation.ids_shared_with(current_subject) }, :classes => SocialStream::Search.models(mode, key), :per_page => per_page, :page => page }

    options.deep_merge!({ :with => { :created_at => time_constraint(params[:time]) } }) if params[:time].present?
    if key.present?
      case key
      when 'excursion'
        options.deep_merge!({ :order => :created_at, :sort_mode => :desc }) if params[:sort].present? and params[:sort] == "newest"
        options.deep_merge!({ :order => :visit_count, :sort_mode => :desc }) if params[:sort].present? and params[:sort] == "views"
        options.deep_merge!({ :order => :like_count, :sort_mode => :desc }) if params[:sort].present? and params[:sort] == "likes"
        options.deep_merge!({ :order => :slide_count, :sort_mode => :desc }) if params[:sort].present? and params[:sort] == "slides"

        options.deep_merge!({ :with => { :slide_count => 1..10 } }) if params[:slides].present? and params[:slides] == "10"
        options.deep_merge!({ :with => { :slide_count => 10..20 } }) if params[:slides].present? and params[:slides] == "20"
        options.deep_merge!({ :with => { :slide_count => 20..99 } }) if params[:slides].present? and params[:slides] == "more"
      when 'user'
        # No options for user just yet
      when 'resource'
        options.deep_merge!({ :classes => type_constraint(params[:class]) }) if params[:class].present?
      when 'activity2'
        # No options for activity2 just yet
      end
    end
    options
  end

  def get_search_query_words
    search_query = ""
    bare_query = strip_tags(params[:q]) unless bare_query.html_safe?
    return bare_query.strip.split
  end

  def search_results?(key)
    SocialStream::Search.count(params[:q],
                               current_subject,
                               :key => key) > 0
  end

  private

  def time_constraint constraint
    case constraint
    when 'day'
      1.day.ago..Time.now
    when 'week'
      1.week.ago..Time.now
    when 'month'
      1.month.ago..Time.now
    when 'year'
      1.year.ago..Time.now
    end
  end

  def type_constraint constraint
    constraint.split(',').map { |e| e.classify.constantize }
  end
end
