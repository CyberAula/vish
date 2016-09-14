Link.class_eval do

  #method that returns a processed url with some fixes
  #adds http if not present
  #fixes youtube, prezi, ... if the url is not embedable
  def getProcessedUrl
    final_url = url.start_with?('http') ? url : "http://"+url
    if final_url.start_with?('https://www.youtube.com/watch?v=') || final_url.start_with?('http://www.youtube.com/watch?v=')
      final_url = final_url.sub '/watch?v=', '/embed/'
    elsif final_url.start_with?('https://prezi.com/') && !final_url.start_with?('https://prezi.com/embed/')
      #we remove "https://prezi.com/" and from the last "/" to the end to get the video identifier
      video = final_url[18..final_url.index("/",18)-1]
      final_url = "https://prezi.com/embed/" + video
    elsif (final_url.start_with?('http://slides.com/') || final_url.start_with?('slides.com/')) && !final_url.end_with?('/embed')
      final_url = final_url[0..-3] + "/embed"
    end
    return final_url
  end

end
