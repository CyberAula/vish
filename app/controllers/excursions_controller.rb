class ExcursionsController < ApplicationController

  require 'fileutils'

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :clone, :uploadTmpJSON ]
  before_filter :profile_subject!, :only => :index
  before_filter :fill_create_params, :only => [ :new, :create]
  skip_load_and_authorize_resource :only => [ :excursion_thumbnails, :metadata, :scormMetadata, :iframe_api, :preview, :clone, :manifest, :evaluate, :last_slide, :downloadTmpJSON, :uploadTmpJSON]
  skip_before_filter :store_location, :if => :format_full?
  skip_after_filter :discard_flash, :only => [:clone]
  
  # Enable CORS
  before_filter :cors_preflight_check, :only => [:excursion_thumbnails,:last_slide,:iframe_api]
  after_filter :cors_set_access_control_headers, :only => [:excursion_thumbnails,:last_slide,:iframe_api]
  
  include SocialStream::Controllers::Objects


  #############
  # REST methods
  #############

  def index
  end

  def show 
    show! do |format|
      format.html {
        if @excursion.draft 
          if (can? :edit, @excursion)
            redirect_to edit_excursion_path(@excursion)
          else
            redirect_to "/"
          end
        else
          tr = TrackingSystemEntry.trackRLOsInExcursions(params["rec"],@excursion,request,current_subject)
          @tracking_system_entry_id = tr.id unless tr.nil?
          
          rsEngine = TrackingSystemEntry.getRandomRSEngine
          @rec = TrackingSystemEntry.getRSCode(rsEngine)
          @resource_suggestions = RecommenderSystem.resource_suggestions(current_subject,@excursion,{:n=>16, :models => [Excursion], :recEngine => rsEngine, :track => true})
          render
        end
      }
      format.full {
        @orgUrl = params[:orgUrl]
        @title = @excursion.title
        render :layout => 'veditor'
      }
      format.json {
        render :json => resource 
      }
      format.gateway {
        @gateway = params[:gateway]
        @title = @excursion.title
        render :layout => 'veditor.full'
      }
      format.scorm {
        @excursion.to_scorm(self)
        @excursion.increment_download_count
        send_file "#{Rails.root}/public/scorm/excursions/#{@excursion.id}.zip", :type => 'application/zip', :disposition => 'attachment', :filename => "scorm-#{@excursion.id}.zip"
      }
      format.pdf {
        @excursion.to_pdf(self)
        if File.exist?("#{Rails.root}/public/pdf/excursions/#{@excursion.id}/#{@excursion.id}.pdf")
          send_file "#{Rails.root}/public/pdf/excursions/#{@excursion.id}/#{@excursion.id}.pdf", :type => 'application/pdf', :disposition => 'attachment', :filename => "#{@excursion.id}.pdf"
        else
          render :nothing => true, :status => 500
        end
      }
    end
  end

  def new
    new! do |format|
      format.full { render :layout => 'veditor' }
    end
  end

  def edit
    edit! do |format|
      format.full { render :layout => 'veditor' }
    end
  end

  def create
    params[:excursion].permit!
    @excursion = Excursion.new(params[:excursion])

    if(params[:draft] and params[:draft] == "true")
      @excursion.draft = true
    else
      @excursion.draft = false
    end

    @excursion.save!

    published = (@excursion.draft===false)
    if published
      @excursion.afterPublish
    end

    render :json => { :url => (@excursion.draft ? user_path(current_subject) : excursion_path(resource, :recent => :true)),
                      :uploadPath => excursion_path(@excursion, :format=> "json"),
                      :editPath => edit_excursion_path(@excursion)
                    }
  end

  def update
    if params[:excursion]
      params[:excursion].permit!
    end

    @excursion = Excursion.find(params[:id])
    wasDraft = @excursion.draft

    if(params[:draft])
      if(params[:draft] == "true")
        @excursion.draft = true
        @excursion.scope = 1
      elsif (params[:draft] == "false")
        @excursion.draft = false
        @excursion.scope = 0
      end
    end

    isAdmin = current_subject.admin?

    begin
      if isAdmin
        Excursion.record_timestamps=false
      end
      @excursion.update_attributes!(params[:excursion])
    ensure
      if isAdmin
        Excursion.record_timestamps=true
      end
    end
   
    published = (wasDraft===true and @excursion.draft===false)
    if published
      @excursion.afterPublish
    end

    render :json => { :url => (@excursion.draft ? user_path(current_subject) : excursion_path(resource, :recent => :true)),
                      :uploadPath => excursion_path(@excursion, :format=> "json"),
                      :editPath => edit_excursion_path(@excursion),
                      :exitPath => (@excursion.draft ? user_path(current_subject) : excursion_path(resource))
                    }
  end

  def destroy
    destroy! do |format|
      format.all { redirect_to user_path(current_subject) }
    end
  end


  ############################
  # Custom actions over Excursions and services provided by excursions controller
  ############################

  def preview
    respond_to do |format|
      format.all { render "show.full.erb", :layout => 'veditor.full' }
    end
  end

  def metadata
    excursion = Excursion.find_by_id(params[:id])
    respond_to do |format|
      format.any {
        unless excursion.nil?
          xmlMetadata = Excursion.generate_LOM_metadata(JSON(excursion.json),excursion,{:id => Rails.application.routes.url_helpers.excursion_url(:id => excursion.id), :LOMschema => params[:LOMschema] || "custom"})
        else
          xmlMetadata = ::Builder::XmlMarkup.new(:indent => 2)
          xmlMetadata.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
          xmlMetadata.error("Excursion not found")
        end
        render :xml => xmlMetadata.target!, :content_type => "text/xml"
      }
    end
  end

  def scormMetadata
    excursion = Excursion.find_by_id(params[:id])
    respond_to do |format|
      format.xml {
        xmlMetadata = Excursion.generate_scorm_manifest(JSON(excursion.json),excursion,{:LOMschema => params[:LOMschema]})
        render :xml => xmlMetadata.target!
      }
      format.any {
        redirect_to excursion_path(excursion)+"/scormMetadata.xml"
      }
    end
  end

  def clone
    original = Excursion.find_by_id(params[:id])
    if original.blank?
      flash[:error] = t('excursion.clone.not_found')
      redirect_to excursions_path if original.blank? # Bad parameter
    else
      # Do clone
      excursion = original.clone_for current_subject.actor
      flash[:success] = t('excursion.clone.ok')
      redirect_to excursion_path(excursion)
    end
  end

  def manifest
    headers['Last-Modified'] = Time.now.httpdate
    @excursion = Excursion.find_by_id(params[:id])
    render 'cache.manifest', :layout => false, :content_type => 'text/cache-manifest'
  end

  def iframe_api
    respond_to do |format|
      format.js {
        render :file => "#{Rails.root}/lib/plugins/vish_editor/app/assets/javascripts/VISH.IframeAPI.js",
          :content_type => 'application/javascript',
          :layout => false
      }
    end
  end

  def excursion_thumbnails
    thumbnails = Hash.new
    thumbnails["pictures"] = []

    81.times do |index|
      index = index+1
      thumbnail = Hash.new
      thumbnail["title"] = "Thumbnail " + index.to_s
      thumbnail["description"] = "Sample Thumbnail"
      tnumber = index.to_s
      if index<10
        tnumber = "0" + tnumber
      end
      thumbnail["src"] = Vish::Application.config.full_domain + "/assets/logos/original/excursion-"+tnumber+".png"
      thumbnails["pictures"].push(thumbnail)
    end

    render :json => thumbnails
  end


  ##################
  # Evaluation Methods
  ##################
  
  def evaluate
    @excursion = Excursion.find(params["id"])
    @evmethod = params["evmethod"] || "wbltses"
    
    respond_to do |format|
      format.html {
        render "learning_evaluation"
      }
    end
  end


  ##################
  # Recomendation on the last slide
  ##################
  
  def last_slide
    #Prepare parameters to call the RecommenderSystem

    if params[:excursion_id]
      current_excursion =  Excursion.find_by_id(params[:excursion_id])
    else
      current_excursion = nil
    end

    options = {:n => (params[:quantity] || 6).to_i, :models => [Excursion]}
    if params[:q]
      options[:keywords] = params[:q].split(",")
    end

    # Uncomment this block to activate the A/B testing
    # A/B Testing: some % of the requests will be attended by the full RS, the other % will be attended by other algorithms
    rnd = rand
    if rnd < 0.10
      #Random
      options[:recEngine] = "Random"
    elsif rnd < 0.5
      #Full RS without quality metrics
      options[:recEngine] = "ViSHRS-Quality"
    elsif rnd < 0.9
      #Full RS without quality and popularity metrics
      options[:recEngine] = "ViSHRS-Quality-Popularity"
    else
      #Full RS
      options[:recEngine] = "ViSHRecommenderSystem"
    end

    excursions = RecommenderSystem.resource_suggestions(current_subject,current_excursion,options)

    respond_to do |format|
      format.json {
        render :json => excursions.map { |ex| ex.reduced_json(self) }
      }
    end
  end



  #####################
  ## VE Methods
  ####################

  def uploadTmpJSON
    respond_to do |format|  
      format.json {
        results = Hash.new

        unless params["json"].present?
          return render :json => results
        else
          json = params["json"]
        end

        responseFormat = "json" #Default
        if params["responseFormat"].is_a? String
          if params["responseFormat"].downcase == "scorm"
            responseFormat = "scorm"
          end
          if params["responseFormat"].downcase == "qti"
            responseFormat = "qti"
          end
          if params["responseFormat"].downcase == "moodlexml"
            responseFormat = "MoodleXML"
          end
        end

        count = Site.current.config["tmpCounter"].nil? ? 1 : Site.current.config["tmpCounter"]
        Site.current.config["tmpCounter"] = count + 1
        Site.current.save!

        if responseFormat == "json"
          #Generate JSON file
          filePath = "#{Rails.root}/public/tmp/json/#{count.to_s}.json"
          t = File.open(filePath, 'w')
          t.write json
          t.close
          results["url"] = "#{Vish::Application.config.full_domain}/excursions/tmpJson.json?fileId=#{count.to_s}"
        elsif responseFormat == "scorm"
          #Generate SCORM package
          filePath = "#{Rails.root}/public/tmp/scorm/"
          fileName = "scorm-tmp-#{count.to_s}"
          Excursion.createSCORM(filePath,fileName,JSON(json),nil,self)
          results["url"] = "#{Vish::Application.config.full_domain}/tmp/scorm/#{fileName}.zip"
        elsif responseFormat == "qti"
           #Generate QTI package
           filePath = "#{Rails.root}/public/tmp/qti/"
           FileUtils.mkdir_p filePath
           fileName = "qti-tmp-#{count.to_s}"
           Excursion.createQTI(filePath,fileName,JSON(json))
           results["url"] = "#{Vish::Application.config.full_domain}/tmp/qti/#{fileName}.zip"
        elsif responseFormat == "MoodleXML"
           filePath = "#{Rails.root}/public/tmp/moodlequizxml/"
           FileUtils.mkdir_p filePath
           fileName = "moodlequizxml-tmp-#{count.to_s}"
           Excursion.createMoodleQUIZXML(filePath,fileName,JSON(json))
           results["url"] = "#{Vish::Application.config.full_domain}/tmp/moodlequizxml/#{fileName}.zip"
        end

        render :json => results
      }
    end
  end

  def downloadTmpJSON
    respond_to do |format|  
      format.json {
        if params["fileId"] == nil
          results = Hash.new
          render :json => results
          return
        else
          fileId = params["fileId"]
        end

        if params["filename"]
          filename = params["filename"]
        else
          filename = fileId
        end

        filePath = "#{Rails.root}/public/tmp/json/#{fileId}.json"
        if File.exist? filePath
          send_file "#{filePath}", :type => 'application/json', :disposition => 'attachment', :filename => "#{filename}.json"
        else 
          render :json => results
        end
      }
    end
  end


  private

  def allowed_params
    [:json, :slide_count, :thumbnail_url, :draft, :scope]
  end

  def fill_create_params
    params["excursion"] ||= {}

    if params["draft"]==="true"
      params["excursion"]["scope"] = "1" #private
    else
      params["excursion"]["scope"] = "0" #public
    end

    unless current_subject.nil?
      params["excursion"]["owner_id"] = current_subject.actor_id
      params["excursion"]["author_id"] = current_subject.actor_id
      params["excursion"]["user_author_id"] = current_subject.actor_id
    end
  end
end