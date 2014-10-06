class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  before_filter :authenticate_user!, :except => [:show]
  skip_load_and_authorize_resource :only => [:categorize]
  
  def index
    redirect_to url_for(current_subject) + "?tab=categories"
  end

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
          c.save!
          existing_categories_ids.push(c.id)
        end
      end

      existing_categories_ids.uniq!

      object_id = ActivityObject.find(params[:activity_object_id])
      subject_categories = Category.authored_by(current_subject)
      
      subject_categories.each do |delet|
        delet.property_objects.delete(object_id)
      end

      categories_to_categorize = Category.find(existing_categories_ids)
      categories_to_categorize.each do |categoryToCategorize|
         categoryToCategorize.property_objects << object_id
         categoryToCategorize.property_objects.uniq!
      end
    end

    render :json => { :success => true }
  end

  def reSort

    #if insertions array params presents
    # parse.Json params
    # for each in MovethingsOut
    # then deletes of all elemens in delete
    if params[:movements].present?
      begin
        movements = JSON.parse(params[:movements])
      rescue
        movements = []
      end
    end

    movements.each do |n|
      #Find n[0] put n[0] y n[1]

    end


    if params[:deletions].present?
      begin
        deletions = JSON.parse(params[:deletions])
      rescue
        deletions = []
      end
    end

    deletions.each do |r|
      #check if the object exists
      ActivityObject.find(r).destroy!
    end

    render :json => { :success => true }
  end


  def update
    @category.title = params[:category][:title]
    @category.description = params[:category][:description]
    @category.update
    redirect_to @category
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
  
  def moveThingsInsideOut(primary, secondary)
    #It would be nice to put a dot marking if that is a root category or not
    #Cases -actual state is root goes to undercategory.
    #      - actual state is not root and goes to root
    #      - actual state is not root and goes to no root -> implemented
      if ActivityObject.find(primary).object_type == "Category"
          ActivityObject.find(primary).property_objects << secondary
      end
  end

  def allowed_params
    [:item_type, :item_id, :scope]
  end

end
