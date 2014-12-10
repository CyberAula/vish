class StaticController < ApplicationController
  skip_before_filter :store_location, :only => [:legal_notice]

  def download_user_manual
    #add one to the user manual download count
    Stats.increment("user_manual_download_count", 1)
    send_file "#{Rails.root}/public/vish_user_manual.pdf", :type => 'application/pdf'
  end

  def legal_notice
  end

  def overview
  end

end
