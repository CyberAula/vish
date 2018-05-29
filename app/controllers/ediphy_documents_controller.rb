class EdiphyDocumentsController < ApplicationController
	include SocialStream::Controllers::Objects

	before_filter :merge_json_params
	#before_filter :verify_authenticity_token
	before_filter :authenticate_user!
	after_filter :cors_set_access_control_headers, :only => [:create, :merge_json_params]
	skip_load_and_authorize_resource :only => [:create, :update, :add_xml,:delete]

	def new
		new! do |format|
			format.full
		end
	end

	def create
		authorize! :create, EdiphyDocument
		if params[:ediphy_document][:json][:present][:globalConfig][:title].blank? or params[:ediphy_document][:json][:present][:globalConfig][:title].include?("/ediphy_documents/")
			render :nothing => true, :status => 200, :content_type => 'text/html'
		end

		if current_subject.actor.id == params[:ediphy_document][:user][:id].to_i
			ed = EdiphyDocument.new
			ed.json = params[:ediphy_document][:json].to_json
			ed.title = params[:ediphy_document][:json][:present][:globalConfig][:title]
			ed.owner_id = current_subject.actor_id
			ed.author_id = current_subject.actor_id
			#DRAFT
			
			scope = JSON.parse(ed.json)["present"]["globalConfig"]["status"]
			ed.draft = scope == "draft" ? true :  false
			ed.save!

			render json: { ediphy_id: ed.id}
		else
			render status: :forbidden
		end
	end

	def add_xml
		if params["url"] == "/ediphy_documents/new.full"
			ed = EdiphyDocument.new
			ed.json = "{}"
			ed.owner = current_subject.actor
			ed.author = current_subject.actor
			ed.save!

			id = ed.id
		else
			id = /\d+/.match(params["url"]).to_s.to_i
		end

		unless id == nil || id == 0
			ediphy_exercise = EdiphyExercise.new
			ediphy_exercise.ediphy_document_id = id
			ediphy_exercise.xml = params["xml"]
			ediphy_exercise.save!
		end
		ed ||= EdiphyDocument.find(id)
		render json: { ediphy_document_path: ed.absolutePath, ediphy_exercise_path: ediphy_exercise.absolutePath }
	end

	def update
		if current_subject.actor.id == params[:ediphy_document][:user][:id].to_i
			ed = EdiphyDocument.find(params[:id])
			authorize!(:update, ed)
			ed.json = params[:ediphy_document][:json].to_json
			ed.title = params[:ediphy_document][:json][:present][:globalConfig][:title]
			ed.save!

			### Refactor to fill_create parms
			scope = JSON.parse(ed.json)["present"]["globalConfig"]["status"]
			published = scope == "draft" ? true :  false
			ed.draft = published
			
			ao = ed.activity_object
			ao.scope = scope == "draft" ? 0 : 1
			ed.save!

			if published
      			ed.afterPublish
    		end

			render json: { ediphy_id: ed.id}
		else
			render status: :forbidden
		end
	end

	def edit
		edit! do |format|
			format.full
		end
	end

	def show
		@resource_suggestions = RecommenderSystem.resource_suggestions({:user => current_subject, :lo => @ediphy_document, :n=>10, :models => [EdiphyDocument, Excursion]})
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
		          @resource_suggestions = RecommenderSystem.resource_suggestions({:user => current_subject, :lo => @ediphy_document, :n=>10, :models => [EdiphyDocument, Excursion]})
		          ActorHistorial.saveAO(current_subject,@ediphy_document)
		          render
		        end
			}
			format.json {
		      render :json => resource 
		    }
		end
	end

	def delete
		ed = EdiphyDocument.find(params[:id])
		authorize!(:delete, ed)
		if !params[:user].blank? and !params[:user][:id].blank? and current_subject.actor.id == params[:user][:id].to_i
			destroy! do |format|
				format.json { render json:  { redirect_url: user_path(current_subject)}}
			end
		elsif ed.author == current_subject.actor
			destroy! do |format|
				format.json{  render json: {}}
			end
		end
	end

	def metadata
		ed = EdiphyDocument.find_by_id(params[:id])
	    respond_to do |format|
	      format.any {
	        unless ed.nil?
	          xmlMetadata = EdiphyDocument.generate_LOM_metadata(JSON(ed.json),ed,{:id => Rails.application.routes.url_helpers.ediphy_document_url(:id => ed.id), :LOMschema => params[:LOMschema] || "custom"})
	          render :xml => xmlMetadata.target!, :content_type => "text/xml"
	        else
	          xmlMetadata = ::Builder::XmlMarkup.new(:indent => 2)
	          xmlMetadata.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
	          xmlMetadata.error("Ediphy Document not found")
	          render :xml => xmlMetadata.target!, :content_type => "text/xml", :status => 404
	        end
	      }
	    end
	end

	private

	#If you dear programmer are asking ¡what is this method doing', just to mention, rails makes a terrible conversion from json to Ruby arrays
	#and basically changes all empty arrays for nils (this is for security purposes, but seems like killing flies by cannonballs)
	#So we need to fix this somehow because our json app does things like that for some reason. I Hope it helped

	def allowed_params
		[:user, :json]
	end

	def merge_json_params
		if request.format.json?
			body = request.body.read
			request.body.rewind
			params.merge!(ActiveSupport::JSON.decode(body)) unless body == ""
		end
	end


end
