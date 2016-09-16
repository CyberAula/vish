class MailListsController < ApplicationController

  before_filter :find_mail_list
  before_filter :authenticate_user!, :only => [ :show ]
  skip_after_filter :discard_flash, :only => [:subscribed, :unsubscribed]

  def show
    authorize! :show, @mail_list
    respond_to do |format|
      format.any { 
        render :json => @mail_list.contacts, :content_type => "application/json"
      }
    end
  end

  def subscribe
  end

  def subscribed
    unless params[:grant] == "true"
      flash[:errors] =  I18n.t("mail_list.grant_error")
      return redirect_to subscribe_mail_list_path(@mail_list)
    end

    #Create subscription to MailList
    if params[:actor_id]
      subscription = @mail_list.subscribe_actor(Actor.find_by_id(params[:actor_id]))
    else
      subscription = @mail_list.subscribe_email(params[:email],params[:name])
    end

    unless subscription.is_a? MailListItem
      if subscription.is_a? String
        flash[:errors] = subscription
      else
        flash[:errors] =  I18n.t("mail_list.subscription_generic_error")
      end
      return redirect_to subscribe_mail_list_path(@mail_list)
    end
    @email = subscription.email
    discard_flash
    render "subscribed"
  end

  def unsubscribe
  end

  def unsubscribed
    #Remove subscription to MailList
    if params[:actor_id]
      unsubscription = @mail_list.unsubscribe_actor(Actor.find_by_id(params[:actor_id]))
    else
      unsubscription = @mail_list.unsubscribe_email(params[:email])
    end

    unless unsubscription.is_a? MailListItem
      if unsubscription.is_a? String
        flash[:errors] = unsubscription
      else
        flash[:errors] =  I18n.t("mail_list.email_not_found")
      end
      return redirect_to unsubscribe_mail_list_path(@mail_list)
    end
    @email = unsubscription.email
    discard_flash
    render "unsubscribed"
  end


  private

  def find_mail_list
    @mail_list = MailList.find(params[:id])
  end
  
end

