class Link < Document
  include SocialStream::Models::Object

  def format
    :link
  end

end