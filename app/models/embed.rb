class Embed < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :fulltext, :allow_blank => false
  validates_presence_of :title, :allow_blank => false
  
  define_index do
    activity_object_index
    has live
  end

  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :fulltext => fulltext
    }
  end

  #Change URLs to https when clientProtocol is HTTPs
  def self.checkUrlProtocol(url,clientProtocol)
    return url unless url.is_a? String and clientProtocol.include?("https")
    protocolMatch = url.scan(/^https?:\/\//)
    return url if protocolMatch.blank?

    urlProtocol = protocolMatch[0].sub(":\/\/","");
    clientProtocol = clientProtocol.sub(":\/\/","");

    if (urlProtocol != clientProtocol)
      case(clientProtocol)
        when "https"
          #Try to load HTTP url over HTTPs
          url = "https" + url.sub(urlProtocol,""); #replace first
        when "http"
          #Try to load HTTPs url over HTTP. Do nothing.
        else
         #Document is not loaded over HTTP or HTTPs. Do nothing.
        end
    end
    return url
  end

end
