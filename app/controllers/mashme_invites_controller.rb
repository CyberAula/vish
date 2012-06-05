class MashmeInvitesController < ApplicationController

  before_filter :authenticate_user!

  def invite
    #params[:url]
    params[:targets].split(',').each do |t|
      Actor.find(t).notify(I18n.t('mashme.invitesubject'), "")
    end
  end

end
