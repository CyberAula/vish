class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  before_filter :add_item_to_category, :only => [:create, :update]

  def create
    create! do |format|
      format.json { render :json => {"title"=>@category.title, "id"=>@category.id}, :status => 200 }
    end
  end

  def update
    update! do |format|
      format.json {render :json => { :success => true }}
    end
  end

  private

  def add_item_to_category
    if params[:item_type].present?
      included = @category.property_objects.include? params[:item_type].constantize.find(params[:item_id]).activity_object
      if params[:insert]=="true" && !included
        @category.property_objects << params[:item_type].constantize.find(params[:item_id]).activity_object
      elsif params[:insert]=="false" && included
        #we remove it
        @category.property_objects.delete(params[:item_type].constantize.find(params[:item_id]).activity_object)
      end
      params.delete :item_type
      params.delete :item_id
    end
  end

  def allowed_params
    [:item_type, :item_id]
  end

end
