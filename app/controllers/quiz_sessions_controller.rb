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

    qs.quiz_results = nil;
    qs.active = true
    qs.save!

    #Now generate the URL
    #We need to save the quiz twice, one to generate the id and the other to save the URL

    # qs.url=short_url ( request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/quiz_sessions/#{qs.id.to_s}" )
    qs.url = request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/quiz_sessions/#{qs.id.to_s}"

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
      answers = JSON(params[:answers])

      if @quiz_session.quiz_results == nil
        results = [];
      else
        results = JSON(@quiz_session.quiz_results);
      end
      
      results.push(answers);
      @quiz_session.quiz_results = results.to_json;
      @quiz_session.save!
      response["processed"] = true;
    else
      response["processed"] = false;
    end

    render :json => response
  end

  # GET /quiz_sessions/X/results
  def results 
    @quiz_session = QuizSession.find(params[:id])
    respond_to do |format|
      format.json { 
        render :json => @quiz_session.quiz_results
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
    
    response = Hash.new
    response["processed"] = true;
    render :json => response
  end


#OLD
  # # GET /quiz_sessions/X/results
  # def results 
  #   @quiz_session = QuizSession.find(params[:id])
  #   @results = {}
  #   @results[:quiz_session_id] = @quiz_session.id
  #   @results[:quiz_id] = @quiz_session.quiz.id
  #   respond_to do |format|
  #     format.html { render :layout => 'iframe' }
  #     @results[:results] = @quiz_session.answers
  #     format.all { render :json => @results }
  #   end
  # end

end
