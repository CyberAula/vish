class SearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  RESULTS_SEARCH_PER_PAGE=24

  def index
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
          { params[:type].pluralize => @search_result } :
          @search_result
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

    SocialStream::Search.search(params[:q],
                                current_subject,
                                mode:  mode,
                                key:   params[:type],
                                page:  page,
                                limit: limit)

  end
end
