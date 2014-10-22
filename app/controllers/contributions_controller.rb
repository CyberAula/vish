# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

class ContributionsController < ApplicationController

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update]
  before_filter :fill_create_params, :only => [:new, :create]

  include SocialStream::Controllers::Objects

  #############
  # REST methods
  #############

  def index
    super
  end

  def show
    show! do |format|
      format.html {
        render        
      }
    end
  end

  def new
    new! do |format|
      format.any {
        render 'new'
      }
    end
  end

  def edit
    edit! do |format|
      format.html {
        render
      }
    end
  end
  

  def create
    super do |format|
      format.html {        
          render
      }
    end
  end

  

  def destroy
    destroy! do |format|
      format.all { redirect_to user_path(current_subject) }
    end
  end


  private

  def allowed_params
    [ ]
  end

  def fill_create_params
    params["contribution"] ||= {}

    unless current_subject.nil?
      params["contribution"]["owner_id"] = current_subject.actor_id
      params["contribution"]["author_id"] = current_subject.actor_id
      params["contribution"]["user_author_id"] = current_subject.actor_id
    end
  end


end