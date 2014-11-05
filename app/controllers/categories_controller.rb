class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  before_filter :authenticate_user!, :except => [:show]
  skip_load_and_authorize_resource :only => [:categorize, :edit_categories]
  skip_after_filter :discard_flash, :only => [:update]


  def index
    redirect_to url_for(current_subject) + "?tab=categories"
  end

  def show_favorites
    render "favorites"
  end

  def create
    unless params[:category][:is_root].blank?
      @indexOf = params[:category][:is_root].to_i
      if @indexOf == -1 then 
        @category.is_root = true 
      else 
        @category.is_root = false 
      end
    end
     @indexOf ||= -1
      create! do |success, failure|
        success.json {
          if @indexOf != -1
            Category.find(@indexOf).property_objects << @category.activity_object
          end
          render :json => {"title"=>@category.title, "id"=>@category.id,"avatar" => @category.avatar, "is_root" => @category.is_root}, :status => 200 }
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
          authorize! :create, c
          c.save!
          existing_categories_ids.push(c.id)
        end
      end

      existing_categories_ids.uniq!

      object_id = ActivityObject.find(params[:activity_object_id])
      subject_categories = Category.authored_by(current_subject)

      subject_categories.each do |category|
        authorize! :update, category
        category.property_objects.delete(object_id)
      end

      categories_to_categorize = Category.find(existing_categories_ids)
      categories_to_categorize.each do |categoryToCategorize|
        authorize! :update, categoryToCategorize
        categoryToCategorize.property_objects << object_id
        categoryToCategorize.property_objects.uniq!
      end
    end

    render :json => { :success => true }
  end

  def edit_categories
    #Parse Parameters
    if params[:actions].present?
      begin
        # if actions array presents
        actions = JSON.parse(params[:actions])
      rescue
        actions = []
      end
    end

    if params[:sort_order].present?
      begin
        sort_order = JSON.parse(params[:sort_order])
      rescue
        sort_order = []
      end
    end

    if params[:cat_id].present?
      the_category = Category.find_by_id(params[:cat_id].to_i)
      authorize! :update, the_category
    end

    #First we put stuff into others and delete stuff from categories
    actions.each do |n|
      next if n.nil? or n.length<2

      dragged = ActivityObject.find_by_id(n[0].to_i)
      next if dragged.nil?

      case n[1].to_i
      when -1
        #Throwed to the bin
        if dragged.object_type == "Category"
          #if it is a category, destroy it
          authorize! :destroy, dragged.object
          dragged.object.destroy
        elsif params[:sort_order].present? && !the_category.nil? and the_category.property_objects.include?(dragged)
          #if it is not just get deleted
          the_category.property_objects.delete(dragged)
        end
      when -2
        #Dragged into top level
        # if params[:sort_order].present?
      else
        # Drag into another category
        receiver = ActivityObject.find_by_id(n[1].to_i)
        next if receiver.nil?

        if receiver.object_type == "Category"
          if !dragged.nil? && !receiver.nil? && dragged != receiver
            authorize! :update, receiver.object
            receiver.property_objects << dragged
            receiver.property_objects.uniq!
            #if dragged is a category notify it is not root
            if dragged.object_type == "Category"
              authorize! :update, dragged.object
              dragged.category.is_root = false
              dragged.category.save
            end
             #notify for leaving a category container
            if !the_category.nil? and the_category.property_objects.include?(dragged)
              the_category.property_objects.delete(dragged)
            end
          end
        end
      end

    end

    unless sort_order.blank?
      if !the_category.nil?
        the_category.category_order = sort_order.to_json
        the_category.save
      elsif params[:profile_or_current_subject_id].present?
        the_user = User.find_by_id(params[:profile_or_current_subject_id])
        unless the_user.nil?
          order_actor = the_user.actor
          unless current_subject.actor==order_actor
            authorize! :update, order_actor
          end
          order_actor.category_order = sort_order.to_json
          order_actor.save
        end
      end
    end

    render :json => { :success => true }
  end


  def update
    super do |format|
      format.html {
        unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
        else
          discard_flash
        end

        redirect_to url_for(resource)
       }
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

  def allowed_params
    [:item_type, :item_id, :scope, :avatar, :is_root]
  end

end
