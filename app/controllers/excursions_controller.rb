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

class ExcursionsController < ApplicationController
  # Quick hack for bypassing social stream's auth
  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :clone]
  before_filter :profile_subject!, :only => :index
  before_filter :hack_auth, :only => [ :new, :create]
  skip_load_and_authorize_resource :only => [ :preview, :clone, :manifest, :recommended]
  include SocialStream::Controllers::Objects
  include HomeHelper

  def manifest
    headers['Last-Modified'] = Time.now.httpdate

    @excursion = Excursion.find_by_id(params[:id])
    render 'cache.manifest', :layout => false, :content_type => 'text/cache-manifest'
  end

  def clone
    original = Excursion.find_by_id(params[:id])
    if original.blank?
      flash[:error] = t('excursion.clone.not_found')
      redirect_to home_path if original.blank? # Bad parameter
    #elsif original.author == current_subject.actor
      #flash[:warning] = t('excursion.clone.owner')
      #redirect_to excursion_path(original)
    else
      # Do clone
      excursion = original.clone_for current_subject.actor
      flash[:success] = t('excursion.clone.ok')
      redirect_to excursion_path(excursion)
    end
  end

  def new
    new! do |format|
      format.full { render :layout => 'iframe' }
    end
  end

  def edit
    edit! do |format|
      format.full { render :layout => 'iframe' }
    end
  end

  def create
    params[:excursion].permit!
    @excursion = Excursion.new(params[:excursion])
    if(params[:draft] and params[:draft] == "true")
      @excursion.draft = true
    else
      @excursion.draft = false
    end
    @excursion.save!
    render :json => { :url => (@excursion.draft ? excursions_path : excursion_path(resource)) }
  end

  def update
    params[:excursion].permit!
    @excursion = Excursion.find(params[:id])
    if(@excursion.draft and params[:draft] and params[:draft] == "true")
      @excursion.draft = true
    else
      @excursion.draft = false
    end
    @excursion.update_attributes(params[:excursion])
    @excursion.save!
    render :json => { :url => (@excursion.draft ? excursions_path : excursion_path(resource)) }
  end

  def destroy
    destroy! do |format|
      format.all { redirect_to home_path }
    end
  end

  def preview
    respond_to do |format|
      format.all { render "show.full.erb", :layout => 'iframe' }
    end
  end

  def show
    show! do |format|
      format.html {
        if @excursion.draft and (can? :edit, @excursion)
          redirect_to edit_excursion_path(@excursion)
        else
          render
        end
      }
      format.full {
        if params[:orgUrl]
          @orgUrl = params[:orgUrl]
        end
        render :layout => 'iframe'
      }
      format.mobile { render :layout => 'iframe' }
      format.json { render :json => resource }
      format.gateway { 
        @gateway = params[:gateway]
        render :layout => 'iframe'
      }
      format.scorm {
        @excursion.to_scorm(self)
        send_file "#{Rails.root}/public/scorm/excursions/#{@excursion.id}.zip", :type => 'application/zip', :disposition => 'attachment', :filename => "scorm-#{@excursion.id}.zip"
      }
    end
  end

  def search
    headers['Last-Modified'] = Time.now.httpdate

    @found_excursions = if params[:scope].present? and params[:scope] == "like"
                          subject_excursions search_subject, { :scope => :like, :limit => params[:per_page].to_i } # This WON'T search... it's a scam
                        else
                          Excursion.search params[:q], search_options
                        end

    respond_to do |format|
      format.html {
        if @found_excursions.size == 0 and params[:scope].present? and params[:scope] == "like"
          render :partial => "excursions/fav_zero_screen"
        else
          render :layout => false
        end
      }
      format.json { render :json => @found_excursions }
    end
  end

  def recommended
    render :partial => "excursions/filter_results", :locals => {:excursions => current_subject.excursion_suggestions(4) }
  end

  private

  def allowed_params
    [:json, :slide_count, :thumbnail_url, :draft, :offline_manifest, :excursion_type]
  end

  def search_options
    opts = search_scope_options

    # Allow  me to search only (e.g.) Flashcards
    opts.deep_merge!({
      :conditions => { :excursion_type => params[:type] }
    }) unless params[:type].blank?

    # Pagination
    opts.deep_merge!({
      :order => :created_at,
      :sort_mode => :desc,
      :per_page => params[:per_page] || 20,
      :page => params[:page]
    })

    opts
  end

  def search_subject
    return current_subject if request.referer.blank?
    @search_subject ||=
      ( Actor.find_by_slug(URI(request.referer).path.split("/")[2]) || current_subject )
  end

  def search_scope_options
    if params[:scope].blank? || search_subject.blank?
      return {}
    end

    case params[:scope]
    when "me"
      if user_signed_in? and (search_subject == current_subject)
        { :with => { :author_id => [ search_subject.id ] } }
      else
        { :with => { :author_id => [ search_subject.id ], :draft => false } }
      end
    when "net"
      { :with => { :author_id => search_subject.following_actor_ids, :draft => false } }
    when "other"
      { :without => { :author_id => search_subject.following_actor_and_self_ids }, :with => { :draft => false } }
    else
      raise "Unknown search scope #{ params[:scope] }"
    end
  end

  def hack_auth
    params["excursion"] ||= {}
    params["excursion"]["relation_ids"] = [Relation::Public.instance.id]
    params["excursion"]["owner_id"] = current_subject.actor_id
    params["excursion"]["author_id"] = current_subject.actor_id
    params["excursion"]["user_author_id"] = current_subject.actor_id
  end
end
