class MashmeInvitesController < ApplicationController

  before_filter :authenticate_user!

  def invite
    #params[:url]
    params[:targets].split(',').each do |t|
      to_actor = Actor.find(t)
      next if to_actor.blank?
      if to_actor.respond_to? :language
        I18n.locale = to_actor.language || I18n.default_locale
      end
      current_user.send_message(to_actor, mashme_invite(params[:room], to_actor.name), t('mashme.invitesubject'))
    end
    render :nothing => true
  end

  def mashme_invite room, username
    t('mashme.invitebody_html', :room => room, :username => CGI::escapeHTML(username), :domain => request.env['HTTP_HOST'])
  end

end
