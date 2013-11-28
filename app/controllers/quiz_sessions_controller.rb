class QuizSessionsController < ApplicationController
  include Shortener::ShortenerHelper
  before_filter :authenticate_user!, :only => [ :index, :create, :close, :delete ]

  # GET /quiz_sessions/
  # List all sessions
  def index
    @quiz_sessions = QuizSession.where(:owner_id => Actor.normalize_id(current_user))
    @quiz_active_sessions = @quiz_sessions.where(:active => true).order('created_at DESC')
    @quiz_inactive_sessions = @quiz_sessions.where(:active => false).order('created_at DESC')
  end

  # POST /quiz_sessions 
  # Open a quiz to collect answers
  # Respond with the quiz session id
  def create
    qs = QuizSession.new
    qs.owner_id = Actor.normalize_id(current_user)

    if params[:name]
      qs.name = params[:name]
    end

    if params[:quiz]
      qs.quiz = JSON(params[:quiz]).to_json
    else
      render :text => "Quiz JSON required"
    end

    qs.active = true
    qs.save!

    #Now generate the URL
    #We need to get the URL after save the quiz
    # qs.url=short_url ( request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/quiz_sessions/#{qs.id.to_s}" )
    # qs.url = "http://" + request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/qs/#{qs.id.to_s}"
    # qs.url = qs.answer_url

    results = Hash.new
    results["id"] = qs.id;
    results["url"] = qs.answer_url;

    render :json => results
  end

  def edit
    @quiz_session = QuizSession.find(params[:id])

    if !verify_owner(@quiz_session)
      render :text => "You are not the owner of this quiz"
      return;
    end

    respond_to do |format|
      format.html {
        render :edit
      }
      format.partial {
        render :edit, :layout => false
      }
    end
  end

  # Update quiz session
  # Change quiz session name
  # POST /quiz_sessions/x
  def update
    qs = QuizSession.find(params[:id])

    if !verify_owner(qs)
      render :text => "You are not the owner of this quiz"
      return;
    end

    if qs.active and params[:quiz_session][:active]=="false"
      #Close Quiz
      qs.closed_at = Time.now
    end

    if params[:quiz_session]
      qs.update_attributes(params[:quiz_session])
    end

    redirect_to "/quiz_sessions/"
  end

  # GET /quiz_sessions/X/close
  def close
    qs = QuizSession.find(params[:id])

    if !verify_owner(qs)
      render :text => "You are not the owner of this quiz"
      return;
    end

    qs.active = false
    qs.name = params[:name] unless params[:name].blank?
    qs.closed_at = Time.now
    qs.save!

    respond_to do |format|
      format.json { 
        response = Hash.new
        response["processed"] = true;
        render :json => response
      }
      format.html {
        redirect_to "/quiz_sessions/"
      }
    end
  end

  # /quiz_sessions/X/delete
  def delete
    qs = QuizSession.find(params[:id])

    if !verify_owner(qs)
      render :text => "You are not the owner of this quiz"
      return;
    end

    #With .delete the dependency "has_many :quiz_answers, :dependent => :destroy" dont works
    qs.destroy
    respond_to do |format|
      format.json { 
        response = Hash.new
        response["processed"] = true;
        render :json => response
      }
      format.html {
        redirect_to "/quiz_sessions/"
      }
    end
  end

  # GET /quiz_sessions/X/results
  def results 
    @quiz_session = QuizSession.find(params[:id])

    if !verify_owner(@quiz_session)
      render :text => "You are not the owner of this quiz"
      return;
    end

    @results = @quiz_session.results

    respond_to do |format|
      format.json {
        render :json => @results
      }
      format.html {
        @answers = @results.to_json
        @processedQS = @quiz_session.getProcessedQS
        render :show_results
      }
      format.partial {
        @answers = @results.to_json
        @processedQS = @quiz_session.getProcessedQS
        render :show_results, :layout => false
      }
    end
  end

  # GET /quiz_sessions/X 
  # Page to answer the quiz 
  def show
    @quiz_session = QuizSession.find(params[:id])
    if @quiz_session.active
      render :template => 'excursions/show', :formats => [:full], :layout => 'iframe'
    else
      # Quiz is closed!!!
      render 'quiz_sessions/closed'
    end
  end

  # POST /quiz_sessions/X
  # Route to send the quiz answers
  def updateAnswers
    @quiz_session = QuizSession.find(params[:id])

    response = Hash.new

    if @quiz_session
      qa = QuizAnswer.new
      qa.quiz_session_id = @quiz_session.id
      qa.answer = JSON(params[:answers]).to_json
      qa.save!
      response["processed"] = true;
    else
      response["processed"] = false;
    end

    render :json => response
  end


  private

  def verify_owner(qs)
    return qs.owner == current_user
  end

end
