class SpamReportsController < ApplicationController
  skip_after_filter :discard_flash, :only => [:create]

  def index
    redirect_to view_context.admin_open_reports_path
  end

  # POST /spam_reports
  def create
     if simple_captcha_valid?
        case params[:option]
        when "0"
          issue = params[:comment_spam]
        when "1"
          issue = params[:comment_error]
        else
          issue = nil
        end

        @report = SpamReport.new(:activity_object_id=> params[:activity_object_id], :reporter_actor_id => !current_subject.nil? ? Actor.normalize_id(current_subject) : nil, :issue=> issue, :report_value=> params[:option])    

        if @report.save
          flash[:success] = t('report.success')
          SpamReportMailer.send_report(current_subject, @report.issueType, issue, params[:activity_object_id]).deliver
        else
          flash[:failure] = t('report.failure')
        end

        redirect_to request.referer
     else
        flash[:failure] = t('simple_captcha.error')
        redirect_to request.referer
    end
  end

  # PUT /spam_reports/:id
  def update
    @report = SpamReport.find(params[:id])
    authorize! :update, @report

    @report.update_attributes(params[:spam_report])

    respond_to do |format|
      format.html { 
        redirect_to view_context.admin_open_reports_path
      }
    end
  end

  # GET /spam_reports/:id/open
  def open
    @report = SpamReport.find(params[:id])
    authorize! :update, @report

    @report.pending = true
    @report.save!

    respond_to do |format|
      format.html { 
        redirect_to view_context.admin_open_reports_path
      }
    end
  end

  # GET /spam_reports/:id/close
  def close
    @report = SpamReport.find(params[:id])
    authorize! :update, @report

    @report.pending = false
    @report.save!

    respond_to do |format|
      format.html { 
        redirect_to view_context.admin_open_reports_path
      }
    end
  end

  # DELETE /spam_reports/:id
  def destroy
    @report = SpamReport.find(params[:id])
    authorize! :destroy, @report

    @report.destroy
    respond_to do |format|
      format.html { redirect_to view_context.admin_open_reports_path }
    end
  end

end