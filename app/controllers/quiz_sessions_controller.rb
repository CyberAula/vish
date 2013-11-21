class QuizSessionsController < ApplicationController
  include Shortener::ShortenerHelper

  before_filter :authenticate_user!, :only => [ :create, :close ]


  # POST /quiz_sessions 
  # Open a quiz to collect answers
  # Respond with the quiz session id
  def create
    qs = QuizSession.new
    qs.owner_id=current_user.id

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
    #We need to save the quiz twice, one to generate the id and the other to save the URL

    # qs.url=short_url ( request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/quiz_sessions/#{qs.id.to_s}" )
    qs.url = "http://" + request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/qs/#{qs.id.to_s}"

    results = Hash.new
    results["id"] = qs.id;
    results["url"] = qs.url;

    render :json => results
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


  # PUT /quiz_sessions/X
  # Route to send the quiz answers
  def update 
    @quiz_session = QuizSession.find(params[:id])

    response = Hash.new

    if @quiz_session
      qa = QuizAnswer.new
      qa.quiz_session_id = @quiz_session.id
      qa.created_at = Time.now
      qa.answer = JSON(params[:answers]).to_json
      qa.save!
      response["processed"] = true;
    else
      response["processed"] = false;
    end

    render :json => response
  end

  # GET /quiz_sessions/X/results
  def results 
    @quiz_session = QuizSession.find(params[:id])
    @results = @quiz_session.results

    respond_to do |format|
      format.json {
        render :json => @results
      }
      format.html {
        @answers = @results.to_json
        @quizParams = @quiz_session.getQuizParams
        render :show_results
      }
      format.partial {
        @answers = @results.to_json
        @quizParams = @quiz_session.getQuizParams
        render :show_results, :layout => false
      }
    end
  end

  # /quiz_sessions/X/close
  def close 
    @quiz_session = QuizSession.find(params[:id])

    if @quiz_session.owner != current_user
      render :text => "You are not the owner of this quiz"
    end

    @quiz_session.active=false
    @quiz_session.name = params[:name] unless params[:name].blank?
    @quiz_session.closed_at = Time.now
    @quiz_session.save!

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
    @quiz_session = QuizSession.find(params[:id])
    @quiz_session.delete
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

  # /quiz_sessions/
  # List all sessions
  def index
    @quiz_sessions = QuizSession.where(:owner_id => Actor.normalize_id(current_user));
    @quiz_active_sessions = @quiz_sessions.where(:active => true).order('created_at DESC')
    @quiz_inactive_sessions = @quiz_sessions.where(:active => false).order('created_at DESC')
  end

end
