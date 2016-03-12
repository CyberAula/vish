module ExcursionsHelper
  
  def excursion_raw_thumbail(excursion)
    Embed.checkUrlProtocol(excursion.thumbnail_url,request.protocol) || "/assets/logos/original/excursion-00.png"
  end

end
