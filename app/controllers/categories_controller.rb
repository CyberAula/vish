class CategoriesController < ApplicationController
  include SocialStream::Controllers::Objects

  before_filter :authenticate_user!, :except => [:show]
  before_filter :fill_create_params, :only => [:create, :update]
  skip_load_and_authorize_resource :only => [:categorize, :edit_categories, :settings]
  skip_after_filter :discard_flash, :only => [:update]


  def index
    redirect_to url_for(current_subject) + "?tab=categories"
  end

  def show
    show! do |format|
      format.html {
        render
      }
      format.json {
        render :json => @category.to_json(helper: self)
      }
      format.scorm {
        if (can? :download_source, @category)
          scormVersion = (params["version"].present? and ["12","2004"].include?(params["version"])) ? params["version"] : "2004"
          rec = (params["rec"].present? and ["true","false"].include?(params["rec"])) ? params["rec"] : "true"
          count = Site.current.config["tmpCounter"].nil? ? 1 : Site.current.config["tmpCounter"]
          Site.current.config["tmpCounter"] = count + 1
          Site.current.save!
          folderPath = "#{Rails.root}/public/tmp/scorm/"
          fileName = "scorm" + scormVersion + "-tmp-#{count.to_s}"
          filePath = "#{folderPath}#{fileName}.zip";
          @category.to_scorm(self,folderPath,fileName,scormVersion,{:category => @category, :rec => rec})
          send_file filePath, :type => 'application/zip', :disposition => 'attachment', :filename => ("scorm" + scormVersion + "-#{@category.id}.zip") if File.exists?(filePath)
        else
          render :nothing => true, :status => 500
        end
      }
    end
  end

  def show_favorites
    render "favorites"
  end

  def list_categories
    render :partial => "entities/entity", :locals => {}
  end

  def create
    unless params[:category][:parent_id].blank?
      parentCategory = Category.find_by_id(params[:category][:parent_id])
      authorize! :update, parentCategory unless parentCategory.nil?
    end

    create! do |success, failure|
      success.json {
        render :json => @category, :status => 200
      }
      failure.json {
        render :json => {"errors" => @category.errors.full_messages.to_sentence}, :status => 400
      }
    end
  end

  def update
    unless params[:category][:parent_id].blank?
      parentCategory = Category.find_by_id(params[:category][:parent_id])
      unless parentCategory.nil?
        authorize! :update, parentCategory
        @category.parent_id = parentCategory.id
      else
        params[:category].delete "parent_id"
      end
    else
      @category.parent_id = nil
    end

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
        actorId = Actor.normalize_id(current_subject)
        new_categories_titles.each do |cTitle|
          c = Category.new
          c.title = cTitle
          c.author_id = actorId
          c.owner_id = actorId
          c.scope = 1
          authorize! :create, c
          c.save!
          existing_categories_ids.push(c.id)
        end
      end

      existing_categories_ids.uniq!

      object_to_categorize = ActivityObject.find_by_id(params[:activity_object_id])

      unless object_to_categorize.nil?
        subject_categories.each do |category|
          authorize! :update, category
          category.deletePropertyObject(object_to_categorize)
        end

        Category.find(existing_categories_ids).each do |categoryToCategorize|
          authorize! :update, categoryToCategorize
          categoryToCategorize.insertPropertyObject(object_to_categorize)
        end
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
          the_category.deletePropertyObject(dragged)
        end
      when -2
        #Dragged into top level
      else
        #Dragged into another category
        receiver = ActivityObject.find_by_id(n[1].to_i)
        next if receiver.nil?

        if receiver.object_type == "Category"
          if !dragged.nil? && !receiver.nil? && dragged!=receiver
            authorize! :update, receiver.object

            #if dragged is a category update its parent
            if dragged.object_type == "Category"
              authorize! :update, dragged.object
              dragged.object.parent_id = receiver.object.id
              dragged.object.save!
            else
              #Dragged is not a category, add it to receiver.
              receiver.object.insertPropertyObject(dragged)
              
              #notify for leaving a category container
              unless the_category.nil?
                the_category.deletePropertyObject(dragged)
              end
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

  def destroy
    super do |format|
      format.html {
        redirect_to url_for(current_subject)
       }
      format.js
    end
  end

  def settings
    authorize! :update, current_subject

    unless params[:categories_view].blank? or !params[:categories_view].is_a? String
        current_subject.actor.update_column :categories_view, params[:categories_view]
    end

    redirect_to url_for(current_subject) + "?tab=categories"
  end


  private

  def allowed_params
    [:item_type, :item_id, :scope, :avatar, :parent_id]
  end

  def fill_create_params
    params["category"] ||= {}
    if params["category"]["parent_id"].blank?
      params["category"]["parent_id"] = nil
    end
  end

end

