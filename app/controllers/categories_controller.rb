class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  before_filter :add_item_to_category, :only => [:create, :update]

  private

  def add_item_to_category
    if params[:category][:item_type].present?
      @category.property_objects << params[:category][:item_type].constantize.find(params[:category][:item_id]).activity_object
      params[:category].delete :item_type
      params[:category].delete :item_id
    end
  end

  def allowed_params
    [:item_type, :item_id]
  end

end
