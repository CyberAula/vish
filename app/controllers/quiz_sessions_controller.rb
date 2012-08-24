class QuizSessionsController < ApplicationController
  before_filter :authenticate_user!, :only => [ :create, :delete ]

  def create # POST /quiz_sessions => open quiz to collect answers => respond with quiz_session id
    return if params[:quiz_id].blank?
    qs = QuizSession.new
    qs.quiz = Quiz.find(params[:quiz_id])
    qs.owner=current_user
    qs.active=true
    qs.name = params[:name] unless params[:name].blank?
    qs.save!
    qs.url="/quiz_sessions/#{qs.id.to_s}"
    qs.save!
    render :text => qs.id.to_s
  end

   def show # GET /quiz_sessions/X => render vote or results page 
    @quiz_session = QuizSession.find(params[:id])
    render :layout => 'iframe'
  end

  def index # GET /quiz_sessions => list your quiz sessions as a list
    # TODO
  end

  def update # PUT /quiz_sessions/X => vote => redirect to show
    return if params[:option].blank?
    @quiz_session = QuizSession.find(params[:id])
    render 'quiz_sessions/closed' unless @quiz_session.active # Quiz is closed!!!
    qa = QuizAnswer.new
    qa.quiz_session = @quiz_session
    qa.json = '{"option": ' + params[:option].to_json + '}'
    qa.save!
    redirect_to quiz_session_path(@quiz_session.id)
  end

  def destroy # DELETE /quiz_sessions/X => close quiz => show results
    @quiz_session = QuizSession.find(params[:id])
    render 'quiz_sessions/not_owner' unless @quiz_session.owner = current_user
    @quiz_session.active=false
    @quiz_session.name = params[:name] unless params[:name].blank?
    @quiz_session.name = "No Name" if @quiz_session.name.blank?
    @quiz_session.closed_at = Time.now
    @quiz_session.save!
    redirect_to quiz_session_path(@quiz_session)
  end
end
