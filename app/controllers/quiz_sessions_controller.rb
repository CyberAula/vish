class QuizSessionsController < ApplicationController
  include Shortener::ShortenerHelper

  before_filter :authenticate_user!, :only => [ :create, :delete ]

    # create_table :quiz_sessions do |t|
    #   t.integer :owner_id
    #   t.string  :name
    #   t.string  :quiz
    #   t.string  :quiz_results
    #   t.boolean :active, :default => true
    #   t.datetime :created_at
    #   t.datetime :updated_at
    #   t.datetime :closed_at
    # end



  # POST /quiz_sessions 
  # Open a quiz to collect answers
  # Respond with the quiz session id
  def create 
    #debugger
    qs = QuizSession.new
    qs.owner_id=current_user.id

    if params[:name]
      qs.name = params[:name]
    end

    if params[:quiz_json]
      render :text => "Quiz Json required"
    end

    qs.quiz_results = [];
    qs.active=true

    # qs.url=short_url ( request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/quiz_sessions/#{qs.id.to_s}" )
    qs.url= request.env['HTTP_HOST'].sub(/^(m|www)\./, '') + "/quiz_sessions/#{qs.id.to_s}"
    qs.save!

    render :text => qs.id.to_s
  end


  # GET /quiz_sessions/X 
  #render vote page 
  def show
    @quiz_session = QuizSession.find(params[:id])
   #debugger
    if @quiz_session.active
      respond_to do |format|
        format.html { render :layout => 'iframe' }
        format.all { render }
      end
    else
      render 'quiz_sessions/closed' # Quiz is closed!!!
    end
  end

  def results # GET /quiz_sessions/X/results => render results page 
    @quiz_session = QuizSession.find(params[:id])
    @results = {}
    @results[:quiz_session_id] = @quiz_session.id
    @results[:quiz_id] = @quiz_session.quiz.id
    respond_to do |format|
      format.html { render :layout => 'iframe' }
      @results[:results] = @quiz_session.answers
      format.all { render :json => @results }
    end
  end

  def index # GET /quiz_sessions => list your quiz sessions as a list
    # TODO
  end

  def update # PUT /quiz_sessions/X => vote => respond
    return if params[:option].blank?
    @quiz_session = QuizSession.find(params[:id])
    render 'quiz_sessions/closed' unless @quiz_session.active # Quiz is closed!!!
    qa = QuizAnswer.new
    qa.quiz_session = @quiz_session
    qa.json = '{"option": ' + params[:option].to_json + '}'
    qa.save!
    render 'quiz_sessions/accepted'
  end

  def destroy # DELETE /quiz_sessions/X => close quiz => show results
    @quiz_session = QuizSession.find(params[:id])
    render 'quiz_sessions/not_owner' unless @quiz_session.owner = current_user
    @quiz_session.active=false
    @quiz_session.name = params[:name] unless params[:name].blank?
    @quiz_session.name = "No Name" if @quiz_session.name.blank?
    @quiz_session.closed_at = Time.now
    @quiz_session.save!
       render 'quiz_sessions/accepted'
  end
end
