class TagsController < ApplicationController
  before_filter :authenticate_user!
  
  # Enable CORS
  before_filter :cors_preflight_check, :only => [:index]
  after_filter :cors_set_access_control_headers, :only => [:index]

  def index
    if params[:mode]=="popular" or !params[:q].present?
      @tags = most_popular
    else
      @tags = match_tag
    end

    items_per_page = params[:limit].present? ? params[:limit] : 25
    @tags = @tags.page(params[:page]).per(items_per_page)

    if @tags.blank? && params[:q].present?
      @tags = [ ActsAsTaggableOn::Tag.new(name: params[:q]) ]
    end

    respond_to do |format|
      format.json {
        render json: @tags
      }
    end
  end


  private

  def match_tag
    ActsAsTaggableOn::Tag.where('name LIKE ?',"%#{ params[:q] }%")
  end

  def most_popular
    ActivityObject.tag_counts(:order => "count desc")
  end

end