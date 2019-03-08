class EdiphyDocumentsController < ApplicationController

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :clone ]
  skip_load_and_authorize_resource :only => [:translate, :clone]
  before_filter :profile_subject!, :only => :index
  before_filter :merge_json_params
  before_filter :fill_create_params, :only => [ :new, :create ]
  skip_before_filter :store_location, :if => :format_full?
  skip_after_filter :discard_flash, :only => [:clone]


  include SocialStream::Controllers::Objects


  def index
    redirect_to home_path
  end

  def show
    show! do |format|
      format.html{
        if @ediphy_document.draft
              if (can? :edit, @ediphy_document)
                redirect_to edit_ediphy_document_path(@ediphy_document)
              else
                redirect_to "/"
              end
            else
              @resource_suggestions = RecommenderSystem.resource_suggestions({:user => current_subject, :lo => @ediphy_document, :n=>10, :models => [EdiphyDocument, Excursion]})
              ActorHistorial.saveAO(current_subject,@ediphy_document)
              render
            end
      }
      format.full{
        if @ediphy_document.draft
          if (can? :edit, @ediphy_document)
            redirect_to edit_ediphy_document_path(@ediphy_document)
          else
            redirect_to "/"
          end
        else
          render
        end
      }
      format.json {
        response.headers['Access-Control-Allow-Origin'] = '*'
        render :json => resource
      }
    end
  end

  def new
    new! do |format|
      format.html { render :layout => 'ediphy', :locals => {:default_tag=> params[:default_tag]}}
    end
  end

  def edit
    edit! do |format|
      format.html { render :layout => 'ediphy' }
    end
  end

  def create
    params[:ediphy_document].permit!
    scope = params[:ediphy_document][:json][:present][:status] rescue "draft"
    contributors = params[:ediphy_document][:json][:present][:globalConfig][:originalContributors]

    params[:ediphy_document][:json] = params[:ediphy_document][:json].to_json if params[:ediphy_document][:json].present?
    ed = EdiphyDocument.new(params[:ediphy_document])
    ed.contributors = contributors.nil? ? [] : contributors.select { |c|  c["vishMetadata"]["id"] != params["ediphy_document"]["author_id"] }.map{|c| (Actor.find_by_id(c["vishMetadata"]["id"]))}  rescue []
    ed.contributors.uniq!
    #Set scope and draft
    ed.draft = (scope == "draft" ? true :  false)
    ed.scope = (ed.draft == true ? 1 :  0)
    ed.save!

    ed.afterPublish if (ed.draft===false)

    render json: { ediphy_id: ed.id }
  end

  def update
    params[:ediphy_document].permit!
    params[:ediphy_document].delete(:user)
    scope = params[:ediphy_document][:json][:present][:status] rescue "draft"
    params[:ediphy_document][:json] = params[:ediphy_document][:json].to_json if params[:ediphy_document][:json].present?

    ed = EdiphyDocument.find(params[:id])
    wasDraft = ed.draft
    ed.draft = (scope == "draft" ? true :  false)
    ed.scope = (ed.draft == true ? 1 :  0)

    isAdmin = current_subject.admin?

    begin
      EdiphyDocument.record_timestamps=false if isAdmin
      ed.update_attributes!(params[:ediphy_document])
    ensure
      EdiphyDocument.record_timestamps=true if isAdmin
    end

    ed.afterPublish if (wasDraft===true and ed.draft===false)

    render json: { ediphy_id: ed.id }
  end

  def destroy
    destroy! do |format|
      format.all { redirect_to user_path(current_subject) }
    end
  end

  def translate
    respond_to do |format|
      format.json do
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Max-Age'] = "1728000"
        if params[:id]
          @excursion = Excursion.find(params[:id])
          if @excursion.allow_clone
            render json: @excursion.to_ediphy
          else
            render json: {error: "Not allowed", status: 403}, status: 403
          end
        else
          render json: {error: "Not found", status: 404}, status: 404
        end
      end
      format.html do
        if params[:id]
          @excursion = Excursion.find(params[:id])
          if can? :clone, @excursion
            render 'ediphy_documents/new', :layout => 'ediphy', :locals => { :default_tag=> params[:default_tag]}
          else
            redirect_to(excursion_path(@excursion))
          end
        end

      end
    end
  end

  def clone
    original = EdiphyDocument.find_by_id(params[:id])
    if original.blank?
      flash[:error] = t('ediphy_document.clone.not_found')
      redirect_to excursions_path if original.blank? # Bad parameter
    else
      # Do clone
      ediphy_document = original.clone_for current_subject.actor
      flash[:success] = t('ediphy_document.clone.ok')
      redirect_to ediphy_document_path(ediphy_document)
    end
  end
  private

  def allowed_params
    [:json, :draft, :scope]
  end

  def fill_create_params
    params["ediphy_document"] ||= {}

    #Include user information according to ViSH requirements
    params["ediphy_document"].delete("user")
    unless current_subject.nil?
      params["ediphy_document"]["owner_id"] = current_subject.actor_id
      params["ediphy_document"]["author_id"] = current_subject.actor_id
      params["ediphy_document"]["user_author_id"] = current_subject.actor_id
    end

  end

  #If you dear programmer are asking ¡what is this method doing', just to mention, rails makes a terrible conversion from json to Ruby arrays
  #and basically changes all empty arrays for nils (this is for security purposes, but seems like killing flies by cannonballs)
  #So we need to fix this somehow because our json app does things like that for some reason. I Hope it helped

  def merge_json_params
    if request.format.json?
      body = request.body.read
      request.body.rewind
      params.merge!(ActiveSupport::JSON.decode(body)) unless body == ""
    end
  end

end