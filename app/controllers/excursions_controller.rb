class ExcursionsController < ApplicationController

  require 'fileutils'

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :clone, :uploadTmpJSON, :upload_attachment ]
  before_filter :profile_subject!, :only => :index
  before_filter :fill_create_params, :only => [ :new, :create]
  skip_load_and_authorize_resource :only => [ :excursion_thumbnails, :metadata, :scormMetadata, :iframe_api, :preview, :clone, :manifest, :evaluate, :last_slide, :downloadTmpJSON, :uploadTmpJSON, :interactions, :upload_attachment, :show_attachment]
  skip_before_filter :store_location, :only => [ :show_attachment ]
  skip_before_filter :store_location, :if => :format_full?
  skip_after_filter :discard_flash, :only => [:clone]
  after_filter :notify_teacher, :only => [:create, :update]

  # Enable CORS
  before_filter :cors_preflight_check, :only => [:excursion_thumbnails,:last_slide,:iframe_api]
  after_filter :cors_set_access_control_headers, :only => [:excursion_thumbnails,:last_slide,:iframe_api]
  
  include SocialStream::Controllers::Objects


  #############
  # REST methods
  #############

  def index
    redirect_to home_path
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
          @resource_suggestions = RecommenderSystem.resource_suggestions({:user => current_subject, :lo => @excursion, :n=>10, :models => [Excursion]})
          ActorHistorial.saveAO(current_subject,@excursion)
          render
        end
      }
      format.full {
        @orgUrl = params[:orgUrl]
        @title = @excursion.title
        render :layout => 'veditor'
      }
      format.fs {
        @excursion.activity_object.increment!(:visit_count) if @excursion.public_scope?
        @orgUrl = params[:orgUrl]
        @title = @excursion.title
        render "show.full", :layout => 'veditor'
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
        if (can? :download_source, @excursion)
          scormVersion = (params["version"].present? and ["12","2004"].include?(params["version"])) ? params["version"] : "2004"
          @excursion.to_scorm(self,scormVersion)
          @excursion.increment_download_count
          send_file @excursion.scormFilePath(scormVersion), :type => 'application/zip', :disposition => 'attachment', :filename => ("scorm" + scormVersion + "-#{@excursion.id}.zip")
        else
          render :nothing => true, :status => 500
        end
      }
      format.pdf {
        @excursion.to_pdf
        if @excursion.downloadable? and File.exist?("#{Rails.root}/public/pdf/excursions/#{@excursion.id}/#{@excursion.id}.pdf")
          send_file "#{Rails.root}/public/pdf/excursions/#{@excursion.id}/#{@excursion.id}.pdf", :type => 'application/pdf', :disposition => 'attachment', :filename => "#{@excursion.id}.pdf"
        else
          render :nothing => true, :status => 500
        end
      }
    end
  end

  def new
    new! do |format|
      format.full { render :layout => 'veditor', :locals => {:default_tag=> params[:default_tag]}}
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

    render :json => { :url => (@excursion.draft ? user_path(current_subject) : excursion_path(resource)),
                      :uploadPath => excursion_path(@excursion, :format=> "json"),
                      :editPath => edit_excursion_path(@excursion),
                      :id => @excursion.id
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
      Excursion.record_timestamps=false if isAdmin
      @excursion.update_attributes!(params[:excursion])
    ensure
      Excursion.record_timestamps=true if isAdmin
    end
   
    published = (wasDraft===true and @excursion.draft===false)
    if published
      @excursion.afterPublish
    end

    render :json => { :url => (@excursion.draft ? user_path(current_subject) : excursion_path(resource)),
                      :uploadPath => excursion_path(@excursion, :format=> "json"),
                      :editPath => edit_excursion_path(@excursion),
                      :exitPath => (@excursion.draft ? user_path(current_subject) : excursion_path(resource)),
                      :id => @excursion.id
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
          render :xml => xmlMetadata.target!, :content_type => "text/xml"
        else
          xmlMetadata = ::Builder::XmlMarkup.new(:indent => 2)
          xmlMetadata.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
          xmlMetadata.error("Excursion not found")
          render :xml => xmlMetadata.target!, :content_type => "text/xml", :status => 404
        end
      }
    end
  end

  def scormMetadata
    excursion = Excursion.find_by_id(params[:id])
    scormVersion = ((params["version"].present? and ["12","2004"].include?(params["version"])) ? params["version"] : "2004")
    respond_to do |format|
      format.xml {
        xmlMetadata = Excursion.generate_scorm_manifest(scormVersion,JSON(excursion.json),excursion,{:LOMschema => params[:LOMschema]})
        render :xml => xmlMetadata.target!
      }
      format.any {
        redirect_to (excursion_path(excursion)+"/scormMetadata.xml?version=" + scormVersion)
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

  def interactions
    unless user_signed_in? and current_user.admin?
      return render :text => "Unauthorized"
    end

    validInteractions = LoInteraction.all.select{|it| it.nvalidsamples >= 5 and it.nsamples > 0 and !it.activity_object.nil? and !it.activity_object.object.nil? and !it.activity_object.object.reviewers_qscore.nil?}
    # validInteractions = validInteractions.sort_by{|it| -it.nsamples}
    @excursions = validInteractions.map{|it| it.activity_object.object}
    @excursions = @excursions.sort_by{|e| -e.reviewers_qscore}
    respond_to do |format|
      format.json {
        render json: @excursions.map{ |excursion| excursion.interaction_attributes }, :filename => "LoInteractions.json", :type => "application/json"
      }
      format.any {
        render :xlsx => "interactions", :filename => "LoInteractions.xlsx", :type => "application/vnd.openxmlformates-officedocument.spreadsheetml.sheet"
      }
    end
  end

  def upload_attachment
    excursion = Excursion.find_by_id(params["pres_id"])
    unless excursion.nil? || params[:attachment].blank?
      authorize! :update, excursion
      excursion.update_attributes(:attachment => params[:attachment])
      if excursion.save
        respond_to do |format|
          format.json  { render :json => { :status => "ok", :message => "success"} }
        end
      else
        respond_to do |format|
          format.json  { render :json => { :status => "bad_request", :message => "bad_size"} }
        end
      end
    else
      respond_to do |format|
        format.json  { render :json => { :status => "bad_request", :message => "wrong_params"} }
      end
    end
  end

  def show_attachment
    excursion_id = params[:id]
    excursion = Excursion.find(excursion_id)

    unless excursion.blank? || excursion.attachment.blank?
      attachment = File.open(excursion.attachment.path)
      attachment_name = rename_attachment(attachment, excursion_id)
      send_file attachment, :filename => attachment_name
    end
  end

  ##################
  # Evaluation Methods
  ##################
  
  def evaluate
    @excursion = Excursion.find(params["id"])
    @evmethod = params["evmethod"] || "wblts"
    
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
    current_excursion =  Excursion.find_by_id(params[:excursion_id]) if params[:excursion_id]
    options = {:user => current_subject, :lo => current_excursion, :n => (params[:quantity] || 6).to_i, :models => [Excursion]}
    options[:keywords] = params[:q].split(",") if params[:q]

    excursions = RecommenderSystem.resource_suggestions(options)

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
          responseFormatParsedParam = params["responseFormat"].downcase
          if responseFormatParsedParam.include?("scorm")
            responseFormat = "scorm"
            scormVersion = responseFormatParsedParam.sub("scorm","")
          elsif responseFormatParsedParam == "qti"
            responseFormat = "qti"
          elsif responseFormatParsedParam == "moodlexml"
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
        elsif responseFormat == "scorm" and ["12","2004"].include?(scormVersion)
          #Generate SCORM package
          filePath = "#{Rails.root}/public/tmp/scorm/"
          fileName = "scorm" + scormVersion + "-tmp-#{count.to_s}"
          Excursion.createSCORM(scormVersion,filePath,fileName,JSON(json),nil,self)
          results["url"] = "#{Vish::Application.config.full_domain}/tmp/scorm/#{fileName}.zip"
        elsif responseFormat == "qti"
           #Generate QTI package
           filePath = "#{Rails.root}/public/tmp/qti/"
           FileUtils.mkdir_p filePath
           fileName = "qti-tmp-#{count.to_s}"
           Excursion.createQTI(filePath,fileName,JSON(json))
           results["url"] = "#{Vish::Application.config.full_domain}/tmp/qti/#{fileName}.zip"
        elsif responseFormat == "MoodleXML"
            #Generate Moodle XML package
           filePath = "#{Rails.root}/public/tmp/moodlequizxml/"
           FileUtils.mkdir_p filePath
           fileName = "moodlequizxml-tmp-#{count.to_s}"
           Excursion.createMoodleQUIZXML(filePath,fileName,JSON(json))
           results["url"] = "#{Vish::Application.config.full_domain}/tmp/moodlequizxml/#{fileName}.xml"
           results["xml"] = File.open("#{filePath}#{fileName}.xml").read
           results["filename"] = "#{fileName}.xml"
        end

        results["url"] = Embed.checkUrlProtocol(results["url"],request.protocol) unless results["url"].blank?

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

  def rename_attachment(name,id)
      file_ext= File.extname(name)
      file_new_name = "excursion_"+ id +"_attachment" + file_ext
      file_new_name
  end

  def notify_teacher
      pupil = @excursion.author.user
      unless pupil.user.private_student_group_id.nil? || pupil.private_student_group.teacher_notification != "ALL"
        teacher = Actor.find(pupil.user.private_student_group.owner_id).user
        excursion_path = excursion_path(@excursion) #TODO get full path
        TeacherNotificationMailer.notify_teacher(teacher, pupil, excursion_path)
      end
  end

end