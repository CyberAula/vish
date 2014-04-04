class ScormfilesController < ApplicationController
  before_filter :authenticate_user!
  include SocialStream::Controllers::Objects
end

