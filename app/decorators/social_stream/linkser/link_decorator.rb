Link.class_eval do

  validates_presence_of :title, :allow_blank => false

  # Method that returns a processed url with some enhancements:
  # - Adds http/s if not present
  # - Modifies urls from content providers (e.g. youtube, prezi, ...) if the url is not embeddable
  def getProcessedUrl
    urlWithProtocol = self.getUrlWithProtocol

    uri = URI(urlWithProtocol) rescue nil
    return urlWithProtocol if uri.nil? or uri.host.blank? or uri.path.blank? or uri.scheme.blank?
    myparams = uri.query.nil? ? [] : (CGI::parse(uri.query) rescue [])
    
    final_url = ""
    case
    when uri.host[/youtu.be|youtube.com/] && uri.path.start_with?("/watch")
      final_url = uri.scheme + "://" + uri.host + "/embed/" + myparams["v"][0]
    when uri.host[/prezi.com/] && !uri.path.start_with?("/embed/")
      presentation = uri.path[1..uri.path.index("/",1)-1]
      final_url = uri.scheme + "://" + uri.host + "/embed/" + presentation
    when uri.host[/slides.com/]  && !uri.path.end_with?("/embed")
      final_url = uri.scheme + "://" + uri.host +  uri.path.sub("#/","") + "/embed"
    when uri.host[/vimeo.com/] && uri.host[/player.vimeo.com/].nil?
      final_url = uri.scheme + "://" + "player." + uri.host + "/video" + uri.path
    else
      final_url = urlWithProtocol
    end

    final_url
  end

  def getUrlWithProtocol
    if self.url.start_with?('http:') or self.url.start_with?('https:')
      self.url
    else
      if self.url.start_with?('//')
        ("http:"+ self.url)
      else
        ("http://"+ self.url)
      end
    end
  end

  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :url => url,
     :type => "Link"
    }
  end

end
