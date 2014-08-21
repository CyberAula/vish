class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  #before_filter :add_item_to_categories, :only => [:create, :update]
  skip_load_and_authorize_resource :only => [:add_items]
  
  def show_favorites
    render "favorites"
  end

  def create
    create! do |success, failure|
      success.json { render :json => {"title"=>@category.title, "id"=>@category.id}, :status => 200 }
      failure.json { render :json => {"errors" => @category.errors.full_messages.to_sentence}, :status => 400}
    end
  end

  def update
    update! do |format|
      format.json {render :json => { :success => true }}
    end
  end

  def add_items
    if params[:item_type].present? && params["categories_array"].present?
      cat_array = JSON.parse(params["categories_array"])
      #2 actions, remove categories that are no longer assinged and apply new ones
      item = params[:item_type].constantize.find(params[:item_id]).activity_object
      item.holder_categories.each do |cat|
        if cat_array.include?(cat.id)
          cat_array.delete(cat.id) #remove item because the category is already applied
          next
        end
        #the_cat = Category.find(cat.id)
        #the_cat.property_objects.delete(item)
      end
      #now apply the rest of categories, the new ones
      cat_array.each do |new_cat_id|
        new_cat = Category.find(new_cat_id)
        new_cat.property_objects << item
      end
      render :json => { :success => true }
    end
  end


  def destroy
    super do |format|
      format.html {
        redirect_to url_for(current_subject)
       }

      format.js
    end
   end

  private

  def add_item_to_categories
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
 
  def categories_check
    categories_already = {}
    Category.all.each do |t|
      categories_already << {t.title => t.id} 
    end
    if params[:category_array].present?
      params[:category_array].each do |cat|
        if !categories_already.member?(cat)
        end
      end
    end
    #Category.all
    #Check in categories which categories are new and create them, when done, get an array with all ids
    #apply the categories to an item
  end

  def allowed_params
    [:item_type, :item_id, :scope]
  end

end
