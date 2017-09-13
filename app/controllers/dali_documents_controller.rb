class DaliDocumentsController < ApplicationController
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
		#TODO: make this work
		authorize! :create, DaliDocument
		if params[:dali_document][:json][:present][:globalConfig][:title].blank? or params[:dali_document][:json][:present][:globalConfig][:title].include?("/dali_documents/")
			render :nothing => true, :status => 200, :content_type => 'text/html'
		end

		if current_subject.actor.id == params[:dali_document][:user][:id].to_i
			dd = DaliDocument.new
			dd.json = params[:dali_document][:json].to_json
			dd.title = params[:dali_document][:json][:present][:title]
			dd.owner_id = params[:dali_document][:user][:id]
			dd.author_id = params[:dali_document][:user][:id]
			dd.save!

			render json: { dali_id: dd.id}
		else
			render status: :forbidden
		end
	end

	def add_xml
		if params["url"] == "/dali_documents/new.full"
			dd = DaliDocument.new
			dd.json = "{}"
			dd.owner = current_subject.actor
			dd.author = current_subject.actor
			dd.save!

			id = dd.id
		else
			id = /\d+/.match(params["url"]).to_s.to_i
		end

		unless id == nil || id == 0
			dali_exercise = DaliExercise.new
			dali_exercise.dali_document_id = id
			dali_exercise.xml = params["xml"]
			dali_exercise.save!
		end
		dd ||= DaliDocument.find(id)
		render json: { dali_document_path: dd.absolutePath, dali_exercise_path: dali_exercise.absolutePath }
	end

	def update
		if current_subject.actor.id == params[:dali_document][:user][:id].to_i
			dd = DaliDocument.find(params[:id])
			authorize!(:update, dd)
			dd.json = params[:dali_document][:json].to_json
			dd.title = params[:dali_document][:json][:present][:title]
			dd.save!

			render json: { dali_id: dd.id}
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
		show! do |format|
			format.full
		end
	end

	def delete
		dd = DaliDocument.find(params[:id])
		authorize!(:delete, dd)
		if !params[:user].blank? and !params[:user][:id].blank? and current_subject.actor.id == params[:user][:id].to_i
			destroy! do |format|
				format.json { render json:  { redirect_url: user_path(current_subject)}}
			end
		elsif dd.author == current_subject.actor
			destroy! do |format|
				format.json{  render json: {}}
			end
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
