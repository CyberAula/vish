class HomeController < ApplicationController
  before_filter :authenticate_user!
  layout "home"
end
