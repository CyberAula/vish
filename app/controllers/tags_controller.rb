class TagsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    params[:limit] ||= 10
    @tags = case params[:mode]
              when "popular" then most_popular
              else match_tag
            end
    response = @tags.map{ |t| { 'key' => t.name, 'value' => t.name } }.to_json
    if @tags.count == 0
      response = "[]"
      response = "[{\"key\":\""+params[:tag]+"\" , \"value\":\""+params[:tag]+"\"}]" unless params[:tag].blank?
    end

    respond_to do |format|
      format.json { render :text => response}
    end
  end

  private

  def match_tag
    ActsAsTaggableOn::Tag.where('name like ?','%'+params[:tag]+'%').limit(params[:limit])
  end

  def most_popular
    ActivityObject.tag_counts(:limit => params[:limit], :order => "count desc")
  end
end
