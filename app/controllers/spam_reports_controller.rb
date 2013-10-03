class SpamReportsController < ApplicationController
  
  # POST /spam_reports
  def create
    #save reporter_user_id
    #redirect to excursion
    issue = params[:comment_error] !="" ? params[:comment_error] : params[:comment_spam]
    @spam = SpamReport.new(:activity_object_id=> params[:activity_object_id], :reporter_user_id => current_subject ? current_subject.id : 0, :issue=> issue, :report_value=> params[:option])
    @spam.save!
    flash[:success] = t('spam.success')
    SpamReportMailer.send_report(current_subject, params[:option], issue, params[:activity_object_id])
    redirect_to request.referer
  end

  
end