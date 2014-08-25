class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  #before_filter :add_item_to_categories, :only => [:create, :update]
  before_filter :authenticate_user!
  skip_load_and_authorize_resource :only => [:categorize]
  
  def show_favorites
    render "favorites"
  end

  def create
    create! do |success, failure|
      success.json { render :json => {"title"=>@category.title, "id"=>@category.id}, :status => 200 }
      failure.json { render :json => {"errors" => @category.errors.full_messages.to_sentence}, :status => 400}
    end
  end

  def categorize
    if params[:category_array].present?
      subject_categories = Category.authored_by(current_subject)
      subject_categories_ids = subject_categories.map{|c| c.id}
      subject_categories_names = subject_categories.map{|c| c.title}
      new_categories_titles = []
      existing_categories_ids = []

      begin
        category_array = JSON.parse(params[:category_array])
      rescue
        category_array = []
      end
      category_array.each do |c|
        if subject_categories_ids.include?(c["id"].to_i)
          existing_categories_ids.push(c["id"].to_i)
        elsif subject_categories_names.include?(c["title"])
          existing_categories_ids.push(subject_categories.select{|myC| myC.title==c["title"]}.first.id)
        elsif !c["title"].blank?
          new_categories_titles.push(c["title"])
        end
      end

      unless new_categories_titles.blank?
        #Create new categories and store their ids in existing_categories_ids
        new_categories_titles.each do |cTitle|
          c = Category.new
          c.title = cTitle
          actorId = Actor.normalize_id(current_subject)
          c.author_id = actorId
          c.owner_id = actorId
          binding.pry
          c.save!
          existing_categories_ids.push(c.id)
        end
      end

      #Categorize the resource with the categories stored in existing_categories_ids
      existing_categories_ids.uniq!
      categories_to_categorize = Category.find(existing_categories_ids)
      categories_to_categorize.each do |categoryToCategorize|
        # categoryToCategorize.property_objects << item
      end
    end

    #Category.all
    #Check in categories which categories are new and create them, when done, get an array with all ids
    #apply the categories to an item
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

  def update
    update! do |format|
      format.json {render :json => { :success => true }}
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

  # def add_item_to_categories
  #   if params[:item_type].present?
  #     included = @category.property_objects.include? params[:item_type].constantize.find(params[:item_id]).activity_object
  #     if params[:insert]=="true" && !included
  #       @category.property_objects << params[:item_type].constantize.find(params[:item_id]).activity_object
  #     elsif params[:insert]=="false" && included
  #       #we remove it
  #       @category.property_objects.delete(params[:item_type].constantize.find(params[:item_id]).activity_object)
  #     end
  #     params.delete :item_type
  #     params.delete :item_id
  #   end
  # end
 
  def allowed_params
    [:item_type, :item_id, :scope]
  end

end
