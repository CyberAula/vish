require 'net/http'
require 'net/https'

class SessionsController < Devise::SessionsController
  skip_before_filter :store_location
  after_filter :logout_oauth, :only => :destroy

  # GET /resource/sign_in
  def new
    super
  end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  def logout_oauth
  end
end
