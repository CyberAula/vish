Link.class_eval do

  validates_presence_of :title, :allow_blank => false

  # Method that returns a processed url with some enhancements:
  # - Adds http/s if not present
  # - Modifies urls from content providers (e.g. youtube, prezi, ...) if the url is not embeddable
  def getProcessedUrl
    urlWithProtocol = self.getUrlWithProtocol
    uri = URI(urlWithProtocol)
    myparams = uri.query ? CGI::parse(uri.query) : []
    final_url = ""
    case
    when uri.host[/youtu.be|youtube.com/] && uri.path.start_with?("/watch")
      final_url = uri.scheme + "://" + uri.host + "/embed/" + myparams["v"][0]
    when uri.host[/prezi.com/] && !uri.path.start_with?("/embed/")
      presentation = uri.path[1..uri.path.index("/",1)-1]
      final_url = uri.scheme + "://" + uri.host + "/embed/" + presentation
    when uri.host[/slides.com/]  && !uri.path.end_with?("/embed")
      final_url = uri.scheme + "://" + uri.host +  uri.path.sub("#/","") + "/embed"
    when uri.host[/vimeo.com/]
      final_url = uri.scheme + "://" + "player." + uri.host + "/video" + uri.path
    else
      final_url = urlWithProtocol
    end
    final_url
  end

  def getUrlWithProtocol
     final_url = link.url.start_with?('http') ? link.url : "http://"+link.url
     final_url
  end

end
