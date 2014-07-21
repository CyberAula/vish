# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

class ExcursionsController < ApplicationController

  require 'fileutils'

  # Quick hack for bypassing social stream's auth
  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :clone, :uploadTmpJSON ]
  before_filter :profile_subject!, :only => :index
  before_filter :hack_auth, :only => [ :new, :create]
  skip_load_and_authorize_resource :only => [ :excursion_thumbnails, :metadata, :scormMetadata, :iframe_api, :preview, :clone, :manifest, :evaluate, :learning_evaluate, :last_slide, :downloadTmpJSON, :uploadTmpJSON]
  skip_after_filter :discard_flash, :only => [:clone]
  
  # Enable CORS (http://www.tsheffler.com/blog/?p=428) for last_slide, and iframe_api methods
  before_filter :cors_preflight_check, :only => [ :last_slide, :iframe_api]
  after_filter :cors_set_access_control_headers, :only => [ :last_slide, :iframe_api]
  

  include SocialStream::Controllers::Objects

  #############
  # CORS
  #############
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end


  #############
  # REST methods
  #############

  def index
    index! do |format|
      format.html{
        if !params[:networking]
          render "index"
        elsif (params[:page] == "1" && params[:networking])
          render :partial => "excursions/home/home_mynetwork", :locals => {:scope => :net, :page=> params[:page], :sort_by=> params[:sort_by]||"popularity", :prefix_id=>"network"}, :layout => false
        else
          render :partial => "excursions/home/mynetwork_home", :locals => {:scope => :net, :page=> params[:page], :sort_by=> params[:sort_by]||"popularity", :prefix_id=>"network"}, :layout => false
        end
      }
    end
  end

  def show 
    show! do |format|
      format.html {
        @evaluations = @excursion.averageEvaluation
        @numberOfEvaluations = @excursion.numberOfEvaluations
        @learningEvaluations = @excursion.averageLearningEvaluation
        @numberOfLearningEvaluations = @excursion.numberOfLearningEvaluations
        if @excursion.draft and (can? :edit, @excursion)
          redirect_to edit_excursion_path(@excursion)
        else
          render
        end
      }
      format.full {
        @orgUrl = params[:orgUrl]
        render :layout => 'iframe'
      }
      format.mobile { render :layout => 'iframe' }
      format.json { render :json => resource }
      format.gateway { 
        @gateway = params[:gateway]
        render :layout => 'iframe.full'
      }
      format.scorm {
        @excursion.to_scorm(self)
        @excursion.increment_download_count
        send_file "#{Rails.root}/public/scorm/excursions/#{@excursion.id}.zip", :type => 'application/zip', :disposition => 'attachment', :filename => "scorm-#{@excursion.id}.zip"
      }
      format.pdf{
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
      format.full { render :layout => 'iframe' }
    end
  end

  def edit
    edit! do |format|
      format.full { render :layout => 'iframe' }
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
      elsif (params[:draft] == "false")
        @excursion.draft = false
      end
    end

    @excursion.update_attributes!(params[:excursion])

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
      format.all { render "show.full.erb", :layout => 'iframe.full' }
    end
  end

  def metadata
    excursion = Excursion.find_by_id(params[:id])
    respond_to do |format|
      format.xml {
        xmlMetadata = Excursion.generate_LOM_metadata(JSON(excursion.json),excursion,{:id => Rails.application.routes.url_helpers.excursion_url(:id => excursion.id), :LOMschema => params[:LOMschema] || "custom"})
        render :xml => xmlMetadata.target!
      }
      format.any {
        redirect_to excursion_path(excursion)+"/metadata.xml"
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
        render :file => "#{Rails.root}/vendor/plugins/vish_editor/app/assets/javascripts/VISH.IframeAPI.js",
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
    @excursion_evaluation = ExcursionEvaluation.new(:excursion => Excursion.find_by_id(params[:id]))
    @excursion_evaluation.ip = request.remote_ip
    6.times do |ind|
      @excursion_evaluation.send("answer_#{ind}=", params[("excursion_evaluation_#{ind}").to_sym])
    end
    @excursion_evaluation.save!
    respond_to do |format|   
      format.js {render :text => "Thank you", :status => 200}
    end
  end

  def learning_evaluate
    @excursion_learning_evaluation = ExcursionLearningEvaluation.new(:excursion => Excursion.find_by_id(params[:id]))
    @excursion_learning_evaluation.ip = request.remote_ip
    6.times do |ind|
      @excursion_learning_evaluation.send("answer_#{ind}=", params[("excursion_evaluation_#{ind}").to_sym])
    end
    @excursion_learning_evaluation.save!
    respond_to do |format|   
      format.js {render :text => "Thank you", :status => 200}
    end
  end


  ##################
  # Recomendation on the last slide
  ##################
  
  def last_slide
    #Prepare parameters to call the RecommenderSystem

    if params[:excursion_id]
      current_excursion =  Excursion.find(params[:excursion_id]) rescue nil
    end

    options = {:n => (params[:quantity] || 6).to_i}
    if params[:q]
      options[:keywords] = params[:q].split(",")
    end

    # Uncomment this block to activate the A/B testing
    # A/B Testing: 50% of the requests will be attended by the RS, the other 50% will be attended by a random algorithm
    if rand < 0.5
      excursions = Excursion.where(:draft=>false).sample(options[:n])
      excursions.map{ |e|
        e.score_tracking = {
          :rec => "Random"
        }.to_json
      }
    else
      excursions = RecommenderSystem.excursion_suggestions(current_user,current_excursion,options)
    end

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

        if params["json"] == nil
          render :json => results
          return
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
    [:json, :slide_count, :thumbnail_url, :draft, :offline_manifest]
  end

  def hack_auth
    params["excursion"] ||= {}
    params["excursion"]["relation_ids"] = [Relation::Public.instance.id]
    params["excursion"]["owner_id"] = current_subject.actor_id
    params["excursion"]["author_id"] = current_subject.actor_id
    params["excursion"]["user_author_id"] = current_subject.actor_id
  end
end