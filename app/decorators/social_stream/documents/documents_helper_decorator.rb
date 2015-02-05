DocumentsHelper.module_eval do

  # Return the right icon of the resource
  def icon document, allowRaw=true
    #Default icons
    unless document.class.superclass.name != "Document"
      #For documents (based on SS documents)
      icon_name = case icon_mime_type document
        when :default then "file-o"
        when :text then "file-text-o"
        when :image then "image"
        when :audio then "music"
        when :video then "video-camera"
        when :pdf then "file-pdf-o"
        when :swf then "file-swf-o"
        when :zipfile then "file-zip-o"
        else "file" #icon_mime_type document
      end
    else
      #For new ViSH models
      icon_name = case document.class.name
        when "Link" then "link"
        when "Embed" then "code"
        when "Writing" then "file-text-o"
        when "Scormfile" then "scorm-o"
        when "Webapp" then "webapp-o"
        when "Workshop" then "lightbulb-o"
        else "file" # SocialStream::Documents.icon_mime_types[:default]
      end
    end

    #Custom Avatars
    unless allowRaw==false
      customAvatar = document.getAvatarUrl
    else
      customAvatar = nil
    end

    unless customAvatar.nil?
      return "<div class='img-box resource_avatar resource_avatar_for_#{ icon_name }' style='background-image: url("+customAvatar+")'></div><i class=\"icon-#{ icon_name } icon-#{ icon_name }_decorator\"></i>"
    else
      return "<i class=\"fa fa-#{ icon_name }\"></i>".html_safe
    end
  end

  # Find the right class for the icon of this document, based on its format
  def icon_mime_type document
    if SocialStream::Documents.icon_mime_types[:subtypes].include?(document.format)
      document.format
    elsif SocialStream::Documents.icon_mime_types[:types].include?(document.mime_type_type_sym)
      document.mime_type_type_sym
    else
      "file" # SocialStream::Documents.icon_mime_types[:default]
    end
  end


end
