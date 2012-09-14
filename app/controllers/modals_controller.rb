class ModalsController < ApplicationController
  before_filter :profile_subject!, :only => :actor
  before_filter :kill_cache

  respond_to :js

  def actor
    render
  end

  def embed
    @embed = Embed.find(params[:id])
    render
  end

  def link
    @link = Link.find(params[:id])
    render
  end

  def officedoc
    @document = Officedoc.find(params[:id])
    render 'modals/document'
  end

  def audio
    @document = Audio.find(params[:id])
    render 'modals/document'
  end

  def video
    @document = Video.find(params[:id])
    render 'modals/document'
  end

  def picture
    @document = Picture.find(params[:id])
    render 'modals/document'
  end

  def swf
    @document = Swf.find(params[:id])
    render 'modals/document'
  end

  def document
    @document = Document.find(params[:id])
    render
  end

  private

  def kill_cache
    headers['Last-Modified'] = Time.now.httpdate
  end
end
