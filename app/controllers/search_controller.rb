class SearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  RESULTS_SEARCH_PER_PAGE=24

  def index
    params[:page] = params[:page] || 1

    @search_result =
      if params[:q].blank?
        search :extended # TODO: this should have :match_mode => :fullscan for efficiency
      elsif params[:q].strip.size < SocialStream::Search::MIN_QUERY
        Kaminari.paginate_array([])
      elsif params[:mode] == "quick"
        search :quick
      else
        search :extended
      end

    respond_to do |format|
      format.html {
        if request.xhr?
          if params[:mode] == "quick"
            render partial: "quick"
          else
            render partial: 'results'            
          end
        end
      }

      format.json {
        json_obj = (
          params[:type].present? ?
          { params[:type].pluralize => @search_result.compact } :
          @search_result.compact
        )

        render :json => json_obj.to_json(helper: self)
      }

      format.js
    end
  end

  private

  def search mode
    page =  ( mode == :quick ? 1 : params[:page] )
    limit = ( mode == :quick ? 7 : RESULTS_SEARCH_PER_PAGE )

    case params[:sort_by]
    when 'ranking'
      order = 'ranking DESC'
    when 'popularity'
      #Use ranking instead of popularity
      order = 'ranking DESC'
      # order = 'popularity DESC'
    when 'updated_at'
      order = 'updated_at DESC'
    when 'created_at'
      order = 'created_at DESC'
    when 'visits'
      order = 'visit_count DESC'
    when 'favorites'
      order = 'like_count DESC'
    else
      #order by relevance
      order = nil
    end

    unless params[:ids_to_avoid].nil?
      params[:ids_to_avoid] = params[:ids_to_avoid].split(",")
    end

    models = SocialStream::Search.models(mode, params[:type])
    RecommenderSystem.search({:keywords=>params[:q], :n=>limit, :page=>page, :order => order, :models => models, :ids_to_avoid=>params[:ids_to_avoid]})
  end

end

          