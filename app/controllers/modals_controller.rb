class ModalsController < ApplicationController
  before_filter :profile_subject!

  respond_to :js

  def actor
    render
  end
end
